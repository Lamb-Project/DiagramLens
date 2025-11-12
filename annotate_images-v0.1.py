#!/usr/bin/env python3
"""
annotate_images.py

Read a markdown file, find all image references, ask a local Ollama model
to (1) categorize the diagram type and (2) generate a detailed technical description.
Two markdown files are written:

* <output_md> – the original markdown with technical descriptions inserted after each image.
* <summary_md> – a structured list of all diagrams with their categories and descriptions.

Usage
-----
    uv run img-parse/annotate_images.py \
        --input  path/to/file.md \
        --output path/to/file_annotated.md \
        --summary path/to/summary.md \
        --categories img-parse/image_categories.json \
        --model qwen3-vl:30b   # any Ollama vision model

Dependencies (install with uv)
---------------
    uv add requests pillow rich
"""

import argparse
import base64
import json
import os
import re
import sys
import unicodedata
from pathlib import Path
from typing import List, Tuple, Dict, Any

import requests
from PIL import Image
from rich.console import Console
from rich.progress import track

# ---------------------------------------------------------------
# Ollama helper
# ---------------------------------------------------------------
OLLAMA_URL = "http://localhost:11434/api/chat"
MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5 MiB


def _load_image_as_base64(image_path: Path) -> str:
    """Read an image file and return a base64‑encoded string."""
    with image_path.open("rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def call_ollama(
    model: str,
    prompt: str,
    image_path: Path | None = None,
    temperature: float = 0.0,
) -> str:
    """
    Send a request to the local Ollama server with proper image handling.
    """
    # Build message with image attached if provided
    message = {"role": "user", "content": prompt}
    
    if image_path:
        # Verify image validity
        Image.open(image_path).verify()
        # Attach image to the message object
        message["images"] = [_load_image_as_base64(image_path)]
    
    payload = {
        "model": model,
        "messages": [message],
        "options": {
            "temperature": temperature,
        },
        "stream": False,
    }

    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=120)
        resp.raise_for_status()
        data = resp.json()
        return data.get("message", {}).get("content", "").strip()
    except Exception as exc:
        sys.stderr.write(f"[ERROR] Ollama request failed: {exc}\n")
        return ""


# ---------------------------------------------------------------
# Markdown processing
# ---------------------------------------------------------------
IMG_REGEX = re.compile(r"!\[.*?\]\((?P<path>[^)]+)\)")


def find_image_refs(md_text: str) -> List[Tuple[str, int, int]]:
    """
    Find all markdown image references in the text.
    Returns: [(image_path, start_index, end_index), ...]
    """
    matches = []
    for m in IMG_REGEX.finditer(md_text):
        matches.append((m.group("path"), m.start(), m.end()))
    return matches


def load_categories_config(json_path: Path) -> Dict[str, Any]:
    """Load categories and their technical description prompts."""
    with json_path.open(encoding="utf-8") as f:
        return json.load(f)


# ---------------------------------------------------------------
# Main workflow
# ---------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate technical descriptions of diagrams in markdown files."
    )
    parser.add_argument("--input", required=True, help="Path to source .md file")
    parser.add_argument("--output", required=True, help="Path for annotated .md file")
    parser.add_argument("--summary", required=True, help="Path for summary .md file")
    parser.add_argument(
        "--categories",
        required=True,
        help="JSON file with categories and description prompts",
    )
    parser.add_argument(
        "--model",
        default="qwen3-vl:30b",
        help="Ollama vision model (default: qwen3-vl:30b)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed progress",
    )
    args = parser.parse_args()
    
    console = Console()

    # Resolve paths
    input_md_path = Path(args.input).resolve()
    output_md_path = Path(args.output).resolve()
    summary_md_path = Path(args.summary).resolve()
    categories_path = Path(args.categories).resolve()

    # Validate input
    if not input_md_path.is_file():
        console.print(f"[red]Error: Input file not found: {input_md_path}[/red]")
        sys.exit(1)

    # Load markdown and find images
    if args.verbose:
        console.print(f"[cyan]Reading: {input_md_path}[/cyan]")
    
    md_text = input_md_path.read_text(encoding="utf-8")
    image_refs = find_image_refs(md_text)
    
    if not image_refs:
        console.print("[yellow]No images found in markdown file.[/yellow]")
        sys.exit(0)
    
    console.print(f"[green]Found {len(image_refs)} diagram(s) to process[/green]")

    # Load configuration
    config = load_categories_config(categories_path)
    categories = config.get("categories", [])
    category_prompts = config.get("category_prompts", {})
    
    if not categories:
        console.print("[red]Error: No categories in configuration file.[/red]")
        sys.exit(1)

    # Process each image
    new_md_parts = []
    summary_lines = [
        "# Diagram Analysis Summary\n",
        f"**Source Document:** {input_md_path.name}\n",
        f"**Total Diagrams:** {len(image_refs)}\n",
        "\n---\n\n"
    ]
    
    last_idx = 0
    category_counts = {}

    # Progress tracking
    iterator = track(image_refs, description="Processing diagrams...") if not args.verbose else image_refs

    for idx, (img_path_str, start, end) in enumerate(iterator, 1):
        # Preserve markdown up to image
        new_md_parts.append(md_text[last_idx:start])
        img_md = md_text[start:end]
        new_md_parts.append(img_md)

        # Normalize path for Unicode issues
        img_path_str_norm = unicodedata.normalize('NFC', img_path_str).strip()
        img_path = (input_md_path.parent / img_path_str_norm).resolve()
        
        if args.verbose:
            console.print(f"\n[cyan]Processing [{idx}/{len(image_refs)}]: {img_path.name}[/cyan]")
        
        # Default values
        category = "unknown"
        description = ""
        
        # Check if file exists and is valid
        if not img_path.is_file():
            description = f"⚠️ Image file not found: `{img_path_str}`"
            console.print(f"[red]Missing: {img_path}[/red]")
        else:
            try:
                Image.open(img_path).verify()
            except Exception as e:
                description = f"⚠️ Invalid image file: `{img_path_str}`"
                console.print(f"[red]Invalid image: {e}[/red]")
            else:
                # Check size limit
                if img_path.stat().st_size > MAX_IMAGE_SIZE:
                    description = f"⚠️ Image too large (>{MAX_IMAGE_SIZE//1024//1024} MB)"
                    console.print(f"[yellow]Skipping large file[/yellow]")
                else:
                    # Step 1: Categorize the diagram
                    cat_prompt = (
                        "Identify the type of this software engineering diagram. "
                        f"Choose ONE from: {', '.join(categories)}\n"
                        "Reply with only the category name, nothing else."
                    )
                    
                    if args.verbose:
                        console.print("  [dim]Detecting diagram type...[/dim]")
                    
                    category_response = call_ollama(
                        model=args.model,
                        prompt=cat_prompt,
                        image_path=img_path,
                        temperature=0.0,
                    )
                    
                    # Normalize category
                    category = category_response.lower().strip()
                    if category not in [c.lower() for c in categories]:
                        category = "other"
                    
                    # Count categories
                    category_counts[category] = category_counts.get(category, 0) + 1
                    
                    if args.verbose:
                        console.print(f"  [green]Type: {category}[/green]")

                    # Step 2: Generate technical description
                    desc_prompt = category_prompts.get(
                        category,
                        category_prompts.get("other", {})
                    ).get("prompt", "Describe this diagram in detail.")
                    
                    if args.verbose:
                        console.print("  [dim]Generating technical description...[/dim]")
                    
                    description = call_ollama(
                        model=args.model,
                        prompt=desc_prompt,
                        image_path=img_path,
                        temperature=0.1,
                    )
                    
                    if not description:
                        description = "No description generated."
                    
                    if args.verbose and len(description) > 80:
                        console.print(f"  [dim]{description[:80]}...[/dim]")

        # Add technical description to markdown
        desc_block = (
            f"\n\n**Diagram Type:** {category.replace('_', ' ').title()}\n\n"
            f"**Technical Description:**\n{description}\n\n"
        )
        new_md_parts.append(desc_block)

        # Add to summary
        summary_lines.append(f"## Diagram {idx}: {os.path.basename(img_path_str)}\n\n")
        summary_lines.append(f"![{os.path.basename(img_path_str)}]({img_path_str})\n\n")
        summary_lines.append(f"- **Type:** {category.replace('_', ' ').title()}\n")
        summary_lines.append(f"- **File:** `{img_path_str}`\n")
        summary_lines.append(f"- **Description:**\n\n{description}\n\n")
        summary_lines.append("---\n\n")

        last_idx = end

    # Add remaining content
    new_md_parts.append(md_text[last_idx:])

    # Add category statistics to summary
    if category_counts:
        stats_lines = ["## Category Distribution\n\n"]
        for cat, count in sorted(category_counts.items()):
            percentage = (count / len(image_refs)) * 100
            stats_lines.append(f"- **{cat.replace('_', ' ').title()}:** {count} ({percentage:.1f}%)\n")
        stats_lines.append("\n---\n\n")
        # Insert after the header
        summary_lines[4:4] = stats_lines

    # Write output files
    output_md_path.parent.mkdir(parents=True, exist_ok=True)
    output_md_path.write_text("".join(new_md_parts), encoding="utf-8")
    
    summary_md_path.parent.mkdir(parents=True, exist_ok=True)
    summary_md_path.write_text("".join(summary_lines), encoding="utf-8")

    # Final report
    console.print(f"\n[green bold]✅ Processing Complete[/green bold]")
    console.print(f"📄 Annotated document: [cyan]{output_md_path}[/cyan]")
    console.print(f"📊 Summary document: [cyan]{summary_md_path}[/cyan]")
    
    if category_counts:
        console.print(f"\n[yellow]Category Distribution:[/yellow]")
        for cat, count in sorted(category_counts.items()):
            console.print(f"  • {cat.replace('_', ' ').title()}: {count}")


if __name__ == "__main__":
    main()