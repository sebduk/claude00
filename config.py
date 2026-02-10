"""
Configuration file for Face Recognition Project
Adjust these settings to tune performance and quality
"""

# ====================
# THUMBNAIL GENERATION
# ====================

# Maximum number of frames to check when looking for frontal face
# Lower = faster processing, might miss good faces
# Higher = slower processing, more likely to find good face
# Recommended: 15-25 for balance, 30-40 for quality, 10-15 for speed
MAX_FRAMES_TO_CHECK = 20

# Minimum frontal score to accept a face (0.0 - 1.0)
# Lower = accept more profile faces (more thumbnails succeed but lower quality)
# Higher = require more frontal faces (better quality but more fallbacks)
# Recommended: 0.5-0.6 for balance, 0.7-0.8 for quality, 0.4-0.5 for acceptance
MIN_FRONTAL_SCORE = 0.6

# Whether to fall back to person crop if no good frontal face found
# True = always generate thumbnail (may show profile/side view)
# False = only use good frontal faces (may fail more often)
FALLBACK_TO_ANY_FACE = True

# Sampling strategy for finding best frame
# 'smart' = focus on middle 60% of video (skip intros/credits)
# 'uniform' = sample evenly across entire video
SAMPLE_STRATEGY = 'smart'

# Minimum face size to detect (in pixels per dimension)
# Smaller = detect more distant faces (slower, more false positives)
# Larger = only detect close faces (faster, fewer false positives)
# Recommended: 40-60
MIN_FACE_SIZE = 50

# Target face height in thumbnail (pixels)
# How large the face should appear in the final 200x300 thumbnail
TARGET_FACE_HEIGHT = 120

# ====================
# FACE DETECTION
# ====================

# Face detection model
# 'hog' = faster, less accurate, CPU-friendly
# 'cnn' = slower, more accurate, GPU-friendly
FACE_DETECTION_MODEL = 'hog'

# Number of times to upsample image for face detection
# Higher = detect smaller/more distant faces (slower)
# Lower = only detect larger/closer faces (faster)
# Recommended: 0 for speed, 1 for balance, 2 for quality
FACE_DETECTION_UPSAMPLE = 1

# ====================
# MOSAIC GENERATION
# ====================

# Screenshot interval in seconds
# How often to capture a frame for the mosaic
MOSAIC_INTERVAL_SECONDS = 30

# Maximum screenshot dimension (maintains aspect ratio)
SCREENSHOT_MAX_DIMENSION = 300

# ====================
# FACE MATCHING
# ====================

# Face matching threshold (0.0 - 1.0)
# Lower = stricter matching (fewer false positives)
# Higher = looser matching (more matches but more false positives)
# Recommended: 0.5-0.55 for strict, 0.6 for balanced, 0.65-0.7 for loose
FACE_MATCH_THRESHOLD = 0.6

# ====================
# PARALLEL PROCESSING
# ====================

# Number of parallel workers
# None = auto-detect (CPU count - 1)
# Set manually if you want to limit resource usage
PARALLEL_WORKERS = None

# ====================
# DATABASE
# ====================

# SQLite database file path
DATABASE_PATH = "face_recognition.db"

# ====================
# DIRECTORIES
# ====================

# Video directories
KNOWN_VIDEOS_DIR = "videos/known"
UNKNOWN_VIDEOS_DIR = "videos/unknown"

# Output directories
THUMBNAILS_DIR = "thumbnails"
MOSAICS_DIR = "mosaics"

# ====================
# PERFORMANCE TUNING
# ====================

# When processing gets slow, try these combinations:

# SPEED PRIORITY (fastest, lower quality):
# MAX_FRAMES_TO_CHECK = 10
# MIN_FRONTAL_SCORE = 0.4
# FACE_DETECTION_MODEL = 'hog'
# FACE_DETECTION_UPSAMPLE = 0
# PARALLEL_WORKERS = (CPU count - 1)

# BALANCED (recommended):
# MAX_FRAMES_TO_CHECK = 20
# MIN_FRONTAL_SCORE = 0.6
# FACE_DETECTION_MODEL = 'hog'
# FACE_DETECTION_UPSAMPLE = 1
# PARALLEL_WORKERS = None (auto)

# QUALITY PRIORITY (slowest, best results):
# MAX_FRAMES_TO_CHECK = 40
# MIN_FRONTAL_SCORE = 0.7
# FACE_DETECTION_MODEL = 'cnn'
# FACE_DETECTION_UPSAMPLE = 2
# PARALLEL_WORKERS = (CPU count // 2)