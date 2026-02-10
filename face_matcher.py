"""
Face Matcher for Face Recognition Project
Handles face profile creation, consolidation, and matching against known individuals
"""

import face_recognition
import numpy as np
from typing import List, Dict, Tuple, Optional
from db_manager import DatabaseManager


class FaceMatcher:
    """Match faces against known individual profiles"""
    
    def __init__(self, db_manager: DatabaseManager, match_threshold: float = 0.6):
        """
        Initialize face matcher
        
        Args:
            db_manager: Database manager instance
            match_threshold: Distance threshold for face matching (lower = stricter)
                           Default 0.6 is standard, use 0.5 for stricter matching
        """
        self.db = db_manager
        self.match_threshold = match_threshold
        
        # Cache for individual consolidated profiles
        # Structure: {individual_id: average_encoding}
        self.individual_profiles = {}
    
    def build_individual_profiles(self):
        """
        Build consolidated face profiles for all known individuals
        Uses average of all face encodings for each person
        """
        print("Building consolidated profiles for known individuals...")
        
        individuals = self.db.get_all_individuals()
        
        for individual in individuals:
            individual_id = individual['individual_id']
            name = individual['name']
            
            # Get all face profiles for this individual
            face_profiles = self.db.get_face_profiles_by_individual(individual_id)
            
            if not face_profiles:
                print(f"  No face profiles found for {name}")
                continue
            
            # Extract encodings
            encodings = [profile['face_encoding'] for profile in face_profiles]
            
            # Calculate average encoding
            avg_encoding = np.mean(encodings, axis=0)
            
            # Store in cache
            self.individual_profiles[individual_id] = avg_encoding
            
            print(f"  Built profile for {name} from {len(encodings)} faces")
        
        print(f"Completed: {len(self.individual_profiles)} individual profiles built")
    
    def consolidate_known_folder_profiles(self, folder_person: str) -> Optional[int]:
        """
        Create consolidated profile for a person based on their known folder clips
        
        Args:
            folder_person: Name of the person (from folder name)
        
        Returns:
            individual_id of the created/updated individual
        """
        # Get or create individual record
        individual = self.db.get_individual_by_name(folder_person)
        if not individual:
            individual_id = self.db.add_individual(folder_person)
            print(f"Created new individual: {folder_person} (ID: {individual_id})")
        else:
            individual_id = individual['individual_id']
            print(f"Updating profile for: {folder_person} (ID: {individual_id})")
        
        # Get all clips for this person in their known folder
        clips = self.db.get_all_clips(clip_type='known')
        person_clips = [c for c in clips if c['folder_person'] == folder_person]
        
        if not person_clips:
            print(f"  No clips found for {folder_person}")
            return individual_id
        
        # Collect all face profiles from these clips
        all_encodings = []
        
        for clip in person_clips:
            face_profiles = self.db.get_face_profiles_by_clip(clip['clip_id'])
            
            for profile in face_profiles:
                all_encodings.append(profile['face_encoding'])
                
                # Update profile to link to this individual if not already linked
                if profile['individual_id'] != individual_id:
                    self.db.update_face_individual(
                        profile['profile_id'], 
                        individual_id, 
                        match_confidence=1.0  # Known from folder structure
                    )
                
                # Create clip-individual link
                self.db.link_clip_to_individual(
                    clip['clip_id'], 
                    individual_id, 
                    confidence=1.0
                )
        
        if all_encodings:
            # Calculate and cache average encoding
            avg_encoding = np.mean(all_encodings, axis=0)
            self.individual_profiles[individual_id] = avg_encoding
            
            print(f"  Consolidated {len(all_encodings)} faces for {folder_person}")
        
        return individual_id
    
    def match_face_to_individuals(self, face_encoding: np.ndarray) -> List[Tuple[int, float]]:
        """
        Match a face encoding against all known individual profiles
        
        Args:
            face_encoding: 128-d face encoding to match
        
        Returns:
            List of tuples (individual_id, distance) for matches below threshold,
            sorted by distance (best match first)
        """
        if not self.individual_profiles:
            self.build_individual_profiles()
        
        matches = []
        
        for individual_id, profile_encoding in self.individual_profiles.items():
            # Calculate face distance (lower = more similar)
            distance = face_recognition.face_distance([profile_encoding], face_encoding)[0]
            
            # If below threshold, it's a match
            if distance <= self.match_threshold:
                matches.append((individual_id, float(distance)))
        
        # Sort by distance (best matches first)
        matches.sort(key=lambda x: x[1])
        
        return matches
    
    def process_unknown_clip(self, clip_id: int, face_encodings: List[np.ndarray]) -> Dict[int, Tuple[int, float]]:
        """
        Process an unknown clip's faces and match against known individuals
        Skips matches that are in known_error_matches table
        
        Args:
            clip_id: ID of the clip being processed
            face_encodings: List of face encodings from the clip
        
        Returns:
            Dictionary mapping face index to (individual_id, confidence) if matched
        """
        # Get known error matches for this clip
        cursor = self.db.connection.cursor()
        cursor.execute("""
            SELECT individual_id FROM known_error_matches WHERE clip_id = ?
        """, (clip_id,))
        error_matches = set(row[0] for row in cursor.fetchall())
        
        results = {}
        matched_individuals = set()
        
        for idx, encoding in enumerate(face_encodings):
            matches = self.match_face_to_individuals(encoding)
            
            if matches:
                # Take best match that's not in error list
                for individual_id, distance in matches:
                    # Skip if this is a known error match
                    if individual_id in error_matches:
                        print(f"  Face {idx} skipping known error match to individual {individual_id}")
                        continue
                    
                    # Convert distance to confidence (inverse relationship)
                    # Distance of 0.0 = 100% confidence, 0.6 = 0% confidence
                    confidence = 1.0 - (distance / self.match_threshold)
                    
                    results[idx] = (individual_id, confidence)
                    matched_individuals.add(individual_id)
                    
                    print(f"  Face {idx} matched to individual {individual_id} "
                          f"(confidence: {confidence:.2%})")
                    break  # Use first non-error match
        
        # Create clip-individual links for all matched individuals
        for individual_id in matched_individuals:
            # Calculate average confidence for this individual across all matched faces
            individual_confidences = [
                conf for face_idx, (ind_id, conf) in results.items() 
                if ind_id == individual_id
            ]
            avg_confidence = np.mean(individual_confidences)
            
            self.db.link_clip_to_individual(clip_id, individual_id, avg_confidence)
        
        return results
    
    def find_similar_unknown_faces(self, min_matches: int = 3, 
                                  similarity_threshold: float = 0.5) -> List[List[int]]:
        """
        Find clusters of similar faces in unknown clips (potential new individuals)
        
        Args:
            min_matches: Minimum number of matching faces to form a cluster
            similarity_threshold: Face distance threshold for similarity
        
        Returns:
            List of clusters, each cluster is a list of profile_ids
        """
        # Get all face profiles from unknown clips
        unknown_clips = self.db.get_all_clips(clip_type='unknown')
        
        all_profiles = []
        for clip in unknown_clips:
            profiles = self.db.get_face_profiles_by_clip(clip['clip_id'])
            # Only include faces not matched to known individuals
            all_profiles.extend([p for p in profiles if p['individual_id'] is None])
        
        if len(all_profiles) < min_matches:
            return []
        
        # Simple clustering: compare each face to all others
        clusters = []
        used_profiles = set()
        
        for i, profile_a in enumerate(all_profiles):
            if profile_a['profile_id'] in used_profiles:
                continue
            
            cluster = [profile_a['profile_id']]
            
            for j, profile_b in enumerate(all_profiles[i+1:], start=i+1):
                if profile_b['profile_id'] in used_profiles:
                    continue
                
                # Calculate distance
                distance = face_recognition.face_distance(
                    [profile_a['face_encoding']], 
                    profile_b['face_encoding']
                )[0]
                
                if distance <= similarity_threshold:
                    cluster.append(profile_b['profile_id'])
                    used_profiles.add(profile_b['profile_id'])
            
            # Only keep clusters with minimum matches
            if len(cluster) >= min_matches:
                clusters.append(cluster)
                for profile_id in cluster:
                    used_profiles.add(profile_id)
        
        return clusters
    
    def get_match_statistics(self) -> Dict:
        """
        Get statistics about matched and unmatched clips
        
        Returns:
            Dictionary with match statistics
        """
        all_clips = self.db.get_all_clips()
        
        stats = {
            'total_clips': len(all_clips),
            'known_clips': len([c for c in all_clips if c['clip_type'] == 'known']),
            'unknown_clips': len([c for c in all_clips if c['clip_type'] == 'unknown']),
            'matched_unknown': 0,
            'unmatched_unknown': 0,
            'total_individuals': len(self.db.get_all_individuals()),
            'clips_per_individual': {}
        }
        
        # Count matched unknown clips
        unknown_clips = [c for c in all_clips if c['clip_type'] == 'unknown']
        for clip in unknown_clips:
            individuals = self.db.get_individuals_in_clip(clip['clip_id'])
            if individuals:
                stats['matched_unknown'] += 1
            else:
                stats['unmatched_unknown'] += 1
        
        # Count clips per individual
        for individual in self.db.get_all_individuals():
            clips = self.db.get_clips_for_individual(individual['individual_id'])
            stats['clips_per_individual'][individual['name']] = len(clips)
        
        return stats


# Example usage
if __name__ == "__main__":
    # Initialize
    with DatabaseManager("face_recognition.db") as db:
        matcher = FaceMatcher(db, match_threshold=0.6)
        
        # Build consolidated profiles for all known individuals
        matcher.build_individual_profiles()
        
        # Get statistics
        stats = matcher.get_match_statistics()
        print("\nMatch Statistics:")
        print(f"  Total clips: {stats['total_clips']}")
        print(f"  Known clips: {stats['known_clips']}")
        print(f"  Unknown clips: {stats['unknown_clips']}")
        print(f"  Matched unknown: {stats['matched_unknown']}")
        print(f"  Unmatched unknown: {stats['unmatched_unknown']}")
        print(f"\nIndividuals: {stats['total_individuals']}")
        for name, count in stats['clips_per_individual'].items():
            print(f"  {name}: {count} clips")