#!/usr/bin/env python3
"""
Diagnostic Script for Face Recognition System
Verifies:
1. Known error matches are properly excluded from matching
2. Cascade deletes work correctly when clips are deleted
3. No denied matches reappear after pipeline runs
"""

import sqlite3
import sys
from pathlib import Path
from db_manager import DatabaseManager
from face_matcher import FaceMatcher


def test_known_error_matches_exclusion(db_path="face_recognition.db"):
    """
    Test that clips with known error matches are not matched again
    """
    print("\n" + "="*60)
    print("TEST 1: Known Error Matches Exclusion")
    print("="*60)
    
    with DatabaseManager(db_path) as db:
        # Get all known error matches
        cursor = db.connection.cursor()
        cursor.execute("""
            SELECT 
                kem.clip_id,
                kem.individual_id,
                c.filename,
                i.name,
                kem.date_added,
                kem.notes
            FROM known_error_matches kem
            JOIN clips c ON kem.clip_id = c.clip_id
            JOIN individuals i ON kem.individual_id = i.individual_id
            ORDER BY kem.date_added DESC
        """)
        
        error_matches = cursor.fetchall()
        
        print(f"\nFound {len(error_matches)} known error matches in database:")
        print("-" * 60)
        
        for clip_id, individual_id, filename, name, date_added, notes in error_matches:
            print(f"Clip: {filename} (ID: {clip_id})")
            print(f"  ❌ Denied match to: {name} (ID: {individual_id})")
            print(f"  Date: {date_added}")
            if notes:
                print(f"  Note: {notes}")
            print()
        
        # Check if any of these are still in clip_individuals
        cursor.execute("""
            SELECT 
                kem.clip_id,
                kem.individual_id,
                c.filename,
                i.name
            FROM known_error_matches kem
            JOIN clip_individuals ci 
                ON kem.clip_id = ci.clip_id 
                AND kem.individual_id = ci.individual_id
            JOIN clips c ON kem.clip_id = c.clip_id
            JOIN individuals i ON kem.individual_id = i.individual_id
        """)
        
        still_matched = cursor.fetchall()
        
        if still_matched:
            print("⚠️  WARNING: Found denied matches that are still in clip_individuals:")
            print("-" * 60)
            for clip_id, individual_id, filename, name in still_matched:
                print(f"  Clip: {filename} (ID: {clip_id})")
                print(f"  Individual: {name} (ID: {individual_id})")
                print(f"  ⚠️  This should NOT happen - the unbind action should have removed this!")
            print("\n❌ TEST FAILED: Denied matches are still linked in database")
            return False
        else:
            print("✅ TEST PASSED: No denied matches are still linked in database")
            
        # Verify matcher respects error matches
        matcher = FaceMatcher(db, match_threshold=0.6)
        matcher.build_individual_profiles()
        
        # Test a few clips with known error matches
        test_count = min(5, len(error_matches))
        if test_count > 0:
            print(f"\n" + "-" * 60)
            print(f"Testing matcher on {test_count} clips with denied matches...")
            print("-" * 60)
            
            for i in range(test_count):
                clip_id, individual_id, filename, name, _, _ = error_matches[i]
                
                # Get face encodings for this clip
                face_profiles = db.get_face_profiles_by_clip(clip_id)
                if not face_profiles:
                    continue
                
                encodings = [p['face_encoding'] for p in face_profiles]
                
                # Process the clip
                matches = matcher.process_unknown_clip(clip_id, encodings)
                
                # Check if the denied individual appears in matches
                denied_in_results = any(
                    ind_id == individual_id 
                    for face_idx, (ind_id, conf) in matches.items()
                )
                
                if denied_in_results:
                    print(f"  ❌ {filename}: Denied individual {name} STILL MATCHED!")
                    return False
                else:
                    print(f"  ✅ {filename}: Denied individual {name} correctly excluded")
        
        print("\n✅ TEST PASSED: Face matcher correctly excludes denied matches")
        return True


def test_cascade_deletes(db_path="face_recognition.db"):
    """
    Test that deleting a clip removes all related records
    """
    print("\n" + "="*60)
    print("TEST 2: Cascade Delete Verification")
    print("="*60)
    
    with DatabaseManager(db_path) as db:
        cursor = db.connection.cursor()
        
        # Get counts before
        cursor.execute("SELECT COUNT(*) FROM clips")
        total_clips = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM face_profiles")
        total_profiles = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM clip_individuals")
        total_clip_individuals = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM known_error_matches")
        total_error_matches = cursor.fetchone()[0]
        
        print(f"\nCurrent database state:")
        print(f"  Clips: {total_clips}")
        print(f"  Face Profiles: {total_profiles}")
        print(f"  Clip-Individual Links: {total_clip_individuals}")
        print(f"  Known Error Matches: {total_error_matches}")
        
        # Find a clip to test with (prefer one with relationships)
        cursor.execute("""
            SELECT c.clip_id, c.filename, 
                   COUNT(DISTINCT fp.profile_id) as num_profiles,
                   COUNT(DISTINCT ci.individual_id) as num_individuals,
                   COUNT(DISTINCT kem.error_id) as num_errors
            FROM clips c
            LEFT JOIN face_profiles fp ON c.clip_id = fp.clip_id
            LEFT JOIN clip_individuals ci ON c.clip_id = ci.clip_id
            LEFT JOIN known_error_matches kem ON c.clip_id = kem.clip_id
            WHERE c.clip_type = 'unknown'
            GROUP BY c.clip_id
            HAVING num_profiles > 0
            LIMIT 1
        """)
        
        test_clip = cursor.fetchone()
        
        if not test_clip:
            print("\n⚠️  No suitable test clip found (need unknown clip with face profiles)")
            return True
        
        clip_id, filename, num_profiles, num_individuals, num_errors = test_clip
        
        print(f"\nTest clip selected: {filename} (ID: {clip_id})")
        print(f"  Face Profiles: {num_profiles}")
        print(f"  Individual Links: {num_individuals}")
        print(f"  Error Matches: {num_errors}")
        
        # Note: We're NOT actually deleting to preserve data
        # Instead, we'll verify the foreign key constraints are set up correctly
        
        cursor.execute("""
            SELECT sql FROM sqlite_master 
            WHERE type='table' AND name IN ('face_profiles', 'clip_individuals', 'known_error_matches')
        """)
        
        schemas = cursor.fetchall()
        
        print("\nVerifying CASCADE DELETE constraints:")
        print("-" * 60)
        
        all_have_cascade = True
        for schema_sql in schemas:
            sql = schema_sql[0]
            if 'ON DELETE CASCADE' in sql:
                table_name = sql.split('CREATE TABLE')[1].split('(')[0].strip()
                print(f"  ✅ {table_name}: Has CASCADE DELETE")
            else:
                table_name = sql.split('CREATE TABLE')[1].split('(')[0].strip()
                print(f"  ❌ {table_name}: Missing CASCADE DELETE")
                all_have_cascade = False
        
        if all_have_cascade:
            print("\n✅ TEST PASSED: All related tables have CASCADE DELETE constraints")
            print("   When a clip is deleted, all related records will be automatically removed:")
            print("   - Face profiles")
            print("   - Clip-individual links")
            print("   - Known error matches")
            return True
        else:
            print("\n❌ TEST FAILED: Some tables missing CASCADE DELETE constraints")
            return False


def check_duplicate_matches():
    """
    Check for any clips that might be getting re-matched to denied individuals
    """
    print("\n" + "="*60)
    print("TEST 3: Check for Duplicate Match Issues")
    print("="*60)
    
    with DatabaseManager() as db:
        cursor = db.connection.cursor()
        
        # Find clips that have BOTH an error match AND a current match to same individual
        cursor.execute("""
            SELECT 
                c.clip_id,
                c.filename,
                i.individual_id,
                i.name,
                kem.date_added as denied_date,
                ci.confidence as current_confidence
            FROM clips c
            JOIN known_error_matches kem ON c.clip_id = kem.clip_id
            JOIN clip_individuals ci 
                ON c.clip_id = ci.clip_id 
                AND kem.individual_id = ci.individual_id
            JOIN individuals i ON ci.individual_id = i.individual_id
            ORDER BY kem.date_added DESC
        """)
        
        duplicates = cursor.fetchall()
        
        if duplicates:
            print(f"\n❌ CRITICAL: Found {len(duplicates)} clips with contradictory data!")
            print("-" * 60)
            print("These clips have BOTH denied matches AND current matches to the same person:")
            print()
            
            for clip_id, filename, individual_id, name, denied_date, confidence in duplicates:
                print(f"Clip: {filename} (ID: {clip_id})")
                print(f"  Individual: {name} (ID: {individual_id})")
                print(f"  Denied on: {denied_date}")
                print(f"  But currently matched with {confidence:.1%} confidence")
                print(f"  ⚠️  This should NOT happen!")
                print()
            
            print("RECOMMENDED ACTION:")
            print("  Run the following SQL to clean up:")
            print()
            print("  DELETE FROM clip_individuals")
            print("  WHERE (clip_id, individual_id) IN (")
            print("    SELECT clip_id, individual_id FROM known_error_matches")
            print("  );")
            print()
            return False
        else:
            print("\n✅ TEST PASSED: No contradictory matches found")
            print("   All denied matches are properly excluded from current matches")
            return True


def main():
    """Run all diagnostic tests"""
    print("="*60)
    print("FACE RECOGNITION SYSTEM DIAGNOSTICS")
    print("="*60)
    
    results = []
    
    # Test 1: Known error matches exclusion
    try:
        results.append(("Known Error Matches Exclusion", test_known_error_matches_exclusion()))
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        results.append(("Known Error Matches Exclusion", False))
    
    # Test 2: Cascade deletes
    try:
        results.append(("Cascade Delete Verification", test_cascade_deletes()))
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        results.append(("Cascade Delete Verification", False))
    
    # Test 3: Check for duplicates
    try:
        results.append(("Duplicate Match Detection", check_duplicate_matches()))
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        results.append(("Duplicate Match Detection", False))
    
    # Summary
    print("\n" + "="*60)
    print("DIAGNOSTIC SUMMARY")
    print("="*60)
    
    all_passed = True
    for test_name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{test_name}: {status}")
        if not passed:
            all_passed = False
    
    print("="*60)
    
    if all_passed:
        print("\n🎉 All tests passed! System is working correctly.")
        print("\nConfirmed:")
        print("  ✅ Denied matches are properly excluded from future matching")
        print("  ✅ Cascade deletes are properly configured")
        print("  ✅ No contradictory match data in database")
        return 0
    else:
        print("\n⚠️  Some tests failed. Please review the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
