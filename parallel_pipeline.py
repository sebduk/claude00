"""
Parallel Processing Pipeline for Face Recognition Project
Uses multiprocessing to process multiple videos simultaneously
Much faster than the sequential pipeline for large video collections
"""

import sys
from pathlib import Path
from typing import List, Tuple
import argparse
from multiprocessing import Pool, cpu_count, Manager
import time

from db_manager import DatabaseManager
from video_processor import VideoProcessor
from face_matcher import FaceMatcher
from filesystem_sync import FileSystemSync


class ParallelProcessingPipeline:
    """Parallel pipeline to process video clips using multiprocessing"""
    
    def __init__(self, known_dir: str, unknown_dir: str, db_path: str = "face_recognition.db", 
                 num_workers: int = None):
        """
        Initialize parallel processing pipeline
        
        Args:
            known_dir: Root directory for known clips
            unknown_dir: Root directory for unknown clips
            db_path: Path to SQLite database
            num_workers: Number of parallel workers (default: CPU count - 1)
        """
        self.db_path = db_path
        self.known_dir = Path(known_dir)
        self.unknown_dir = Path(unknown_dir)
        
        # Determine optimal worker count
        if num_workers is None:
            # Leave one CPU free for system
            self.num_workers = max(1, cpu_count() - 1)
        else:
            self.num_workers = max(1, num_workers)
        
        print(f"Using {self.num_workers} parallel workers")
        
        # These need to be initialized per-worker
        self.db = None
        self.processor = None
        self.matcher = None
        self.sync = None
    
    def _init_worker(self):
        """Initialize worker-specific resources (called in each process)"""
        global worker_db, worker_processor, worker_sync
        worker_db = DatabaseManager(self.db_path)
        worker_processor = VideoProcessor()
        worker_sync = FileSystemSync(worker_db, str(self.known_dir), str(self.unknown_dir))
    
    def _process_single_clip_worker(self, args: Tuple) -> dict:
        """
        Worker function to process a single clip
        Runs in parallel process
        
        Args:
            args: Tuple of (video_path, clip_type, folder_person)
        
        Returns:
            Dictionary with processing results
        """
        video_path, clip_type, folder_person = args
        
        try:
            # Get video metadata
            metadata = worker_processor.get_video_metadata(str(video_path))
            
            # Calculate relative path
            rel_path = worker_sync.get_relative_path(video_path, clip_type)
            
            # Add to database
            clip_id = worker_db.add_clip(
                filename=metadata['filename'],
                filepath=rel_path,
                filesize=metadata['filesize'],
                file_date=metadata['file_date'],
                width=metadata['width'],
                height=metadata['height'],
                duration=metadata['duration'],
                duration_text=metadata['duration_text'],
                clip_type=clip_type,
                folder_person=folder_person
            )
            
            # Create thumbnail and extract faces
            thumbnail_path, faces = worker_processor.create_thumbnail(str(video_path), clip_id)
            worker_db.update_clip_thumbnail(clip_id, thumbnail_path)
            
            # Create mosaic
            mosaic_path = worker_processor.create_mosaic(str(video_path), clip_id)
            if mosaic_path:
                worker_db.update_clip_mosaic(clip_id, mosaic_path)
            
            # Store face profiles in database
            for face in faces:
                is_primary = face.get('is_primary', False)
                
                worker_db.add_face_profile(
                    clip_id=clip_id,
                    face_encoding=face['encoding'],
                    face_location=face['location'],
                    confidence=face['confidence'],
                    is_primary=is_primary
                )
            
            return {
                'success': True,
                'clip_id': clip_id,
                'filename': metadata['filename'],
                'faces_found': len(faces)
            }
        
        except Exception as e:
            return {
                'success': False,
                'filename': str(video_path.name),
                'error': str(e)
            }
    
    def process_new_files_parallel(self):
        """Process all new files using parallel workers"""
        print("\n" + "="*60)
        print("PARALLEL PROCESSING NEW FILES")
        print("="*60)
        
        # Initialize sync in main process
        with DatabaseManager(self.db_path) as db:
            sync = FileSystemSync(db, str(self.known_dir), str(self.unknown_dir))
            
            # Find new files
            new_known, new_unknown = sync.find_new_files()
        
        # Prepare work items
        work_items = []
        
        # Known clips
        for video_path in new_known:
            person_name = video_path.relative_to(self.known_dir).parts[0] if len(video_path.relative_to(self.known_dir).parts) > 1 else None
            work_items.append((video_path, 'known', person_name))
        
        # Unknown clips
        for video_path in new_unknown:
            work_items.append((video_path, 'unknown', None))
        
        if not work_items:
            print("\nNo new files to process")
            return
        
        print(f"\nProcessing {len(work_items)} clips with {self.num_workers} workers...")
        
        # Create process pool and process in parallel
        start_time = time.time()
        
        with Pool(processes=self.num_workers, initializer=self._init_worker) as pool:
            # Use imap_unordered for progress tracking
            results = []
            completed = 0
            
            for result in pool.imap_unordered(self._process_single_clip_worker, work_items):
                completed += 1
                results.append(result)
                
                # Print progress
                if result['success']:
                    print(f"[{completed}/{len(work_items)}] ✓ {result['filename']} - {result['faces_found']} faces")
                else:
                    print(f"[{completed}/{len(work_items)}] ✗ {result['filename']} - ERROR: {result['error']}")
                
                # Print time estimate
                if completed % 10 == 0:
                    elapsed = time.time() - start_time
                    avg_time = elapsed / completed
                    remaining = (len(work_items) - completed) * avg_time
                    print(f"    Progress: {completed}/{len(work_items)} | Elapsed: {elapsed/60:.1f}m | ETA: {remaining/60:.1f}m")
        
        # Summary
        successful = sum(1 for r in results if r['success'])
        failed = len(results) - successful
        elapsed = time.time() - start_time
        
        print(f"\n" + "="*60)
        print(f"PARALLEL PROCESSING COMPLETE")
        print("="*60)
        print(f"Total clips: {len(work_items)}")
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")
        print(f"Time: {elapsed/60:.1f} minutes ({elapsed/len(work_items):.1f}s per clip)")
        print(f"Speed improvement: ~{self.num_workers}x faster than sequential")
    
    def _regenerate_asset_worker(self, args: Tuple) -> dict:
        """
        Worker function to regenerate missing thumbnails/mosaics
        
        Args:
            args: Tuple of (clip, asset_type) where asset_type is 'thumbnail' or 'mosaic'
        
        Returns:
            Dictionary with regeneration results
        """
        clip, asset_type = args
        
        try:
            # Construct full video path
            root = self.known_dir if clip['clip_type'] == 'known' else self.unknown_dir
            video_path = root / clip['filepath']
            
            if not video_path.exists():
                return {
                    'success': False,
                    'filename': clip['filename'],
                    'error': 'Video file not found'
                }
            
            if asset_type == 'thumbnail':
                # Regenerate thumbnail
                thumbnail_path, faces = worker_processor.create_thumbnail(str(video_path), clip['clip_id'])
                worker_db.update_clip_thumbnail(clip['clip_id'], thumbnail_path)
                
                # Store face profiles if not already stored
                existing_profiles = worker_db.get_face_profiles_by_clip(clip['clip_id'])
                
                if not existing_profiles:
                    for face in faces:
                        is_primary = face.get('is_primary', False)
                        worker_db.add_face_profile(
                            clip_id=clip['clip_id'],
                            face_encoding=face['encoding'],
                            face_location=face['location'],
                            confidence=face['confidence'],
                            is_primary=is_primary
                        )
                
                return {
                    'success': True,
                    'filename': clip['filename'],
                    'asset_type': 'thumbnail',
                    'faces_found': len(faces)
                }
            
            else:  # mosaic
                mosaic_path = worker_processor.create_mosaic(str(video_path), clip['clip_id'])
                if mosaic_path:
                    worker_db.update_clip_mosaic(clip['clip_id'], mosaic_path)
                
                return {
                    'success': True,
                    'filename': clip['filename'],
                    'asset_type': 'mosaic'
                }
        
        except Exception as e:
            return {
                'success': False,
                'filename': clip['filename'],
                'error': str(e)
            }
    
    def regenerate_missing_assets_parallel(self):
        """Regenerate missing thumbnails and mosaics in parallel"""
        print("\n" + "="*60)
        print("PARALLEL REGENERATION OF MISSING ASSETS")
        print("="*60)
        
        # Find clips with missing assets
        with DatabaseManager(self.db_path) as db:
            all_clips = db.get_all_clips()
        
        work_items = []
        
        for clip in all_clips:
            # Check if thumbnail is missing or deleted
            if not clip['thumbnail_path'] or not Path(clip['thumbnail_path']).exists():
                work_items.append((clip, 'thumbnail'))
            
            # Check if mosaic is missing or deleted
            if not clip['mosaic_path'] or not Path(clip['mosaic_path']).exists():
                work_items.append((clip, 'mosaic'))
        
        if not work_items:
            print("\nNo missing assets to regenerate")
            return
        
        print(f"\nRegenerating {len(work_items)} assets with {self.num_workers} workers...")
        
        start_time = time.time()
        
        with Pool(processes=self.num_workers, initializer=self._init_worker) as pool:
            results = []
            completed = 0
            
            for result in pool.imap_unordered(self._regenerate_asset_worker, work_items):
                completed += 1
                results.append(result)
                
                if result['success']:
                    asset = result['asset_type']
                    extra = f" - {result.get('faces_found', 0)} faces" if asset == 'thumbnail' else ""
                    print(f"[{completed}/{len(work_items)}] ✓ {result['filename']} ({asset}){extra}")
                else:
                    print(f"[{completed}/{len(work_items)}] ✗ {result['filename']} - ERROR: {result['error']}")
        
        elapsed = time.time() - start_time
        successful = sum(1 for r in results if r['success'])
        
        print(f"\nRegenerated {successful} assets in {elapsed/60:.1f} minutes")
    
    def run_full_pipeline_parallel(self):
        """Run the complete processing pipeline with parallelization"""
        print("\n" + "="*60)
        print("PARALLEL FACE RECOGNITION PIPELINE - FULL RUN")
        print("="*60)
        
        # Step 1: Sync filesystem (single-threaded, fast)
        print("\n[STEP 1] Syncing filesystem with database...")
        with DatabaseManager(self.db_path) as db:
            sync = FileSystemSync(db, str(self.known_dir), str(self.unknown_dir))
            sync.sync_all(auto_update_moves=True, auto_cleanup_orphans=False)
        
        # Step 2: Regenerate missing assets (parallel)
        print("\n[STEP 2] Checking for missing thumbnails/mosaics...")
        self.regenerate_missing_assets_parallel()
        
        # Step 3: Process new files (parallel)
        print("\n[STEP 3] Processing new files...")
        self.process_new_files_parallel()
        
        # Step 4: Build known profiles (single-threaded, fast)
        print("\n[STEP 4] Building known individual profiles...")
        with DatabaseManager(self.db_path) as db:
            matcher = FaceMatcher(db)
            
            # Get all unique person names from known clips
            known_clips = db.get_all_clips(clip_type='known')
            person_names = set(clip['folder_person'] for clip in known_clips 
                              if clip['folder_person'])
            
            print(f"\nFound {len(person_names)} individuals in known folders")
            
            for person_name in sorted(person_names):
                matcher.consolidate_known_folder_profiles(person_name)
            
            matcher.build_individual_profiles()
        
        # Step 5: Match unknown clips (single-threaded, relatively fast)
        print("\n[STEP 5] Matching unknown clips...")
        with DatabaseManager(self.db_path) as db:
            matcher = FaceMatcher(db)
            
            if not matcher.individual_profiles:
                matcher.build_individual_profiles()
            
            unknown_clips = db.get_all_clips(clip_type='unknown')
            
            print(f"\nProcessing {len(unknown_clips)} unknown clips...")
            
            matched_count = 0
            
            for clip in unknown_clips:
                face_profiles = db.get_face_profiles_by_clip(clip['clip_id'])
                
                if not face_profiles:
                    continue
                
                encodings = [p['face_encoding'] for p in face_profiles]
                matches = matcher.process_unknown_clip(clip['clip_id'], encodings)
                
                if matches:
                    matched_count += 1
                    
                    for face_idx, (individual_id, confidence) in matches.items():
                        profile = face_profiles[face_idx]
                        db.update_face_individual(
                            profile['profile_id'],
                            individual_id,
                            confidence
                        )
            
            print(f"\nMatched {matched_count} unknown clips to known individuals")
        
        # Step 6: Show statistics
        print("\n[STEP 6] Final statistics...")
        with DatabaseManager(self.db_path) as db:
            matcher = FaceMatcher(db)
            stats = matcher.get_match_statistics()
        
        print("\n" + "="*60)
        print("PIPELINE COMPLETE")
        print("="*60)
        print(f"\nTotal clips: {stats['total_clips']}")
        print(f"  Known: {stats['known_clips']}")
        print(f"  Unknown: {stats['unknown_clips']}")
        print(f"    - Matched to individuals: {stats['matched_unknown']}")
        print(f"    - Unmatched: {stats['unmatched_unknown']}")
        print(f"\nKnown individuals: {stats['total_individuals']}")
        
        if stats['clips_per_individual']:
            print("\nClips per individual:")
            for name, count in sorted(stats['clips_per_individual'].items(), 
                                     key=lambda x: x[1], reverse=True)[:10]:
                print(f"  {name}: {count} clips")


def main():
    """Command-line interface for the parallel pipeline"""
    parser = argparse.ArgumentParser(
        description='Parallel Face Recognition Video Processing Pipeline'
    )
    
    parser.add_argument(
        '--known-dir',
        default='videos/known',
        help='Directory containing known clips organized by person folders'
    )
    
    parser.add_argument(
        '--unknown-dir',
        default='videos/unknown',
        help='Directory containing unknown clips organized by date folders'
    )
    
    parser.add_argument(
        '--db',
        default='face_recognition.db',
        help='Path to SQLite database'
    )
    
    parser.add_argument(
        '--workers',
        type=int,
        default=None,
        help='Number of parallel workers (default: CPU count - 1)'
    )
    
    parser.add_argument(
        '--action',
        choices=['full', 'process', 'regenerate'],
        default='full',
        help='Action to perform (full pipeline, process only, or regenerate only)'
    )
    
    args = parser.parse_args()
    
    # Initialize parallel pipeline
    pipeline = ParallelProcessingPipeline(
        known_dir=args.known_dir,
        unknown_dir=args.unknown_dir,
        db_path=args.db,
        num_workers=args.workers
    )
    
    if args.action == 'full':
        pipeline.run_full_pipeline_parallel()
    elif args.action == 'process':
        pipeline.process_new_files_parallel()
    elif args.action == 'regenerate':
        pipeline.regenerate_missing_assets_parallel()


if __name__ == "__main__":
    main()