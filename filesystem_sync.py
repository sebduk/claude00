"""
File System Synchronization for Face Recognition Project
Scans directories and syncs with database, handles moved files
"""

from pathlib import Path
from typing import List, Dict, Tuple
from db_manager import DatabaseManager


class FileSystemSync:
    """Synchronize file system with database"""
    
    def __init__(self, db_manager: DatabaseManager, known_dir: str, unknown_dir: str):
        """
        Initialize file system sync
        
        Args:
            db_manager: Database manager instance
            known_dir: Root directory for known clips (organized by person folders)
            unknown_dir: Root directory for unknown clips (organized by date folders)
        """
        self.db = db_manager
        self.known_dir = Path(known_dir)
        self.unknown_dir = Path(unknown_dir)
        
        # Ensure directories exist
        self.known_dir.mkdir(parents=True, exist_ok=True)
        self.unknown_dir.mkdir(parents=True, exist_ok=True)
    
    def scan_filesystem(self, video_extensions: List[str] = None) -> Dict[str, List[Path]]:
        """
        Scan both known and unknown directories for video files
        
        Args:
            video_extensions: List of video extensions to search for
                            Default: ['.mp4', '.avi', '.mov', '.mkv']
        
        Returns:
            Dictionary with 'known' and 'unknown' keys, each containing list of Paths
        """
        if video_extensions is None:
            video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.MP4', '.AVI', '.MOV']
        
        found_files = {
            'known': [],
            'unknown': []
        }
        
        # Scan known directory
        print(f"Scanning known directory: {self.known_dir}")
        for ext in video_extensions:
            found_files['known'].extend(self.known_dir.rglob(f'*{ext}'))
        
        # Scan unknown directory
        print(f"Scanning unknown directory: {self.unknown_dir}")
        for ext in video_extensions:
            found_files['unknown'].extend(self.unknown_dir.rglob(f'*{ext}'))
        
        print(f"Found {len(found_files['known'])} known clips")
        print(f"Found {len(found_files['unknown'])} unknown clips")
        
        return found_files
    
    def get_relative_path(self, absolute_path: Path, clip_type: str) -> str:
        """
        Convert absolute path to relative path from appropriate root
        
        Args:
            absolute_path: Absolute path to file
            clip_type: 'known' or 'unknown'
        
        Returns:
            Relative path string
        """
        root = self.known_dir if clip_type == 'known' else self.unknown_dir
        return str(absolute_path.relative_to(root))
    
    def extract_person_from_path(self, path: Path, clip_type: str) -> str:
        """
        Extract person name from file path (for known clips)
        
        Args:
            path: Path to video file
            clip_type: 'known' or 'unknown'
        
        Returns:
            Person name (immediate parent folder) or None
        """
        if clip_type != 'known':
            return None
        
        # Get relative path from known_dir
        try:
            rel_path = path.relative_to(self.known_dir)
            # First component is the person's folder name
            return rel_path.parts[0] if len(rel_path.parts) > 1 else None
        except ValueError:
            return None
    
    def find_new_files(self) -> Tuple[List[Path], List[Path]]:
        """
        Find video files in filesystem that are not in database
        
        Returns:
            Tuple of (new_known_files, new_unknown_files)
        """
        # Get all files from filesystem
        fs_files = self.scan_filesystem()
        
        # Get all clips from database
        db_clips = self.db.get_all_clips()
        db_paths = {clip['filepath'] for clip in db_clips}
        
        new_known = []
        new_unknown = []
        
        # Check known files
        for file_path in fs_files['known']:
            rel_path = self.get_relative_path(file_path, 'known')
            if rel_path not in db_paths:
                new_known.append(file_path)
        
        # Check unknown files
        for file_path in fs_files['unknown']:
            rel_path = self.get_relative_path(file_path, 'unknown')
            if rel_path not in db_paths:
                new_unknown.append(file_path)
        
        print(f"\nFound {len(new_known)} new known files")
        print(f"Found {len(new_unknown)} new unknown files")
        
        return new_known, new_unknown
    
    def find_moved_files(self) -> List[Dict]:
        """
        Detect files that have been moved in the filesystem
        Matches by filename and filesize
        
        Returns:
            List of dictionaries with old and new path information
        """
        # Get all files from filesystem
        fs_files = self.scan_filesystem()
        
        # Create lookup by filename and size
        fs_lookup = {}
        for clip_type in ['known', 'unknown']:
            for file_path in fs_files[clip_type]:
                stat = file_path.stat()
                key = (file_path.name, stat.st_size)
                fs_lookup[key] = {
                    'path': file_path,
                    'clip_type': clip_type,
                    'person': self.extract_person_from_path(file_path, clip_type)
                }
        
        # Find clips in database that don't exist at their recorded path
        db_clips = self.db.get_all_clips()
        moved_files = []
        
        for clip in db_clips:
            # Determine full path based on clip type
            root = self.known_dir if clip['clip_type'] == 'known' else self.unknown_dir
            old_full_path = root / clip['filepath']
            
            # If file doesn't exist at recorded location
            if not old_full_path.exists():
                # Try to find it by filename and size
                key = (clip['filename'], clip['filesize'])
                
                if key in fs_lookup:
                    new_info = fs_lookup[key]
                    new_rel_path = self.get_relative_path(new_info['path'], new_info['clip_type'])
                    
                    moved_files.append({
                        'clip_id': clip['clip_id'],
                        'old_path': clip['filepath'],
                        'old_type': clip['clip_type'],
                        'old_person': clip['folder_person'],
                        'new_path': new_rel_path,
                        'new_type': new_info['clip_type'],
                        'new_person': new_info['person']
                    })
        
        print(f"\nDetected {len(moved_files)} moved files")
        
        return moved_files
    
    def update_moved_files(self, moved_files: List[Dict] = None):
        """
        Update database with new paths for moved files
        
        Args:
            moved_files: List of moved file info (from find_moved_files)
                        If None, will detect and update automatically
        """
        if moved_files is None:
            moved_files = self.find_moved_files()
        
        if not moved_files:
            print("No moved files to update")
            return
        
        print(f"\nUpdating {len(moved_files)} moved files in database...")
        
        for move_info in moved_files:
            print(f"  {move_info['old_path']} -> {move_info['new_path']}")
            
            # Update database
            self.db.update_clip_paths(
                old_filepath=move_info['old_path'],
                new_filepath=move_info['new_path'],
                new_clip_type=move_info['new_type'],
                new_folder_person=move_info['new_person']
            )
        
        print("Database updated successfully")
    
    def find_orphaned_clips(self) -> List[Dict]:
        """
        Find clips in database where the file no longer exists anywhere
        
        Returns:
            List of clip dictionaries for orphaned files
        """
        orphaned = self.db.get_orphaned_clips(str(self.known_dir), str(self.unknown_dir))
        
        # Double-check by looking for them by name/size
        moved_files = self.find_moved_files()
        moved_clip_ids = {m['clip_id'] for m in moved_files}
        
        # True orphans are those not in moved files
        true_orphans = [
            clip for clip in orphaned 
            if clip['clip_id'] not in moved_clip_ids
        ]
        
        print(f"\nFound {len(true_orphans)} truly orphaned clips (files deleted)")
        
        return true_orphans
    
    def cleanup_orphaned_clips(self, confirm: bool = True) -> int:
        """
        Remove orphaned clips from database
        
        Args:
            confirm: If True, ask for confirmation before deleting each clip
        
        Returns:
            Number of clips deleted
        """
        orphaned = self.find_orphaned_clips()
        
        if not orphaned:
            print("No orphaned clips to clean up")
            return 0
        
        deleted_count = 0
        
        for clip in orphaned:
            print(f"\nOrphaned: {clip['filepath']}")
            
            if confirm:
                response = input("  Delete from database? (y/n): ").lower()
                if response != 'y':
                    continue
            
            self.db.delete_clip(clip['clip_id'])
            deleted_count += 1
            print(f"  Deleted clip_id {clip['clip_id']}")
        
        print(f"\nCleaned up {deleted_count} orphaned clips")
        return deleted_count
    
    def sync_all(self, auto_update_moves: bool = True, auto_cleanup_orphans: bool = False):
        """
        Perform complete sync: detect new files, moved files, and orphaned clips
        
        Args:
            auto_update_moves: Automatically update moved files without confirmation
            auto_cleanup_orphans: Automatically cleanup orphaned clips without confirmation
        
        Returns:
            Dictionary with sync results
        """
        print("="*60)
        print("STARTING FILE SYSTEM SYNC")
        print("="*60)
        
        results = {
            'new_files': {'known': 0, 'unknown': 0},
            'moved_files': 0,
            'orphaned_clips': 0
        }
        
        # Find new files
        new_known, new_unknown = self.find_new_files()
        results['new_files']['known'] = len(new_known)
        results['new_files']['unknown'] = len(new_unknown)
        
        # Update moved files
        if auto_update_moves:
            moved = self.find_moved_files()
            self.update_moved_files(moved)
            results['moved_files'] = len(moved)
        
        # Cleanup orphaned clips
        if auto_cleanup_orphans:
            results['orphaned_clips'] = self.cleanup_orphaned_clips(confirm=False)
        else:
            orphaned = self.find_orphaned_clips()
            results['orphaned_clips'] = len(orphaned)
        
        print("\n" + "="*60)
        print("SYNC COMPLETE")
        print("="*60)
        print(f"New known files: {results['new_files']['known']}")
        print(f"New unknown files: {results['new_files']['unknown']}")
        print(f"Moved files: {results['moved_files']}")
        print(f"Orphaned clips: {results['orphaned_clips']}")
        
        return results


# Example usage
if __name__ == "__main__":
    # Initialize
    with DatabaseManager("face_recognition.db") as db:
        sync = FileSystemSync(
            db_manager=db,
            known_dir="videos/known",
            unknown_dir="videos/unknown"
        )
        
        # Perform full sync
        results = sync.sync_all(
            auto_update_moves=True,
            auto_cleanup_orphans=False  # Be careful with auto-cleanup
        )
        
        # Find new files that need processing
        new_known, new_unknown = sync.find_new_files()
        
        if new_known or new_unknown:
            print("\nNew files found that need to be added to database:")
            print("Run the processing pipeline to add them.")
