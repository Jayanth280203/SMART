#!/bin/bash
# Render.com startup script
# This runs before the app starts - trains ML models if not present

echo "=== SMART Portal Startup ==="
echo "Current directory: $(pwd)"
echo "Checking for ML models..."

python -c "
import os, sys
import pandas as pd
import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder

# On Render, repo root is the working directory
APP_DIR = os.path.join(os.getcwd(), 'app')
DATASET = os.path.join(os.getcwd(), 'TN_Student_Skill_Dataset.csv')

# Check if models already exist
if os.path.exists(os.path.join(APP_DIR, 'skill_role_model.pkl')):
    print('Models already exist. Skipping training.')
    sys.exit()

print('Models not found. Training now from dataset...')

if not os.path.exists(DATASET):
    print(f'ERROR: Dataset not found at {DATASET}')
    sys.exit(1)

df = pd.read_csv(DATASET).fillna('NONE')

def cgpa_band(c):
    try:
        c = float(c)
        if c >= 8.5: return 2
        if c >= 7.0: return 1
    except: pass
    return 0

def safe_le_fit(series):
    le = LabelEncoder()
    le.fit(series.astype(str).str.strip())
    return le

def safe_transform(le, series):
    known = set(le.classes_)
    return series.astype(str).str.strip().apply(lambda x: le.transform([x])[0] if x in known else 0)

print('Fitting encoders...')
le_dept = safe_le_fit(df['department'])
le_degree = safe_le_fit(df['degree'])
le_nm = safe_le_fit(df['naan_mudhalvan_course'])
le_academic = safe_le_fit(df['predicted_academic_job_role'])
le_skill = safe_le_fit(df['predicted_skill_job_role'])

df['_dept_enc'] = safe_transform(le_dept, df['department'])
df['_degree_enc'] = safe_transform(le_degree, df['degree'])
df['_cgpa_band'] = df['cgpa'].apply(cgpa_band)
df['_has_cert'] = df['certifications'].apply(lambda x: 0 if str(x).strip() in ('NONE','nan','') else 1)
df['_has_intern'] = df['internships'].apply(lambda x: 0 if str(x).strip() in ('NONE','nan','') else 1)
df['_num_skills'] = df['skills'].apply(lambda s: len(str(s).split(',')) if str(s).strip() not in ('NONE','nan','') else 0)
df['_nm_enc'] = safe_transform(le_nm, df['naan_mudhalvan_course'])

y_acad = safe_transform(le_academic, df['predicted_academic_job_role'])
y_skill = safe_transform(le_skill, df['predicted_skill_job_role'])

print('Training Academic Model...')
X_acad = df[['_dept_enc', '_degree_enc', '_cgpa_band']].values
rf_academic = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
rf_academic.fit(X_acad, y_acad)

print('Training Skill Model...')
X_skill = df[['_dept_enc', '_has_cert', '_has_intern', '_num_skills', '_nm_enc']].values
rf_skill = RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
rf_skill.fit(X_skill, y_skill)

print('Saving models...')
joblib.dump(rf_academic, os.path.join(APP_DIR, 'academic_role_model.pkl'))
joblib.dump(rf_skill, os.path.join(APP_DIR, 'skill_role_model.pkl'))
joblib.dump(le_dept, os.path.join(APP_DIR, 'le_dept.pkl'))
joblib.dump(le_degree, os.path.join(APP_DIR, 'le_degree.pkl'))
joblib.dump(le_nm, os.path.join(APP_DIR, 'le_nm.pkl'))
joblib.dump(le_academic, os.path.join(APP_DIR, 'le_academic.pkl'))
joblib.dump(le_skill, os.path.join(APP_DIR, 'le_skill.pkl'))

print('All models trained and saved!')
"

echo "Starting Flask app..."
cd app && gunicorn app:app --bind 0.0.0.0:${PORT:-10000} --workers 2 --timeout 300
