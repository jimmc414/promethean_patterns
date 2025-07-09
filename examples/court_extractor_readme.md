# Court Judgment Document Extractor

A sophisticated legal document extraction tool that converts court judgments into structured JSON data using an AI-powered state machine.

## Overview

This tool systematically extracts all relevant information from court judgment documents, including:

- **Case Metadata**: Case names, numbers, filing dates, court information
- **Parties**: Plaintiffs, defendants, intervenors with full legal names
- **Legal Professionals**: Judges, attorneys, law firms with bar numbers
- **Claims & Issues**: All legal claims with descriptions and basis
- **Rulings & Orders**: Court decisions, reasoning, and orders
- **Financial Information**: Damages, settlements, fees, fines with context
- **Temporal Data**: All dates with associated events
- **Legal Citations**: Cases cited, statutes, regulations
- **Procedural History**: Docket entries and case progression

## Features

### 1. **Intelligent Document Analysis**
- Automatically identifies document type (judgment, order, motion)
- Recognizes court level and jurisdiction
- Maps document structure for systematic extraction

### 2. **Hierarchical Extraction**
- Processes documents section by section
- Maintains relationships between entities
- Preserves legal reasoning structure

### 3. **Confidence Scoring**
- Each extracted element includes confidence score
- Flags ambiguous information for review
- Validates cross-references and consistency

### 4. **Multiple Output Formats**
- **JSON**: Complete structured data with all fields
- **CSV**: Key data points in tabular format
- **Summary Report**: Human-readable case summary

## Usage

```bash
# Make executable
chmod +x court_judgment_extractor.sh

# Run the extractor
./court_judgment_extractor.sh
```

### Input Options

1. **Paste Text**: Copy and paste judgment text directly
2. **File Path**: Load from a text file
3. **Sample Document**: Use built-in example for testing

### Output Structure

The tool generates a comprehensive JSON structure:

```json
{
  "extraction_metadata": {
    "extraction_date": "2024-01-15T10:30:00",
    "document_id": "unique_id",
    "confidence_scores": {
      "overall": 0.95,
      "parties": 0.98,
      "financial": 0.92
    }
  },
  "case_information": {
    "case_name": "Doe v. ACME Corporation",
    "case_number": "22-CV-1234",
    "court": "United States District Court, Southern District of New York",
    "date_filed": "2022-03-15",
    "date_decided": "2023-11-30"
  },
  "parties": {
    "plaintiffs": [
      {
        "name": "Jane Doe",
        "type": "Individual",
        "representation": "Smith & Associates"
      }
    ],
    "defendants": [
      {
        "name": "ACME Corporation",
        "type": "Corporation",
        "representation": "BigLaw Firm LLP"
      }
    ]
  },
  "judges": [
    {
      "name": "John Smith",
      "role": "District Judge"
    }
  ],
  "claims": [
    {
      "claim_number": 1,
      "description": "Employment discrimination",
      "legal_basis": "Title VII"
    }
  ],
  "rulings": [
    {
      "issue": "Motion for Summary Judgment",
      "ruling": "GRANTED IN PART, DENIED IN PART",
      "reasoning": "Plaintiff failed to establish prima facie case for promotion claim"
    }
  ],
  "monetary_awards": [
    {
      "type": "Damages sought",
      "amount": 500000,
      "recipient": "Plaintiff",
      "status": "Pending"
    }
  ],
  "key_dates": [
    {
      "event": "Trial commencement",
      "date": "2024-01-15"
    }
  ]
}
```

## Extraction Process

### Phase 1: Document Loading
- Accepts text input or file upload
- Validates document format
- Stores raw text for processing

### Phase 2: Structure Analysis
- Identifies document sections
- Determines extraction strategy
- Maps relationships between sections

### Phase 3: Section-by-Section Extraction
- **Metadata**: Case caption, court, dates
- **Parties**: Names, types, representation
- **Procedural**: Motions, orders, rulings
- **Substantive**: Claims, legal reasoning
- **Financial**: All monetary amounts
- **Temporal**: Dates and deadlines

### Phase 4: Validation
- Cross-references party names
- Validates date consistency
- Checks financial calculations
- Ensures citation formatting

### Phase 5: Output Generation
- Formats final JSON structure
- Generates summary report
- Creates CSV export
- Saves all outputs to session directory

## Advanced Features

### Entity Relationship Mapping
- Links attorneys to clients
- Associates rulings with specific claims
- Connects monetary awards to parties

### Citation Parsing
- Extracts case citations in standard format
- Identifies statutory references
- Links citations to context

### Confidence Scoring
```json
{
  "extracted_value": "Jane Doe",
  "confidence": 0.98,
  "source_section": "Caption",
  "extraction_method": "Pattern matching"
}
```

### Error Handling
- Graceful handling of incomplete documents
- Recovery from parsing errors
- Validation warnings for suspicious data

## Session Management

Each extraction creates a timestamped session:
```
extractions/20240115_103000/
├── extraction.log       # Complete process log
├── output/
│   ├── extracted_data.json   # Full structured data
│   ├── summary_report.txt    # Human-readable summary
│   └── case_data.csv        # Tabular key data
└── final_state.json     # Final extraction state
```

## Customization

The tool can be customized for:
- Different jurisdictions
- Specific document types
- Additional extraction fields
- Custom validation rules

## Best Practices

1. **Document Preparation**
   - Ensure text is OCR'd if from scanned documents
   - Include full document with all pages
   - Preserve original formatting where possible

2. **Review Extracted Data**
   - Check confidence scores
   - Verify financial amounts
   - Confirm party names and relationships

3. **Use Validation Features**
   - Review any flagged inconsistencies
   - Verify cross-references
   - Check date sequences

## Technical Details

- Uses Claude AI for intelligent extraction
- Maintains complete state throughout process
- Implements retry logic for robustness
- Preserves extraction history for audit

## Future Enhancements

- Batch processing for multiple documents
- Integration with legal databases
- Export to case management systems
- Machine learning for improved accuracy

---

This extractor demonstrates the power of AI-driven legal document analysis, turning unstructured court judgments into actionable structured data.