#!/usr/bin/env bash
# Build nim-dotenv with the Nim compiler.
set -euo pipefail
cd "$(dirname "$0")"
export TC="$HOME/.local/toolchains"
export PATH="$TC/nim/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
mkdir -p bin
nim c -d:release --hints:off --nimcache:/tmp/nc_nim_dotenv -o:bin/nim-dotenv src/main.nim
echo "built bin/nim-dotenv"