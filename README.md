# Diagram Annotator for Technical Documentation

A powerful Python tool that automatically identifies, categorizes, and generates detailed technical descriptions for diagrams in markdown documentation using vision-capable Large Language Models (LLMs) through Ollama.

Since the software is intended to be used in academical settings, we use Ollama to leverage local MLLMs like qwen3-vl:32b (the tested model).

The system performs well with md. files generated with PDF OCR analyzers like https://github.com/granludo/deepseekocr-mlx (the one we tested).

By Marc Alier & Juanan Pereira  https://lamb-project.org 

## 🎯 Overview

This tool processes markdown files containing software engineering diagrams and:
- **Automatically categorizes** diagrams into 35+ types (UML, C4, ERD, flowcharts, etc.)
- **Generates detailed technical descriptions** tailored to each diagram type
- **Uses context-aware analysis** to improve categorization accuracy
- **Produces annotated documentation** with inline technical descriptions
- **Creates comprehensive summaries** of all diagrams found

## ✨ Key Features

### Context-Aware Categorization
- Analyzes surrounding text to predict diagram types before visual inspection
- Combines textual context with visual analysis for higher accuracy
- Tracks prediction accuracy to measure context usefulness

### Extensive Diagram Support
Supports 35+ diagram types including:
- **UML Diagrams**: Class, Sequence, Use Case, State, Activity, Component, etc.
- **Architecture**: C4 Model, System Architecture, Cloud Architecture, Microservices
- **Data Modeling**: ERD, Database Schema, Data Flow Diagrams
- **Process**: Flowcharts, BPMN, Gantt Charts
- **Technical**: Network Diagrams, Git Workflows, API Specifications
- **Design**: UI Mockups, Wireframes
- **Analysis**: Decision Trees, Fault Trees, Mind Maps

### Intelligent Description Generation
- Custom prompts for each diagram type focusing on relevant details
- Structured analysis based on diagram-specific elements
- Technical accuracy in terminology and notation identification

## 📋 Requirements

- Python 3.8+
- [Ollama](https://ollama.ai/) installed and running locally
- A vision-capable model installed in Ollama (e.g., `qwen2-vl:7b`, `llava`, `bakllava`)
- [uv](https://github.com/astral-sh/uv) for dependency management (recommended)

## 🚀 Installation

### 1. Install Ollama
```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve
```

### 2. Pull a Vision Model
```bash
# Recommended: Qwen2-VL (good balance of quality and speed)
ollama pull qwen2-vl:7b

# Alternative options:
# ollama pull llava:13b
# ollama pull bakllava
```

### 3. Install Python Dependencies
```bash
# Using uv (recommended)
uv add requests pillow rich

# Or using pip
pip install requests pillow rich
```

## 💻 Usage

### Basic Usage
```bash
python annotate_images_enhanced.py \
    --input docs/architecture.md \
    --output docs/architecture_annotated.md \
    --summary docs/diagram_summary.md \
    --categories image_categories_enhanced.json \
    --model qwen3-vl:8b
```

### Advanced Options
```bash
python annotate_images_enhanced.py \
    --input docs/architecture.md \
    --output docs/architecture_annotated.md \
    --summary docs/diagram_summary.md \
    --categories image_categories_enhanced.json \
    --model qwen3-vl:32b \
    --context-size 750 \    # Amount of surrounding text to analyze
    --verbose              # Show detailed progress
```

### Command-Line Arguments

| Argument | Description | Required | Default |
|----------|-------------|----------|---------|
| `--input` | Path to source markdown file | Yes | - |
| `--output` | Path for annotated markdown output | Yes | - |
| `--summary` | Path for diagram summary output | Yes | - |
| `--categories` | JSON file with diagram categories | Yes | - |
| `--model` | Ollama vision model to use | No | `qwen2-vl:7b` |
| `--context-size` | Characters of context to analyze | No | 500 |
| `--verbose` | Show detailed progress | No | False |

## 📁 Project Structure

```
diagram-annotator/
├── annotate_images_enhanced.py    # Main script
├── image_categories_enhanced.json # Diagram categories & prompts
├── README.md                       # This file
├── examples/                       # Example documents
│   ├── input/                     # Sample markdown files
│   └── output/                    # Generated outputs
└── tests/                         # Test documents
```

## 🔧 Configuration

### Customizing Categories

Edit `image_categories_enhanced.json` to:
- Add new diagram types
- Modify categorization prompts
- Adjust context indicators
- Customize description generation prompts

Example structure:
```json
{
  "categories": ["class diagram", "sequence diagram", ...],
  "category_prompts": {
    "class diagram": {
      "prompt": "Describe this UML Class Diagram...",
      "focus_areas": ["classes", "methods", ...],
      "keywords": ["class", "inheritance", ...]
    }
  },
  "context_indicators": {
    "class diagram": ["UML", "inheritance", "class", ...]
  }
}
```

### Model Selection

Different models offer different trade-offs:

| Model | Quality | Speed | Memory | Best For |
|-------|---------|-------|---------|----------|
| `qwen2-vl:7b` | Good | Fast | 8GB | General use |
| `qwen2-vl:72b` | Excellent | Slow | 40GB+ | High accuracy |
| `llava:13b` | Good | Medium | 16GB | Balanced |
| `bakllava` | Fair | Fast | 8GB | Quick processing |

## 📊 Output Examples

### Annotated Markdown
The tool inserts technical descriptions after each diagram:

```markdown
![System Architecture](diagrams/architecture.png)

**Diagram Type:** Architecture Diagram

**Technical Description:**
This architecture diagram shows a microservices-based system with:
1. API Gateway serving as the entry point
2. Three microservices: User Service, Order Service, Payment Service
3. PostgreSQL database for User Service
4. MongoDB for Order Service
5. Redis cache layer
6. RabbitMQ message broker for inter-service communication
7. All services deployed in Docker containers
...
```

### Summary Document
Generates a comprehensive summary with:
- Total diagram count
- Category distribution statistics
- Context prediction accuracy
- Detailed entry for each diagram with description

## 🎯 Use Cases

 - **Documentation Generation**: Automatically document existing diagrams
 - **Documentation Validation**: Verify diagrams match their descriptions
 - **Knowledge Extraction**: Extract technical details from visual documentation
 - **Accessibility**: Generate text descriptions for screen readers
 - **Documentation Migration**: Convert visual-heavy docs to text-searchable format
 - **Quality Assurance**: Ensure diagram completeness and clarity

---

## License



This project is licensed under the **GNU General Public License v3.0**. See the full license text in the [`LICENSE`](../LICENSE) file.

For a concise summary of the GPL‑3.0 terms, you can also refer to the [SPDX license identifier](https://spdx.org/licenses/GPL-3.0-only.html).

## 🐛 Troubleshooting

### Common Issues

**Ollama Connection Error**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama if needed
ollama serve
```

**Model Not Found**
```bash
# List available models
ollama list

# Pull the required model
ollama pull qwen2-vl:7b
```

**Image Processing Errors**
- Ensure images are in supported formats (PNG, JPG, GIF, WebP)
- Check image file sizes (default limit: 5MB)
- Verify image paths are relative to the markdown file

**Low Accuracy**
- Try a larger model (e.g., `qwen3-vl:72b`)
- Increase context size with `--context-size 1000`
- Ensure diagram images are clear and high-resolution

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

1. **Additional Diagram Types**: Add support for more specialized diagrams
2. **Improved Prompts**: Refine categorization and description prompts
3. **Performance Optimization**: Batch processing, caching
4. **Output Formats**: Support for different output formats (HTML, PDF)
5. **Integration**: GitHub Actions, documentation pipelines

## 📄 License

This software is licensed GPL 3.0 
(c) Marc Alier


## 🙏 Acknowledgments

- Built with [Ollama](https://ollama.ai/) for local LLM inference
- Uses vision models like [Qwen2-VL](https://github.com/QwenLM/Qwen2-VL) and [LLaVA](https://llava-vl.github.io/)
- Inspired by the need for better technical documentation accessibility

## 📧 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Consult the troubleshooting section

---

**Note**: This tool requires significant computational resources for vision model inference. Performance will vary based on your hardware capabilities and chosen model size.