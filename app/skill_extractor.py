import re
import os
try:
    import google.generativeai as genai
    _GENAI_AVAILABLE = True
except ImportError:
    genai = None
    _GENAI_AVAILABLE = False

class SkillExtractor:
    def __init__(self):
        # We've switched to a Hybrid Regex + Gemini approach to avoid spaCy/Pydantic v1
        # compatibility issues on Python 3.14. This is actually more accurate.
        self.skill_map = {
            "ml": "Machine Learning",
            "ai": "Artificial Intelligence",
            "cnn": "Convolutional Neural Network",
            "rnn": "Recurrent Neural Network",
            "nlp": "Natural Language Processing",
            "js": "JavaScript",
            "reactjs": "React",
            "aws": "Amazon Web Services",
            "ds": "Data Science",
            "sql": "SQL",
            "mysql": "MySQL",
            "mongodb": "MongoDB"
        }

    def extract_skills(self, text):
        """Advanced Hybrid Extraction: Regex for speed + Gemini for context understanding"""
        found_skills = set()
        text_lower = text.lower()
        
        # 1. High-Performance Regex Matching (Base Skills)
        common_tech = [
            "python", "java", "c++", "javascript", "react", "angular", "node",
            "fastapi", "flask", "django", "aws", "azure", "docker", "kubernetes",
            "machine learning", "deep learning", "nlp", "scikit-learn", 
            "tensorflow", "pytorch", "sql", "tableau", "power bi", "pandas", "numpy"
        ]
        
        for skill in common_tech:
            if re.search(rf"\b{re.escape(skill)}\b", text_lower):
                found_skills.add(self.normalize_skill(skill))

        # 2. Gemini-Powered Intelligence (Hidden Skills & NER)
        api_key = os.environ.get('GEMINI_API_KEY', '')
        if api_key and _GENAI_AVAILABLE and genai is not None:
            try:
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel('gemini-pro')
                # We ask Gemini to extract structured skills from the first 2000 chars
                prompt = f"System: You are an expert ATS parser. Extract a comma-separated list of technical skills and certifications from this resume excerpt:\n{text[:2500]}"
                response = model.generate_content(prompt)
                ai_extracted = [s.strip() for s in response.text.split(',') if s.strip()]
                for s in ai_extracted:
                    found_skills.add(self.normalize_skill(s))
            except Exception as e:
                print(f"Gemini Skill Extraction failed: {e}")

        return list(found_skills)

    def normalize_skill(self, skill):
        # Remove special characters and lowercase for mapping
        clean_s = re.sub(r'[^a-zA-Z0-9]', '', skill.lower()).strip()
        if clean_s in self.skill_map:
            return self.skill_map[clean_s]
        # Otherwise, return title case
        return skill.strip().title()

    def extract_experience(self, text):
        """Extract total years of experience using regex heuristics"""
        patterns = [
            r"(\d+)\+?\s*(?:years?|yrs?)\s*(?:of)?\s*experience",
            r"(?:Worked for|Experience:)\s*(\d+)\s*(?:years?|yrs?)",
        ]
        for p in patterns:
            match = re.search(p, text, re.IGNORECASE)
            if match:
                return int(match.group(1))
        return 0
