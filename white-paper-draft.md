Perfect — that’s a thorough README and it gives us all the detail needed to make the “methods” section of your paper technically sound and verifiable.

Here’s how we can integrate that into a polished and cohesive **technical paper draft** that accurately reflects both **DeepSeekOCR-MLX** and **DiagramLens** in your processing pipeline.

---

## Title

**A Local Multimodal Pipeline for Technical Report Analysis Using Vision-Language Models**

---

Marc Alier, Juanan Pereira, Francisco Garcia-Peñalvo, María José Casañ

### Abstract

This paper presents a fully local, privacy-preserving pipeline for transforming technical PDF reports into analyzable Markdown documents enriched with visual diagram descriptions. The pipeline combines optical character recognition (OCR) and multimodal large language model (MLLM) analysis to enable automated quality assessment of technical documentation. All processing runs locally on Apple Silicon Mac Studio systems (M2 Ultra and M3 Ultra) to ensure compliance with data confidentiality and GDPR requirements. The workflow integrates **DeepSeekOCR-MLX** for PDF transcription and layout extraction, and **DiagramLens** for vision-language classification and description of diagrams. The resulting Markdown files include textual transcriptions and automatically generated descriptions for each detected diagram, forming a foundation for further automated evaluation using rubrics.

---

### 1. Introduction

Technical reports often contain a mix of narrative text, equations, and diagrams that convey essential technical or design information. Assessing the overall quality of such documents requires both textual and visual understanding. However, due to the sensitive nature of many reports—including industrial projects and academic works subject to privacy regulations—cloud-based AI services cannot be safely used.

This work introduces a fully local solution for extracting, interpreting, and enriching report contents to prepare them for structured quality assessment. The system combines open-source tools for OCR and visual reasoning, providing an end-to-end process that respects data confidentiality while leveraging modern multimodal large language models.

---

### 2. System Architecture

The workflow is divided into two main stages: **document transcription** and **diagram analysis** (Figure 1).

#### 2.1 Local Environment

All computations are executed locally on **Apple Mac Studio** systems equipped with **M2 Ultra** and **M3 Ultra** processors with maximum RAM configurations. This environment supports efficient inference of medium and large vision-language models via **Ollama**, without transmitting data externally.

#### 2.2 Stage 1 — PDF Transcription with DeepSeekOCR-MLX

The pipeline begins with **DeepSeekOCR-MLX**, a fork of DeepSeekOCR optimized for Apple’s MLX framework. It converts each page of a PDF technical report into a Markdown (`.md`) transcription while preserving layout information.

For each page, the system outputs:

* A Markdown file containing the recognized text
* A rendered image of the page with overlaid bounding boxes for text regions and figures
* Cropped images of each detected figure or diagram

The full document is also compiled into a combined Markdown file. This structured representation forms the input for the next stage.

#### 2.3 Stage 2 — Diagram Analysis with DiagramLens

**DiagramLens**, developed by the LAMB Project, extends this process by detecting and interpreting diagrams found in the Markdown file. Built in Python, it uses **vision-capable LLMs** (e.g., Qwen3-VL) accessed locally through **Ollama**.

The tool performs three sequential tasks:

1. **Contextual Pre-Classification** – The surrounding text of each image is analyzed to hypothesize the likely diagram type (UML, BPMN, architecture, ERD, etc.).
2. **Visual Confirmation** – The image and context are passed to a VLLM to confirm the classification.
3. **Diagram Description Generation** – Based on the confirmed category, DiagramLens uses a specialized prompt to generate a detailed technical description.

The system supports over 35 diagram types across domains such as software architecture, process modeling, and data design. Descriptions emphasize domain-relevant details (e.g., entities and relationships in ERDs, services and communication flows in architecture diagrams).

#### 2.4 Outputs

The final stage produces:

* A **fully annotated Markdown document**, where each diagram is followed by its classification and generated description
* A **summary file** listing all diagrams, their detected types, and condensed descriptions

These outputs enable automated agents to later evaluate report completeness, technical clarity, and consistency against defined rubrics.

---

### 3. Implementation Details

DiagramLens is open source under GPL v3 and available at [https://github.com/Lamb-Project/DiagramLens](https://github.com/Lamb-Project/DiagramLens). It requires Python 3.8+, Ollama, and a vision model such as `qwen3-vl:7b` or higher. The system’s modular design allows prompt customization, category expansion, and model substitution.

For performance, Ollama runs inference locally, avoiding GPU memory bottlenecks through streaming and model quantization. Typical inference with `qwen3-vl:8b` achieves acceptable latency (< 3 s per image) on M3 Ultra machines.

---

### 4. Use Cases and Applications

The generated annotated Markdown can serve multiple downstream applications:

* **Automated Rubric Evaluation** – Assessment agents can score clarity, completeness, and diagram accuracy.
* **Documentation Validation** – Detect mismatches between text and visual content.
* **Accessibility Enhancement** – Provide text alternatives for complex figures.
* **Knowledge Extraction** – Populate structured knowledge bases from visual elements.

---

### 5. Conclusion

This pipeline demonstrates that local multimodal AI workflows can effectively process and analyze complex technical reports while preserving confidentiality. By combining **DeepSeekOCR-MLX** for text extraction with **DiagramLens** for visual understanding, the system bridges the gap between document OCR and semantic analysis. The resulting annotated Markdown becomes a high-value dataset for automated assessment and technical documentation research.

---

Would you like me to include a **“Related Work”** and **“Future Work”** section next (to complete it as a publishable paper), or keep it at this stage-level summary version?
