"""
Local SNOMED CT Parser
Queries RF2 files directly - no API limits
"""

import csv
import logging
from typing import Dict, List, Any, Optional
from pathlib import Path
import pickle
import hashlib

# Increase CSV field size limit for large SNOMED files
csv.field_size_limit(1000000)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SNOMEDLocal:
    """
    Local SNOMED CT parser for RF2 files with disk caching
    """
    
    def __init__(self, snomed_dir: str):
        """
        Initialize local SNOMED parser
        
        Args:
            snomed_dir: Path to SNOMED CT RF2 directory
        """
        self.base_path = Path(snomed_dir)
        self.snapshot_path = self.base_path / "Snapshot" / "Terminology"
        
        # Cache directory
        self.cache_dir = Path("snomed_cache")
        self.cache_dir.mkdir(exist_ok=True)
        
        # File paths
        self.concepts_file = self.snapshot_path / "sct2_Concept_Snapshot_US1000124_20250901.txt"
        self.descriptions_file = self.snapshot_path / "sct2_Description_Snapshot-en_US1000124_20250901.txt"
        self.relationships_file = self.snapshot_path / "sct2_Relationship_Snapshot_US1000124_20250901.txt"
        
        # Generate cache file paths based on source file hashes
        self.descriptions_cache_file = self.cache_dir / "descriptions_cache.pkl"
        self.relationships_cache_file = self.cache_dir / "relationships_cache.pkl"
        
        # Caches
        self.concepts_cache = {}
        self.descriptions_cache = {}
        self.relationships_cache = {}
        
        # Important concept IDs
        self.DISORDER = "64572001"  # Disease (disorder)
        self.FINDING_SITE = "363698007"  # Finding site
        self.ASSOCIATED_FINDING = "246090004"  # Associated finding
        self.IS_A = "116680003"  # Is a (hierarchy)
        
        logger.info(f"Initialized SNOMED Local Parser at {snomed_dir}")
    
    def load_descriptions(self) -> Dict[str, List[Dict]]:
        """Load descriptions (terms) for concepts with caching"""
        if self.descriptions_cache:
            return self.descriptions_cache
        
        # Try to load from cache first
        if self.descriptions_cache_file.exists():
            try:
                logger.info("Loading SNOMED descriptions from cache...")
                with open(self.descriptions_cache_file, 'rb') as f:
                    self.descriptions_cache = pickle.load(f)
                logger.info(f"Loaded {len(self.descriptions_cache)} concept descriptions from cache")
                return self.descriptions_cache
            except Exception as e:
                logger.warning(f"Cache load failed: {e}. Rebuilding...")
        
        logger.info("Loading SNOMED descriptions from RF2 files...")
        
        with open(self.descriptions_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter='\t')
            for row in reader:
                if row['active'] == '1':  # Only active descriptions
                    concept_id = row['conceptId']
                    if concept_id not in self.descriptions_cache:
                        self.descriptions_cache[concept_id] = []
                    
                    self.descriptions_cache[concept_id].append({
                        'id': row['id'],
                        'term': row['term'],
                        'type': row['typeId'],  # 900000000000003001 = FSN, 900000000000013009 = Synonym
                        'lang': row['languageCode']
                    })
        
        # Save to cache
        try:
            logger.info("Saving descriptions cache...")
            with open(self.descriptions_cache_file, 'wb') as f:
                pickle.dump(self.descriptions_cache, f)
        except Exception as e:
            logger.warning(f"Cache save failed: {e}")
        
        logger.info(f"Loaded {len(self.descriptions_cache)} concept descriptions")
        return self.descriptions_cache
    
    def load_relationships(self) -> Dict[str, List[Dict]]:
        """Load relationships between concepts with caching"""
        if self.relationships_cache:
            return self.relationships_cache
        
        # Try to load from cache first
        if self.relationships_cache_file.exists():
            try:
                logger.info("Loading SNOMED relationships from cache...")
                with open(self.relationships_cache_file, 'rb') as f:
                    self.relationships_cache = pickle.load(f)
                logger.info(f"Loaded relationships for {len(self.relationships_cache)} concepts from cache")
                return self.relationships_cache
            except Exception as e:
                logger.warning(f"Cache load failed: {e}. Rebuilding...")
        
        logger.info("Loading SNOMED relationships from RF2 files...")
        
        with open(self.relationships_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f, delimiter='\t')
            for row in reader:
                if row['active'] == '1':  # Only active relationships
                    source_id = row['sourceId']
                    if source_id not in self.relationships_cache:
                        self.relationships_cache[source_id] = []
                    
                    self.relationships_cache[source_id].append({
                        'type': row['typeId'],
                        'destination': row['destinationId']
                    })
        
        # Save to cache
        try:
            logger.info("Saving relationships cache...")
            with open(self.relationships_cache_file, 'wb') as f:
                pickle.dump(self.relationships_cache, f)
        except Exception as e:
            logger.warning(f"Cache save failed: {e}")
        
        logger.info(f"Loaded relationships for {len(self.relationships_cache)} concepts")
        return self.relationships_cache
    
    def get_preferred_term(self, concept_id: str) -> str:
        """Get preferred term for a concept"""
        if not self.descriptions_cache:
            self.load_descriptions()
        
        descriptions = self.descriptions_cache.get(concept_id, [])
        
        # Try to find preferred term (synonym)
        for desc in descriptions:
            if desc['type'] == '900000000000013009':  # Synonym
                return desc['term']
        
        # Fallback to FSN
        for desc in descriptions:
            if desc['type'] == '900000000000003001':  # FSN
                return desc['term'].split('(')[0].strip()
        
        return f"Concept {concept_id}"
    
    def get_disorders(self, limit: int = 1000) -> List[Dict[str, Any]]:
        """
        Get all disorders (diseases)
        
        Args:
            limit: Maximum number to return
            
        Returns:
            List of disorder concepts
        """
        if not self.relationships_cache:
            self.load_relationships()
        if not self.descriptions_cache:
            self.load_descriptions()
        
        logger.info("Finding all disorders...")
        
        disorders = []
        for concept_id, rels in self.relationships_cache.items():
            # Check if this concept is a disorder (has "Is a" relationship to DISORDER)
            for rel in rels:
                if rel['type'] == self.IS_A and self._is_descendant_of(concept_id, self.DISORDER):
                    term = self.get_preferred_term(concept_id)
                    disorders.append({
                        'conceptId': concept_id,
                        'term': term
                    })
                    break
            
            if len(disorders) >= limit:
                break
        
        logger.info(f"Found {len(disorders)} disorders")
        return disorders
    
    def _is_descendant_of(self, concept_id: str, ancestor_id: str, max_depth: int = 10) -> bool:
        """Check if concept is a descendant of ancestor"""
        if concept_id == ancestor_id:
            return True
        
        if max_depth <= 0:
            return False
        
        rels = self.relationships_cache.get(concept_id, [])
        for rel in rels:
            if rel['type'] == self.IS_A:
                if rel['destination'] == ancestor_id:
                    return True
                if self._is_descendant_of(rel['destination'], ancestor_id, max_depth - 1):
                    return True
        
        return False
    
    def get_finding_sites(self, concept_id: str) -> List[Dict[str, str]]:
        """Get anatomical sites for a disorder"""
        if not self.relationships_cache:
            self.load_relationships()
        
        sites = []
        rels = self.relationships_cache.get(concept_id, [])
        
        for rel in rels:
            if rel['type'] == self.FINDING_SITE:
                site_term = self.get_preferred_term(rel['destination'])
                sites.append({
                    'siteId': rel['destination'],
                    'site': site_term
                })
        
        return sites
    
    def get_associated_findings(self, concept_id: str) -> List[Dict[str, str]]:
        """Get clinical findings/symptoms for a disorder"""
        if not self.relationships_cache:
            self.load_relationships()
        
        findings = []
        rels = self.relationships_cache.get(concept_id, [])
        
        for rel in rels:
            if rel['type'] == self.ASSOCIATED_FINDING:
                finding_term = self.get_preferred_term(rel['destination'])
                findings.append({
                    'findingId': rel['destination'],
                    'finding': finding_term
                })
        
        return findings
    
    def search_by_body_area(self, body_area_term: str, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Enhanced search for disorders affecting a specific body area.
        Uses multiple strategies:
        1. Direct finding site relationships
        2. Keyword matching in disorder names
        3. Parent anatomical concepts
        
        Args:
            body_area_term: Body area name (e.g., "head", "chest", "abdomen")
            limit: Maximum results
            
        Returns:
            List of disorders with that finding site
        """
        if not self.relationships_cache:
            self.load_relationships()
        if not self.descriptions_cache:
            self.load_descriptions()
        
        logger.info(f"Searching disorders for body area: {body_area_term}")
        
        # Enhanced body area mapping with multiple concepts and keywords
        body_area_config = {
            'head': {
                'concepts': ['69536005', '774007', '123851003', '25238003'],  # Head, Head and neck, Mouth, Brain
                'keywords': ['headache', 'cranial', 'cerebral', 'brain', 'migraine', 'meningitis']
            },
            'chest': {
                'concepts': ['51185008', '302551006', '43799004', '39607008', '80891009'],  # Thorax, Chest wall, Lung, Heart
                'keywords': ['chest', 'thoracic', 'pulmonary', 'cardiac', 'lung', 'heart', 'pneumonia', 'bronch', 'asthma', 'angina']
            },
            'abdomen': {
                'concepts': ['818983003', '272622007', '302553008', '86762007'],  # Abdomen, Abdominal, Liver
                'keywords': ['abdominal', 'gastric', 'intestinal', 'hepatic', 'liver', 'stomach', 'appendicitis', 'colitis']
            },
            'back': {
                'concepts': ['77568009', '123960003', '421060004'],  # Back, Spine, Vertebral column
                'keywords': ['back', 'spinal', 'vertebral', 'lumbar', 'sciatica']
            },
            'arms': {
                'concepts': ['53120007', '40983000', '361288001'],  # Upper limb, Upper extremity
                'keywords': ['arm', 'shoulder', 'elbow', 'wrist', 'hand', 'carpal']
            },
            'legs': {
                'concepts': ['61685007', '30021000', '362785004'],  # Lower limb, Lower extremity
                'keywords': ['leg', 'hip', 'knee', 'ankle', 'foot', 'thigh', 'calf']
            },
            'skin': {
                'concepts': ['39937001', '181469002'],  # Skin structure
                'keywords': ['skin', 'dermat', 'cutaneous', 'rash', 'eczema', 'psoriasis']
            },
            'joints': {
                'concepts': ['39352004', '272673000', '71341001'],  # Joint, Bone, Synovial joint
                'keywords': ['joint', 'arthritis', 'articular', 'osteoarthritis']
            },
            'eyes': {
                'concepts': ['81745001', '371398005', '244486005'],  # Eye structure
                'keywords': ['eye', 'ocular', 'ophthalm', 'vision', 'conjunctivitis']
            },
            'ears': {
                'concepts': ['117590005', '1910005', '25577004'],  # Ear structure
                'keywords': ['ear', 'otic', 'hearing', 'auditory', 'otitis']
            },
            'throat': {
                'concepts': ['54066008', '264231000', '261227007'],  # Pharynx, Throat
                'keywords': ['throat', 'pharyn', 'tonsil', 'laryn']
            },
            'nose': {
                'concepts': ['45206002', '260540009', '181195007'],  # Nose
                'keywords': ['nose', 'nasal', 'sinus', 'rhinitis']
            }
        }
        
        config = body_area_config.get(body_area_term.lower(), {'concepts': [], 'keywords': []})
        area_concepts = config['concepts']
        keywords = config['keywords']
        
        disorders = {}  # Use dict to deduplicate
        
        # Strategy 1: Search by finding site relationships
        for concept_id, rels in self.relationships_cache.items():
            if len(disorders) >= limit:
                break
            
            if not self._is_descendant_of(concept_id, self.DISORDER):
                continue
            
            for rel in rels:
                if rel['type'] == self.FINDING_SITE:
                    # Check if destination matches any of our area concepts
                    dest_id = rel['destination']
                    for area_concept in area_concepts:
                        if dest_id == area_concept or self._is_descendant_of(dest_id, area_concept):
                            term = self.get_preferred_term(concept_id)
                            disorders[concept_id] = {
                                'conceptId': concept_id,
                                'term': term,
                                'findingSite': body_area_term,
                                'match_type': 'finding_site'
                            }
                            break
                
                if concept_id in disorders:
                    break
        
        # Strategy 2: Keyword search in disorder names
        for concept_id in self.descriptions_cache.keys():
            if len(disorders) >= limit:
                break
            
            if concept_id in disorders:
                continue
            
            if not self._is_descendant_of(concept_id, self.DISORDER):
                continue
            
            term = self.get_preferred_term(concept_id)
            term_lower = term.lower()
            
            if any(keyword in term_lower for keyword in keywords):
                disorders[concept_id] = {
                    'conceptId': concept_id,
                    'term': term,
                    'findingSite': body_area_term,
                    'match_type': 'keyword'
                }
        
        result = list(disorders.values())[:limit]
        logger.info(f"Found {len(result)} disorders for {body_area_term}")
        return result


if __name__ == "__main__":
    # Test the local SNOMED parser
    snomed = SNOMEDLocal("D:\\Symptomate😂2\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z")
    
    print("=" * 70)
    print("Testing Local SNOMED Parser")
    print("=" * 70)
    
    # Test 1: Get some disorders
    print("\n1. Getting first 10 disorders...")
    disorders = snomed.get_disorders(limit=10)
    for d in disorders:
        print(f"   - {d['term']} (ID: {d['conceptId']})")
    
    # Test 2: Get finding sites for a disorder
    if disorders:
        concept_id = disorders[0]['conceptId']
        print(f"\n2. Getting finding sites for {disorders[0]['term']}...")
        sites = snomed.get_finding_sites(concept_id)
        for s in sites:
            print(f"   - {s['site']}")
        
        # Test 3: Get associated findings
        print(f"\n3. Getting clinical findings for {disorders[0]['term']}...")
        findings = snomed.get_associated_findings(concept_id)
        for f in findings:
            print(f"   - {f['finding']}")
    
    # Test 4: Search by body area
    print("\n4. Searching disorders affecting 'head'...")
    head_disorders = snomed.search_by_body_area("head", limit=10)
    for d in head_disorders:
        print(f"   - {d['term']}")
    
    print("\n" + "=" * 70)
