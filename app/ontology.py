import networkx as nx

class SkillOntology:
    def __init__(self):
        # Build a hierarchical skill graph
        self.G = nx.DiGraph()
        self._build_ontology()

    def _build_ontology(self):
        # Adding nodes and directed edges (Super-skill -> Sub-skill)
        ontology_data = {
            "Machine Learning": ["Deep Learning", "Supervised Learning", "Unsupervised Learning", "Reinforcement Learning"],
            "Deep Learning": ["Computer Vision", "Natural Language Processing", "CNN", "RNN", "Transformers"],
            "Natural Language Processing": ["Tokenization", "NER", "Sentiment Analysis", "Transformers"],
            "Computer Vision": ["Object Detection", "Image Segmentation", "OCR", "CNN"],
            "Software Engineering": ["Backend Development", "Frontend Development", "Database Management", "DevOps"],
            "Backend Development": ["Python", "Java", "Go", "Node.js", "Django", "Flask", "FastAPI"],
            "Frontend Development": ["HTML", "CSS", "JavaScript", "React", "Angular", "Vue", "NextJS"],
            "Database Management": ["SQL", "NoSQL", "PostgreSQL", "MySQL", "MongoDB", "Redis"],
            "DevOps": ["Cloud Computing", "Docker", "Kubernetes", "CI/CD", "Terraform", "Jenkins"],
            "Cloud Computing": ["Amazon Web Services", "Microsoft Azure", "Google Cloud Platform"],
            "Data Analysis": ["Tableau", "Power BI", "Pandas", "Matplotlib", "Seaborn", "Excel"]
        }

        for super_skill, sub_skills in ontology_data.items():
            for sub_skill in sub_skills:
                self.G.add_edge(super_skill, sub_skill)

    def infer_skills(self, found_skills):
        """If a candidate has 'CNN', infer 'Deep Learning' and 'Machine Learning'"""
        inferred = set(found_skills)
        for skill in found_skills:
            # Traversal upwards in the DAG to find ancestors
            # We want all nodes from which we can reach 'skill'
            try:
                # networkx generic_bfs_edges or ancestors
                ancestors = nx.ancestors(self.G, skill)
                inferred.update(ancestors)
            except nx.NetworkXError:
                # Skill not in graph, skip
                pass
        return list(inferred)

    def get_match_score(self, resume_skills, job_skills):
        """Compare resume skills vs job skills using ontology matching"""
        # A simple method: how many of the required job skills or their sub-skills exist in resume?
        if not job_skills:
            return 1.0
        
        matches = 0
        inferred_resume_skills = self.infer_skills(resume_skills)
        
        for js in job_skills:
            if js in inferred_resume_skills:
                matches += 1
            else:
                # Optional: Check if any sub-skill of the job requirement is in resume (e.g., job wants ML, resume has 'CNN')
                # But 'infer_skills' already handles this in reverse.
                pass
                
        return matches / len(job_skills)
