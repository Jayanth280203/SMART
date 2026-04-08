import pandas as pd
from similarity_engine import SimilarityEngine
from ontology import SkillOntology

class JobMatcher:
    def __init__(self, jobs_df, similarity_engine, ontology):
        self.jobs_df = jobs_df
        self.similarity_engine = similarity_engine
        self.ontology = ontology

    def match_resume_to_jobs(self, resume_text, resume_skills, top_n=5):
        """Rank resumes to top 5 jobs from a dataset"""
        job_results = []
        
        # Pre-process jobs in memory (heuristic for MSc project)
        for index, row in self.jobs_df.iterrows():
            # Combine title, description, skills for semantic match
            jd_text = f"{row.get('title', '')} {row.get('description', '')}"
            jd_skills_text = str(row.get('skills', '')).split(',')
            
            # Semantic Similarity
            semantic_score = self.similarity_engine.compare_resume_to_jd(resume_text, jd_text)
            
            # Skill Graph Score
            ontology_score = self.ontology.get_match_score(resume_skills, jd_skills_text)
            
            # Final ranking score (0-1)
            rank_score = (0.60 * semantic_score) + (0.40 * ontology_score)
            
            job_results.append({
                "job_id": row.get('id', index),
                "title": row.get('title', 'Unknown Role'),
                "company": row.get('company', 'Unknown Company'),
                "location": row.get('location', 'Remote'),
                "match_score": round(float(rank_score * 100), 2),
                "semantic_score": round(float(semantic_score * 100), 2),
                "ontology_match": round(float(ontology_score * 100), 2),
                "link": row.get('link', '#')
            })

        # Sort by match score descending
        sorted_jobs = sorted(job_results, key=lambda x: x['match_score'], reverse=True)
        return list(sorted_jobs)[:top_n]

    def recommend_best_districts(self, resume_skills, district_demand_df):
        """Compare candidate skills with district-wise job demand"""
        # Group by district, check most frequent skills
        # Find districts where candidate's skills are in high demand
        districts = district_demand_df['district'].unique()
        
        recs = []
        for dist in districts:
            dist_jobs = district_demand_df[district_demand_df['district'] == dist]
            # Heuristic for demo: count overlapping skills
            demand_skills = []
            for s in dist_jobs['skills'].dropna():
                demand_skills.extend([x.strip().lower() for x in str(s).split(',')])
            
            score = 0
            for skill in resume_skills:
                if skill.lower() in demand_skills:
                    score += 1
            
            if score > 0:
                recs.append({
                    "district": dist,
                    "demand_score": score,
                    "matched_skills": [s for s in resume_skills if s.lower() in demand_skills]
                })
        
        # Sort by demand score
        return list(sorted(recs, key=lambda x: x['demand_score'], reverse=True))[:3]
