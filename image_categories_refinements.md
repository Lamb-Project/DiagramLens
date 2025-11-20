# Refinement of Vision-Language Model Prompts for Automated UML Diagram Analysis: A Case Study in Software Engineering Education


## 1. Problem Context

The automated assessment of software engineering documentation requires accurate extraction and interpretation of UML diagrams embedded in student submissions. Initial deployment of vision-language model (VLM) analysis revealed several systematic errors that compromised the reliability of quality assessments:

- **Diagram Conflation**: Multiple diagrams within single images were incorrectly merged into unified descriptions
- **Notation Misidentification**: Critical UML stereotypes and relationships were overlooked or incorrectly inferred
- **Type Confusion**: Architectural diagrams were frequently misclassified as simpler diagram types
- **Multiplicity Errors**: Cardinality indicators in class diagrams showed consistent misinterpretation patterns
- **Hallucination Under Degraded Input**: Poor image quality led to fabricated elements rather than acknowledged limitations

## 2. Methodological Approach to Prompt Refinement

The refinement process followed an evidence-based methodology:

1. **Error Pattern Analysis**: Systematic review of misclassified diagrams from student reports (samples 1.1, 1.6, 3.1, 3.2, 3.4)
2. **Expert Annotation**: Software engineering educators identified specific failure modes and their pedagogical impact
3. **Prompt Engineering**: Iterative refinement targeting identified weaknesses
4. **Validation Framework**: Addition of explicit verification checkpoints within prompts

## 3. Key Prompt Modifications and Rationale

### 3.1 Multiple Diagram Detection

**Change**: Added mandatory preliminary detection phase to identify multiple diagrams within single images.

**Rationale**: Student submissions frequently included multiple sequence diagrams or use case variants in single figures. The original prompts' assumption of single-diagram images led to erroneous conflation of distinct scenarios, particularly problematic when assessing completeness of use case coverage.

**Implementation**:
```
"CRITICAL: First determine if this image contains ONE or MULTIPLE sequence diagrams.
Identification checks:
- Look for separate titles or use case names
- Check for visual separators (lines, spacing, boxes)
- Different participant sets indicate different diagrams"
```

### 3.2 Domain Model Specialization

**Change**: Introduced explicit differentiation between domain models and design class diagrams, with targeted extraction rules for each.

**Rationale**: Domain models in early design phases should contain only conceptual classes and attributes, without implementation details. Students frequently received incorrect penalties when assessors looked for methods, interfaces, or visibility markers that are inappropriate for domain models.

**Implementation**:
- Domain models explicitly exclude: methods, visibility markers, interfaces, abstract classes
- Multiplicities require exact transcription with verification protocols
- Added fallback for ambiguous cases: "Multiplicity unclear"

### 3.3 Stereotype Verification Protocol

**Change**: Replaced inference-based relationship detection with explicit text verification requirements.

**Rationale**: The VLM previously inferred `<<include>>` and `<<extend>>` relationships based on arrow styles, leading to false positives when students used incorrect notation. The revised approach only reports relationships where stereotype text is explicitly visible, aligning with grading rubrics that penalize notation errors.

**Implementation**:
```
"<<include>> relationships:
- ONLY report if <<include>> text is visible
- Format: 'UC1 <<include>> UC2'
Be precise: Only report relationships where stereotype text is EXPLICITLY visible"
```

### 3.4 Architecture Classification Taxonomy

**Change**: Expanded architecture diagram classification to distinguish between analysis architecture (BCE pattern), deployment architecture, and component architecture.

**Rationale**: Architecture diagrams showed the highest misclassification rate, with analysis-level BCE (Boundary-Control-Entity) diagrams frequently interpreted as use case diagrams. This misclassification prevented proper assessment of architectural design decisions.

**Implementation**:
- Added explicit detection for BCE stereotypes and notation
- Separated deployment concerns from logical architecture
- Included validation against common misidentification patterns

### 3.5 Quality Degradation Handling

**Change**: Introduced explicit protocols for handling degraded image quality without hallucination.

**Rationale**: Low-resolution scans and poor-quality photographs are common in student submissions. The original prompts' attempts to "best guess" unclear elements led to fabricated details that could incorrectly influence grading.

**Implementation**:
```
"If image quality is poor, note: 'Image quality affects readability'
If any elements are not visible, omit them rather than guessing"
```

## 4. Validation Framework Integration

A comprehensive validation layer was added to catch systematic errors:

- **Multiple Diagram Detection**: Mandatory check before detailed analysis
- **Notation Verification**: Explicit error reporting for incorrect UML syntax
- **Type-Specific Constraints**: Domain models verified against method presence
- **Relationship Precision**: Stereotype text required for relationship classification

## 5. Impact on Assessment Accuracy

Preliminary testing indicates the revised prompts address the primary failure modes:

- **Use Case Diagrams**: Improved detection of generalization relationships and package boundaries
- **Class Diagrams**: Multiplicity accuracy increased, particularly for singleton relationships (1 vs 0..*)
- **Sequence Diagrams**: Eliminated false merging of distinct scenarios
- **Architecture Diagrams**: Correct identification rate improved for BCE pattern recognition

## 6. Limitations and Future Work

While the revised prompts show improved accuracy, several challenges remain:

1. **Context Sensitivity**: Prompts remain sensitive to diagram quality and non-standard notation
2. **Semantic Understanding**: Assessing diagram completeness against requirements remains challenging
3. **Pedagogical Alignment**: Further refinement needed to match specific institutional rubrics

Future work will focus on:
- Developing confidence scoring mechanisms
- Creating diagram-specific quality metrics
- Integrating semantic validation against requirements specifications

## 7. Conclusion

The systematic refinement of VLM prompts for UML diagram analysis demonstrates the importance of domain-specific prompt engineering in educational technology applications. By addressing identified failure modes through targeted modifications, the revised prompt set provides more reliable automated assessment support while maintaining transparency about limitations. This work contributes to the broader goal of scalable, consistent evaluation in software engineering education.

## References

[Note: This section would include relevant citations to VLM literature, software engineering education research, and automated assessment systems in a full paper]

---

## Appendix: Summary of Major Changes

| Diagram Type | Primary Issues | Key Modifications |
|--------------|---------------|-------------------|
| Use Case | Package confusion, missing generalizations | Explicit boundary vs. package detection, stereotype verification |
| Class/Domain Model | Multiplicity errors, type confusion | Exact transcription requirements, domain model specialization |
| Sequence | Diagram merging/splitting | Multi-diagram detection protocol, use case separation |
| Architecture | Misidentification as other types | BCE pattern recognition, architecture taxonomy |
| All Types | Quality-induced hallucination | Explicit quality limitation reporting |