#!/usr/bin/env bash
# Scripts/download-models.sh
#
# Downloads the large model files that are NOT stored in git:
#   1. qwen2.5-3b-instruct-q4_k_m.gguf  (~2 GB) — on-device chat LLM via llama.cpp
#   2. multilingual-e5-small.mlpackage  (~90 MB) — sentence embedding model (Core ML)
#
# Run this once after cloning before opening Xcode:
#   bash Scripts/download-models.sh
#
# Both files are placed in NuraSafe/ so the Xcode file-system-synchronised
# group automatically includes them in the app bundle target.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$REPO_ROOT/NuraSafe"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[download-models]${NC} $*"; }
warning() { echo -e "${YELLOW}[download-models]${NC} $*"; }
error()   { echo -e "${RED}[download-models] ERROR:${NC} $*" >&2; }

# ── Dependency check ─────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
    error "curl is required but not found. Install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# ── Model definitions ─────────────────────────────────────────────────────────
#
# GGUF — Qwen 2.5 3B Instruct Q4_K_M
# Source: https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF
GGUF_FILENAME="qwen2.5-3b-instruct-q4_k_m.gguf"
GGUF_URL="https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf?download=true"
GGUF_SIZE_APPROX="~2.0 GB"

# mlpackage — multilingual-e5-small (Core ML)
# Source: https://huggingface.co/humzasami/multilingual-e5-small-coreml
# (Replace this URL with your own HuggingFace hosted .mlpackage if you
#  have one, or convert locally with the instructions in EmbeddingService.swift
#  and host it yourself.)
E5_FILENAME="multilingual-e5-small.mlpackage"
E5_URL=""   # Set this to your hosted mlpackage URL, e.g.:
            # https://huggingface.co/<you>/multilingual-e5-small-coreml/resolve/main/multilingual-e5-small.mlpackage

# ── Helper: download with resume support ──────────────────────────────────────
download_file() {
    local url="$1"
    local dest="$2"
    local label="$3"
    local approx_size="${4:-}"

    if [[ -f "$dest" ]]; then
        info "$label already exists at $dest — skipping."
        return 0
    fi

    if [[ -z "$url" ]]; then
        warning "$label: no URL configured. See instructions below."
        return 1
    fi

    info "Downloading $label${approx_size:+ ($approx_size)}…"
    info "  → $dest"

    # -L follows redirects (HuggingFace uses them)
    # -C - resumes partial downloads
    # --progress-bar shows a clean bar instead of verbose stats
    if curl -L -C - --progress-bar -o "$dest" "$url"; then
        info "$label downloaded successfully."
    else
        error "Download failed for $label. Check your internet connection and the URL."
        rm -f "$dest"
        return 1
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
info "NuraSafe model downloader"
info "Destination: $DEST_DIR"
echo ""

mkdir -p "$DEST_DIR"

# 1. Download GGUF
download_file "$GGUF_URL" "$DEST_DIR/$GGUF_FILENAME" "Qwen 2.5 3B GGUF" "$GGUF_SIZE_APPROX"

# 2. Download E5 mlpackage
if [[ -n "$E5_URL" ]]; then
    download_file "$E5_URL" "$DEST_DIR/$E5_FILENAME" "multilingual-e5-small.mlpackage" "~90 MB"
else
    warning "multilingual-e5-small.mlpackage: no download URL configured."
    echo ""
    echo "  To generate it yourself, run the Python snippet in NuraSafe/Core/EmbeddingService.swift"
    echo "  (requires: pip install transformers coremltools torch sentencepiece)"
    echo "  Then place the resulting multilingual-e5-small.mlpackage in NuraSafe/"
    echo ""
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
info "Done. Open NuraSafe.xcodeproj in Xcode and build."
echo ""
echo "  The synchronized NuraSafe/ folder automatically picks up both files."
echo "  No manual 'Add to Target' step is required."
echo ""
