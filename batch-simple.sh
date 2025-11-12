#!/usr/bin/env bash
# Simple portable batch runner for annotate_images_enhanced.py using uv
# Usage:
#   ./batch-simple.sh -i <input_dir> -o <output_dir> [-c <categories.json>] [-m <model>] [-C <context>] [-n] [-v]
set -euo pipefail

INPUT_DIR=""
OUTPUT_DIR=""
CATEGORIES="image_categories_enhanced.json"
MODEL="qwen3-vl:30b"
CONTEXT_SIZE=500
VERBOSE=false
DRYRUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") -i <input_dir> -o <output_dir> [options]

Options:
  -i DIR    Input directory containing .md files (required)
  -o DIR    Output directory for results (required)
  -c FILE   Categories JSON (default: ${CATEGORIES})
  -m MODEL  Ollama model (default: ${MODEL})
  -C N      Context size (default: ${CONTEXT_SIZE})
  -n        Dry run
  -v        Verbose (passes --verbose to Python and prints the command)
  -h        Help
EOF
}

while getopts ":i:o:c:m:C:nvh" opt; do
  case "$opt" in
    i) INPUT_DIR=$OPTARG ;;
    o) OUTPUT_DIR=$OPTARG ;;
    c) CATEGORIES=$OPTARG ;;
    m) MODEL=$OPTARG ;;
    C) CONTEXT_SIZE=$OPTARG ;;
    n) DRYRUN=true ;;
    v) VERBOSE=true ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
  echo "Error: -i and -o are required." >&2
  usage
  exit 2
fi

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: input directory not found: $INPUT_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

found_any=false
while IFS= read -r -d '' file; do
  found_any=true
  base="$(basename "$file")"
  stem="${base%.md}"
  out_md="${OUTPUT_DIR}/${stem}_annotated.md"
  sum_md="${OUTPUT_DIR}/${stem}_summary.md"

  cmd=( uv run annotate_images_enhanced.py
        --input "$file"
        --output "$out_md"
        --summary "$sum_md"
        --categories "$CATEGORIES"
        --model "$MODEL"
        --context-size "$CONTEXT_SIZE" )

  if $VERBOSE; then
    cmd+=( --verbose )
  fi

  echo "📄 Processing: $base"
  if $VERBOSE || $DRYRUN; then
    printf '▶ '
    for a in "${cmd[@]}"; do printf '%q ' "$a"; done
    printf '\n'
  fi

  if $DRYRUN; then
    continue
  fi

  "${cmd[@]}"
done < <(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null)

if ! $found_any; then
  echo "No markdown files found in $INPUT_DIR"
fi
