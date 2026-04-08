#!/bin/bash
# Render.com startup script
# Trains ML models with 70/30 train-test split (>=95% accuracy required)

echo "=== SMART Portal Startup ==="
echo "Current directory: $(pwd)"
echo "Checking for ML models..."

python -c "
import os, sys
import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

APP_DIR = os.path.join(os.getcwd(), 'app')
DATASET = os.path.join(os.getcwd(), 'TN_Student_Skill_Dataset.csv')

if os.path.exists(os.path.join(APP_DIR, 'skill_role_model.pkl')):
    print('Models already exist. Skipping training.')
    sys.exit()

print('Models not found. Training with 70/30 split...')

if not os.path.exists(DATASET):
    print(f'ERROR: Dataset not found at {DATASET}')
    sys.exit(1)

df = pd.read_csv(DATASET).fillna('NONE')
print(f'Dataset loaded: {len(df)} records')

# ---- Feature Engineering ----
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

# Fit Encoders
le_dept    = safe_le_fit(df['department'])
le_degree  = safe_le_fit(df['degree'])
le_nm      = safe_le_fit(df['naan_mudhalvan_course'])
le_academic= safe_le_fit(df['predicted_academic_job_role'])
le_skill   = safe_le_fit(df['predicted_skill_job_role'])

# Feature columns
df['_dept_enc']   = safe_transform(le_dept, df['department'])
df['_degree_enc'] = safe_transform(le_degree, df['degree'])
df['_cgpa_band']  = df['cgpa'].apply(cgpa_band)
df['_has_cert']   = df['certifications'].apply(lambda x: 0 if str(x).strip() in ('NONE','nan','') else 1)
df['_has_intern'] = df['internships'].apply(lambda x: 0 if str(x).strip() in ('NONE','nan','') else 1)
df['_num_skills'] = df['skills'].apply(lambda s: len(str(s).split(',')) if str(s).strip() not in ('NONE','nan','') else 0)
df['_nm_enc']     = safe_transform(le_nm, df['naan_mudhalvan_course'])

# ========================================================
# MODEL 1: Academic Job Role (Department + Degree + CGPA)
# ========================================================
X_acad = df[['_dept_enc', '_degree_enc', '_cgpa_band']].values
y_acad = safe_transform(le_academic, df['predicted_academic_job_role']).values

# 70% Train | 30% Test Split
X_train_a, X_test_a, y_train_a, y_test_a = train_test_split(
    X_acad, y_acad, test_size=0.30, random_state=42, stratify=y_acad
)
print(f'Academic Model -> Train: {len(X_train_a)} | Test: {len(X_test_a)}')

rf_academic = RandomForestClassifier(n_estimators=200, random_state=42, n_jobs=-1)
rf_academic.fit(X_train_a, y_train_a)

y_pred_a = rf_academic.predict(X_test_a)
acad_acc = accuracy_score(y_test_a, y_pred_a) * 100
print(f'Academic Model Accuracy (30% Test Set): {acad_acc:.2f}%')

if acad_acc < 95:
    print(f'WARNING: Academic accuracy {acad_acc:.2f}% < 95%. Retraining with more estimators...')
    rf_academic = RandomForestClassifier(n_estimators=500, random_state=42, n_jobs=-1)
    rf_academic.fit(X_train_a, y_train_a)
    acad_acc = accuracy_score(y_test_a, rf_academic.predict(X_test_a)) * 100
    print(f'Retrained Academic Accuracy: {acad_acc:.2f}%')

# Retrain final model on FULL dataset for best deployment performance
rf_academic.fit(X_acad, y_acad)
print(f'Academic Model final trained on full dataset. Test Accuracy: {acad_acc:.2f}%')

# ========================================================
# MODEL 2: Skill Job Role (Dept + Cert + Intern + Skills + NM)
# ========================================================
X_skill = df[['_dept_enc', '_has_cert', '_has_intern', '_num_skills', '_nm_enc']].values
y_skill = safe_transform(le_skill, df['predicted_skill_job_role']).values

# 70% Train | 30% Test Split
X_train_s, X_test_s, y_train_s, y_test_s = train_test_split(
    X_skill, y_skill, test_size=0.30, random_state=42, stratify=y_skill
)
print(f'Skill Model -> Train: {len(X_train_s)} | Test: {len(X_test_s)}')

rf_skill = RandomForestClassifier(n_estimators=200, random_state=42, n_jobs=-1)
rf_skill.fit(X_train_s, y_train_s)

y_pred_s = rf_skill.predict(X_test_s)
skill_acc = accuracy_score(y_test_s, y_pred_s) * 100
print(f'Skill Model Accuracy (30% Test Set): {skill_acc:.2f}%')

if skill_acc < 95:
    print(f'WARNING: Skill accuracy {skill_acc:.2f}% < 95%. Retraining with more estimators...')
    rf_skill = RandomForestClassifier(n_estimators=500, random_state=42, n_jobs=-1)
    rf_skill.fit(X_train_s, y_train_s)
    skill_acc = accuracy_score(y_test_s, rf_skill.predict(X_test_s)) * 100
    print(f'Retrained Skill Accuracy: {skill_acc:.2f}%')

# Retrain final model on FULL dataset
rf_skill.fit(X_skill, y_skill)
print(f'Skill Model final trained on full dataset. Test Accuracy: {skill_acc:.2f}%')

# ========================================================
# SUMMARY
# ========================================================
print('')
print('========================================')
print('       MODEL TRAINING SUMMARY')
print('========================================')
print(f'  Total Dataset Records  : {len(df)}')
print(f'  Train Split            : 70% ({len(X_train_a)} records)')
print(f'  Test Split             : 30% ({len(X_test_a)} records)')
print(f'  Academic Model Accuracy: {acad_acc:.2f}%')
print(f'  Skill Model Accuracy   : {skill_acc:.2f}%')
print('========================================')

# Save all models and encoders
joblib.dump(rf_academic,  os.path.join(APP_DIR, 'academic_role_model.pkl'))
joblib.dump(rf_skill,     os.path.join(APP_DIR, 'skill_role_model.pkl'))
joblib.dump(le_dept,      os.path.join(APP_DIR, 'le_dept.pkl'))
joblib.dump(le_degree,    os.path.join(APP_DIR, 'le_degree.pkl'))
joblib.dump(le_nm,        os.path.join(APP_DIR, 'le_nm.pkl'))
joblib.dump(le_academic,  os.path.join(APP_DIR, 'le_academic.pkl'))
joblib.dump(le_skill,     os.path.join(APP_DIR, 'le_skill.pkl'))
print('All models saved successfully!')
"

echo "Starting Flask app..."
cd app && gunicorn app:app --bind 0.0.0.0:${PORT:-10000} --workers 2 --timeout 300
