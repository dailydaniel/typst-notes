import { Command, type Child } from "@tauri-apps/plugin-shell";
import type { Transport } from "@codemirror/lsp-client";

/**
 * LSP Transport over Tauri sidecar stdin/stdout.
 * Spawns tinymist as a sidecar process and handles
 * Content-Length framing for JSON-RPC messages.
 *
 * Uses encoding: "raw" to receive stdout as Uint8Array
 * (not split by newlines), which is required for LSP framing.
 */
export class TauriLspTransport implements Transport {
  private child: Child | null = null;
  private handlers: Array<(message: string) => void> = [];
  private buffer: Uint8Array = new Uint8Array(0);
  private decoder = new TextDecoder();
  private encoder = new TextEncoder();

  async start(): Promise<void> {
    const command = Command.sidecar("binaries/tinymist", ["lsp"], {
      encoding: "raw",
    });

    command.stdout.on("data", (chunk: Uint8Array | number[]) => {
      const bytes = chunk instanceof Uint8Array ? chunk : new Uint8Array(chunk);
      const newBuf = new Uint8Array(this.buffer.length + bytes.length);
      newBuf.set(this.buffer);
      newBuf.set(bytes, this.buffer.length);
      this.buffer = newBuf;
      this.drain();
    });

    command.stderr.on("data", (chunk: Uint8Array | number[]) => {
      const bytes = chunk instanceof Uint8Array ? chunk : new Uint8Array(chunk);
      console.debug("[tinymist]", this.decoder.decode(bytes));
    });

    command.on("error", (err: string) => {
      console.error("[tinymist] process error:", err);
    });

    command.on("close", (data: { code: number | null }) => {
      console.warn("[tinymist] exited with code", data.code);
      this.child = null;
    });

    this.child = await command.spawn();
  }

  send(message: string): void {
    if (!this.child) throw new Error("LSP transport not connected");
    const body = this.encoder.encode(message);
    const header = this.encoder.encode(`Content-Length: ${body.byteLength}\r\n\r\n`);
    const frame = new Uint8Array(header.length + body.length);
    frame.set(header);
    frame.set(body, header.length);
    this.child.write(Array.from(frame));
  }

  subscribe(handler: (message: string) => void): void {
    this.handlers.push(handler);
  }

  unsubscribe(handler: (message: string) => void): void {
    const i = this.handlers.indexOf(handler);
    if (i >= 0) this.handlers.splice(i, 1);
  }

  async stop(): Promise<void> {
    if (this.child) {
      await this.child.kill();
      this.child = null;
    }
    this.buffer = new Uint8Array(0);
    this.handlers = [];
  }

  get isRunning(): boolean {
    return this.child !== null;
  }

  /** Find byte sequence in buffer */
  private findSequence(seq: Uint8Array, start = 0): number {
    outer: for (let i = start; i <= this.buffer.length - seq.length; i++) {
      for (let j = 0; j < seq.length; j++) {
        if (this.buffer[i + j] !== seq[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  private static SEPARATOR = new TextEncoder().encode("\r\n\r\n");

  /** Parse Content-Length framed messages from buffer */
  private drain(): void {
    while (true) {
      const sepIdx = this.findSequence(TauriLspTransport.SEPARATOR);
      if (sepIdx < 0) return;

      const headerStr = this.decoder.decode(this.buffer.slice(0, sepIdx));
      const match = headerStr.match(/Content-Length:\s*(\d+)/i);
      if (!match) {
        // Malformed header — skip past separator
        this.buffer = this.buffer.slice(sepIdx + 4);
        continue;
      }

      const bodyLen = parseInt(match[1], 10);
      const bodyStart = sepIdx + 4;

      if (this.buffer.length < bodyStart + bodyLen) return; // incomplete

      const body = this.decoder.decode(this.buffer.slice(bodyStart, bodyStart + bodyLen));
      this.buffer = this.buffer.slice(bodyStart + bodyLen);

      for (const h of this.handlers) {
        try {
          h(body);
        } catch (e) {
          console.error("[lsp handler error]", e);
        }
      }
    }
  }
}
