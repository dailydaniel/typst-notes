#!/usr/bin/env bash
set -euo pipefail

# Versions (match what's currently bundled)
TYPST_VERSION="0.14.2"
TINYMIST_VERSION="0.14.10"

# Target triple: auto-detect or pass as argument
# This is the TAURI target (what Tauri expects in the binary name).
if [ -n "${1:-}" ]; then
  TARGET="$1"
else
  ARCH=$(uname -m)
  OS=$(uname -s)
  case "$OS-$ARCH" in
    Darwin-arm64)  TARGET="aarch64-apple-darwin" ;;
    Darwin-x86_64) TARGET="x86_64-apple-darwin" ;;
    Linux-x86_64)  TARGET="x86_64-unknown-linux-gnu" ;;
    MINGW*|MSYS*)  TARGET="x86_64-pc-windows-msvc" ;;
    *)             echo "Unsupported platform: $OS-$ARCH"; exit 1 ;;
  esac
fi

BINDIR="$(dirname "$0")/../notes-app/src-tauri/binaries"
mkdir -p "$BINDIR"
BINDIR="$(cd "$BINDIR" && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Target: $TARGET"
echo "Output: $BINDIR"
echo ""

# --- Mapping: Tauri target -> release asset names ---
# Typst uses linux-musl in releases, Tauri expects linux-gnu in sidecar name
case "$TARGET" in
  x86_64-unknown-linux-gnu) TYPST_RELEASE_TARGET="x86_64-unknown-linux-musl" ;;
  *)                        TYPST_RELEASE_TARGET="$TARGET" ;;
esac

# --- Typst ---

case "$TARGET" in
  *windows*) TYPST_OUT="typst-${TARGET}.exe" ;;
  *)         TYPST_OUT="typst-${TARGET}" ;;
esac

echo "Fetching typst v${TYPST_VERSION} for ${TARGET}..."

case "$TARGET" in
  *windows*)
    TYPST_ASSET="typst-${TYPST_RELEASE_TARGET}.zip"
    gh release download "v${TYPST_VERSION}" \
      --repo typst/typst \
      --pattern "$TYPST_ASSET" \
      --dir "$TMPDIR"
    unzip -q "$TMPDIR/$TYPST_ASSET" -d "$TMPDIR"
    cp "$TMPDIR/typst-${TYPST_RELEASE_TARGET}/typst.exe" "$BINDIR/$TYPST_OUT"
    ;;
  *)
    TYPST_ASSET="typst-${TYPST_RELEASE_TARGET}.tar.xz"
    gh release download "v${TYPST_VERSION}" \
      --repo typst/typst \
      --pattern "$TYPST_ASSET" \
      --dir "$TMPDIR"
    tar -xf "$TMPDIR/$TYPST_ASSET" -C "$TMPDIR"
    cp "$TMPDIR/typst-${TYPST_RELEASE_TARGET}/typst" "$BINDIR/$TYPST_OUT"
    ;;
esac

chmod +x "$BINDIR/$TYPST_OUT" 2>/dev/null || true
echo "  -> $TYPST_OUT"

# --- Tinymist ---

case "$TARGET" in
  *windows*) TINYMIST_OUT="tinymist-${TARGET}.exe" ;;
  *)         TINYMIST_OUT="tinymist-${TARGET}" ;;
esac

echo "Fetching tinymist v${TINYMIST_VERSION} for ${TARGET}..."

case "$TARGET" in
  *apple*)
    TINYMIST_ASSET="tinymist-${TARGET}.tar.gz"
    gh release download "v${TINYMIST_VERSION}" \
      --repo Myriad-Dreamin/tinymist \
      --pattern "$TINYMIST_ASSET" \
      --dir "$TMPDIR"
    tar -xzf "$TMPDIR/$TINYMIST_ASSET" -C "$TMPDIR"
    cp "$TMPDIR/tinymist-${TARGET}/tinymist" "$BINDIR/$TINYMIST_OUT"
    ;;
  *linux*)
    gh release download "v${TINYMIST_VERSION}" \
      --repo Myriad-Dreamin/tinymist \
      --pattern "tinymist-linux-x64" \
      --dir "$TMPDIR"
    cp "$TMPDIR/tinymist-linux-x64" "$BINDIR/$TINYMIST_OUT"
    ;;
  *windows*)
    gh release download "v${TINYMIST_VERSION}" \
      --repo Myriad-Dreamin/tinymist \
      --pattern "tinymist-win32-x64.exe" \
      --dir "$TMPDIR"
    cp "$TMPDIR/tinymist-win32-x64.exe" "$BINDIR/$TINYMIST_OUT"
    ;;
esac

chmod +x "$BINDIR/$TINYMIST_OUT" 2>/dev/null || true
echo "  -> $TINYMIST_OUT"

# Remove macOS quarantine flag
if [ "$(uname -s)" = "Darwin" ]; then
  xattr -d com.apple.quarantine "$BINDIR/$TYPST_OUT" 2>/dev/null || true
  xattr -d com.apple.quarantine "$BINDIR/$TINYMIST_OUT" 2>/dev/null || true
  echo "Removed quarantine flags"
fi

echo ""
echo "Done. Binaries in $BINDIR:"
ls -la "$BINDIR/"
