#!/usr/bin/env python3
"""
🚀 SYMPTOMATE FASTAPI BACKEND
============================
FastAPI server for Flutter app to handle:
- Gemini API calls for advanced reasoning
- Medical chat functionality
- SNOMED integration
- Secure API key handling
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
import pickle
from datetime import datetime
import uvicorn
import asyncio
import logging
from snomed_integration import SnomedIntegration

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Symptomate Medical API",
    description="FastAPI backend for Flutter medical diagnostic app",
    version="2.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for your Flutter app domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Gemini API
try:
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    gemini_model = genai.GenerativeModel('gemini-pro')
    logger.info("✅ Gemini API initialized successfully")
except Exception as e:
    logger.error(f"❌ Gemini API initialization failed: {e}")
    gemini_model = None

# Initialize SNOMED integration
try:
    snomed_integration = SnomedIntegration()
    logger.info("✅ SNOMED integration initialized")
except Exception as e:
    logger.error(f"❌ SNOMED integration failed: {e}")
    snomed_integration = None

# Load DDXPlus metadata for context
try:
    with open('ddxplus_diseases.pkl', 'rb') as f:
        disease_names = pickle.load(f)
    with open('ddxplus_features.pkl', 'rb') as f:
        feature_names = pickle.load(f)
    logger.info(f"✅ DDXPlus metadata loaded: {len(feature_names)} features, {len(disease_names)} diseases")
except Exception as e:
    logger.error(f"❌ DDXPlus metadata loading failed: {e}")
    disease_names = []
    feature_names = []

# Pydantic models for API requests/responses
class SymptomData(BaseModel):
    symptoms: Dict[str, float]  # symptom_name: probability (0.0-1.0)
    confidence: Optional[float] = 0.0
    additional_info: Optional[str] = ""

class TFLitePrediction(BaseModel):
    disease_predictions: List[float]  # 49 probabilities from TFLite
    confidence_score: float
    symptoms: Dict[str, float]
    timestamp: str

class ChatMessage(BaseModel):
    message: str
    context: Optional[List[str]] = []
    symptoms: Optional[Dict[str, float]] = {}
    previous_predictions: Optional[List[Dict[str, Any]]] = []

class EnhancedDiagnosisRequest(BaseModel):
    tflite_predictions: TFLitePrediction
    chat_context: Optional[List[str]] = []
    user_questions: Optional[List[str]] = []

class APIResponse(BaseModel):
    success: bool
    data: Optional[Any] = None
    error: Optional[str] = None
    timestamp: str

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "gemini_api": "available" if gemini_model else "unavailable",
        "snomed_integration": "available" if snomed_integration else "unavailable",
        "timestamp": datetime.now().isoformat()
    }

# Chat endpoint for advanced medical reasoning
@app.post("/chat")
async def medical_chat(message: ChatMessage):
    """
    Advanced medical chat using Gemini API
    Called from Flutter for complex medical reasoning
    """
    if not gemini_model:
        raise HTTPException(status_code=503, detail="Gemini API not available")
    
    try:
        # Prepare medical context
        medical_context = f"""
        You are a medical AI assistant helping with rural healthcare diagnosis.
        
        Context Information:
        - Available diseases: {', '.join(disease_names[:10])}... (49 total)
        - Patient symptoms: {message.symptoms}
        - Previous conversation: {message.context}
        
        Guidelines:
        1. Provide clear, simple medical explanations
        2. Always recommend consulting healthcare professionals
        3. Focus on rural healthcare accessibility
        4. Use simple English suitable for rural areas
        5. Provide actionable guidance
        
        User Question: {message.message}
        """
        
        # Generate response using Gemini
        response = gemini_model.generate_content(medical_context)
        
        # Log the interaction
        logger.info(f"Chat request processed for: {message.message[:50]}...")
        
        return APIResponse(
            success=True,
            data={
                "response": response.text,
                "confidence": "high",
                "source": "gemini_medical_ai",
                "context_used": bool(message.symptoms or message.context)
            },
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Chat endpoint error: {e}")
        raise HTTPException(status_code=500, detail=f"Chat processing failed: {str(e)}")

# Enhanced diagnosis endpoint
@app.post("/enhanced_diagnosis")
async def enhanced_diagnosis(request: EnhancedDiagnosisRequest):
    """
    Enhance TFLite predictions with Gemini AI reasoning
    Combines offline TFLite predictions with online AI enhancement
    """
    if not gemini_model:
        raise HTTPException(status_code=503, detail="Gemini API not available")
    
    try:
        # Get top predictions from TFLite
        predictions = request.tflite_predictions.disease_predictions
        top_indices = sorted(range(len(predictions)), key=lambda i: predictions[i], reverse=True)[:5]
        
        top_diseases = []
        for idx in top_indices:
            if idx < len(disease_names):
                top_diseases.append({
                    "name": disease_names[idx],
                    "probability": predictions[idx],
                    "index": idx
                })
        
        # Prepare enhanced analysis prompt
        enhancement_prompt = f"""
        Medical Diagnosis Enhancement Request:
        
        TFLite Model Results:
        - Top predictions: {json.dumps(top_diseases, indent=2)}
        - Overall confidence: {request.tflite_predictions.confidence_score}
        - Patient symptoms: {request.tflite_predictions.symptoms}
        
        Previous Chat Context:
        {request.chat_context}
        
        Please provide:
        1. Enhanced medical reasoning for top 3 diagnoses
        2. Additional questions to ask patient
        3. Red flags or warning signs to watch for
        4. Simple treatment guidance suitable for rural areas
        5. When to seek immediate medical attention
        
        Format as clear, actionable medical guidance.
        """
        
        # Generate enhanced response
        response = gemini_model.generate_content(enhancement_prompt)
        
        # SNOMED enhancement if available
        snomed_analysis = None
        if snomed_integration and request.tflite_predictions.symptoms:
            try:
                symptom_list = [k for k, v in request.tflite_predictions.symptoms.items() if v > 0]
                snomed_analysis = snomed_integration.analyze_symptoms(symptom_list)
            except Exception as e:
                logger.warning(f"SNOMED analysis failed: {e}")
        
        return APIResponse(
            success=True,
            data={
                "enhanced_reasoning": response.text,
                "tflite_predictions": top_diseases,
                "confidence_score": request.tflite_predictions.confidence_score,
                "snomed_analysis": snomed_analysis,
                "recommendations": {
                    "immediate_action": "Consult healthcare professional",
                    "monitoring": "Watch for symptom changes",
                    "followup": "Regular medical checkup"
                }
            },
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Enhanced diagnosis error: {e}")
        raise HTTPException(status_code=500, detail=f"Enhanced diagnosis failed: {str(e)}")

# SNOMED analysis endpoint
@app.post("/snomed_analysis")
async def snomed_analysis(symptoms: SymptomData):
    """
    Standalone SNOMED analysis endpoint
    Provides medical concept analysis for symptoms
    """
    if not snomed_integration:
        raise HTTPException(status_code=503, detail="SNOMED integration not available")
    
    try:
        # Extract positive symptoms
        positive_symptoms = [k for k, v in symptoms.symptoms.items() if v > 0.5]
        
        if not positive_symptoms:
            return APIResponse(
                success=True,
                data={"message": "No significant symptoms provided"},
                timestamp=datetime.now().isoformat()
            )
        
        # Perform SNOMED analysis
        analysis = snomed_integration.analyze_symptoms(positive_symptoms)
        
        return APIResponse(
            success=True,
            data={
                "snomed_concepts": analysis,
                "analyzed_symptoms": positive_symptoms,
                "medical_context": "SNOMED CT concept analysis"
            },
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"SNOMED analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"SNOMED analysis failed: {str(e)}")

# Simple diagnosis validation endpoint
@app.post("/validate_diagnosis")
async def validate_diagnosis(symptoms: SymptomData):
    """
    Quick diagnosis validation using Gemini
    For simple yes/no medical questions
    """
    if not gemini_model:
        raise HTTPException(status_code=503, detail="Gemini API not available")
    
    try:
        # Simple validation prompt
        validation_prompt = f"""
        Quick medical validation request:
        
        Symptoms reported: {symptoms.symptoms}
        Confidence level: {symptoms.confidence}
        Additional info: {symptoms.additional_info}
        
        Provide brief validation:
        1. Are these symptoms concerning? (Yes/No/Maybe)
        2. Should patient seek immediate care? (Yes/No)
        3. One-sentence recommendation
        
        Keep response under 100 words.
        """
        
        response = gemini_model.generate_content(validation_prompt)
        
        return APIResponse(
            success=True,
            data={
                "validation": response.text,
                "quick_assessment": True,
                "severity": "requires_evaluation"
            },
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=500, detail=f"Validation failed: {str(e)}")

# Get medical knowledge endpoint
@app.get("/medical_knowledge/{disease_name}")
async def get_medical_knowledge(disease_name: str):
    """
    Get detailed medical knowledge about a specific disease
    """
    if not gemini_model:
        raise HTTPException(status_code=503, detail="Gemini API not available")
    
    try:
        knowledge_prompt = f"""
        Provide comprehensive but simple medical information about: {disease_name}
        
        Include:
        1. Simple description (rural-friendly language)
        2. Common symptoms
        3. Typical causes
        4. When to seek medical help
        5. Basic preventive measures
        6. Treatment overview (mention need for professional care)
        
        Keep language simple and accessible for rural healthcare workers.
        """
        
        response = gemini_model.generate_content(knowledge_prompt)
        
        return APIResponse(
            success=True,
            data={
                "disease": disease_name,
                "medical_info": response.text,
                "source": "gemini_medical_knowledge"
            },
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Medical knowledge error: {e}")
        raise HTTPException(status_code=500, detail=f"Knowledge retrieval failed: {str(e)}")

# Main server startup
if __name__ == "__main__":
    logger.info("🚀 Starting Symptomate FastAPI Backend...")
    logger.info("📱 Ready to serve Flutter app requests")
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )