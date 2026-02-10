#!/usr/bin/env python3
"""
Diagnose Missing Clips
Find clips in filesystem that aren't in database and why
"""

import sys
from pathlib import Path
from db_manager import DatabaseManager
from video_processor import VideoProcessor
import argparse


def scan_directory_for_clips(directory: Path, extensions: list = None):
    """Scan directory and return all video files"""
    if extensions is None:
        extensions = ['.mp4', '.avi', '.mov', '.mkv', '.m4v', '.MP4', '.AVI', '.MOV']
    
    video_files = []
    for ext in extensions:
        video_files.extend(directory.rglob(f'*{ext}'))
    
    return video_files


def diagnose_all_clips(known_dir: str, unknown_dir: str, db_path: str = "face_recognition.db"):
    """
    Complete diagnosis of all clips
    """
    known_dir = Path(known_dir)
    unknown_dir = Path(unknown_dir)
    
    print("="*80)
    print("COMPLETE CLIP DIAGNOSIS")
    print("="*80)
    
    # Get all files from filesystem
    print("\n[1/4] Scanning filesystem...")
    known_files = scan_directory_for_clips(known_dir)
    unknown_files = scan_directory_for_clips(unknown_dir)
    
    print(f"  Found {len(known_files)} files in known/")
    print(f"  Found {len(unknown_files)} files in unknown/")
    total_fs_files = len(known_files) + len(unknown_files)
    
    # Get all clips from database
    print("\n[2/4] Checking database...")
    with DatabaseManager(db_path) as db:
        db_clips = db.get_all_clips()
        print(f"  Found {len(db_clips)} clips in database")
        
        # Create lookup of database paths
        db_paths = {clip['filepath'] for clip in db_clips}
        
        # Get individuals with clip counts
        individuals = db.get_all_individuals()
        
        # Count actual clips per individual
        individual_file_counts = {}
        for ind in individuals:
            person_folder = known_dir / ind['name']
            if person_folder.exists():
                files = scan_directory_for_clips(person_folder)
                individual_file_counts[ind['name']] = len(files)
            else:
                individual_file_counts[ind['name']] = 0
    
    # Find missing clips
    print("\n[3/4] Finding missing clips...")
    missing_known = []
    missing_unknown = []
    
    for file_path in known_files:
        rel_path = str(file_path.relative_to(known_dir))
        if rel_path not in db_paths:
            missing_known.append(file_path)
    
    for file_path in unknown_files:
        rel_path = str(file_path.relative_to(unknown_dir))
        if rel_path not in db_paths:
            missing_unknown.append(file_path)
    
    total_missing = len(missing_known) + len(missing_unknown)
    
    # Test why clips are missing
    print("\n[4/4] Testing missing clips...")
    processor = VideoProcessor()
    
    corrupt_files = []
    processable_files = []
    
    test_limit = min(20, total_missing)  # Test first 20 missing files
    test_files = (missing_known + missing_unknown)[:test_limit]
    
    for idx, file_path in enumerate(test_files, 1):
        print(f"  [{idx}/{test_limit}] Testing: {file_path.name}...", end=' ')
        try:
            metadata = processor.get_video_metadata(str(file_path))
            print("✓ OK")
            processable_files.append(file_path)
        except Exception as e:
            print(f"✗ FAILED: {str(e)[:50]}")
            corrupt_files.append((file_path, str(e)))
    
    # Summary Report
    print("\n" + "="*80)
    print("DIAGNOSIS SUMMARY")
    print("="*80)
    
    print(f"\nFilesystem: {total_fs_files} total video files")
    print(f"Database: {len(db_clips)} clips")
    print(f"Missing from database: {total_missing} files ({total_missing/total_fs_files*100:.1f}%)")
    print(f"  - Known: {len(missing_known)} files")
    print(f"  - Unknown: {len(missing_unknown)} files")
    
    if test_files:
        print(f"\nSample testing ({test_limit} files):")
        print(f"  Processable: {len(processable_files)} ({len(processable_files)/len(test_files)*100:.1f}%)")
        print(f"  Corrupt: {len(corrupt_files)} ({len(corrupt_files)/len(test_files)*100:.1f}%)")
    
    # Individuals with missing clips
    print("\n" + "="*80)
    print("INDIVIDUALS WITH MISSING CLIPS")
    print("="*80)
    
    problems = []
    for ind in individuals:
        name = ind['name']
        db_count = ind['num_clips']
        fs_count = individual_file_counts.get(name, 0)
        
        if fs_count != db_count:
            problems.append({
                'name': name,
                'db_count': db_count,
                'fs_count': fs_count,
                'missing': fs_count - db_count
            })
    
    if problems:
        problems.sort(key=lambda x: x['missing'], reverse=True)
        print(f"\nFound {len(problems)} individuals with discrepancies:")
        print(f"\n{'Individual':<30} {'Files in Folder':<15} {'In Database':<15} {'Missing':<10}")
        print("-" * 70)
        for p in problems:
            print(f"{p['name']:<30} {p['fs_count']:<15} {p['db_count']:<15} {p['missing']:<10}")
    else:
        print("\n✓ All individuals have correct clip counts!")
    
    # Detailed missing files list
    if missing_known:
        print("\n" + "="*80)
        print(f"MISSING KNOWN CLIPS ({len(missing_known)} files)")
        print("="*80)
        
        # Group by person folder
        by_person = {}
        for file_path in missing_known:
            parts = file_path.relative_to(known_dir).parts
            person = parts[0] if len(parts) > 1 else "unknown"
            if person not in by_person:
                by_person[person] = []
            by_person[person].append(file_path.name)
        
        for person, files in sorted(by_person.items()):
            print(f"\n{person}: {len(files)} missing files")
            for fname in files[:10]:  # Show first 10
                print(f"  - {fname}")
            if len(files) > 10:
                print(f"  ... and {len(files) - 10} more")
    
    if missing_unknown:
        print("\n" + "="*80)
        print(f"MISSING UNKNOWN CLIPS ({len(missing_unknown)} files)")
        print("="*80)
        
        # Group by folder
        by_folder = {}
        for file_path in missing_unknown:
            parts = file_path.relative_to(unknown_dir).parts
            folder = parts[0] if len(parts) > 1 else "root"
            if folder not in by_folder:
                by_folder[folder] = []
            by_folder[folder].append(file_path.name)
        
        for folder, files in sorted(by_folder.items()):
            print(f"\n{folder}: {len(files)} missing files")
            for fname in files[:10]:  # Show first 10
                print(f"  - {fname}")
            if len(files) > 10:
                print(f"  ... and {len(files) - 10} more")
    
    # Recommendations
    print("\n" + "="*80)
    print("RECOMMENDATIONS")
    print("="*80)
    
    if total_missing == 0:
        print("\n✓ No missing clips! Database is in sync with filesystem.")
    else:
        print(f"\nYou have {total_missing} clips in filesystem that aren't in the database.")
        print("\nTo process them:")
        print("  1. For processable files:")
        print("     python3 parallel_pipeline.py --action process --workers 6")
        print("\n  2. For corrupt files:")
        print("     python3 check_corrupted_videos.py videos/known/")
        print("     python3 check_corrupted_videos.py videos/unknown/")
        
        if problems:
            print(f"\n  3. Focus on individuals with most missing clips:")
            for p in problems[:5]:
                print(f"     - {p['name']}: {p['missing']} missing")
    
    # Save detailed report
    report_file = "missing_clips_report.txt"
    with open(report_file, 'w') as f:
        f.write("MISSING CLIPS DETAILED REPORT\n")
        f.write("="*80 + "\n\n")
        
        f.write("MISSING KNOWN CLIPS:\n")
        for file_path in missing_known:
            rel_path = file_path.relative_to(known_dir)
            f.write(f"  {rel_path}\n")
        
        f.write(f"\nMISSING UNKNOWN CLIPS:\n")
        for file_path in missing_unknown:
            rel_path = file_path.relative_to(unknown_dir)
            f.write(f"  {rel_path}\n")
    
    print(f"\nDetailed report saved to: {report_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Diagnose missing clips and database inconsistencies'
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
    
    parser.add_argument(
        '--db',
        default='face_recognition.db',
        help='Path to database'
    )
    
    args = parser.parse_args()
    
    diagnose_all_clips(args.known_dir, args.unknown_dir, args.db)


if __name__ == "__main__":
    main()