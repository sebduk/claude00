"""
Main Processing Pipeline for Face Recognition Project
Orchestrates the complete workflow: scanning, processing, face detection, matching
"""

import sys
from pathlib import Path
from typing import List
import argparse

from db_manager import DatabaseManager
from video_processor import VideoProcessor
from face_matcher import FaceMatcher
from filesystem_sync import FileSystemSync


class ProcessingPipeline:
    """Main pipeline to process all video clips"""
    
    def __init__(self, known_dir: str, unknown_dir: str, db_path: str = "face_recognition.db"):
        """
        Initialize processing pipeline
        
        Args:
            known_dir: Root directory for known clips
            unknown_dir: Root directory for unknown clips
            db_path: Path to SQLite database
        """
        self.db = DatabaseManager(db_path)
        self.processor = VideoProcessor()
        self.matcher = FaceMatcher(self.db)
        self.sync = FileSystemSync(self.db, known_dir, unknown_dir)
        
        self.known_dir = Path(known_dir)
        self.unknown_dir = Path(unknown_dir)
    
    def process_single_clip(self, video_path: Path, clip_type: str, 
                           folder_person: str = None) -> int:
        """
        Process a single video clip: extract metadata, faces, create thumbnails
        
        Args:
            video_path: Path to video file
            clip_type: 'known' or 'unknown'
            folder_person: Person name (for known clips)
        
        Returns:
            clip_id of processed clip
        """
        print(f"\nProcessing: {video_path.name}")
        
        # Get video metadata
        metadata = self.processor.get_video_metadata(str(video_path))
        
        # Calculate relative path
        rel_path = self.sync.get_relative_path(video_path, clip_type)
        
        # Add to database
        clip_id = self.db.add_clip(
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
        
        print(f"  Added to database (clip_id: {clip_id})")
        
        # Create thumbnail and extract faces
        try:
            thumbnail_path, faces = self.processor.create_thumbnail(str(video_path), clip_id)
            self.db.update_clip_thumbnail(clip_id, thumbnail_path)
            print(f"  Created thumbnail: {thumbnail_path}")
            print(f"  Detected {len(faces)} face(s)")
        except Exception as e:
            print(f"  ERROR creating thumbnail: {e}")
            faces = []
        
        # Create mosaic
        try:
            mosaic_path = self.processor.create_mosaic(str(video_path), clip_id)
            if mosaic_path:
                self.db.update_clip_mosaic(clip_id, mosaic_path)
                print(f"  Created mosaic: {mosaic_path}")
        except Exception as e:
            print(f"  ERROR creating mosaic: {e}")
        
        # Store face profiles in database
        for face in faces:
            is_primary = face.get('is_primary', False)
            
            profile_id = self.db.add_face_profile(
                clip_id=clip_id,
                face_encoding=face['encoding'],
                face_location=face['location'],
                confidence=face['confidence'],
                is_primary=is_primary
            )
            
            print(f"  Stored face profile {profile_id} (primary: {is_primary})")
        
        return clip_id
    
    def process_new_files(self):
        """Process all new files found in filesystem"""
        print("\n" + "="*60)
        print("PROCESSING NEW FILES")
        print("="*60)
        
        # Find new files
        new_known, new_unknown = self.sync.find_new_files()
        
        # Process known clips
        print(f"\nProcessing {len(new_known)} new known clips...")
        for video_path in new_known:
            person_name = self.sync.extract_person_from_path(video_path, 'known')
            self.process_single_clip(video_path, 'known', person_name)
        
        # Process unknown clips
        print(f"\nProcessing {len(new_unknown)} new unknown clips...")
        for video_path in new_unknown:
            self.process_single_clip(video_path, 'unknown')
        
        print(f"\nCompleted processing {len(new_known) + len(new_unknown)} new files")
    
    def regenerate_missing_assets(self):
        """
        Regenerate thumbnails and mosaics for clips that are missing them
        This handles interrupted processing
        """
        print("\n" + "="*60)
        print("REGENERATING MISSING THUMBNAILS AND MOSAICS")
        print("="*60)
        
        all_clips = self.db.get_all_clips()
        
        missing_thumbs = []
        missing_mosaics = []
        
        for clip in all_clips:
            # Check if thumbnail is missing or deleted
            if not clip['thumbnail_path'] or not Path(clip['thumbnail_path']).exists():
                missing_thumbs.append(clip)
            
            # Check if mosaic is missing or deleted
            if not clip['mosaic_path'] or not Path(clip['mosaic_path']).exists():
                missing_mosaics.append(clip)
        
        print(f"\nFound {len(missing_thumbs)} clips with missing thumbnails")
        print(f"Found {len(missing_mosaics)} clips with missing mosaics")
        
        # Regenerate thumbnails
        for clip in missing_thumbs:
            print(f"\nRegenerating thumbnail for: {clip['filename']}")
            
            # Construct full video path
            root = self.known_dir if clip['clip_type'] == 'known' else self.unknown_dir
            video_path = root / clip['filepath']
            
            if not video_path.exists():
                print(f"  WARNING: Video file not found at {video_path}")
                continue
            
            try:
                # Create thumbnail and extract faces
                thumbnail_path, faces = self.processor.create_thumbnail(str(video_path), clip['clip_id'])
                self.db.update_clip_thumbnail(clip['clip_id'], thumbnail_path)
                print(f"  Created thumbnail: {thumbnail_path}")
                print(f"  Detected {len(faces)} face(s)")
                
                # Store face profiles if not already stored
                existing_profiles = self.db.get_face_profiles_by_clip(clip['clip_id'])
                
                if not existing_profiles:
                    for face in faces:
                        is_primary = face.get('is_primary', False)
                        
                        profile_id = self.db.add_face_profile(
                            clip_id=clip['clip_id'],
                            face_encoding=face['encoding'],
                            face_location=face['location'],
                            confidence=face['confidence'],
                            is_primary=is_primary
                        )
                        print(f"  Stored face profile {profile_id} (primary: {is_primary})")
            
            except Exception as e:
                print(f"  ERROR regenerating thumbnail: {e}")
        
        # Regenerate mosaics
        for clip in missing_mosaics:
            print(f"\nRegenerating mosaic for: {clip['filename']}")
            
            # Construct full video path
            root = self.known_dir if clip['clip_type'] == 'known' else self.unknown_dir
            video_path = root / clip['filepath']
            
            if not video_path.exists():
                print(f"  WARNING: Video file not found at {video_path}")
                continue
            
            try:
                mosaic_path = self.processor.create_mosaic(str(video_path), clip['clip_id'])
                if mosaic_path:
                    self.db.update_clip_mosaic(clip['clip_id'], mosaic_path)
                    print(f"  Created mosaic: {mosaic_path}")
            except Exception as e:
                print(f"  ERROR regenerating mosaic: {e}")
        
        print(f"\nCompleted regeneration")
        print(f"  Thumbnails: {len(missing_thumbs)}")
        print(f"  Mosaics: {len(missing_mosaics)}")
    
    def build_known_profiles(self):
        """Build consolidated profiles for all known individuals"""
        print("\n" + "="*60)
        print("BUILDING KNOWN INDIVIDUAL PROFILES")
        print("="*60)
        
        # Get all unique person names from known clips
        known_clips = self.db.get_all_clips(clip_type='known')
        person_names = set(clip['folder_person'] for clip in known_clips 
                          if clip['folder_person'])
        
        print(f"\nFound {len(person_names)} individuals in known folders")
        
        # Build profile for each person
        for person_name in sorted(person_names):
            self.matcher.consolidate_known_folder_profiles(person_name)
        
        # Rebuild matcher's cache
        self.matcher.build_individual_profiles()
    
    def match_unknown_clips(self):
        """Match all unknown clips against known individual profiles"""
        print("\n" + "="*60)
        print("MATCHING UNKNOWN CLIPS TO KNOWN INDIVIDUALS")
        print("="*60)
        
        # Ensure profiles are built
        if not self.matcher.individual_profiles:
            self.matcher.build_individual_profiles()
        
        # Get all unknown clips
        unknown_clips = self.db.get_all_clips(clip_type='unknown')
        
        print(f"\nProcessing {len(unknown_clips)} unknown clips...")
        
        matched_count = 0
        
        for clip in unknown_clips:
            print(f"\nClip: {clip['filename']}")
            
            # Get face profiles for this clip
            face_profiles = self.db.get_face_profiles_by_clip(clip['clip_id'])
            
            if not face_profiles:
                print("  No faces detected")
                continue
            
            # Extract encodings
            encodings = [p['face_encoding'] for p in face_profiles]
            
            # Match against known individuals
            matches = self.matcher.process_unknown_clip(clip['clip_id'], encodings)
            
            if matches:
                matched_count += 1
                
                # Update face profiles with individual assignments
                for face_idx, (individual_id, confidence) in matches.items():
                    profile = face_profiles[face_idx]
                    self.db.update_face_individual(
                        profile['profile_id'],
                        individual_id,
                        confidence
                    )
        
        print(f"\nMatched {matched_count} unknown clips to known individuals")
    
    def run_full_pipeline(self):
        """Run the complete processing pipeline"""
        print("\n" + "="*60)
        print("FACE RECOGNITION PIPELINE - FULL RUN")
        print("="*60)
        
        # Step 1: Sync filesystem
        print("\n[STEP 1] Syncing filesystem with database...")
        self.sync.sync_all(auto_update_moves=True, auto_cleanup_orphans=False)
        
        # Step 2: Regenerate missing assets (handles interrupted processing)
        print("\n[STEP 2] Checking for missing thumbnails/mosaics...")
        self.regenerate_missing_assets()
        
        # Step 3: Process new files
        print("\n[STEP 3] Processing new files...")
        self.process_new_files()
        
        # Step 4: Build known profiles
        print("\n[STEP 4] Building known individual profiles...")
        self.build_known_profiles()
        
        # Step 5: Match unknown clips
        print("\n[STEP 5] Matching unknown clips...")
        self.match_unknown_clips()
        
        # Step 6: Show statistics
        print("\n[STEP 6] Final statistics...")
        stats = self.matcher.get_match_statistics()
        
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
                                     key=lambda x: x[1], reverse=True):
                print(f"  {name}: {count} clips")
    
    def regenerate_tagged_thumbnails(self, tag_name: str = "ReThumb"):
        """
        Regenerate thumbnails for all clips tagged with specified tag
        Automatically removes the tag after successful regeneration
        
        Args:
            tag_name: Name of tag to filter clips (default: "ReThumb")
        """
        print(f"\n{'='*60}")
        print(f"REGENERATING THUMBNAILS FOR TAGGED CLIPS")
        print(f"Tag: {tag_name}")
        print(f"{'='*60}\n")
        
        # Get tag_id for the specified tag
        tag = self.db.connection.execute(
            "SELECT tag_id FROM tags WHERE tag_name = ?", 
            (tag_name,)
        ).fetchone()
        
        if not tag:
            print(f"❌ Tag '{tag_name}' not found in database.")
            print(f"   Please create this tag first in admin/tags.php")
            return
        
        tag_id = tag['tag_id']
        
        # Get all clips with this tag
        clips = self.db.connection.execute("""
            SELECT c.*, t.tag_name
            FROM clips c
            JOIN clip_tags ct ON c.clip_id = ct.clip_id
            JOIN tags t ON ct.tag_id = t.tag_id
            WHERE ct.tag_id = ?
            ORDER BY c.clip_type, c.filepath
        """, (tag_id,)).fetchall()
        
        if not clips:
            print(f"ℹ️  No clips found with tag '{tag_name}'")
            return
        
        print(f"Found {len(clips)} clip(s) to regenerate:\n")
        
        success_count = 0
        error_count = 0
        
        for clip in clips:
            clip_id = clip['clip_id']
            filename = clip['filename']
            filepath = clip['filepath']
            clip_type = clip['clip_type']
            
            # Construct full video path
            if clip_type == 'known':
                video_path = self.known_dir / filepath
            else:
                video_path = self.unknown_dir / filepath
            
            print(f"[{success_count + error_count + 1}/{len(clips)}] {filename}")
            print(f"  Path: {filepath}")
            
            # Check if video file exists
            if not video_path.exists():
                print(f"  ❌ ERROR: Video file not found at {video_path}")
                error_count += 1
                continue
            
            try:
                # Delete old face profiles for this clip
                self.db.connection.execute(
                    "DELETE FROM face_profiles WHERE clip_id = ?",
                    (clip_id,)
                )
                self.db.connection.commit()
                
                # Regenerate thumbnail with new 6-level hierarchy
                thumbnail_path, faces = self.processor.create_thumbnail(str(video_path), clip_id)
                
                # Update database with new thumbnail
                self.db.update_clip_thumbnail(clip_id, thumbnail_path)
                
                # Store new face profiles
                for face in faces:
                    self.db.add_face_profile(
                        clip_id=clip_id,
                        face_encoding=face['encoding'],
                        face_location=face.get('location'),
                        confidence=face.get('confidence', 0),
                        is_primary=face.get('is_primary', False)
                    )
                
                print(f"  ✅ Regenerated: {thumbnail_path}")
                print(f"  👤 Detected {len(faces)} face(s)")
                
                # Remove the tag after successful regeneration
                self.db.connection.execute(
                    "DELETE FROM clip_tags WHERE clip_id = ? AND tag_id = ?",
                    (clip_id, tag_id)
                )
                self.db.connection.commit()
                print(f"  🏷️  Removed '{tag_name}' tag")
                
                success_count += 1
                
            except Exception as e:
                print(f"  ❌ ERROR: {str(e)}")
                import traceback
                traceback.print_exc()
                error_count += 1
        
        # Summary
        print(f"\n{'='*60}")
        print(f"REGENERATION SUMMARY")
        print(f"{'='*60}")
        print(f"✅ Successfully regenerated: {success_count}")
        print(f"❌ Errors: {error_count}")
        print(f"📊 Total processed: {success_count + error_count}")
        print(f"\nAll successfully regenerated clips have had the '{tag_name}' tag removed.")
    
    def close(self):
        """Clean up resources"""
        self.db.close()


def main():
    """Command-line interface for the pipeline"""
    parser = argparse.ArgumentParser(
        description='Face Recognition Video Processing Pipeline'
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
        '--action',
        choices=['full', 'sync', 'process', 'build-profiles', 'match', 'stats', 'regenerate', 'rethumb'],
        default='full',
        help='Action to perform'
    )
    
    parser.add_argument(
        '--tag',
        default='ReThumb',
        help='Tag name to filter clips for rethumb action (default: ReThumb)'
    )
    
    args = parser.parse_args()
    
    # Initialize pipeline
    pipeline = ProcessingPipeline(
        known_dir=args.known_dir,
        unknown_dir=args.unknown_dir,
        db_path=args.db
    )
    
    try:
        if args.action == 'full':
            pipeline.run_full_pipeline()
        elif args.action == 'sync':
            pipeline.sync.sync_all(auto_update_moves=True)
        elif args.action == 'process':
            pipeline.process_new_files()
        elif args.action == 'build-profiles':
            pipeline.build_known_profiles()
        elif args.action == 'match':
            pipeline.match_unknown_clips()
        elif args.action == 'regenerate':
            pipeline.regenerate_missing_assets()
        elif args.action == 'rethumb':
            pipeline.regenerate_tagged_thumbnails(tag_name=args.tag)
        elif args.action == 'stats':
            stats = pipeline.matcher.get_match_statistics()
            print("\nStatistics:")
            print(f"  Total clips: {stats['total_clips']}")
            print(f"  Known: {stats['known_clips']}")
            print(f"  Unknown: {stats['unknown_clips']}")
            print(f"  Matched unknown: {stats['matched_unknown']}")
            print(f"  Individuals: {stats['total_individuals']}")
    
    finally:
        pipeline.close()


if __name__ == "__main__":
    main()