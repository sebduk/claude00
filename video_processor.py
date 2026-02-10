"""
Video Processor for Face Recognition Project
Handles video file processing: face detection, thumbnail generation, mosaic creation
"""

import cv2
import face_recognition
import numpy as np
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from datetime import datetime
from PIL import Image
import math

# Import configuration (with fallback defaults)
try:
    import config
    MAX_FRAMES_TO_CHECK = config.MAX_FRAMES_TO_CHECK
    MIN_FRONTAL_SCORE = config.MIN_FRONTAL_SCORE
    FALLBACK_TO_ANY_FACE = config.FALLBACK_TO_ANY_FACE
    SAMPLE_STRATEGY = config.SAMPLE_STRATEGY
    MIN_FACE_SIZE = config.MIN_FACE_SIZE
    TARGET_FACE_HEIGHT = config.TARGET_FACE_HEIGHT
    FACE_DETECTION_MODEL = config.FACE_DETECTION_MODEL
    FACE_DETECTION_UPSAMPLE = config.FACE_DETECTION_UPSAMPLE
    SCREENSHOT_MAX_DIMENSION = config.SCREENSHOT_MAX_DIMENSION
except (ImportError, AttributeError):
    # Fallback defaults if config not available
    MAX_FRAMES_TO_CHECK = 20
    MIN_FRONTAL_SCORE = 0.6
    FALLBACK_TO_ANY_FACE = True
    SAMPLE_STRATEGY = 'smart'
    MIN_FACE_SIZE = 50
    TARGET_FACE_HEIGHT = 120
    FACE_DETECTION_MODEL = 'hog'
    FACE_DETECTION_UPSAMPLE = 1
    SCREENSHOT_MAX_DIMENSION = 300


class VideoProcessor:
    """Process video files for face detection and thumbnail generation"""
    
    def __init__(self, thumbnail_dir: str = "thumbnails", mosaic_dir: str = "mosaics"):
        """
        Initialize video processor
        
        Args:
            thumbnail_dir: Directory to save thumbnail images
            mosaic_dir: Directory to save mosaic images
        """
        self.thumbnail_dir = Path(thumbnail_dir)
        self.mosaic_dir = Path(mosaic_dir)
        
        # Create output directories if they don't exist
        self.thumbnail_dir.mkdir(parents=True, exist_ok=True)
        self.mosaic_dir.mkdir(parents=True, exist_ok=True)
        
        # Thumbnail dimensions (portrait orientation)
        self.THUMB_WIDTH = 200
        self.THUMB_HEIGHT = 300
        
        # Screenshot max dimension (maintain aspect ratio)
        self.SCREENSHOT_MAX_DIM = SCREENSHOT_MAX_DIMENSION
        
        # Load configuration from config.py (or use defaults)
        self.TARGET_FACE_HEIGHT = TARGET_FACE_HEIGHT
        self.MAX_FRAMES_TO_CHECK = MAX_FRAMES_TO_CHECK
        self.MIN_FRONTAL_SCORE = MIN_FRONTAL_SCORE
        self.FALLBACK_TO_ANY_FACE = FALLBACK_TO_ANY_FACE
        self.SAMPLE_STRATEGY = SAMPLE_STRATEGY
        self.MIN_FACE_SIZE = MIN_FACE_SIZE
        self.FACE_DETECTION_MODEL = FACE_DETECTION_MODEL
        self.FACE_DETECTION_UPSAMPLE = FACE_DETECTION_UPSAMPLE
    
    def get_video_metadata(self, video_path: str) -> Dict:
        """
        Extract metadata from video file
        
        Args:
            video_path: Path to video file
        
        Returns:
            Dictionary with filename, filesize, file_date, width, height, duration, duration_text
        
        Raises:
            ValueError: If video file is corrupted or unreadable
        """
        path = Path(video_path)
        
        # File system metadata
        stat = path.stat()
        filesize = stat.st_size
        file_date = datetime.fromtimestamp(stat.st_mtime).isoformat()
        
        # Video metadata using OpenCV
        cap = cv2.VideoCapture(str(path))
        
        # Check if video opened successfully
        if not cap.isOpened():
            raise ValueError(f"Cannot open video file - may be corrupted or incomplete")
        
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        # Validate metadata
        if width == 0 or height == 0 or fps == 0:
            cap.release()
            raise ValueError(f"Invalid video metadata - width: {width}, height: {height}, fps: {fps}")
        
        # Calculate duration (handle edge case where fps might be 0)
        duration = frame_count / fps if fps > 0 else 0
        
        # Format duration as HH:MM:SS
        hours = int(duration // 3600)
        minutes = int((duration % 3600) // 60)
        seconds = int(duration % 60)
        duration_text = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        
        cap.release()
        
        return {
            'filename': path.name,
            'filesize': filesize,
            'file_date': file_date,
            'width': width,
            'height': height,
            'duration': duration,
            'duration_text': duration_text
        }
    
    def detect_faces_in_frame(self, frame: np.ndarray) -> List[Dict]:
        """
        Detect faces in a single frame with improved criteria for frontal faces
        
        Args:
            frame: OpenCV frame (BGR format)
        
        Returns:
            List of face dictionaries with encoding, location, and score
        """
        # Convert BGR to RGB for face_recognition library
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Detect face locations and encodings
        # Use CNN model for better accuracy (change to 'hog' for speed)
        face_locations = face_recognition.face_locations(
            rgb_frame, 
            model=self.FACE_DETECTION_MODEL,
            number_of_times_to_upsample=self.FACE_DETECTION_UPSAMPLE
        )
        
        # Only process if faces found
        if not face_locations:
            return []
        
        face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)
        face_landmarks = face_recognition.face_landmarks(rgb_frame, face_locations)
        
        faces = []
        frame_height, frame_width = frame.shape[:2]
        
        for location, encoding, landmarks in zip(face_locations, face_encodings, face_landmarks):
            top, right, bottom, left = location
            
            # Calculate face dimensions
            face_width = right - left
            face_height = bottom - top
            face_area = face_width * face_height
            
            # Filter out faces that are too small (likely false positives)
            min_face_size = self.MIN_FACE_SIZE
            if face_width < min_face_size or face_height < min_face_size:
                continue
            
            # Calculate if face is frontal, gaze direction, and profile detection
            frontal_score, gaze_score, is_profile = self._calculate_frontal_score(landmarks, face_width, face_height)
            
            # Center position (faces closer to center score higher)
            center_x = (left + right) / 2
            center_y = (top + bottom) / 2
            
            # Distance from center (normalized)
            center_dist = math.sqrt(
                ((center_x - frame_width/2) / frame_width)**2 + 
                ((center_y - frame_height/2) / frame_height)**2
            )
            
            # Confidence score: frontal + size + position
            # Frontal score is most important (weight 0.5), then size (0.3), then center (0.2)
            size_score = (face_area / (frame_width * frame_height))
            position_score = (1 - center_dist)
            
            confidence = (frontal_score * 0.5) + (size_score * 0.3) + (position_score * 0.2)
            
            faces.append({
                'encoding': encoding,
                'location': {
                    'top': top,
                    'right': right,
                    'bottom': bottom,
                    'left': left
                },
                'confidence': confidence,
                'frontal_score': frontal_score,
                'gaze_score': gaze_score,
                'is_profile': is_profile
            })
        
        return faces
    
    def _calculate_frontal_score(self, landmarks: Dict, face_width: int, face_height: int) -> tuple:
        """
        Calculate how frontal a face is and gaze direction based on facial landmarks
        
        Args:
            landmarks: Dictionary of facial landmarks from face_recognition
            face_width: Width of face bounding box
            face_height: Height of face bounding box
        
        Returns:
            Tuple of (frontal_score, gaze_score, is_profile)
            - frontal_score: 0.0 (profile) to 1.0 (frontal facing)
            - gaze_score: 0.0 (looking away) to 1.0 (looking at camera)
            - is_profile: True if this is a profile view
        """
        # Check if we have the necessary landmarks
        if 'nose_tip' not in landmarks or 'left_eye' not in landmarks or 'right_eye' not in landmarks:
            return 0.5, 0.5, False  # Neutral scores if landmarks incomplete
        
        # Get key landmarks
        nose_tip = landmarks['nose_tip'][2]  # Center of nose tip
        left_eye = landmarks['left_eye']
        right_eye = landmarks['right_eye']
        
        # Calculate eye centers
        left_eye_center = (
            sum(p[0] for p in left_eye) / len(left_eye),
            sum(p[1] for p in left_eye) / len(left_eye)
        )
        right_eye_center = (
            sum(p[0] for p in right_eye) / len(right_eye),
            sum(p[1] for p in right_eye) / len(right_eye)
        )
        
        # Calculate horizontal center between eyes
        eye_center_x = (left_eye_center[0] + right_eye_center[0]) / 2
        
        # === FRONTAL SCORE (face angle) ===
        # Nose should be centered between eyes for frontal face
        nose_offset = abs(nose_tip[0] - eye_center_x)
        nose_centered_score = 1.0 - min(1.0, nose_offset / (face_width * 0.25))
        
        # Check eye symmetry (both eyes should be visible and similar size for frontal)
        eye_distance = abs(right_eye_center[0] - left_eye_center[0])
        expected_eye_distance = face_width * 0.5  # Eyes typically ~50% of face width apart
        symmetry_score = 1.0 - min(1.0, abs(eye_distance - expected_eye_distance) / expected_eye_distance)
        
        # Combined frontal score
        frontal_score = (nose_centered_score * 0.7) + (symmetry_score * 0.3)
        
        # === PROFILE DETECTION ===
        # Profile if frontal score is low and eyes are very asymmetric
        is_profile = frontal_score < 0.4 and symmetry_score < 0.5
        
        # === GAZE SCORE (eye direction) ===
        # Estimate gaze by looking at eye position within face
        # If eyes are centered in their sockets, likely looking at camera
        gaze_score = 0.5  # Default neutral
        
        if 'left_eye' in landmarks and 'right_eye' in landmarks:
            # Calculate eye aspect ratio and position
            # Eyes looking at camera tend to be more open and centered
            left_eye_width = max(p[0] for p in left_eye) - min(p[0] for p in left_eye)
            left_eye_height = max(p[1] for p in left_eye) - min(p[1] for p in left_eye)
            
            right_eye_width = max(p[0] for p in right_eye) - min(p[0] for p in right_eye)
            right_eye_height = max(p[1] for p in right_eye) - min(p[1] for p in right_eye)
            
            # Eyes looking at camera are more open (height closer to width)
            left_openness = min(1.0, left_eye_height / (left_eye_width + 0.1)) if left_eye_width > 0 else 0.5
            right_openness = min(1.0, right_eye_height / (right_eye_width + 0.1)) if right_eye_width > 0 else 0.5
            
            avg_openness = (left_openness + right_openness) / 2
            
            # Eyes looking at camera are typically 0.3-0.5 open (not too wide, not squinting)
            # Score peaks at 0.4 openness
            if 0.3 <= avg_openness <= 0.5:
                openness_score = 1.0
            else:
                openness_score = 1.0 - min(1.0, abs(avg_openness - 0.4) / 0.3)
            
            # Combine with frontal score (can't look at camera if face is turned away)
            gaze_score = (openness_score * 0.6) + (frontal_score * 0.4)
        
        return frontal_score, gaze_score, is_profile
    
    def find_best_face_frame(self, video_path: str) -> Tuple[np.ndarray, List[Dict]]:
        """
        Find the frame with the best frontal face for thumbnail
        Uses intelligent sampling strategy for efficiency
        
        Args:
            video_path: Path to video file
        
        Returns:
            Tuple of (best_frame, faces_in_frame)
        """
        cap = cv2.VideoCapture(str(video_path))
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        best_frame = None
        best_faces = []
        best_score = 0
        best_frontal_score = 0
        
        # Smart sampling: focus on middle portion of video where people are more likely visible
        if self.SAMPLE_STRATEGY == 'smart':
            # Sample middle 60% of video more densely
            # Skip first 20% (often intro/titles) and last 20% (often credits/outro)
            start_frame = int(total_frames * 0.2)
            end_frame = int(total_frames * 0.8)
            
            # Calculate frame positions to check (max MAX_FRAMES_TO_CHECK)
            frames_to_check = min(self.MAX_FRAMES_TO_CHECK, end_frame - start_frame)
            frame_interval = (end_frame - start_frame) // frames_to_check
            
            frame_positions = [start_frame + (i * frame_interval) for i in range(frames_to_check)]
        else:
            # Uniform sampling across entire video
            frame_interval = max(1, total_frames // self.MAX_FRAMES_TO_CHECK)
            frame_positions = list(range(0, total_frames, frame_interval))[:self.MAX_FRAMES_TO_CHECK]
        
        frames_checked = 0
        
        for frame_pos in frame_positions:
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
            ret, frame = cap.read()
            
            if not ret:
                continue
            
            frames_checked += 1
            
            # Detect faces in this frame
            faces = self.detect_faces_in_frame(frame)
            
            if not faces:
                continue
            
            # Find best face in this frame
            for face in faces:
                frontal_score = face.get('frontal_score', 0.5)
                confidence = face['confidence']
                
                # Early exit if we found a great frontal face
                if frontal_score >= 0.85 and confidence > best_score:
                    best_score = confidence
                    best_frontal_score = frontal_score
                    best_frame = frame.copy()
                    best_faces = faces
                    # Found excellent face, no need to check more frames
                    print(f"      Found excellent frontal face (score: {frontal_score:.2f}) at frame {frame_pos}, stopping early")
                    cap.release()
                    return best_frame, best_faces
                
                # Otherwise keep track of best so far
                if confidence > best_score:
                    best_score = confidence
                    best_frontal_score = frontal_score
                    best_frame = frame.copy()
                    best_faces = faces
        
        cap.release()
        
        # Evaluate results
        if best_frame is not None:
            if best_frontal_score >= self.MIN_FRONTAL_SCORE:
                print(f"      Found good frontal face (score: {best_frontal_score:.2f}) after checking {frames_checked} frames")
            else:
                print(f"      Best face found has low frontal score ({best_frontal_score:.2f}), may need manual review")
        else:
            print(f"      No faces detected in {frames_checked} frames checked")
            # Use middle frame as fallback
            cap = cv2.VideoCapture(str(video_path))
            cap.set(cv2.CAP_PROP_POS_FRAMES, total_frames // 2)
            ret, best_frame = cap.read()
            cap.release()
            best_faces = []
        
        return best_frame, best_faces
    
    def create_thumbnail(self, video_path: str, clip_id: int) -> Tuple[str, List[Dict]]:
        """
        Create thumbnail using 6-level hierarchy:
        1. Face only facing camera (frontal_score >= 0.7, gaze_score >= 0.6) - BEST
        2. Face only looking at camera (frontal_score < 0.7, gaze_score >= 0.6)
        3. Face only profile (is_profile = True)
        4. Individual upper body (face detected, low scores)
        5. Individual full body (face detected, very low scores)
        6. Screenshot from center - WORST
        
        Args:
            video_path: Path to video file
            clip_id: Database clip ID for naming
        
        Returns:
            Tuple of (thumbnail_path, all_detected_faces)
        """
        # Find best frame with frontal face
        frame, faces = self.find_best_face_frame(video_path)
        
        if not faces:
            # Level 6: No faces detected - create thumbnail from center of frame
            print(f"      Level 6: No faces detected, using center screenshot")
            thumbnail = self._resize_to_portrait(frame)
        else:
            # Get primary face (highest confidence)
            primary_face = max(faces, key=lambda f: f['confidence'])
            frontal_score = primary_face.get('frontal_score', 0.5)
            gaze_score = primary_face.get('gaze_score', 0.5)
            is_profile = primary_face.get('is_profile', False)
            
            # Determine thumbnail level based on scores
            if frontal_score >= 0.7 and gaze_score >= 0.6:
                # Level 1: Best - Face facing AND looking at camera
                print(f"      Level 1: Face facing camera (frontal={frontal_score:.2f}, gaze={gaze_score:.2f})")
                thumbnail = self._create_normalized_face_thumbnail(frame, primary_face['location'])
            
            elif gaze_score >= 0.6:
                # Level 2: Face looking at camera (even if not perfectly frontal)
                print(f"      Level 2: Face looking at camera (frontal={frontal_score:.2f}, gaze={gaze_score:.2f})")
                thumbnail = self._create_normalized_face_thumbnail(frame, primary_face['location'])
            
            elif is_profile:
                # Level 3: Profile face
                print(f"      Level 3: Profile face detected (frontal={frontal_score:.2f})")
                thumbnail = self._create_profile_face_thumbnail(frame, primary_face['location'])
            
            elif frontal_score >= 0.4 or gaze_score >= 0.4:
                # Level 4: Upper body (partial frontal or partial gaze)
                print(f"      Level 4: Upper body (frontal={frontal_score:.2f}, gaze={gaze_score:.2f})")
                thumbnail = self._create_person_thumbnail(frame, primary_face['location'])
            
            else:
                # Level 5: Full body (very low scores, but face detected)
                print(f"      Level 5: Full body (frontal={frontal_score:.2f}, gaze={gaze_score:.2f})")
                thumbnail = self._create_full_body_thumbnail(frame, primary_face['location'])
            
            # Mark this as the primary face
            primary_face['is_primary'] = True
        
        # Save thumbnail
        thumbnail_filename = f"thumb_{clip_id}.jpg"
        thumbnail_path = self.thumbnail_dir / thumbnail_filename
        
        cv2.imwrite(str(thumbnail_path), thumbnail)
        
        return str(thumbnail_path), faces
    
    def _create_person_thumbnail(self, frame: np.ndarray, face_location: Dict) -> np.ndarray:
        """
        Create thumbnail showing the person (head to waist/shoulders - upper body)
        Used for level 4 in hierarchy
        
        Args:
            frame: Source frame
            face_location: Dictionary with top, right, bottom, left
        
        Returns:
            Portrait thumbnail with person's upper body visible
        """
        top = face_location['top']
        right = face_location['right']
        bottom = face_location['bottom']
        left = face_location['left']
        
        face_height = bottom - top
        face_width = right - left
        
        # Expand significantly to capture person (not just face)
        # Aim for 3-4x face height vertically to get upper body
        crop_height = int(face_height * 3.5)
        crop_width = int(crop_height * (self.THUMB_WIDTH / self.THUMB_HEIGHT))  # Maintain portrait aspect
        
        # Center the crop on upper portion of face (to include body below)
        center_y = top + int(face_height * 0.3)  # 30% down from top of face
        center_x = left + face_width // 2
        
        crop_top = max(0, center_y - int(crop_height * 0.25))  # Face in upper quarter
        crop_bottom = min(frame.shape[0], crop_top + crop_height)
        crop_left = max(0, center_x - crop_width // 2)
        crop_right = min(frame.shape[1], crop_left + crop_width)
        
        # Adjust if we hit boundaries
        if crop_bottom - crop_top < crop_height:
            crop_top = max(0, crop_bottom - crop_height)
        if crop_right - crop_left < crop_width:
            crop_left = max(0, crop_right - crop_width)
        
        # Crop the region
        cropped = frame[crop_top:crop_bottom, crop_left:crop_right]
        
        # Resize to portrait thumbnail
        return self._resize_to_portrait(cropped)
    
    def _create_full_body_thumbnail(self, frame: np.ndarray, face_location: Dict) -> np.ndarray:
        """
        Create thumbnail showing the person's full body
        Used for level 5 in hierarchy
        
        Args:
            frame: Source frame
            face_location: Dictionary with top, right, bottom, left
        
        Returns:
            Portrait thumbnail with person's full body visible
        """
        top = face_location['top']
        right = face_location['right']
        bottom = face_location['bottom']
        left = face_location['left']
        
        face_height = bottom - top
        face_width = right - left
        
        # Expand greatly to capture full body
        # Aim for 6-8x face height vertically to get full body
        crop_height = int(face_height * 7)
        crop_width = int(crop_height * (self.THUMB_WIDTH / self.THUMB_HEIGHT))  # Maintain portrait aspect
        
        # Center the crop on upper portion of face (to include body below)
        center_y = top + int(face_height * 0.2)  # 20% down from top of face
        center_x = left + face_width // 2
        
        crop_top = max(0, center_y - int(crop_height * 0.15))  # Face in upper 15%
        crop_bottom = min(frame.shape[0], crop_top + crop_height)
        crop_left = max(0, center_x - crop_width // 2)
        crop_right = min(frame.shape[1], crop_left + crop_width)
        
        # Adjust if we hit boundaries
        if crop_bottom - crop_top < crop_height:
            crop_top = max(0, crop_bottom - crop_height)
        if crop_right - crop_left < crop_width:
            crop_left = max(0, crop_right - crop_width)
        
        # Crop the region
        cropped = frame[crop_top:crop_bottom, crop_left:crop_right]
        
        # Resize to portrait thumbnail
        return self._resize_to_portrait(cropped)
    
    def _create_profile_face_thumbnail(self, frame: np.ndarray, face_location: Dict) -> np.ndarray:
        """
        Create thumbnail optimized for profile view (face only, side view)
        Used for level 3 in hierarchy
        
        Args:
            frame: Source frame
            face_location: Dictionary with top, right, bottom, left
        
        Returns:
            Portrait thumbnail with profile face
        """
        top = face_location['top']
        right = face_location['right']
        bottom = face_location['bottom']
        left = face_location['left']
        
        face_height = bottom - top
        face_width = right - left
        
        # For profile, include more horizontal space (face extends more to one side)
        # Aim for 2x face height vertically, 2.5x face width horizontally
        crop_height = int(face_height * 2.5)
        crop_width = int(face_width * 3)
        
        # Center the crop on the face
        center_y = top + face_height // 2
        center_x = left + face_width // 2
        
        crop_top = max(0, center_y - crop_height // 2)
        crop_bottom = min(frame.shape[0], center_y + crop_height // 2)
        crop_left = max(0, center_x - crop_width // 2)
        crop_right = min(frame.shape[1], center_x + crop_width // 2)
        
        # Crop the region
        cropped = frame[crop_top:crop_bottom, crop_left:crop_right]
        
        # Resize to portrait thumbnail
        return self._resize_to_portrait(cropped)
    
    def _create_normalized_face_thumbnail(self, frame: np.ndarray, face_location: Dict) -> np.ndarray:
        """
        Create thumbnail with face normalized to target size
        
        Args:
            frame: Source frame
            face_location: Dictionary with top, right, bottom, left
        
        Returns:
            Portrait thumbnail with normalized face size
        """
        top = face_location['top']
        right = face_location['right']
        bottom = face_location['bottom']
        left = face_location['left']
        
        face_height = bottom - top
        face_width = right - left
        
        # Calculate scale factor to normalize face to target height
        scale_factor = self.TARGET_FACE_HEIGHT / face_height
        
        # Expand crop area to include head and shoulders
        # Aim for 2x face height vertically, 1.5x face width horizontally
        crop_height = int(face_height * 2.5)
        crop_width = int(face_width * 1.8)
        
        # Center the crop on the face (slightly above center for headroom)
        center_y = top + face_height // 2 - int(face_height * 0.2)
        center_x = left + face_width // 2
        
        crop_top = max(0, center_y - crop_height // 2)
        crop_bottom = min(frame.shape[0], center_y + crop_height // 2)
        crop_left = max(0, center_x - crop_width // 2)
        crop_right = min(frame.shape[1], center_x + crop_width // 2)
        
        # Crop the region
        cropped = frame[crop_top:crop_bottom, crop_left:crop_right]
        
        # Resize to portrait thumbnail maintaining aspect ratio
        return self._resize_to_portrait(cropped)
    
    def _resize_to_portrait(self, frame: np.ndarray) -> np.ndarray:
        """
        Resize frame to portrait thumbnail (200x300)
        
        Args:
            frame: Source frame
        
        Returns:
            Resized portrait image
        """
        height, width = frame.shape[:2]
        
        # Calculate scaling to fit in portrait box
        scale = min(self.THUMB_WIDTH / width, self.THUMB_HEIGHT / height)
        
        new_width = int(width * scale)
        new_height = int(height * scale)
        
        resized = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)
        
        # Create portrait canvas and center the image
        canvas = np.zeros((self.THUMB_HEIGHT, self.THUMB_WIDTH, 3), dtype=np.uint8)
        
        y_offset = (self.THUMB_HEIGHT - new_height) // 2
        x_offset = (self.THUMB_WIDTH - new_width) // 2
        
        canvas[y_offset:y_offset+new_height, x_offset:x_offset+new_width] = resized
        
        return canvas
    
    def create_mosaic(self, video_path: str, clip_id: int, interval_seconds: int = 30) -> str:
        """
        Create mosaic of screenshots taken at regular intervals
        Screenshots maintain original aspect ratio with longest axis = 300px
        
        Args:
            video_path: Path to video file
            clip_id: Database clip ID for naming
            interval_seconds: Interval between screenshots in seconds
        
        Returns:
            Path to saved mosaic image
        """
        cap = cv2.VideoCapture(str(video_path))
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        video_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        video_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Calculate frame interval
        frame_interval = int(fps * interval_seconds)
        
        screenshots = []
        
        for frame_pos in range(0, total_frames, frame_interval):
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
            ret, frame = cap.read()
            
            if ret:
                # Resize maintaining aspect ratio with longest axis = 300px
                screenshot = self._resize_screenshot(frame, self.SCREENSHOT_MAX_DIM)
                screenshots.append(screenshot)
        
        cap.release()
        
        if not screenshots:
            return None
        
        # Arrange screenshots in a grid
        mosaic = self._create_grid_mosaic(screenshots)
        
        # Save mosaic
        mosaic_filename = f"mosaic_{clip_id}.jpg"
        mosaic_path = self.mosaic_dir / mosaic_filename
        
        cv2.imwrite(str(mosaic_path), mosaic)
        
        return str(mosaic_path)
    
    def _resize_screenshot(self, frame: np.ndarray, max_dimension: int) -> np.ndarray:
        """
        Resize frame maintaining aspect ratio with longest axis = max_dimension
        
        Args:
            frame: Source frame
            max_dimension: Maximum dimension (width or height)
        
        Returns:
            Resized image maintaining aspect ratio
        """
        height, width = frame.shape[:2]
        
        # Determine scaling factor based on longest axis
        if width > height:
            # Landscape or square - scale based on width
            scale = max_dimension / width
        else:
            # Portrait - scale based on height
            scale = max_dimension / height
        
        new_width = int(width * scale)
        new_height = int(height * scale)
        
        resized = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)
        
        return resized
    
    def _create_grid_mosaic(self, screenshots: List[np.ndarray]) -> np.ndarray:
        """
        Arrange screenshots in a grid
        Screenshots may have different dimensions (maintaining aspect ratios)
        
        Args:
            screenshots: List of screenshot images
        
        Returns:
            Combined mosaic image
        """
        num_screenshots = len(screenshots)
        
        if num_screenshots == 0:
            return np.zeros((100, 100, 3), dtype=np.uint8)
        
        # Calculate grid dimensions (roughly square)
        cols = int(math.ceil(math.sqrt(num_screenshots)))
        rows = int(math.ceil(num_screenshots / cols))
        
        # Find maximum dimensions for grid cells
        max_height = max(s.shape[0] for s in screenshots)
        max_width = max(s.shape[1] for s in screenshots)
        
        # Create empty canvas
        mosaic_height = rows * max_height
        mosaic_width = cols * max_width
        mosaic = np.zeros((mosaic_height, mosaic_width, 3), dtype=np.uint8)
        
        # Place screenshots (centered in their cells)
        for idx, screenshot in enumerate(screenshots):
            row = idx // cols
            col = idx % cols
            
            screenshot_height, screenshot_width = screenshot.shape[:2]
            
            # Calculate cell position
            cell_y_start = row * max_height
            cell_x_start = col * max_width
            
            # Center screenshot within cell
            y_offset = (max_height - screenshot_height) // 2
            x_offset = (max_width - screenshot_width) // 2
            
            y_start = cell_y_start + y_offset
            y_end = y_start + screenshot_height
            x_start = cell_x_start + x_offset
            x_end = x_start + screenshot_width
            
            mosaic[y_start:y_end, x_start:x_end] = screenshot
        
        return mosaic


# Example usage
if __name__ == "__main__":
    processor = VideoProcessor()
    
    # Process a video file
    video_path = "test_video.mp4"
    
    # Get metadata
    metadata = processor.get_video_metadata(video_path)
    print(f"Video metadata: {metadata}")
    
    # Create thumbnail (assuming clip_id = 1)
    thumb_path, faces = processor.create_thumbnail(video_path, clip_id=1)
    print(f"Thumbnail saved to: {thumb_path}")
    print(f"Detected {len(faces)} face(s)")
    
    # Create mosaic
    mosaic_path = processor.create_mosaic(video_path, clip_id=1, interval_seconds=30)
    print(f"Mosaic saved to: {mosaic_path}")