import pandas as pd
import random
import re
from pymongo import MongoClient

print('Loading dataset...')
df = pd.read_csv('TN_Student_Skill_Dataset.csv')

print('Generating mobile numbers and emails...')
def gen_mobile(seed):
    random.seed(seed)
    return '9' + str(random.randint(100000000, 999999999))

def gen_email(row):
    name = str(row['name']).split()[0].lower()
    name = re.sub(r'[^a-z]', '', name)
    umis = str(row['UMIS number'])
    return f'{name}.{umis[-4:]}@smart.edu'

df['mobile_number'] = df['studentID'].apply(lambda x: gen_mobile(x))
df['email_id'] = df.apply(gen_email, axis=1)

print('Saving to CSV...')
df.to_csv('TN_Student_Skill_Dataset.csv', index=False)
print('CSV Updated successfully!')

# Now update MongoDB
print('Connecting to MongoDB Atlas...')
MONGO_URI = 'mongodb+srv://jayanthr239_db_user:U37kOH0GvVwaTXxF@cluster0.duhyvxx.mongodb.net/?appName=Cluster0'
client = MongoClient(MONGO_URI)
db = client['smart_erp']
students_col = db['students']

print('Updating MongoDB documents...')
updates = 0
for index, row in df.iterrows():
    umis = str(row['UMIS number'])
    mobile = row['mobile_number']
    email = row['email_id']
    
    result = students_col.update_one(
        {'UMIS number': umis},
        {'$set': {'mobile_number': mobile, 'email_id': email}} # update if exists
    )
    if result.modified_count > 0:
        updates += 1

print(f'MongoDB Update Complete. Modified {updates} existing records.')
