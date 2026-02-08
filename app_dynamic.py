"""
Symptomate - Dynamic Diagnostic System
Integrates SNOMED Local + NHS UK + Gemini AI
No hardcoded disease rules - all discovered at runtime
"""

import os
import logging
from typing import Dict, List, Any
from dynamic_diagnostic_engine import DynamicDiseaseDiscovery

logging.basicConfig(level=logging.WARNING, format='%(message)s')
for name in logging.root.manager.loggerDict:
    logging.getLogger(name).setLevel(logging.WARNING)

# Logger for error reporting
logger = logging.getLogger(__name__)


# Configuration
SNOMED_PATH = "D:\\Symptomate😂2\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z"
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

# Body areas
BODY_AREAS = {
    "1": {"id": "head", "name": "🧠 Head", "desc": "head"},
    "2": {"id": "eyes", "name": "👁️ Eyes", "desc": "eyes"},
    "3": {"id": "ears", "name": "👂 Ears", "desc": "ears"},
    "4": {"id": "nose", "name": "👃 Nose/Sinuses", "desc": "nose"},
    "5": {"id": "throat", "name": "🗣️ Throat/Neck", "desc": "throat"},
    "6": {"id": "chest", "name": "🫁 Chest/Lungs", "desc": "chest"},
    "7": {"id": "abdomen", "name": "🫃 Abdomen", "desc": "abdomen"},
    "8": {"id": "back", "name": "🦴 Back", "desc": "back"},
    "9": {"id": "arms", "name": "💪 Arms/Hands", "desc": "arms"},
    "10": {"id": "legs", "name": "🦵 Legs/Feet", "desc": "legs"},
    "11": {"id": "skin", "name": "🧴 Skin (General)", "desc": "skin"},
    "12": {"id": "general", "name": "🌡️ General/Systemic", "desc": "general"},
    "13": {"id": "joints", "name": "🦴 Joints", "desc": "joints"}
}


def terminal_interface():
    """Interactive terminal interface with dynamic discovery"""
    
    print("=" * 70)
    print("🏥 SYMPTOMATE - Dynamic Diagnostic System")
    print("=" * 70)
    # print("📚 Knowledge: SNOMED CT (Local) + NHS UK + Gemini AI")
    # print("🎯 Method: Dynamic disease discovery at runtime")
    print("=" * 70)
    
    # # Initialize dynamic engine
    # print("\n⏳ Initializing diagnostic engine...")
    # print("   (Loading SNOMED CT database - this may take a moment)")
    
    engine = DynamicDiseaseDiscovery(SNOMED_PATH, GEMINI_API_KEY)
    
    # print("✅ Engine initialized!\n")
    
    # Phase 1: Body area selection
    print("📍Body Area Selection")
    print("-" * 70)
    print("Available body areas:\n")
    
    for key, area in BODY_AREAS.items():
        print(f"  {key}. {area['name']} ({area['desc']})")
    
    body_input = input("\nEnter the numbers of affected areas (comma-separated, e.g., 1,12):\n➤ ").strip()
    
    selected_areas = []
    for num in body_input.split(','):
        num = num.strip()
        if num in BODY_AREAS:
            selected_areas.append(BODY_AREAS[num]['id'])
    
    if not selected_areas:
        print("❌ No valid areas selected. Exiting.")
        return
    
    print(f"\n✅ Selected areas: {', '.join([BODY_AREAS[k]['name'] for k in body_input.split(',') if k.strip() in BODY_AREAS])}")
    
    # Phase 2: Dynamic disease discovery
    # print("\n" + "=" * 70)
    # print("🔍 PHASE 2: Discovering Relevant Diseases")
    # print("=" * 70)
    # print("Querying SNOMED CT + NHS UK for diseases affecting selected areas...")
    # print("(This discovers diseases dynamically - not from hardcoded list)\n")
    
    all_discovered_diseases = []

    for area in selected_areas:
        print(f"🔎 Searching diseases for: {area}...")
        diseases = engine.discover_diseases_for_body_area(area, limit=10)
        all_discovered_diseases.extend(diseases)
        print(f"   Found {len(diseases)} diseases\n")

    # Hardcoded rules
    HARDCODED_DISEASES = {
        "head": [
            {"name": "Tension headache", "symptoms": ["dull pressure", "scalp tightness"], "question": "Is the pain like a tight band around your head?"},
            {"name": "Cluster headache", "symptoms": ["severe one-sided pain", "tearing eye"], "question": "Is the headache extremely severe on one side with eye watering?"},
            {"name": "Temporal arteritis", "symptoms": ["scalp tenderness", "jaw pain", "vision issues"], "question": "Do you feel jaw pain while chewing or sudden vision problems?"},
            {"name": "Concussion", "symptoms": ["dizziness", "confusion after injury"], "question": "Did symptoms start after a recent head injury or fall?"}
        ],
        "nose": [
            {"name": "Common cold", "symptoms": ["runny nose", "sore throat"], "question": "Did symptoms begin with mild fever or sore throat?"},
            {"name": "Allergic rhinitis", "symptoms": ["sneezing", "itching", "watery eyes"], "question": "Do you have itching with frequent sneezing and watery eyes?"},
            {"name": "Nasal polyp", "symptoms": ["blockage", "reduced smell"], "question": "Have you noticed a reduced sense of smell?"},
            {"name": "Deviated septum", "symptoms": ["constant one-side blockage"], "question": "Is one side of your nose always blocked even without infection?"}
        ],
        "back": [
            {"name": "Muscle strain", "symptoms": ["pain after lifting", "localized stiffness"], "question": "Did the pain start after lifting something heavy or sudden movement?"},
            {"name": "Spinal stenosis", "symptoms": ["leg numbness while walking"], "question": "Do you feel leg pain or numbness that worsens when walking?"},
            {"name": "Ankylosing spondylitis", "symptoms": ["morning stiffness improving with activity"], "question": "Is back stiffness worse in the morning but better with movement?"},
            {"name": "Vertebral compression fracture", "symptoms": ["sudden severe pain", "older age"], "question": "Did severe back pain start suddenly after a minor fall or in older age?"}
        ],
        "arms": [
            {"name": "Tendonitis", "symptoms": ["pain with repeated movement"], "question": "Does the pain worsen when you move or use the arm repeatedly?"},
            {"name": "Frozen shoulder", "symptoms": ["severe stiffness", "limited motion"], "question": "Are you unable to fully lift or rotate your shoulder?"},
            {"name": "Bursitis", "symptoms": ["swelling and tenderness near joint"], "question": "Is there noticeable swelling or tenderness around the joint?"},
            {"name": "Cubital tunnel syndrome", "symptoms": ["numb ring/little finger", "weak grip"], "question": "Do you feel numbness mainly in the ring and little fingers?"}
        ],
        "legs": [
            {"name": "Knee osteoarthritis", "symptoms": ["knee pain", "stiffness with age"], "question": "Is knee pain worse during walking or with activity as you age?"},
            {"name": "Muscle cramp", "symptoms": ["sudden tight painful contraction"], "question": "Did the pain start suddenly as a tight muscle spasm?"},
            {"name": "Deep vein thrombosis", "symptoms": ["calf swelling", "warmth", "pain"], "question": "Is one leg swollen, warm, and painful suddenly? (urgent sign)"},
            {"name": "Peripheral neuropathy", "symptoms": ["burning", "tingling feet"], "question": "Do you feel burning or tingling in both feet?"}
        ],
        "general": [
            {"name": "Diabetes mellitus", "symptoms": ["excess thirst", "frequent urination", "fatigue"], "question": "Are you urinating frequently and feeling unusually thirsty?"},
            {"name": "Hypertension", "symptoms": ["often silent", "occasional headache"], "question": "Have you recorded high blood pressure readings before?"},
            {"name": "Influenza (flu)", "symptoms": ["fever", "body ache", "cough", "fatigue"], "question": "Do you have fever with body aches and cough?"},
            {"name": "Anemia", "symptoms": ["fatigue", "pale skin", "shortness of breath"], "question": "Do you feel constant fatigue with pale skin or breathlessness?"}
        ]
    }

    # Merge dynamic and hardcoded diseases
    merged_diseases = list(all_discovered_diseases)
    for area in selected_areas:
        if area in HARDCODED_DISEASES:
            for hd in HARDCODED_DISEASES[area]:
                # Convert hardcoded disease to dynamic-like dict
                symptoms_as_dicts = [{'symptom': s} for s in hd['symptoms']]
                merged_diseases.append({
                    'name': hd['name'],
                    'snomed_id': f"hardcoded_{hd['name'].replace(' ', '_').lower()}",
                    'symptoms': symptoms_as_dicts,
                    'question': hd['question'],
                    'options': ['Yes', 'No'],
                    'id': f"hardcoded_{hd['name'].replace(' ', '_').lower()}"
                })

    if not merged_diseases:
        print("❌ No diseases discovered for selected areas.")
        print("   Try different body areas or check SNOMED data.")
        return

    # Generate questions for ALL diseases, organized by disease
    questions_by_disease = {}
    for disease in merged_diseases:
        disease_id = disease.get('snomed_id', '')
        if 'question' in disease and 'options' in disease:
            # Hardcoded disease
            questions = [{
                'id': disease['id'],
                'text': disease['question'],
                'options': disease['options'],
                'disease_name': disease['name'],
                'disease_id': disease_id,
                'symptom_match': ', '.join([s['symptom'] for s in disease['symptoms']])
            }]
        else:
            questions = engine.generate_questions_for_disease(disease)
        if questions:
            questions_by_disease[disease_id] = {
                'disease': disease,
                'questions': questions
            }

    # Flatten questions and deduplicate by question text
    questions_map = {}  # question_text -> question data
    all_questions_flat = []
    for disease_id, data in questions_by_disease.items():
        for q in data['questions']:
            q['disease_name'] = data['disease']['name']
            q['disease_id'] = disease_id
            all_questions_flat.append(q)

    # Prioritize questions before deduplication
    prioritized_questions = engine.prioritize_questions(all_questions_flat, merged_diseases)

    # Now deduplicate the prioritized questions
    for q in prioritized_questions:
        q_text = q['text'].lower().strip()
        if q_text in questions_map:
            # Question already exists - add this disease to the list
            if 'disease_names' not in questions_map[q_text]:
                questions_map[q_text]['disease_names'] = [questions_map[q_text].get('disease_name', 'Unknown')]
                questions_map[q_text]['disease_ids'] = [questions_map[q_text].get('disease_id')]
            questions_map[q_text]['disease_names'].append(q['disease_name'])
            questions_map[q_text]['disease_ids'].append(q['disease_id'])
        else:
            # New question
            q['disease_names'] = [q['disease_name']]
            q['disease_ids'] = [q['disease_id']]
            questions_map[q_text] = q

    # Convert back to list (already in priority order)
    all_questions = list(questions_map.values())
    max_questions = 15
    questions_to_ask = all_questions[:max_questions]

    print("=" * 70)
    print("💬 Answer Questions")
    print("=" * 70)

    user_answers = {}
    for i, q in enumerate(questions_to_ask, 1):
        print(f"\n[Q{i}] {q['text']}")
        disease_names = q.get('disease_names', [q.get('disease_name', 'Unknown')])
        if len(disease_names) > 1:
            print(f"    (Checking for: {', '.join(disease_names)})")
        else:
            print(f"    (Checking for: {disease_names[0]})")
        print()
        for j, opt in enumerate(q['options'], 1):
            print(f"  {j}. {opt}")
        answer_input = input(f"\n➤ Enter number: ").strip()
        try:
            answer_idx = int(answer_input) - 1
            if 0 <= answer_idx < len(q['options']):
                disease_ids = q.get('disease_ids', [q.get('disease_id')])
                user_answers[q['id']] = {
                    'answer': q['options'][answer_idx],
                    'symptom': q.get('symptom_match', ''),
                    'disease_ids': disease_ids
                }
                print(f"   ✓ Answered: {q['options'][answer_idx]}")
        except:
            print("   ✗ Invalid input, skipped")

    print("\n" + "=" * 70)
    print("🔬 Running Diagnostic Analysis")
    print("=" * 70)
    print("Matching answers against discovered diseases...\n")

    simplified_answers = {}
    for q_id, data in user_answers.items():
        simplified_answers[q_id] = data['answer']
        if data.get('symptom'):
            symptom_key = data['symptom'].lower().replace(' ', '_')[:30]
            simplified_answers[f"symptom_{symptom_key}"] = data['answer']

    diagnoses = engine.diagnose_from_answers(merged_diseases, simplified_answers)

    if not diagnoses:
        print("❌ No matching conditions found based on your answers.")
        print("   This could mean:")
        print("   - Your symptoms don't match known patterns")
        print("   - More specific answers needed")
        print("   - Condition not in SNOMED/NHS UK databases")
        return

    print(f"✅ Found {len(diagnoses)} possible condition(s):\n")
    print("=" * 70)
    for i, diagnosis in enumerate(diagnoses[:5], 1):
        print(f"#{i} - {diagnosis['disease']}")
        print("=" * 70)
        print(f"Confidence: {diagnosis.get('confidence_percentage', 'N/A')} ({diagnosis.get('confidence', 'N/A')})")
        print(f"SNOMED Code: {diagnosis.get('snomed_code', 'N/A')}")
        print(f"Triage: {diagnosis.get('triage', 'unknown').capitalize()}")
        if 'symptoms' in diagnosis:
            print(f"\nMatched Symptoms ({len(diagnosis.get('matched_symptoms', []))}/{diagnosis.get('total_symptoms', 'N/A')}):")
            for symptom in diagnosis.get('matched_symptoms', diagnosis.get('symptoms', []))[:5]:
                print(f"  • {symptom}")
        if diagnosis.get('nhs_url'):
            print(f"\nNHS UK Information:")
            print(f"  URL: {diagnosis['nhs_url']}")
        if diagnosis.get('overview'):
            print(f"\n  Overview: {diagnosis['overview'][:200]}...")
        if diagnosis.get('triage') == 'home care' and diagnosis.get('home_remedies'):
            print("\n🏠 Home Remedies/Exercises:")
            print(diagnosis['home_remedies'])
        print("\n" + "=" * 70 + "\n")
    print("⚠️  DISCLAIMER: This is not a substitute for professional medical advice.")
    print("   Please consult a healthcare provider for proper diagnosis and treatment.")
    print("=" * 70)
    return
    
   # print(f"✅ Total discovered: {len(all_discovered_diseases)} unique diseases\n")
    
    # Show discovered diseases
    # print("📋 Discovered Diseases:")
    # print("-" * 70)
    # for i, disease in enumerate(all_discovered_diseases[:10], 1):
    #     # print(f"{i}. {disease['name']}")
    #     # print(f"   SNOMED: {disease['snomed_id']}")
    #     # print(f"   Symptoms: {len(disease['symptoms'])} found")
    #       print()
    
    # if len(all_discovered_diseases) > 10:
    #     print(f"... and {len(all_discovered_diseases) - 10} more\n")
    
    # # Phase 3: Generate questions
    # print("=" * 70)
    # print("❓ PHASE 3: Generating Diagnostic Questions")
    # print("=" * 70)
    # print("Generating questions dynamically from discovered diseases...")
    # print("(Using Gemini AI if available, fallback to templates)\n")
    
    # Generate questions for ALL diseases, organized by disease
    questions_by_disease = {}
    
    for disease in all_discovered_diseases:
        disease_id = disease['snomed_id']
        questions = engine.generate_questions_for_disease(disease)
        
        if questions:
            questions_by_disease[disease_id] = {
                'disease': disease,
                'questions': questions
            }
    
    # Flatten questions and deduplicate by question text
    questions_map = {}  # question_text -> question data
    all_questions_flat = []
    
    for disease_id, data in questions_by_disease.items():
        for q in data['questions']:
            q['disease_name'] = data['disease']['name']
            q['disease_id'] = disease_id
            all_questions_flat.append(q)
    
    # Prioritize questions before deduplication
   # print("⚡ Prioritizing questions by diagnostic value...")
    prioritized_questions = engine.prioritize_questions(all_questions_flat, all_discovered_diseases)
    
    # Now deduplicate the prioritized questions
    for q in prioritized_questions:
        q_text = q['text'].lower().strip()
        
        if q_text in questions_map:
            # Question already exists - add this disease to the list
            if 'disease_names' not in questions_map[q_text]:
                questions_map[q_text]['disease_names'] = [questions_map[q_text].get('disease_name', 'Unknown')]
                questions_map[q_text]['disease_ids'] = [questions_map[q_text].get('disease_id')]
            
            questions_map[q_text]['disease_names'].append(q['disease_name'])
            questions_map[q_text]['disease_ids'].append(q['disease_id'])
        else:
            # New question
            q['disease_names'] = [q['disease_name']]
            q['disease_ids'] = [q['disease_id']]
            questions_map[q_text] = q
    
    # Convert back to list (already in priority order)
    all_questions = list(questions_map.values())
    
    # Limit total questions
    max_questions = 15
    questions_to_ask = all_questions[:max_questions]
    
    #int(f"   📊 Top priority questions cover: severity, discriminating symptoms, common diseases\n")
    
    # Ask questions
    print("=" * 70)
    print("💬 Answer Questions")
    print("=" * 70)
    
    user_answers = {}
    
    for i, q in enumerate(questions_to_ask, 1):
        print(f"\n[Q{i}] {q['text']}")
        
        # Show all diseases this question checks for
        disease_names = q.get('disease_names', [q.get('disease_name', 'Unknown')])
        if len(disease_names) > 1:
            print(f"    (Checking for: {', '.join(disease_names)})")
        else:
            print(f"    (Checking for: {disease_names[0]})")
        
        print()
        for j, opt in enumerate(q['options'], 1):
            print(f"  {j}. {opt}")
        
        answer_input = input(f"\n➤ Enter number: ").strip()
        
        try:
            answer_idx = int(answer_input) - 1
            if 0 <= answer_idx < len(q['options']):
                # Store answer for all diseases this question checks
                disease_ids = q.get('disease_ids', [q.get('disease_id')])
                
                user_answers[q['id']] = {
                    'answer': q['options'][answer_idx],
                    'symptom': q.get('symptom_match', ''),
                    'disease_ids': disease_ids  # Multiple diseases
                }
                print(f"   ✓ Answered: {q['options'][answer_idx]}")
        except:
            print("   ✗ Invalid input, skipped")
    
    # Phase 5: Diagnosis
    print("\n" + "=" * 70)
    print("🔬 Running Diagnostic Analysis")
    print("=" * 70)
    print("Matching answers against discovered diseases...\n")
    
    # Convert user_answers to simpler format for diagnosis
    simplified_answers = {}
    for q_id, data in user_answers.items():
        simplified_answers[q_id] = data['answer']
        # Also map by symptom for better matching
        if data.get('symptom'):
            symptom_key = data['symptom'].lower().replace(' ', '_')[:30]
            simplified_answers[f"symptom_{symptom_key}"] = data['answer']
    
    diagnoses = engine.diagnose_from_answers(all_discovered_diseases, simplified_answers)
    
    if not diagnoses:
        print("❌ No matching conditions found based on your answers.")
        print("   This could mean:")
        print("   - Your symptoms don't match known patterns")
        print("   - More specific answers needed")
        print("   - Condition not in SNOMED/NHS UK databases")
        return
    
    print(f"✅ Found {len(diagnoses)} possible condition(s):\n")
    print("=" * 70)
    
    for i, diagnosis in enumerate(diagnoses[:5], 1):
        print(f"#{i} - {diagnosis['disease']}")
        print("=" * 70)
        print(f"Confidence: {diagnosis['confidence_percentage']} ({diagnosis['confidence']:.2f})")
        print(f"SNOMED Code: {diagnosis['snomed_code']}")
        print(f"Triage: {diagnosis.get('triage', 'unknown').capitalize()}")
        print(f"\nMatched Symptoms ({len(diagnosis['matched_symptoms'])}/{diagnosis['total_symptoms']}):")
        for symptom in diagnosis['matched_symptoms'][:5]:
            print(f"  • {symptom}")

        if diagnosis.get('nhs_url'):
            print(f"\nNHS UK Information:")
            print(f"  URL: {diagnosis['nhs_url']}")

        if diagnosis.get('overview'):
            print(f"\n  Overview: {diagnosis['overview'][:200]}...")

        # Show home remedies if triage is home care
        if diagnosis.get('triage') == 'home care' and diagnosis.get('home_remedies'):
            print("\n🏠 Home Remedies/Exercises:")
            print(diagnosis['home_remedies'])

        print("\n" + "=" * 70 + "\n")
    
    print("⚠️  DISCLAIMER: This is not a substitute for professional medical advice.")
    print("   Please consult a healthcare provider for proper diagnosis and treatment.")
    print("=" * 70)


if __name__ == "__main__":
    try:
        terminal_interface()
    except KeyboardInterrupt:
        print("\n\n❌ Interrupted by user. Exiting...")
    except Exception as e:
        print(f"\n\n❌ Error: {e}")
        logger.exception("Fatal error in terminal interface")
