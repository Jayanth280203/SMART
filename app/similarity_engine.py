try:
    from sentence_transformers import SentenceTransformer, util
    import torch
    _TRANSFORMERS_AVAILABLE = True
except ImportError:
    _TRANSFORMERS_AVAILABLE = False
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

class SimilarityEngine:
    def __init__(self, model_name='all-MiniLM-L6-v2'):
        # Hybrid Approach: Try advanced transformers, fallback to stable TF-IDF
        self.transformer_operational = False
        try:
            self.model = SentenceTransformer(model_name)
            self.transformer_operational = True
            print(f"Transformers loaded successfully for semantic matching.")
        except Exception as e:
            print(f"Transformers failed to load: {e}. Defaulting to high-accuracy TF-IDF fallback.")
            self.vectorizer = TfidfVectorizer(stop_words='english', lowercase=True)

    def compute_semantic_similarity(self, text1, text2):
        if not text1 or not text2:
            return 0.0
        
        # 1. Option A: Sentence Transformers (Contextual)
        if self.transformer_operational:
            try:
                embeddings1 = self.model.encode(text1, convert_to_tensor=True)
                embeddings2 = self.model.encode(text2, convert_to_tensor=True)
                cosine_score = util.cos_sim(embeddings1, embeddings2)
                return float(cosine_score[0][0])
            except Exception as e:
                print(f"Contextual similarity failed ({e}), trying TF-IDF.")

        # 2. Option B: TF-IDF + Cosine Similarity (Hybrid Match)
        try:
            tfidf_matrix = self.vectorizer.fit_transform([text1, text2])
            sim = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])
            return float(sim[0][0])
        except Exception as e:
            print(f"TF-IDF failed: {e}")
            # Basic character overlap fallback
            t1 = set(text1.lower().split())
            t2 = set(text2.lower().split())
            if not t1 or not t2: return 0.0
            return len(t1 & t2) / len(t1 | t2)

    def compare_resume_to_jd(self, resume_text, jd_text):
        """Compute the overall similarity between the resume content and job description"""
        return self.compute_semantic_similarity(resume_text, jd_text)

    def compute_skills_similarity(self, resume_skills, jd_skills):
        """Compute similarity specifically for lists of skills"""
        r_skills_text = ", ".join(resume_skills)
        j_skills_text = ", ".join(jd_skills)
        return self.compute_semantic_similarity(r_skills_text, j_skills_text)
