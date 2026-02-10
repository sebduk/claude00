#!/usr/bin/env python3
"""
Database Cleanup Script
Fixes inconsistencies in the face recognition database:
1. Removes matches that were previously denied
2. Cleans up orphaned records
"""

import sqlite3
import sys


def cleanup_denied_matches(db_path="face_recognition.db"):
    """
    Remove any clip_individual links that are in known_error_matches
    """
    print("\n" + "="*60)
    print("CLEANUP: Removing Denied Matches from Active Links")
    print("="*60)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Find contradictory matches
    cursor.execute("""
        SELECT 
            ci.clip_id,
            ci.individual_id,
            c.filename,
            i.name
        FROM clip_individuals ci
        JOIN known_error_matches kem 
            ON ci.clip_id = kem.clip_id 
            AND ci.individual_id = kem.individual_id
        JOIN clips c ON ci.clip_id = c.clip_id
        JOIN individuals i ON ci.individual_id = i.individual_id
    """)
    
    contradictions = cursor.fetchall()
    
    if not contradictions:
        print("\n✅ No contradictory matches found. Database is clean.")
        conn.close()
        return 0
    
    print(f"\nFound {len(contradictions)} contradictory matches to remove:")
    print("-" * 60)
    
    for clip_id, individual_id, filename, name in contradictions:
        print(f"  Clip: {filename} (ID: {clip_id})")
        print(f"  Individual: {name} (ID: {individual_id})")
    
    response = input(f"\nRemove these {len(contradictions)} contradictory matches? (yes/no): ")
    
    if response.lower() != 'yes':
        print("Cancelled.")
        conn.close()
        return 1
    
    # Remove from clip_individuals
    cursor.execute("""
        DELETE FROM clip_individuals
        WHERE (clip_id, individual_id) IN (
            SELECT clip_id, individual_id FROM known_error_matches
        )
    """)
    
    removed_ci = cursor.rowcount
    
    # Also update face_profiles to remove individual_id
    cursor.execute("""
        UPDATE face_profiles
        SET individual_id = NULL, match_confidence = NULL
        WHERE (clip_id, individual_id) IN (
            SELECT clip_id, individual_id FROM known_error_matches
        )
    """)
    
    removed_fp = cursor.rowcount
    
    conn.commit()
    
    print(f"\n✅ Cleanup complete:")
    print(f"   Removed {removed_ci} clip-individual links")
    print(f"   Cleared {removed_fp} face profile individual assignments")
    
    conn.close()
    return 0


def cleanup_orphaned_records(db_path="face_recognition.db"):
    """
    Remove orphaned records that reference non-existent clips
    """
    print("\n" + "="*60)
    print("CLEANUP: Removing Orphaned Records")
    print("="*60)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Find orphaned face_profiles
    cursor.execute("""
        SELECT fp.profile_id, fp.clip_id
        FROM face_profiles fp
        LEFT JOIN clips c ON fp.clip_id = c.clip_id
        WHERE c.clip_id IS NULL
    """)
    
    orphaned_profiles = cursor.fetchall()
    
    # Find orphaned clip_individuals
    cursor.execute("""
        SELECT ci.clip_id, ci.individual_id
        FROM clip_individuals ci
        LEFT JOIN clips c ON ci.clip_id = c.clip_id
        WHERE c.clip_id IS NULL
    """)
    
    orphaned_ci = cursor.fetchall()
    
    # Find orphaned known_error_matches
    cursor.execute("""
        SELECT kem.error_id, kem.clip_id
        FROM known_error_matches kem
        LEFT JOIN clips c ON kem.clip_id = c.clip_id
        WHERE c.clip_id IS NULL
    """)
    
    orphaned_errors = cursor.fetchall()
    
    total_orphaned = len(orphaned_profiles) + len(orphaned_ci) + len(orphaned_errors)
    
    if total_orphaned == 0:
        print("\n✅ No orphaned records found. Database is clean.")
        conn.close()
        return 0
    
    print(f"\nFound orphaned records:")
    print(f"  Face Profiles: {len(orphaned_profiles)}")
    print(f"  Clip-Individual Links: {len(orphaned_ci)}")
    print(f"  Known Error Matches: {len(orphaned_errors)}")
    print(f"  Total: {total_orphaned}")
    
    response = input(f"\nRemove these orphaned records? (yes/no): ")
    
    if response.lower() != 'yes':
        print("Cancelled.")
        conn.close()
        return 1
    
    removed = 0
    
    if orphaned_profiles:
        cursor.execute("""
            DELETE FROM face_profiles
            WHERE clip_id NOT IN (SELECT clip_id FROM clips)
        """)
        removed += cursor.rowcount
    
    if orphaned_ci:
        cursor.execute("""
            DELETE FROM clip_individuals
            WHERE clip_id NOT IN (SELECT clip_id FROM clips)
        """)
        removed += cursor.rowcount
    
    if orphaned_errors:
        cursor.execute("""
            DELETE FROM known_error_matches
            WHERE clip_id NOT IN (SELECT clip_id FROM clips)
        """)
        removed += cursor.rowcount
    
    conn.commit()
    
    print(f"\n✅ Removed {removed} orphaned records")
    
    conn.close()
    return 0


def verify_cascade_deletes(db_path="face_recognition.db"):
    """
    Verify that cascade delete constraints are properly set up
    """
    print("\n" + "="*60)
    print("VERIFICATION: Cascade Delete Constraints")
    print("="*60)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check foreign key constraints
    cursor.execute("PRAGMA foreign_keys")
    fk_enabled = cursor.fetchone()[0]
    
    print(f"\nForeign Keys Enabled: {'✅ Yes' if fk_enabled else '❌ No'}")
    
    if not fk_enabled:
        print("\n⚠️  WARNING: Foreign keys are disabled!")
        print("   Cascade deletes will NOT work.")
        print("   Enable them by running: PRAGMA foreign_keys = ON;")
    
    # Check table schemas
    tables = ['face_profiles', 'clip_individuals', 'known_error_matches']
    
    print("\nTable Constraints:")
    print("-" * 60)
    
    for table in tables:
        cursor.execute(f"SELECT sql FROM sqlite_master WHERE type='table' AND name='{table}'")
        schema = cursor.fetchone()[0]
        
        has_cascade = 'ON DELETE CASCADE' in schema
        print(f"{table}: {'✅ CASCADE' if has_cascade else '❌ NO CASCADE'}")
    
    conn.close()


def main():
    """Run cleanup operations"""
    print("="*60)
    print("DATABASE CLEANUP UTILITY")
    print("="*60)
    
    # Verify cascade deletes
    verify_cascade_deletes()
    
    # Cleanup denied matches
    result1 = cleanup_denied_matches()
    
    # Cleanup orphaned records
    result2 = cleanup_orphaned_records()
    
    print("\n" + "="*60)
    print("CLEANUP SUMMARY")
    print("="*60)
    
    if result1 == 0 and result2 == 0:
        print("\n✅ Database cleanup completed successfully!")
        return 0
    else:
        print("\n⚠️  Some operations were cancelled or failed.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
