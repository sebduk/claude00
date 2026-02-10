#!/usr/bin/env python3
"""
Find Duplicate Known Individuals
Compares face encodings between known individuals to find potential duplicates
"""

import sys
import sqlite3
import pickle
import json
import numpy as np

def find_duplicates(threshold=0.6):
    db = sqlite3.connect('face_recognition.db')
    cursor = db.cursor()
    
    # Get all individuals with their face profiles
    cursor.execute('''
        SELECT DISTINCT
            i.individual_id,
            i.name,
            fp.face_encoding,
            c.thumbnail_path,
            c.clip_id
        FROM individuals i
        JOIN face_profiles fp ON i.individual_id = fp.individual_id
        JOIN clips c ON fp.clip_id = c.clip_id
        WHERE fp.face_encoding IS NOT NULL
        ORDER BY i.individual_id
    ''')
    
    profiles = cursor.fetchall()
    
    # Group by individual
    individual_encodings = {}
    individual_info = {}
    
    for individual_id, name, encoding_blob, thumbnail_path, clip_id in profiles:
        if individual_id not in individual_encodings:
            individual_encodings[individual_id] = []
            individual_info[individual_id] = {
                'name': name,
                'thumbnail_path': thumbnail_path,
                'clip_id': clip_id
            }
        
        encoding = pickle.loads(encoding_blob)
        individual_encodings[individual_id].append(encoding)
    
    # Calculate average encodings
    avg_encodings = {}
    for individual_id, encodings in individual_encodings.items():
        avg_encodings[individual_id] = np.mean(encodings, axis=0)
    
    # Find duplicates
    duplicates = []
    individual_ids = list(avg_encodings.keys())
    
    for i in range(len(individual_ids)):
        for j in range(i + 1, len(individual_ids)):
            id1 = individual_ids[i]
            id2 = individual_ids[j]
            
            # Calculate Euclidean distance
            distance = float(np.linalg.norm(avg_encodings[id1] - avg_encodings[id2]))
            
            if distance <= threshold:
                similarity = round((1 - (distance / threshold)) * 100, 1)
                
                duplicates.append({
                    'individual1_id': int(id1),
                    'individual1_name': individual_info[id1]['name'],
                    'individual1_thumbnail': individual_info[id1]['thumbnail_path'],
                    'individual1_clip_id': int(individual_info[id1]['clip_id']),
                    'individual2_id': int(id2),
                    'individual2_name': individual_info[id2]['name'],
                    'individual2_thumbnail': individual_info[id2]['thumbnail_path'],
                    'individual2_clip_id': int(individual_info[id2]['clip_id']),
                    'distance': distance,
                    'similarity': similarity
                })
    
    # Sort by similarity
    duplicates.sort(key=lambda x: x['similarity'], reverse=True)
    
    print(json.dumps(duplicates))
    db.close()

if __name__ == '__main__':
    threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 0.6
    find_duplicates(threshold)