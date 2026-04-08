class ATSScorer:
    def __init__(self, weights=None):
        # Multi-factor scoring model following the MSc project requirements
        self.weights = {
            "semantic_similarity": 0.30,
            "skill_ontology": 0.25,
            "experience_match": 0.15,
            "project_relevance": 0.15,
            "resume_format": 0.10,
            "keyword_match": 0.05
        }
        if weights:
            self.weights.update(weights)

    def compute_hybrid_score(self, scores_dict):
        """Implement the weighted sum for the final score (0-100)"""
        final_score = 0
        for factor, weight in self.weights.items():
            final_score += weight * scores_dict.get(factor, 0.0)
        
        return round(final_score * 100, 2)

    def calculate_experience_score(self, user_exp, req_exp):
        """Relative match for required vs user experience"""
        if req_exp == 0: return 1.0
        # Formula: higher is better, capped at 1.0, but penalized for far below requirement
        diff = user_exp / req_exp
        return min(1.0, diff) if diff >= 0.5 else diff * 0.8

    def evaluate_format_quality(self, text):
        """Heuristic for good resume formatting (sections exist, list items, etc.)"""
        score = 1.0
        # Simple checks: presence of standard sections
        sections = ['Education', 'Experience', 'Projects', 'Skills']
        found = 0
        for s in sections:
            if s.lower() in text.lower():
                found += 1
        
        score = found / len(sections)
        # Check for numeric lists or bullets (heuristic)
        if '•' in text or '*' in text or ' - ' in text:
            score += 0.2
            
        return min(1.0, score)

    def get_breakdown(self, scores_dict):
        """Explainability module for the score"""
        breakdown = {}
        for factor, weight in self.weights.items():
            val = scores_dict.get(factor, 0.0)
            breakdown[factor] = {
                "raw_score": round(float(val), 2),
                "contribution": round(float(weight * val * 100), 2),
                "weight_percent": int(weight * 100)
            }
        return breakdown
