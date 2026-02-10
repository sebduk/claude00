#!/usr/bin/env python3
"""
Check for Corrupted Video Files
Scans directories for videos that can't be processed and moves them to quarantine
"""

import sys
import argparse
from pathlib import Path
from video_processor import VideoProcessor
import shutil


def check_video_file(video_path: Path) -> dict:
    """
    Check if a video file is valid and processable
    
    Args:
        video_path: Path to video file
    
    Returns:
        Dictionary with status and error info
    """
    processor = VideoProcessor()
    
    try:
        metadata = processor.get_video_metadata(str(video_path))
        return {
            'path': video_path,
            'status': 'OK',
            'metadata': metadata
        }
    except ValueError as e:
        return {
            'path': video_path,
            'status': 'CORRUPTED',
            'error': str(e)
        }
    except Exception as e:
        return {
            'path': video_path,
            'status': 'ERROR',
            'error': str(e)
        }


def scan_directory(directory: str, extensions: list = None):
    """
    Scan directory for video files and check each one
    
    Args:
        directory: Root directory to scan
        extensions: List of video extensions (default: common formats)
    
    Returns:
        Dictionary with results categorized by status
    """
    if extensions is None:
        extensions = ['.mp4', '.avi', '.mov', '.mkv', '.m4v', '.MP4', '.AVI', '.MOV']
    
    directory = Path(directory)
    
    print(f"Scanning: {directory}")
    print("="*60)
    
    # Find all video files
    video_files = []
    for ext in extensions:
        video_files.extend(directory.rglob(f'*{ext}'))
    
    print(f"Found {len(video_files)} video files\n")
    
    results = {
        'OK': [],
        'CORRUPTED': [],
        'ERROR': []
    }
    
    for idx, video_path in enumerate(video_files, 1):
        print(f"[{idx}/{len(video_files)}] Checking: {video_path.name}...", end=' ')
        
        result = check_video_file(video_path)
        status = result['status']
        
        results[status].append(result)
        
        if status == 'OK':
            print("✓")
        elif status == 'CORRUPTED':
            print(f"✗ CORRUPTED: {result['error']}")
        else:
            print(f"✗ ERROR: {result['error']}")
    
    return results


def quarantine_corrupted_files(results: dict, quarantine_dir: str, move: bool = False):
    """
    Move or copy corrupted files to quarantine directory
    
    Args:
        results: Results dictionary from scan_directory
        quarantine_dir: Directory to move corrupted files to
        move: If True, move files; if False, copy them
    """
    quarantine_dir = Path(quarantine_dir)
    quarantine_dir.mkdir(parents=True, exist_ok=True)
    
    corrupted_files = results['CORRUPTED'] + results['ERROR']
    
    if not corrupted_files:
        print("\nNo corrupted files to quarantine")
        return
    
    print(f"\n{'Moving' if move else 'Copying'} {len(corrupted_files)} corrupted files to: {quarantine_dir}")
    
    for idx, result in enumerate(corrupted_files, 1):
        src_path = result['path']
        dst_path = quarantine_dir / src_path.name
        
        # Handle duplicate names
        counter = 1
        while dst_path.exists():
            stem = src_path.stem
            suffix = src_path.suffix
            dst_path = quarantine_dir / f"{stem}_{counter}{suffix}"
            counter += 1
        
        try:
            if move:
                shutil.move(str(src_path), str(dst_path))
                action = "Moved"
            else:
                shutil.copy2(str(src_path), str(dst_path))
                action = "Copied"
            
            print(f"  [{idx}/{len(corrupted_files)}] {action}: {src_path.name}")
        except Exception as e:
            print(f"  [{idx}/{len(corrupted_files)}] FAILED: {src_path.name} - {e}")
    
    print(f"\nQuarantined {len(corrupted_files)} files")


def create_report(results: dict, output_file: str = None):
    """
    Create a detailed report of scan results
    
    Args:
        results: Results dictionary from scan_directory
        output_file: Optional file to write report to
    """
    lines = []
    
    lines.append("="*60)
    lines.append("VIDEO FILE SCAN REPORT")
    lines.append("="*60)
    
    total = sum(len(files) for files in results.values())
    
    lines.append(f"\nTotal files scanned: {total}")
    lines.append(f"  ✓ OK: {len(results['OK'])} ({len(results['OK'])/total*100:.1f}%)")
    lines.append(f"  ✗ Corrupted: {len(results['CORRUPTED'])} ({len(results['CORRUPTED'])/total*100:.1f}%)")
    lines.append(f"  ⚠ Other errors: {len(results['ERROR'])} ({len(results['ERROR'])/total*100:.1f}%)")
    
    if results['CORRUPTED']:
        lines.append("\n" + "="*60)
        lines.append("CORRUPTED FILES")
        lines.append("="*60)
        for result in results['CORRUPTED']:
            lines.append(f"\n{result['path']}")
            lines.append(f"  Error: {result['error']}")
    
    if results['ERROR']:
        lines.append("\n" + "="*60)
        lines.append("OTHER ERRORS")
        lines.append("="*60)
        for result in results['ERROR']:
            lines.append(f"\n{result['path']}")
            lines.append(f"  Error: {result['error']}")
    
    report_text = "\n".join(lines)
    
    # Print to console
    print("\n" + report_text)
    
    # Optionally write to file
    if output_file:
        with open(output_file, 'w') as f:
            f.write(report_text)
        print(f"\nReport saved to: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Check video files for corruption and quarantine problematic files'
    )
    
    parser.add_argument(
        'directory',
        help='Directory to scan for video files'
    )
    
    parser.add_argument(
        '--quarantine-dir',
        default='quarantine',
        help='Directory to move corrupted files to (default: quarantine/)'
    )
    
    parser.add_argument(
        '--move',
        action='store_true',
        help='Move corrupted files instead of copying them'
    )
    
    parser.add_argument(
        '--no-quarantine',
        action='store_true',
        help='Only scan and report, do not quarantine files'
    )
    
    parser.add_argument(
        '--report',
        help='Save report to this file (default: print to console only)'
    )
    
    args = parser.parse_args()
    
    # Scan directory
    results = scan_directory(args.directory)
    
    # Create report
    create_report(results, args.report)
    
    # Quarantine corrupted files
    if not args.no_quarantine and (results['CORRUPTED'] or results['ERROR']):
        print("\n" + "="*60)
        response = input("Quarantine corrupted files? (y/n): ").lower()
        
        if response == 'y':
            quarantine_corrupted_files(results, args.quarantine_dir, args.move)
        else:
            print("Skipping quarantine")


if __name__ == "__main__":
    main()