#!/usr/bin/env python3
"""
Clip Management Tool
Handle moving clips between unknown/known and managing matches
"""

import sys
import argparse
from pathlib import Path
import shutil
from db_manager import DatabaseManager


def confirm_match_and_move(db_path: str, clip_id: int, individual_id: int, 
                           known_dir: str, unknown_dir: str, auto_confirm: bool = False):
    """
    Confirm a match and move clip from unknown to known folder
    
    Args:
        db_path: Path to database
        clip_id: ID of the clip to move
        individual_id: ID of the individual to assign to
        known_dir: Root directory for known clips
        unknown_dir: Root directory for unknown clips
        auto_confirm: If True, skip confirmation prompt
    """
    with DatabaseManager(db_path) as db:
        # Get clip info
        clip = db.connection.execute(
            "SELECT * FROM clips WHERE clip_id = ?", (clip_id,)
        ).fetchone()
        
        if not clip:
            print(f"Error: Clip {clip_id} not found")
            return False
        
        clip = dict(clip)
        
        # Get individual info
        individual = db.connection.execute(
            "SELECT * FROM individuals WHERE individual_id = ?", (individual_id,)
        ).fetchone()
        
        if not individual:
            print(f"Error: Individual {individual_id} not found")
            return False
        
        individual = dict(individual)
        
        print(f"\nMoving clip to known folder:")
        print(f"  Clip: {clip['filename']}")
        print(f"  Current type: {clip['clip_type']}")
        print(f"  Assign to: {individual['name']}")
        
        # Confirm
        if not auto_confirm:
            response = input("\nProceed? (y/n): ").lower()
            if response != 'y':
                print("Cancelled")
                return False
        
        # Determine paths
        if clip['clip_type'] == 'unknown':
            old_full_path = Path(unknown_dir) / clip['filepath']
        else:
            old_full_path = Path(known_dir) / clip['filepath']
        
        # Create new path in known folder
        person_folder = Path(known_dir) / individual['name']
        person_folder.mkdir(parents=True, exist_ok=True)
        new_full_path = person_folder / clip['filename']
        
        # Handle duplicate filenames
        counter = 1
        while new_full_path.exists():
            stem = Path(clip['filename']).stem
            suffix = Path(clip['filename']).suffix
            new_full_path = person_folder / f"{stem}_{counter}{suffix}"
            counter += 1
        
        # Move the file
        try:
            shutil.move(str(old_full_path), str(new_full_path))
            print(f"✓ Moved file to: {new_full_path}")
        except Exception as e:
            print(f"✗ Error moving file: {e}")
            return False
        
        # Update database
        new_rel_path = str(new_full_path.relative_to(known_dir))
        
        db.update_clip_paths(
            old_filepath=clip['filepath'],
            new_filepath=new_rel_path,
            new_clip_type='known',
            new_folder_person=individual['name']
        )
        
        # Ensure the match is recorded with high confidence (manual confirmation)
        db.link_clip_to_individual(clip_id, individual_id, confidence=1.0)
        
        print("✓ Database updated")
        print(f"\nClip successfully moved to {individual['name']}'s folder")
        
        return True


def unbind_clip_from_individual(db_path: str, clip_id: int, individual_id: int, 
                                mark_as_error: bool = True):
    """
    Remove incorrect match between clip and individual
    
    Args:
        db_path: Path to database
        clip_id: ID of the clip
        individual_id: ID of the individual to unbind from
        mark_as_error: If True, add to known_error_matches table
    """
    with DatabaseManager(db_path) as db:
        # Get clip info
        clip = db.connection.execute(
            "SELECT * FROM clips WHERE clip_id = ?", (clip_id,)
        ).fetchone()
        
        if not clip:
            print(f"Error: Clip {clip_id} not found")
            return False
        
        clip = dict(clip)
        
        # Get individual info
        individual = db.connection.execute(
            "SELECT * FROM individuals WHERE individual_id = ?", (individual_id,)
        ).fetchone()
        
        if not individual:
            print(f"Error: Individual {individual_id} not found")
            return False
        
        individual = dict(individual)
        
        print(f"\nRemoving incorrect match:")
        print(f"  Clip: {clip['filename']}")
        print(f"  Individual: {individual['name']}")
        
        # Confirm
        response = input("\nProceed? (y/n): ").lower()
        if response != 'y':
            print("Cancelled")
            return False
        
        # Remove from clip_individuals table
        cursor = db.connection.cursor()
        cursor.execute("""
            DELETE FROM clip_individuals 
            WHERE clip_id = ? AND individual_id = ?
        """, (clip_id, individual_id))
        
        # Update face_profiles to remove individual_id
        cursor.execute("""
            UPDATE face_profiles 
            SET individual_id = NULL, match_confidence = NULL
            WHERE clip_id = ? AND individual_id = ?
        """, (clip_id, individual_id))
        
        # Mark as known error match to prevent future matches
        if mark_as_error:
            cursor.execute("""
                INSERT OR IGNORE INTO known_error_matches (clip_id, individual_id, notes)
                VALUES (?, ?, 'Manually unbinded as false positive')
            """, (clip_id, individual_id))
            print("✓ Added to known error matches (won't match again)")
        
        db.connection.commit()
        
        print("✓ Match removed from database")
        print(f"\nClip is no longer associated with {individual['name']}")
        
        return True


def unlink_known_clip(db_path: str, clip_id: int, individual_id: int,
                      known_dir: str, unknown_dir: str, file_date: str = None,
                      auto_confirm: bool = False):
    """
    Unlink a known clip from an individual and move it back to unknown folder
    
    Args:
        db_path: Path to database
        clip_id: ID of the clip to unlink
        individual_id: ID of the individual to unlink from
        known_dir: Root directory for known clips
        unknown_dir: Root directory for unknown clips
        file_date: File date in ISO format (to determine YYYYMM folder)
        auto_confirm: If True, skip confirmation prompt
    """
    with DatabaseManager(db_path) as db:
        # Get clip info
        clip = db.connection.execute(
            "SELECT * FROM clips WHERE clip_id = ?", (clip_id,)
        ).fetchone()
        
        if not clip:
            print(f"Error: Clip {clip_id} not found")
            return False
        
        clip = dict(clip)
        
        # Get individual info
        individual = db.connection.execute(
            "SELECT * FROM individuals WHERE individual_id = ?", (individual_id,)
        ).fetchone()
        
        if not individual:
            print(f"Error: Individual {individual_id} not found")
            return False
        
        individual = dict(individual)
        
        print(f"\nUnlinking clip from known individual:")
        print(f"  Clip: {clip['filename']}")
        print(f"  Current type: {clip['clip_type']}")
        print(f"  Individual: {individual['name']}")
        
        # Use file_date parameter or get from clip
        date_str = file_date if file_date else clip['file_date']
        
        # Extract YYYYMM from date (ISO format: 2024-01-15T10:30:00)
        from datetime import datetime
        try:
            if 'T' in date_str:
                date_obj = datetime.fromisoformat(date_str)
            else:
                date_obj = datetime.strptime(date_str, '%Y-%m-%d')
            year_month = date_obj.strftime('%Y%m')  # Format as YYYYMM (no hyphen)
        except:
            print(f"Warning: Could not parse date {date_str}, using 'unsorted'")
            year_month = 'unsorted'
        
        print(f"  Will move to: unknown/{year_month}/")
        
        # Confirm
        if not auto_confirm:
            response = input("\nProceed? (y/n): ").lower()
            if response != 'y':
                print("Cancelled")
                return False
        
        # Determine current path
        if clip['clip_type'] == 'known':
            old_full_path = Path(known_dir) / clip['filepath']
        else:
            old_full_path = Path(unknown_dir) / clip['filepath']
        
        # Create new path in unknown folder
        unknown_folder = Path(unknown_dir) / year_month
        unknown_folder.mkdir(parents=True, exist_ok=True)
        new_full_path = unknown_folder / clip['filename']
        
        # Handle duplicate filenames
        counter = 1
        while new_full_path.exists():
            stem = Path(clip['filename']).stem
            suffix = Path(clip['filename']).suffix
            new_full_path = unknown_folder / f"{stem}_{counter}{suffix}"
            counter += 1
        
        # Move the file
        try:
            shutil.move(str(old_full_path), str(new_full_path))
            print(f"✓ Moved file to: {new_full_path}")
        except Exception as e:
            print(f"✗ Error moving file: {e}")
            return False
        
        # Update database
        new_rel_path = str(new_full_path.relative_to(unknown_dir))
        
        db.update_clip_paths(
            old_filepath=clip['filepath'],
            new_filepath=new_rel_path,
            new_clip_type='unknown',
            new_folder_person=None
        )
        
        # Remove from clip_individuals
        cursor = db.connection.cursor()
        cursor.execute("""
            DELETE FROM clip_individuals 
            WHERE clip_id = ? AND individual_id = ?
        """, (clip_id, individual_id))
        
        # Update face_profiles to remove individual_id
        cursor.execute("""
            UPDATE face_profiles 
            SET individual_id = NULL, match_confidence = NULL
            WHERE clip_id = ? AND individual_id = ?
        """, (clip_id, individual_id))
        
        # Add to known_error_matches
        cursor.execute("""
            INSERT OR IGNORE INTO known_error_matches (clip_id, individual_id, notes)
            VALUES (?, ?, 'Unlinked from known - wrong attribution')
        """, (clip_id, individual_id))
        
        db.connection.commit()
        
        print("✓ Database updated")
        print(f"\nClip unlinked from {individual['name']} and moved to unknown/{year_month}/")
        
        return True
    """
    Remove all individual matches for a clip (reset to unmatched)
    
    Args:
        db_path: Path to database
        clip_id: ID of the clip
    """
    with DatabaseManager(db_path) as db:
        # Get clip info
        clip = db.connection.execute(
            "SELECT * FROM clips WHERE clip_id = ?", (clip_id,)
        ).fetchone()
        
        if not clip:
            print(f"Error: Clip {clip_id} not found")
            return False
        
        clip = dict(clip)
        
        # Get current matches
        matches = db.connection.execute("""
            SELECT i.name 
            FROM individuals i
            JOIN clip_individuals ci ON i.individual_id = ci.individual_id
            WHERE ci.clip_id = ?
        """, (clip_id,)).fetchall()
        
        if not matches:
            print(f"Clip {clip['filename']} has no matches to remove")
            return True
        
        print(f"\nRemoving all matches for clip: {clip['filename']}")
        print(f"  Currently matched to: {', '.join(m[0] for m in matches)}")
        
        # Confirm
        response = input("\nProceed? (y/n): ").lower()
        if response != 'y':
            print("Cancelled")
            return False
        
        # Remove all matches
        cursor = db.connection.cursor()
        cursor.execute("DELETE FROM clip_individuals WHERE clip_id = ?", (clip_id,))
        cursor.execute("""
            UPDATE face_profiles 
            SET individual_id = NULL, match_confidence = NULL
            WHERE clip_id = ?
        """, (clip_id,))
        
        db.connection.commit()
        
        print("✓ All matches removed")
        print(f"\nClip is now unmatched")
        
        return True


def list_matches_for_clip(db_path: str, clip_id: int):
    """
    List all matches for a clip
    
    Args:
        db_path: Path to database
        clip_id: ID of the clip
    """
    with DatabaseManager(db_path) as db:
        # Get clip info
        clip = db.connection.execute(
            "SELECT * FROM clips WHERE clip_id = ?", (clip_id,)
        ).fetchone()
        
        if not clip:
            print(f"Error: Clip {clip_id} not found")
            return
        
        clip = dict(clip)
        
        print(f"\nClip: {clip['filename']}")
        print(f"Type: {clip['clip_type']}")
        print(f"Path: {clip['filepath']}")
        
        # Get matches
        matches = db.connection.execute("""
            SELECT i.individual_id, i.name, ci.confidence
            FROM individuals i
            JOIN clip_individuals ci ON i.individual_id = ci.individual_id
            WHERE ci.clip_id = ?
            ORDER BY ci.confidence DESC
        """, (clip_id,)).fetchall()
        
        if matches:
            print(f"\nMatched to {len(matches)} individual(s):")
            for individual_id, name, confidence in matches:
                print(f"  - {name} (ID: {individual_id}, Confidence: {confidence:.1%})")
        else:
            print("\nNo matches found")


def find_clip_by_filename(db_path: str, filename: str):
    """
    Find clip ID by filename
    
    Args:
        db_path: Path to database
        filename: Filename to search for
    
    Returns:
        List of matching clips
    """
    with DatabaseManager(db_path) as db:
        clips = db.connection.execute("""
            SELECT clip_id, filename, filepath, clip_type
            FROM clips
            WHERE filename LIKE ?
        """, (f'%{filename}%',)).fetchall()
        
        if clips:
            print(f"\nFound {len(clips)} matching clip(s):")
            for clip_id, fname, fpath, ctype in clips:
                print(f"  ID: {clip_id} | {fname} | Type: {ctype}")
            return clips
        else:
            print(f"\nNo clips found matching: {filename}")
            return []


def main():
    parser = argparse.ArgumentParser(
        description='Manage clip-to-individual matches and move clips between folders'
    )
    
    parser.add_argument(
        '--db',
        default='face_recognition.db',
        help='Path to database'
    )
    
    parser.add_argument(
        '--known-dir',
        default='videos/known',
        help='Known videos directory'
    )
    
    parser.add_argument(
        '--unknown-dir',
        default='videos/unknown',
        help='Unknown videos directory'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Confirm match and move
    confirm_parser = subparsers.add_parser('confirm', help='Confirm match and move clip to known folder')
    confirm_parser.add_argument('clip_id', type=int, help='Clip ID')
    confirm_parser.add_argument('individual_id', type=int, help='Individual ID')
    confirm_parser.add_argument('--auto-confirm', action='store_true', help='Skip confirmation prompt')
    
    # Unbind specific match
    unbind_parser = subparsers.add_parser('unbind', help='Remove incorrect match')
    unbind_parser.add_argument('clip_id', type=int, help='Clip ID')
    unbind_parser.add_argument('individual_id', type=int, help='Individual ID to unbind')
    
    # Unbind all matches
    unbind_all_parser = subparsers.add_parser('unbind-all', help='Remove all matches for a clip')
    unbind_all_parser.add_argument('clip_id', type=int, help='Clip ID')
    
    # Unlink known clip
    unlink_parser = subparsers.add_parser('unlink', help='Unlink known clip and move to unknown')
    unlink_parser.add_argument('clip_id', type=int, help='Clip ID')
    unlink_parser.add_argument('individual_id', type=int, help='Individual ID to unlink from')
    unlink_parser.add_argument('--file-date', help='File date for determining YYYYMM folder')
    unlink_parser.add_argument('--auto-confirm', action='store_true', help='Skip confirmation prompt')
    
    # List matches
    list_parser = subparsers.add_parser('list', help='List matches for a clip')
    list_parser.add_argument('clip_id', type=int, help='Clip ID')
    
    # Find clip
    find_parser = subparsers.add_parser('find', help='Find clip by filename')
    find_parser.add_argument('filename', help='Filename to search for')
    
    args = parser.parse_args()
    
    if args.command == 'confirm':
        confirm_match_and_move(args.db, args.clip_id, args.individual_id, 
                              args.known_dir, args.unknown_dir, 
                              auto_confirm=args.auto_confirm)
    
    elif args.command == 'unbind':
        unbind_clip_from_individual(args.db, args.clip_id, args.individual_id)
    
    elif args.command == 'unbind-all':
        unbind_all_matches_for_clip(args.db, args.clip_id)
    
    elif args.command == 'unlink':
        unlink_known_clip(args.db, args.clip_id, args.individual_id,
                         args.known_dir, args.unknown_dir,
                         file_date=args.file_date,
                         auto_confirm=args.auto_confirm)
    
    elif args.command == 'list':
        list_matches_for_clip(args.db, args.clip_id)
    
    elif args.command == 'find':
        find_clip_by_filename(args.db, args.filename)
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()