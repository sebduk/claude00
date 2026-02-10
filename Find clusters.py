#!/usr/bin/env python3
"""
Find Unknown Face Clusters
Clusters similar faces from unknown clips to identify potential new individuals
"""

import sys
import sqlite3
import pickle
import json
import numpy as np

def find_clusters(threshold=0.5, min_cluster_size=3):
    db = sqlite3.connect('face_recognition.db')
    cursor = db.cursor()
    
    # Get all unmatched face profiles from unknown clips
    cursor.execute('''
        SELECT 
            fp.profile_id,
            fp.face_encoding,
            fp.clip_id,
            c.filename,
            c.thumbnail_path,
            c.file_date
        FROM face_profiles fp
        JOIN clips c ON fp.clip_id = c.clip_id
        WHERE c.clip_type = "unknown"
        AND fp.individual_id IS NULL
        AND fp.face_encoding IS NOT NULL
        ORDER BY c.file_date DESC
    ''')
    
    faces = cursor.fetchall()
    
    if len(faces) < min_cluster_size:
        print(json.dumps([]))
        db.close()
        return
    
    # Deserialize encodings
    face_data = []
    for profile_id, encoding_blob, clip_id, filename, thumbnail_path, file_date in faces:
        encoding = pickle.loads(encoding_blob)
        face_data.append({
            'profile_id': profile_id,
            'encoding': encoding,
            'clip_id': clip_id,
            'filename': filename,
            'thumbnail_path': thumbnail_path,
            'file_date': file_date
        })
    
    # Simple clustering
    clusters = []
    used_faces = set()
    
    for i, face_a in enumerate(face_data):
        if i in used_faces:
            continue
        
        cluster = [i]
        
        for j, face_b in enumerate(face_data):
            if i == j or j in used_faces:
                continue
            
            distance = float(np.linalg.norm(face_a['encoding'] - face_b['encoding']))
            
            if distance <= threshold:
                cluster.append(j)
                used_faces.add(j)
        
        if len(cluster) >= min_cluster_size:
            cluster_data = {
                'size': len(cluster),
                'faces': []
            }
            
            for idx in cluster:
                cluster_data['faces'].append({
                    'profile_id': int(face_data[idx]['profile_id']),
                    'clip_id': int(face_data[idx]['clip_id']),
                    'filename': face_data[idx]['filename'],
                    'thumbnail_path': face_data[idx]['thumbnail_path'],
                    'file_date': face_data[idx]['file_date']
                })
            
            clusters.append(cluster_data)
            used_faces.update(cluster)
    
    # Sort by size
    clusters.sort(key=lambda x: x['size'], reverse=True)
    
    print(json.dumps(clusters))
    db.close()

if __name__ == '__main__':
    threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
    min_cluster_size = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    find_clusters(threshold, min_cluster_size)