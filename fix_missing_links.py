#!/usr/bin/env python3
"""
Fix Missing Links
Link known clips to their individuals based on folder_person field
"""

import sys
from db_manager import DatabaseManager
import argparse


def find_unlinked_clips(db_path: str = "face_recognition.db"):
    """
    Find clips that should be linked to individuals but aren't
    
    Returns:
        List of (clip_id, individual_id, clip_name, individual_name) tuples
    """
    with DatabaseManager(db_path) as db:
        # Find known clips with folder_person that aren't in clip_individuals
        cursor = db.connection.cursor()
        
        unlinked = cursor.execute("""
            SELECT 
                c.clip_id,
                c.filename,
                c.folder_person,
                i.individual_id,
                i.name
            FROM clips c
            JOIN individuals i ON c.folder_person = i.name
            WHERE c.clip_type = 'known'
            AND c.folder_person IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM clip_individuals ci 
                WHERE ci.clip_id = c.clip_id 
                AND ci.individual_id = i.individual_id
            )
            ORDER BY i.name, c.filename
        """).fetchall()
        
        return [dict(row) for row in unlinked]


def fix_all_links(db_path: str = "face_recognition.db", dry_run: bool = False):
    """
    Fix all missing links between clips and individuals
    
    Args:
        db_path: Path to database
        dry_run: If True, only show what would be fixed without making changes
    """
    print("="*80)
    print("FIX MISSING CLIP-INDIVIDUAL LINKS")
    print("="*80)
    
    print("\n[1/3] Finding unlinked clips...")
    unlinked = find_unlinked_clips(db_path)
    
    if not unlinked:
        print("\n✓ No unlinked clips found! All known clips are properly linked.")
        return
    
    print(f"\nFound {len(unlinked)} clips that should be linked:")
    
    # Group by individual
    by_individual = {}
    for item in unlinked:
        name = item['name']
        if name not in by_individual:
            by_individual[name] = []
        by_individual[name].append(item)
    
    print(f"\nAffected individuals: {len(by_individual)}")
    for name, clips in sorted(by_individual.items()):
        print(f"  - {name}: {len(clips)} unlinked clips")
    
    if dry_run:
        print("\n[DRY RUN MODE - No changes will be made]")
        print("\nSample clips that would be linked:")
        for name, clips in sorted(by_individual.items())[:5]:
            print(f"\n{name}:")
            for clip in clips[:3]:
                print(f"  - {clip['filename']}")
            if len(clips) > 3:
                print(f"  ... and {len(clips) - 3} more")
        
        print("\nTo actually fix these links, run without --dry-run")
        return
    
    # Confirm
    print("\n[2/3] Ready to create links...")
    response = input(f"\nCreate {len(unlinked)} clip-individual links? (y/n): ").lower()
    
    if response != 'y':
        print("Cancelled")
        return
    
    # Create links
    print("\n[3/3] Creating links...")
    
    with DatabaseManager(db_path) as db:
        fixed_count = 0
        
        for item in unlinked:
            try:
                # Link clip to individual with confidence 1.0 (known folder = confirmed)
                db.link_clip_to_individual(
                    item['clip_id'],
                    item['individual_id'],
                    confidence=1.0
                )
                fixed_count += 1
                
                if fixed_count % 100 == 0:
                    print(f"  Linked {fixed_count}/{len(unlinked)} clips...")
            
            except Exception as e:
                print(f"  ✗ Error linking {item['filename']}: {e}")
        
        print(f"\n✓ Successfully linked {fixed_count} clips to individuals")
    
    # Verify
    print("\n[VERIFICATION] Checking for remaining unlinked clips...")
    remaining = find_unlinked_clips(db_path)
    
    if not remaining:
        print("✓ All known clips are now properly linked!")
    else:
        print(f"⚠ Warning: {len(remaining)} clips still unlinked (may need manual review)")
    
    # Show updated counts
    print("\n" + "="*80)
    print("UPDATED INDIVIDUAL CLIP COUNTS")
    print("="*80)
    
    with DatabaseManager(db_path) as db:
        individuals = db.get_all_individuals()
        
        for individual in individuals:
            clips = db.get_clips_for_individual(individual['individual_id'])
            
            if individual['name'] in by_individual:
                added = len(by_individual[individual['name']])
                print(f"{individual['name']}: {len(clips)} clips (added {added})")


def show_sample_unlinked(db_path: str = "face_recognition.db"):
    """
    Show a sample of unlinked clips for inspection
    """
    unlinked = find_unlinked_clips(db_path)
    
    if not unlinked:
        print("✓ No unlinked clips found!")
        return
    
    print(f"\nFound {len(unlinked)} unlinked clips")
    print("\nSample (first 20):")
    print(f"\n{'Individual':<30} {'Clip':<50}")
    print("-" * 80)
    
    for item in unlinked[:20]:
        print(f"{item['name']:<30} {item['filename']:<50}")
    
    if len(unlinked) > 20:
        print(f"\n... and {len(unlinked) - 20} more")


def main():
    parser = argparse.ArgumentParser(
        description='Fix missing links between known clips and individuals'
    )
    
    parser.add_argument(
        '--db',
        default='face_recognition.db',
        help='Path to database'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be fixed without making changes'
    )
    
    parser.add_argument(
        '--sample',
        action='store_true',
        help='Just show a sample of unlinked clips'
    )
    
    args = parser.parse_args()
    
    if args.sample:
        show_sample_unlinked(args.db)
    else:
        fix_all_links(args.db, args.dry_run)


if __name__ == "__main__":
    main()
