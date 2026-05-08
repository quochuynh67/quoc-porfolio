#!/usr/bin/env bash
set -e

TARGET_DIR="./data/"

mkdir -p "$TARGET_DIR"

wget \
  --mirror \
  --no-parent \
  --continue \
  --reject "index.html*" \
  --directory-prefix "$TARGET_DIR" \
  https://cdn.emulatorjs.org/stable/data/

echo "Done."
echo "Files saved in: ./data/"

