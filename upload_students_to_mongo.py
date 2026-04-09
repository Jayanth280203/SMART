"""
TN Student Skill Dataset → MongoDB Atlas Uploader
Uploads all records from TN_Student_Skill_Dataset.csv to the 'students' collection.
"""

import pandas as pd
from pymongo import MongoClient, UpdateOne
import sys

# ─── CONFIG ────────────────────────────────────────────────────────────────────
MONGO_URI = "mongodb+srv://jayanthr239_db_user:U37kOH0GvVwaTXxF@cluster0.duhyvxx.mongodb.net/?appName=Cluster0"
DB_NAME   = "smart_erp"
COL_NAME  = "students"
CSV_PATH  = r"d:\FINAL_PROJECT\TN_Student_Skill_Dataset.csv"
BATCH_SIZE = 500   # number of records per bulk write
# ───────────────────────────────────────────────────────────────────────────────

def main():
    print("="*60)
    print("  SMART ERP — Student Dataset MongoDB Uploader")
    print("="*60)

    # 1. Load CSV
    print(f"\n[1/4] Loading CSV: {CSV_PATH}")
    df = pd.read_csv(CSV_PATH)
    df = df.fillna("NONE")

    # Ensure all columns are strings (safe for MongoDB)
    for col in df.columns:
        df[col] = df[col].astype(str).str.strip()

    print(f"      -> {len(df)} records loaded, {len(df.columns)} columns")

    # 2. Connect to MongoDB
    print(f"\n[2/4] Connecting to MongoDB Atlas...")
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    col = db[COL_NAME]
    print(f"      -> Connected to DB: '{DB_NAME}', Collection: '{COL_NAME}'")

    # 3. Upsert in batches (uses 'UMIS number' as the unique key)
    print(f"\n[3/4] Uploading records in batches of {BATCH_SIZE}...")
    records = df.to_dict(orient="records")
    total = len(records)
    inserted = 0
    updated  = 0

    for i in range(0, total, BATCH_SIZE):
        batch = records[i : i + BATCH_SIZE]
        ops = [
            UpdateOne(
                {"UMIS number": rec.get("UMIS number", "")},
                {"$set": rec},
                upsert=True
            )
            for rec in batch
        ]
        result = col.bulk_write(ops, ordered=False)
        inserted += result.upserted_count
        updated  += result.modified_count

        done = min(i + BATCH_SIZE, total)
        pct  = int(done / total * 100)
        bar  = "#" * (pct // 5) + "." * (20 - pct // 5)
        print(f"      [{bar}] {done}/{total} ({pct}%)", end="\r")

    print()  # newline after progress bar

    # 4. Verification
    print(f"\n[4/4] Verification...")
    cloud_count = col.count_documents({})
    print(f"      -> Newly inserted : {inserted}")
    print(f"      -> Updated (dups) : {updated}")
    print(f"      -> Total in cloud  : {cloud_count}")
    print()
    print("[DONE] Upload complete! All records are now in MongoDB Atlas.")
    print("="*60)

    client.close()

if __name__ == "__main__":
    main()
