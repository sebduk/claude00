#!/usr/bin/python3
"""
Force Re-match Individual
Re-runs face matching for a specific individual against all clips
"""

import sys
import sqlite3
import pickle
import numpy as np
import argparse


def force_rematch_individual(individual_id, threshold=0.6, db_path='face_recognition.db'):
    """
    Force re-match an individual against all clips
    
    Args:
        individual_id: ID of individual to re-match
        threshold: Distance threshold for matching (default 0.6)
        db_path: Path to database
    
    Returns:
        dict with statistics
    """
    db = sqlite3.connect(db_path)
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    
    # Get the individual
    cursor.execute("SELECT individual_id, name FROM individuals WHERE individual_id = ?", (individual_id,))
    individual = cursor.fetchone()
    
    if not individual:
        return {'success': False, 'error': 'Individual not found'}
    
    individual_name = individual['name']
    
    # Get all face encodings for this individual (from their known clips)
    cursor.execute("""
        SELECT fp.face_encoding
        FROM face_profiles fp
        WHERE fp.individual_id = ? 
        AND fp.face_encoding IS NOT NULL
    """, (individual_id,))
    
    individual_profiles = cursor.fetchall()
    
    if not individual_profiles:
        return {'success': False, 'error': 'Individual has no face encodings'}
    
    # Calculate average encoding for this individual
    encodings = []
    for profile in individual_profiles:
        encoding = pickle.loads(profile['face_encoding'])
        encodings.append(encoding)
    
    individual_encoding = np.mean(encodings, axis=0)
    
    # Step 1: Clear rejected matches
    cursor.execute("DELETE FROM known_error_matches WHERE individual_id = ?", (individual_id,))
    cleared_rejections = cursor.rowcount
    db.commit()
    
    # Step 2: Get ALL clips except those already in this individual's known folder
    cursor.execute("""
        SELECT c.clip_id, c.filename, c.clip_type, c.filepath
        FROM clips c
        WHERE NOT EXISTS (
            SELECT 1 FROM clips c2
            WHERE c2.clip_id = c.clip_id
            AND c2.clip_type = 'known'
            AND c2.folder_person = ?
        )
        ORDER BY c.clip_type, c.filepath
    """, (individual_name,))
    
    all_clips = cursor.fetchall()
    clips_evaluated = len(all_clips)
    
    # Step 3: For each clip, calculate best distance
    matches = []
    
    for clip in all_clips:
        # Get all face profiles for this clip
        cursor.execute("""
            SELECT profile_id, face_encoding 
            FROM face_profiles 
            WHERE clip_id = ? AND face_encoding IS NOT NULL
        """, (clip['clip_id'],))
        
        profiles = cursor.fetchall()
        
        if not profiles:
            continue
        
        best_distance = float('inf')
        
        for profile in profiles:
            clip_encoding = pickle.loads(profile['face_encoding'])
            
            # Calculate Euclidean distance
            distance = float(np.linalg.norm(individual_encoding - clip_encoding))
            
            if distance < best_distance:
                best_distance = distance
        
        # If within threshold, add to matches
        if best_distance <= threshold:
            confidence = max(0.0, 1.0 - (best_distance / threshold))
            
            matches.append({
                'clip_id': clip['clip_id'],
                'confidence': confidence,
                'distance': best_distance
            })
    
    # Step 4: Clear existing matches for this individual
    cursor.execute("DELETE FROM clip_individuals WHERE individual_id = ?", (individual_id,))
    db.commit()
    
    # Step 5: Insert new matches
    for match in matches:
        cursor.execute("""
            INSERT INTO clip_individuals (clip_id, individual_id, confidence)
            VALUES (?, ?, ?)
        """, (match['clip_id'], individual_id, match['confidence']))
    
    db.commit()
    db.close()
    
    return {
        'success': True,
        'cleared_rejections': cleared_rejections,
        'clips_evaluated': clips_evaluated,
        'new_matches': len(matches),
        'threshold': threshold,
        'individual_profiles_used': len(individual_profiles)
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Force re-match an individual against all clips')
    parser.add_argument('individual_id', type=int, help='ID of individual to re-match')
    parser.add_argument('--threshold', type=float, default=0.6, help='Distance threshold (default: 0.6)')
    parser.add_argument('--db', default='face_recognition.db', help='Database path')
    
    args = parser.parse_args()
    
    result = force_rematch_individual(args.individual_id, args.threshold, args.db)
    
    if result['success']:
        print(f"SUCCESS")
        print(f"cleared_rejections:{result['cleared_rejections']}")
        print(f"clips_evaluated:{result['clips_evaluated']}")
        print(f"new_matches:{result['new_matches']}")
        print(f"threshold:{result['threshold']}")
        print(f"individual_profiles_used:{result['individual_profiles_used']}")
    else:
        print(f"ERROR:{result['error']}")
        sys.exit(1)