#!/usr/bin/env bash

# Diagram Annotator Batch Processing Script
# Processes all markdown files in an input directory and outputs results to an output directory

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Default values
DEFAULT_MODEL="qwen3-vl:30b"
DEFAULT_CONTEXT_SIZE=500
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/annotate_images_enhanced.py"
CATEGORIES_FILE="${SCRIPT_DIR}/image_categories_enhanced.json"

# Function to display usage
usage() {
    cat << EOF
${BOLD}Usage:${NC} $0 [OPTIONS]

${BOLD}Options:${NC}
    -i, --input DIR        Input directory containing markdown files (required)
    -o, --output DIR       Output directory for annotated files (required)
    -m, --model MODEL      Ollama vision model to use (default: ${DEFAULT_MODEL})
    -c, --context SIZE     Context size for analysis (default: ${DEFAULT_CONTEXT_SIZE})
    -v, --verbose          Enable verbose output for each file
    -s, --skip-existing    Skip files that already have outputs
    -d, --dry-run          Show what would be processed without executing
    -h, --help             Display this help message

${BOLD}Examples:${NC}
    # Basic usage
    $0 -i docs/input -o docs/output

    # With custom model and verbose output
    $0 -i docs/input -o docs/output -m qwen3-vl:72b -v

    # Skip existing and use larger context
    $0 -i docs -o output -s -c 1000

EOF
    exit 1
}

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for uv
    if ! command -v uv &> /dev/null; then
        missing_deps+=("uv (install from https://github.com/astral-sh/uv)")
    fi
    
    # Check for Ollama
    if ! command -v ollama &> /dev/null; then
        missing_deps+=("Ollama")
    else
        # Check if Ollama is running
        if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            print_message "$YELLOW" "⚠ Warning: Ollama service is not running. Starting it..."
            ollama serve &> /dev/null &
            sleep 2
        fi
    fi
    
    # Check for the Python script
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        missing_deps+=("annotate_images_enhanced.py")
    fi
    
    # Check for categories file
    if [ ! -f "$CATEGORIES_FILE" ]; then
        missing_deps+=("image_categories_enhanced.json")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "$RED" "❌ Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        exit 1
    fi
}

# Function to process a single markdown file
process_file() {
    local input_file=$1
    local output_dir=$2
    local relative_path=$3
    
    # Create output file paths
    local output_subdir=$(dirname "$output_dir/$relative_path")
    local base_name=$(basename "$input_file" .md)
    local output_file="$output_subdir/${base_name}_annotated.md"
    local summary_file="$output_subdir/${base_name}_summary.md"
    
    # Create output subdirectory if needed
    mkdir -p "$output_subdir"
    
    # Skip if outputs exist and skip-existing is enabled
    if [ "$SKIP_EXISTING" = true ] && [ -f "$output_file" ]; then
        print_message "$YELLOW" "  ⏭ Skipping (output exists): $relative_path"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_message "$CYAN" "  Would process: $relative_path"
        echo "    → Output: $output_file"
        echo "    → Summary: $summary_file"
        return 0
    fi
    
    print_message "$BLUE" "  📄 Processing: $relative_path"
    
    # Build the command using uv run
    local cmd="uv run $PYTHON_SCRIPT"
    cmd="$cmd --input \"$input_file\""
    cmd="$cmd --output \"$output_file\""
    cmd="$cmd --summary \"$summary_file\""
    cmd="$cmd --categories \"$CATEGORIES_FILE\""
    cmd="$cmd --model $MODEL"
    cmd="$cmd --context-size $CONTEXT_SIZE"
    
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd --verbose"
    fi
    
    # Execute the command
    if eval $cmd > /dev/null 2>&1; then
        print_message "$GREEN" "  ✅ Success: $relative_path"
        return 0
    else
        print_message "$RED" "  ❌ Failed: $relative_path"
        return 1
    fi
}

# Function to find all markdown files
find_markdown_files() {
    local input_dir=$1
    # Only search in the top level directory, output NUL-delimited results to handle spaces/newlines
    find "$input_dir" -maxdepth 1 -type f -name "*.md" -print0 2>/dev/null
}

# Parse command line arguments
INPUT_DIR=""
OUTPUT_DIR=""
MODEL="$DEFAULT_MODEL"
CONTEXT_SIZE="$DEFAULT_CONTEXT_SIZE"
VERBOSE=false
SKIP_EXISTING=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -c|--context)
            CONTEXT_SIZE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--skip-existing)
            SKIP_EXISTING=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_message "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    print_message "$RED" "❌ Error: Input and output directories are required"
    usage
fi

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    print_message "$RED" "❌ Error: Input directory does not exist: $INPUT_DIR"
    exit 1
fi

# Print header
echo
print_message "$BOLD$CYAN" "═══════════════════════════════════════════════════════"
print_message "$BOLD$CYAN" "         Diagram Annotator - Batch Processing          "
print_message "$BOLD$CYAN" "═══════════════════════════════════════════════════════"
echo

# Print configuration
print_message "$BOLD" "Configuration:"
echo "  Input Directory:  $INPUT_DIR"
echo "  Output Directory: $OUTPUT_DIR"
echo "  Model:           $MODEL"
echo "  Context Size:    $CONTEXT_SIZE"
echo "  Skip Existing:   $SKIP_EXISTING"
echo "  Verbose:         $VERBOSE"
echo "  Dry Run:         $DRY_RUN"
echo

# Check dependencies
if [ "$DRY_RUN" = false ]; then
    print_message "$BOLD" "Checking dependencies..."
    check_dependencies
    print_message "$GREEN" "✅ All dependencies satisfied"
    echo
fi

# Create output directory
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Find all markdown files
print_message "$BOLD" "Scanning for markdown files..."
md_files=()
# Read NUL-delimited paths into array (portable to Bash 3.x)
while IFS= read -r -d "" f; do
    md_files+=("$f")
done < <(find_markdown_files "$INPUT_DIR")

if [ ${#md_files[@]} -eq 0 ]; then
    print_message "$YELLOW" "⚠ No markdown files found in $INPUT_DIR"
    exit 0
fi

print_message "$GREEN" "Found ${#md_files[@]} markdown file(s)"
echo

# Process files
print_message "$BOLD" "Processing files..."
echo

successful=0
failed=0
skipped=0

# Sequential processing
for file in "${md_files[@]}"; do
    relative_path="${file#$INPUT_DIR/}"
    
    if process_file "$file" "$OUTPUT_DIR" "$relative_path"; then
        ((successful++))
    else
        ((failed++))
    fi
done

# Calculate final statistics
for file in "${md_files[@]}"; do
    relative_path="${file#$INPUT_DIR/}"
    output_subdir=$(dirname "$OUTPUT_DIR/$relative_path")
    base_name=$(basename "$file" .md)
    output_file="$output_subdir/${base_name}_annotated.md"
    
    if [ "$SKIP_EXISTING" = true ] && [ -f "$output_file" ]; then
        ((skipped++))
    elif [ -f "$output_file" ]; then
        ((successful++))
    elif [ "$DRY_RUN" = false ]; then
        ((failed++))
    fi
done

# Print summary
echo
print_message "$BOLD$CYAN" "═══════════════════════════════════════════════════════"
print_message "$BOLD" "Processing Complete!"
echo
print_message "$BOLD" "Summary:"
print_message "$GREEN" "  ✅ Successful: $successful"
if [ $failed -gt 0 ]; then
    print_message "$RED" "  ❌ Failed:     $failed"
fi
if [ $skipped -gt 0 ]; then
    print_message "$YELLOW" "  ⏭ Skipped:    $skipped"
fi
echo
print_message "$BOLD" "Output location: $OUTPUT_DIR"
print_message "$BOLD$CYAN" "═══════════════════════════════════════════════════════"
echo

# Generate index file if multiple files were processed
if [ ${#md_files[@]} -gt 1 ] && [ "$DRY_RUN" = false ]; then
    index_file="$OUTPUT_DIR/index.md"
    print_message "$BOLD" "Generating index file: $index_file"
    
    cat > "$index_file" << EOF
# Diagram Annotation Results

Generated on: $(date)

## Configuration
- Model: $MODEL
- Context Size: $CONTEXT_SIZE
- Source Directory: $INPUT_DIR

## Processed Files

EOF
    
    for file in "${md_files[@]}"; do
        relative_path="${file#$INPUT_DIR/}"
        base_name=$(basename "$file" .md)
        output_subdir=$(dirname "$relative_path")
        
        if [ "$output_subdir" = "." ]; then
            echo "- [$base_name](./${base_name}_annotated.md) ([summary](./${base_name}_summary.md))" >> "$index_file"
        else
            echo "- [$relative_path](./$output_subdir/${base_name}_annotated.md) ([summary](./$output_subdir/${base_name}_summary.md))" >> "$index_file"
        fi
    done
    
    echo >> "$index_file"
    echo "## Statistics" >> "$index_file"
    echo "- Total Files: ${#md_files[@]}" >> "$index_file"
    echo "- Successful: $successful" >> "$index_file"
    echo "- Failed: $failed" >> "$index_file"
    echo "- Skipped: $skipped" >> "$index_file"
fi

# Exit with appropriate code
if [ $failed -gt 0 ]; then
    exit 1
else
    exit 0
fi