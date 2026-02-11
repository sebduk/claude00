"""
Database Manager for Face Recognition Project
Handles all SQLite database operations for clips, individuals, and face profiles
"""

import sqlite3
import pickle
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import math


class DatabaseManager:
    """Manages SQLite database operations for face recognition project"""
    
    def __init__(self, db_path: str = "face_recognition.db"):
        """
        Initialize database connection
        
        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = db_path
        self.connection = None
        self._connect()
        self._initialize_schema()
    
    def _connect(self):
        """Establish database connection with row factory for dict-like access"""
        self.connection = sqlite3.connect(self.db_path)
        self.connection.row_factory = sqlite3.Row  # Access columns by name
    
    def _initialize_schema(self):
        """Create tables if they don't exist (run schema.sql)"""
        schema_file = Path(__file__).parent / "database_schema_v2.sql"
        if schema_file.exists():
            with open(schema_file, 'r') as f:
                self.connection.executescript(f.read())
            self.connection.commit()
    
    def close(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
    
    # ==================== CLIP OPERATIONS ====================
    
    def add_clip(self, filename: str, filepath: str, filesize: int, 
                 file_date: str, width: int, height: int, 
                 duration: float, duration_text: str, clip_type: str, 
                 folder_person: str = None) -> int:
        """
        Add a new video clip to the database
        
        Args:
            filename: Name of the video file
            filepath: Full relative path to the file
            filesize: File size in bytes
            file_date: File modification date (ISO 8601 format)
            width: Video width in pixels
            height: Video height in pixels
            duration: Video duration in seconds
            duration_text: Duration in HH:MM:SS format
            clip_type: 'known' or 'unknown'
            folder_person: Person name from folder structure (for known clips)
        
        Returns:
            clip_id of the newly inserted clip
        """
        diagonal = math.sqrt(width**2 + height**2)
        
        cursor = self.connection.cursor()
        cursor.execute("""
            INSERT INTO clips (filename, filepath, filesize, file_date, width, height, 
                             diagonal_size, duration, duration_text, clip_type, folder_person)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (filename, filepath, filesize, file_date, width, height, 
              diagonal, duration, duration_text, clip_type, folder_person))
        
        self.connection.commit()
        return cursor.lastrowid
    
    def update_clip_paths(self, old_filepath: str, new_filepath: str, 
                         new_clip_type: str = None, new_folder_person: str = None):
        """
        Update clip paths when files are moved in filesystem
        
        Args:
            old_filepath: Original file path
            new_filepath: New file path after move
            new_clip_type: Updated clip type if changed
            new_folder_person: Updated person folder if changed
        """
        cursor = self.connection.cursor()
        
        # Check if new filepath already exists in database
        cursor.execute("SELECT clip_id, filename FROM clips WHERE filepath = ?", (new_filepath,))
        existing = cursor.fetchone()
        
        if existing:
            # Conflict: new path already exists
            # Strategy: The physical file wins - delete the old database entry that's been replaced
            print(f"  ⚠️  Conflict: {new_filepath} already exists in DB (clip_id: {existing[0]})")
            print(f"     Removing old database entry (file no longer exists)")
            cursor.execute("DELETE FROM clips WHERE filepath = ?", (new_filepath,))
            self.connection.commit()
        
        # Now safe to update
        if new_clip_type and new_folder_person is not None:
            cursor.execute("""
                UPDATE clips 
                SET filepath = ?, clip_type = ?, folder_person = ?, 
                    last_updated = CURRENT_TIMESTAMP
                WHERE filepath = ?
            """, (new_filepath, new_clip_type, new_folder_person, old_filepath))
        else:
            cursor.execute("""
                UPDATE clips 
                SET filepath = ?, last_updated = CURRENT_TIMESTAMP
                WHERE filepath = ?
            """, (new_filepath, old_filepath))
        
        self.connection.commit()
        
        if cursor.rowcount == 0:
            print(f"  ⚠️  Warning: No clip found with old path: {old_filepath}")
    
    def update_clip_thumbnail(self, clip_id: int, thumbnail_path: str):
        """Update thumbnail path for a clip"""
        cursor = self.connection.cursor()
        cursor.execute("""
            UPDATE clips SET thumbnail_path = ?, last_updated = CURRENT_TIMESTAMP
            WHERE clip_id = ?
        """, (thumbnail_path, clip_id))
        self.connection.commit()
    
    def update_clip_mosaic(self, clip_id: int, mosaic_path: str):
        """Update mosaic path for a clip"""
        cursor = self.connection.cursor()
        cursor.execute("""
            UPDATE clips SET mosaic_path = ?, last_updated = CURRENT_TIMESTAMP
            WHERE clip_id = ?
        """, (mosaic_path, clip_id))
        self.connection.commit()
    
    def get_clip_by_path(self, filepath: str) -> Optional[Dict]:
        """Get clip information by filepath"""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM clips WHERE filepath = ?", (filepath,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_all_clips(self, clip_type: str = None) -> List[Dict]:
        """
        Get all clips, optionally filtered by type
        
        Args:
            clip_type: Filter by 'known' or 'unknown', None for all
        
        Returns:
            List of clip dictionaries
        """
        cursor = self.connection.cursor()
        if clip_type:
            cursor.execute("SELECT * FROM clips WHERE clip_type = ?", (clip_type,))
        else:
            cursor.execute("SELECT * FROM clips")
        
        return [dict(row) for row in cursor.fetchall()]
    
    # ==================== INDIVIDUAL OPERATIONS ====================
    
    def add_individual(self, name: str, notes: str = None) -> int:
        """
        Add a new known individual
        
        Args:
            name: Person's name (must be unique)
            notes: Optional notes
        
        Returns:
            individual_id of the newly inserted individual
        """
        cursor = self.connection.cursor()
        cursor.execute("""
            INSERT OR IGNORE INTO individuals (name, notes, profile_created)
            VALUES (?, ?, CURRENT_TIMESTAMP)
        """, (name, notes))
        
        self.connection.commit()
        
        # Get the individual_id (either newly inserted or existing)
        cursor.execute("SELECT individual_id FROM individuals WHERE name = ?", (name,))
        return cursor.fetchone()[0]
    
    def get_individual_by_name(self, name: str) -> Optional[Dict]:
        """Get individual by name"""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM individuals WHERE name = ?", (name,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def get_all_individuals(self) -> List[Dict]:
        """Get all known individuals"""
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM individuals ORDER BY name")
        return [dict(row) for row in cursor.fetchall()]
    
    def set_default_thumbnail(self, individual_id: int, clip_id: int):
        """Set the default thumbnail clip for an individual"""
        cursor = self.connection.cursor()
        cursor.execute("""
            UPDATE individuals 
            SET default_thumbnail_clip_id = ?
            WHERE individual_id = ?
        """, (clip_id, individual_id))
        self.connection.commit()
    
    def get_default_thumbnail(self, individual_id: int) -> Optional[Dict]:
        """Get the default thumbnail clip for an individual"""
        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT c.* FROM clips c
            JOIN individuals i ON c.clip_id = i.default_thumbnail_clip_id
            WHERE i.individual_id = ?
        """, (individual_id,))
        row = cursor.fetchone()
        return dict(row) if row else None
    
    # ==================== FACE PROFILE OPERATIONS ====================
    
    def add_face_profile(self, clip_id: int, face_encoding: list, 
                        face_location: Dict, confidence: float,
                        is_primary: bool = False, individual_id: int = None,
                        match_confidence: float = None) -> int:
        """
        Add a face profile (encoding) for a detected face
        
        Args:
            clip_id: ID of the clip containing this face
            face_encoding: 128-d numpy array from face_recognition library
            face_location: Dict with keys: top, right, bottom, left
            confidence: Detection confidence score
            is_primary: Whether this is the primary face for thumbnail
            individual_id: ID of matched individual (if known)
            match_confidence: Confidence of the match to individual
        
        Returns:
            profile_id of the newly inserted face profile
        """
        # Serialize face encoding using pickle
        encoding_blob = pickle.dumps(face_encoding)
        location_json = json.dumps(face_location)
        
        cursor = self.connection.cursor()
        cursor.execute("""
            INSERT INTO face_profiles 
            (clip_id, face_encoding, face_location, confidence, is_primary, 
             individual_id, match_confidence)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (clip_id, encoding_blob, location_json, confidence, is_primary,
              individual_id, match_confidence))
        
        self.connection.commit()
        return cursor.lastrowid
    
    def get_face_profiles_by_clip(self, clip_id: int) -> List[Dict]:
        """Get all face profiles for a specific clip"""
        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT * FROM face_profiles WHERE clip_id = ?
        """, (clip_id,))
        
        profiles = []
        for row in cursor.fetchall():
            profile = dict(row)
            # Deserialize face encoding
            profile['face_encoding'] = pickle.loads(profile['face_encoding'])
            profile['face_location'] = json.loads(profile['face_location'])
            profiles.append(profile)
        
        return profiles
    
    def get_face_profiles_by_individual(self, individual_id: int) -> List[Dict]:
        """Get all face profiles for a specific individual"""
        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT * FROM face_profiles WHERE individual_id = ?
        """, (individual_id,))
        
        profiles = []
        for row in cursor.fetchall():
            profile = dict(row)
            profile['face_encoding'] = pickle.loads(profile['face_encoding'])
            profile['face_location'] = json.loads(profile['face_location'])
            profiles.append(profile)
        
        return profiles
    
    def update_face_individual(self, profile_id: int, individual_id: int, 
                              match_confidence: float):
        """Update the individual assignment for a face profile"""
        cursor = self.connection.cursor()
        cursor.execute("""
            UPDATE face_profiles 
            SET individual_id = ?, match_confidence = ?
            WHERE profile_id = ?
        """, (individual_id, match_confidence, profile_id))
        self.connection.commit()
    
    # ==================== CLIP-INDIVIDUAL RELATIONSHIPS ====================
    
    def link_clip_to_individual(self, clip_id: int, individual_id: int, 
                               confidence: float):
        """Create a link between a clip and an individual"""
        cursor = self.connection.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO clip_individuals (clip_id, individual_id, confidence)
            VALUES (?, ?, ?)
        """, (clip_id, individual_id, confidence))
        self.connection.commit()
    
    def get_individuals_in_clip(self, clip_id: int) -> List[Dict]:
        """Get all individuals that appear in a specific clip"""
        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT i.*, ci.confidence 
            FROM individuals i
            JOIN clip_individuals ci ON i.individual_id = ci.individual_id
            WHERE ci.clip_id = ?
        """, (clip_id,))
        
        return [dict(row) for row in cursor.fetchall()]
    
    def get_clips_for_individual(self, individual_id: int) -> List[Dict]:
        """Get all clips featuring a specific individual"""
        cursor = self.connection.cursor()
        cursor.execute("""
            SELECT c.*, ci.confidence 
            FROM clips c
            JOIN clip_individuals ci ON c.clip_id = ci.clip_id
            WHERE ci.individual_id = ?
        """, (individual_id,))
        
        return [dict(row) for row in cursor.fetchall()]
    
    # ==================== UTILITY FUNCTIONS ====================
    
    def get_orphaned_clips(self, known_dir: str, unknown_dir: str) -> List[Dict]:
        """
        Find clips in database that no longer exist in filesystem
        
        Args:
            known_dir: Root directory for known clips
            unknown_dir: Root directory for unknown clips
        
        Returns:
            List of clip records for missing files
        """
        cursor = self.connection.cursor()
        cursor.execute("SELECT * FROM clips")
        
        orphaned = []
        for row in cursor.fetchall():
            clip = dict(row)
            full_path = Path(known_dir if clip['clip_type'] == 'known' else unknown_dir) / clip['filepath']
            if not full_path.exists():
                orphaned.append(clip)
        
        return orphaned
    
    def delete_clip(self, clip_id: int):
        """Delete a clip and all associated face profiles (cascade)"""
        cursor = self.connection.cursor()
        cursor.execute("DELETE FROM clips WHERE clip_id = ?", (clip_id,))
        self.connection.commit()
    
    def __enter__(self):
        """Context manager entry"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()


# Example usage
if __name__ == "__main__":
    # Initialize database
    with DatabaseManager("face_recognition.db") as db:
        # Add a test individual
        person_id = db.add_individual("John Doe", "Test person")
        print(f"Added individual with ID: {person_id}")
        
        # Add a test clip
        clip_id = db.add_clip(
            filename="test_video.mp4",
            filepath="known/John_Doe/test_video.mp4",
            filesize=1024000,
            file_date="2024-01-15T10:30:00",
            width=1920,
            height=1080,
            duration=30.5,
            duration_text="00:00:30",
            clip_type="known",
            folder_person="John Doe"
        )
        print(f"Added clip with ID: {clip_id}")
        
        # Query all individuals
        individuals = db.get_all_individuals()
        print(f"\nAll individuals: {len(individuals)}")
        for ind in individuals:
            print(f"  - {ind['name']}")