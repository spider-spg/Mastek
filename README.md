# 🏥 Rural India Diagnostic System

## Overview
An AI-powered medical diagnostic assistance system optimized for rural healthcare workers in India. Combines DDXPlus machine learning model with SNOMED CT medical knowledge base to provide transparent, trustworthy diagnostic predictions.

## Key Features

### 🧠 Enhanced Diagnostic Reasoning
- **Transparent Reasoning**: See exactly which symptoms led to each diagnosis
- **Trust Scoring**: 0-100 confidence score with clear risk assessment  
- **Contributing Factors**: Identify primary and supporting evidence
- **Clinical Pathways**: SNOMED medical knowledge + ML predictions

### 🎯 Trust-Based Decision Support
- **🟢 HIGH TRUST (85-100)**: Proceed with treatment planning
- **🟡 MEDIUM TRUST (65-84)**: Verify with additional tests
- **🟠 LOW TRUST (45-64)**: Requires medical evaluation
- **🔴 VERY LOW TRUST (<45)**: Multiple approaches needed

### 🏥 Rural Healthcare Optimized
- Simple English questions (6-15 questions per case)
- Emergency symptom detection
- Body system-specific questioning
- Bias elimination (no more "throat tightness" for everything!)
- Works offline with pre-trained models

## Core Components

### `rural_india_diagnostic.py` - Main Diagnostic Engine
- **IndiaRuralDiagnosticSystem**: Complete diagnostic workflow
- **Enhanced Reasoning**: Transparent factor analysis and trust scoring
- **Clinical Override**: SNOMED knowledge overrides ML bias
- **Dynamic Questioning**: Intelligent question selection

### `snomed_integration.py` - Medical Knowledge Base  
- Real SNOMED CT medical concepts and IDs
- Body system detection and analysis
- Emergency condition identification
- Clinical treatment recommendations

### `data/` - Medical Data Processing
- Symptom mapping and vocabulary
- Disease categorization and aliases
- Feature assembly for ML model
- Medical knowledge preprocessing

## Installation

```bash
# Clone repository
git clone <repository-url>
cd rural-india-diagnostic

# Install dependencies  
pip install -r requirements_enhanced.txt

# Set up environment
cp .env.example .env
# Edit .env with your configurations
```

## Usage

### Basic Diagnosis
```python
from rural_india_diagnostic import IndiaRuralDiagnosticSystem

# Initialize system
system = IndiaRuralDiagnosticSystem()

# Run diagnosis (interactive)
diagnosis = system.start_rural_diagnosis()
```

### With Detailed Medical Reasoning
```python
# For medical professionals - shows full reasoning analysis
diagnosis = system.start_rural_diagnosis(show_detailed_reasoning=True)
```

### Example Output
```
🎯 PRIMARY DIAGNOSIS: Urinary tract infectious disease
   Trust Score: 95/100
   🟢 HIGH CONFIDENCE & HIGH TRUST - Strong indication

🔍 KEY SYMPTOMS IDENTIFIED:
   🔴 Burning during urination (definite)
   🔴 Frequent urination (definite)
   🟡 Fever (sometimes)

✅ CONFIDENCE BOOSTERS:
   + Clinical medical knowledge used
   + Excellent symptom matching

🎯 RECOMMENDED ACTION:
   🟢 HIGH TRUST: Proceed with treatment planning
```

## Technical Architecture

### Machine Learning
- **Model**: DDXPlus trained model (99.3% accuracy)
- **Features**: 223 symptom features
- **Diseases**: 49 common conditions
- **Bias Elimination**: Aggressive filtering of inappropriate predictions

### Medical Knowledge
- **SNOMED CT Integration**: Real medical concept IDs
- **Clinical Override System**: Body-system specific diagnosis
- **Emergency Detection**: Critical symptom identification
- **Treatment Guidance**: Evidence-based recommendations

### Trust & Reasoning System
- **Multi-factor Scoring**: Model confidence + symptom matching + clinical knowledge
- **Risk Assessment**: Clear action guidance for healthcare workers
- **Transparent Factors**: Show what drives each diagnosis
- **Limitation Detection**: Identify when additional evaluation needed

## File Structure

```
rural-india-diagnostic/
├── rural_india_diagnostic.py    # Main diagnostic engine
├── snomed_integration.py        # Medical knowledge base
├── data/                        # Medical data processing
│   ├── symptom_mapping.py       # Symptom vocabulary
│   ├── disease_aliases.py       # Disease categorization
│   └── feature_assembler.py     # ML feature processing
├── ddxplus_*.pkl               # Pre-trained ML models
├── requirements_enhanced.txt    # Dependencies
└── README.md                   # This file
```

## Key Improvements Over Standard Systems

1. **🎯 Bias Elimination**: No more "throat tightness" predictions for non-throat symptoms
2. **🧠 Transparent Reasoning**: Healthcare workers understand WHY each diagnosis was suggested
3. **📊 Trust Scoring**: Clear confidence levels guide medical decisions  
4. **🏥 Clinical Knowledge**: Real SNOMED medical concepts, not hardcoded rules
5. **🚨 Emergency Detection**: Critical symptoms properly identified and escalated
6. **🌍 Rural Optimization**: Designed for limited-resource healthcare settings

## Medical Disclaimers

- This is a medical **assistance tool**, not a replacement for professional diagnosis
- Always consult qualified medical professionals for treatment decisions
- In emergencies, seek immediate medical attention
- Tool helps identify possible conditions for further evaluation

## License

Medical AI system for healthcare assistance in rural India.

---
*Optimized for rural Indian healthcare workers • Built with DDXPlus ML + SNOMED CT medical knowledge*