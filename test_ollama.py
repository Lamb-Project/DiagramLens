#!/usr/bin/env python3
"""
Simple test script to verify Ollama image handling.
It loads a local image (e.g., img-parse/0.jpg) and asks the model
to generate a short description.
"""
import base64
import json
import sys
from pathlib import Path
import requests

# Adjust if your Ollama server runs on a different host/port
OLLAMA_URL = "http://localhost:11434/api/chat"
# Increase timeout because the model may need to load into memory
TIMEOUT = 300  # seconds

def load_image_as_base64(image_path: Path) -> str:
    """Read an image file and return a base64‑encoded string."""
    with image_path.open("rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def call_ollama(model: str, prompt: str, image_path: Path | None = None, temperature: float = 0.0) -> str:
    # Build the messages array with images if provided
    messages = [{
        "role": "user", 
        "content": prompt
    }]
    
    if image_path:
        messages[0]["images"] = [load_image_as_base64(image_path)]
    
    payload = {
        "model": model,
        "messages": messages,
        "options": {
            "temperature": temperature,
        },
        "stream": False,
    }
    
    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=TIMEOUT)
        resp.raise_for_status()
        data = resp.json()
        return data.get("message", {}).get("content", "").strip()
    except requests.exceptions.HTTPError as exc:
        # Try to get more details about the error
        try:
            error_detail = resp.json()
            sys.stderr.write(f"[ERROR] Ollama request failed: {exc}\nDetails: {error_detail}\n")
        except:
            sys.stderr.write(f"[ERROR] Ollama request failed: {exc}\n")
        return ""
    except Exception as exc:
        sys.stderr.write(f"[ERROR] Ollama request failed: {exc}\n")
        return ""

def main() -> None:
    if len(sys.argv) != 3:
        sys.stderr.write("Usage: test_ollama.py <model> <image_path>\n")
        sys.exit(1)
    
    model = sys.argv[1]
    image_path = Path(sys.argv[2]).resolve()
    
    if not image_path.is_file():
        sys.stderr.write(f"[ERROR] Image not found: {image_path}\n")
        sys.exit(1)
    
    prompt = (
        "Provide a concise (1‑2 sentence) description of the image. "
        "Focus on the main elements and their purpose."
    )
    
    description = call_ollama(model=model, prompt=prompt, image_path=image_path, temperature=0.2)
    
    if description:
        print("[RESULT] Description:")
        print(description)
    else:
        print("No description returned.")

if __name__ == "__main__":
    main()