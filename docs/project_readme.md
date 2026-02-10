# Face Recognition Video Project

Complete face recognition system for managing and identifying people in video clips.

## Features

- ✅ Automatic face detection and encoding
- ✅ SQLite database with full metadata tracking
- ✅ Consolidate known individual profiles from folder structure
- ✅ Match unknown clips against known individuals
- ✅ Generate normalized thumbnails (200x300 portrait, consistent face size)
- ✅ Create screenshot mosaics (30-second intervals)
- ✅ File system synchronization (detect moved/renamed files)
- ✅ Web interface with filtering, sorting, and pagination
- ✅ Searchable by filename or person name

## Project Structure

```
face-recognition-project/
├── database_schema.sql      # SQLite database schema
├── db_manager.py           # Database operations
├── video_processor.py      # Video processing and thumbnails
├── face_matcher.py         # Face recognition and matching
├── filesystem_sync.py      # File system synchronization
├── main_pipeline.py        # Main processing pipeline
├── index.php              # Web interface
├── requirements.txt       # Python dependencies
├── face_recognition.db    # SQLite database (created on first run)
├── thumbnails/           # Generated thumbnails (created automatically)
├── mosaics/             # Generated mosaics (created automatically)
└── videos/
    ├── known/           # Known clips organized by person
    │   ├── John_Doe/
    │   │   ├── clip1.mp4
    │   │   └── clip2.mp4
    │   └── Jane_Smith/
    │       └── clip3.mp4
    └── unknown/         # Unknown clips organized by date
        ├── 2024-01/
        ├── 2024-02/
        └── 2024-03/
```

## Installation

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

**requirements.txt:**
```
opencv-python>=4.8.0
face-recognition>=1.3.0
numpy>=1.24.0
Pillow>=10.0.0
```

**Note:** `face_recognition` requires `dlib`, which may need additional system dependencies:

**Ubuntu/Debian:**
```bash
sudo apt-get install cmake build-essential
```

**macOS:**
```bash
brew install cmake
```

### 2. Set Up Database

The database is created automatically on first run. To create it manually:

```bash
sqlite3 face_recognition.db < database_schema.sql
```

### 3. Configure PHP (for web interface)

Ensure PHP 7.0+ is installed with SQLite support:

```bash
# Check PHP version
php -v

# Check SQLite support
php -m | grep sqlite
```

**For local development:**
```bash
# Start PHP built-in server
php -S localhost:8000
```

Then open: `http://localhost:8000`

## Usage

### Directory Setup

Organize your video files:

**Known clips** (in `videos/known/`):
```
videos/known/
├── Alice_Johnson/
│   ├── meeting_2024_01.mp4
│   └── presentation.mp4
└── Bob_Williams/
    └── interview.mp4
```

**Unknown clips** (in `videos/unknown/`):
```
videos/unknown/
├── 2024-01/
│   ├── event1.mp4
│   └── event2.mp4
└── 2024-02/
    └── gathering.mp4
```

### Running the Pipeline

#### Full Processing (Recommended for first run)

Process everything: sync files, extract faces, build profiles, match unknowns:

```bash
python main_pipeline.py --action full
```

#### Individual Operations

**Sync file system only:**
```bash
python main_pipeline.py --action sync
```

**Process new files only:**
```bash
python main_pipeline.py --action process
```

**Build/rebuild known individual profiles:**
```bash
python main_pipeline.py --action build-profiles
```

**Match unknown clips to known individuals:**
```bash
python main_pipeline.py --action match
```

**Show statistics:**
```bash
python main_pipeline.py --action stats
```

#### Custom Directories

```bash
python main_pipeline.py \
    --known-dir /path/to/known \
    --unknown-dir /path/to/unknown \
    --db /path/to/database.db \
    --action full
```

### Moving Files

When you move clips between directories:

1. **Move files in file system** (e.g., from `unknown/` to `known/John_Doe/`)
2. **Run sync** to update database:
   ```bash
   python main_pipeline.py --action sync
   ```

The sync process matches files by filename and size, then updates database paths.

### Python API Usage

#### Process a Single Video

```python
from db_manager import DatabaseManager
from video_processor import VideoProcessor

# Initialize
db = DatabaseManager("face_recognition.db")
processor = VideoProcessor()

# Get metadata
metadata = processor.get_video_metadata("video.mp4")

# Add to database
clip_id = db.add_clip(
    filename=metadata['filename'],
    filepath="known/John_Doe/video.mp4",
    filesize=metadata['filesize'],
    file_date=metadata['file_date'],
    width=metadata['width'],
    height=metadata['height'],
    duration=metadata['duration'],
    clip_type="known",
    folder_person="John_Doe"
)

# Create thumbnail
thumb_path, faces = processor.create_thumbnail("video.mp4", clip_id)
db.update_clip_thumbnail(clip_id, thumb_path)

# Store face profiles
for face in faces:
    db.add_face_profile(
        clip_id=clip_id,
        face_encoding=face['encoding'],
        face_location=face['location'],
        confidence=face['confidence'],
        is_primary=face.get('is_primary', False)
    )

db.close()
```

#### Query Database

```python
from db_manager import DatabaseManager

with DatabaseManager("face_recognition.db") as db:
    # Get all clips
    clips = db.get_all_clips()
    
    # Get clips for a specific person
    person = db.get_individual_by_name("John Doe")
    if person:
        clips = db.get_clips_for_individual(person['individual_id'])
    
    # Search clips
    clips = db.get_all_clips(clip_type='unknown')
```

#### Face Matching

```python
from db_manager import DatabaseManager
from face_matcher import FaceMatcher

with DatabaseManager("face_recognition.db") as db:
    matcher = FaceMatcher(db, match_threshold=0.6)
    
    # Build profiles for known individuals
    matcher.build_individual_profiles()
    
    # Get statistics
    stats = matcher.get_match_statistics()
    print(f"Total individuals: {stats['total_individuals']}")
    print(f"Matched unknown clips: {stats['matched_unknown']}")
```

## Web Interface

### Features

- **Grid view** of video thumbnails
- **Filter** by clip type (known/unknown)
- **Filter** by individual
- **Search** by filename or person name
- **Sort** by date, filename, size, dimensions, duration
- **Pagination** with configurable items per page (25, 50, 100, 200)

### Accessing the Interface

Start PHP server:
```bash
php -S localhost:8000
```

Open browser: `http://localhost:8000`

### Deployment to Web Server

1. Copy all PHP files to web root
2. Ensure database file is readable by web server
3. Ensure thumbnail/mosaic directories are accessible
4. Configure paths in `index.php` if needed

**Apache configuration (.htaccess):**
```apache
# Protect database file
<Files "face_recognition.db">
    Order allow,deny
    Deny from all
</Files>
```

## Database Schema

### Tables

**clips** - Video file metadata
- `clip_id`, `filename`, `filepath`, `filesize`, `file_date`
- `width`, `height`, `diagonal_size`, `duration`
- `thumbnail_path`, `mosaic_path`
- `clip_type` (known/unknown), `folder_person`

**individuals** - Known people
- `individual_id`, `name`, `profile_created`, `num_clips`

**face_profiles** - Face encodings (128-d vectors)
- `profile_id`, `clip_id`, `face_encoding` (BLOB)
- `face_location` (JSON), `confidence`, `is_primary`
- `individual_id`, `match_confidence`

**clip_individuals** - Many-to-many relationship
- Links clips to individuals who appear in them

## Configuration

### Adjust Face Matching Sensitivity

Edit `main_pipeline.py`:

```python
# Stricter matching (fewer false positives)
matcher = FaceMatcher(db, match_threshold=0.5)

# More lenient matching (more matches)
matcher = FaceMatcher(db, match_threshold=0.7)
```

Default: `0.6` (balanced)

### Thumbnail Settings

Edit `video_processor.py`:

```python
# Thumbnail dimensions
self.THUMB_WIDTH = 200
self.THUMB_HEIGHT = 300

# Target face size in thumbnail
self.TARGET_FACE_HEIGHT = 120
```

### Mosaic Interval

```python
# Create mosaic with 60-second intervals instead of 30
mosaic_path = processor.create_mosaic(video_path, clip_id, interval_seconds=60)
```

## Troubleshooting

### Face Detection Not Working

**Issue:** No faces detected in videos

**Solutions:**
- Ensure videos have sufficient resolution (minimum 480p recommended)
- Check lighting conditions in videos
- Try sampling more frames: edit `video_processor.py`, reduce `sample_interval`

### Database Lock Errors

**Issue:** `database is locked` error

**Solution:** Ensure only one process accesses database at a time, or enable WAL mode:

```python
db = sqlite3.connect('face_recognition.db')
db.execute('PRAGMA journal_mode=WAL')
```

### Memory Issues with Large Videos

**Issue:** Out of memory when processing large files

**Solution:** Process videos in smaller batches, or increase frame sampling interval

### PHP Thumbnails Not Displaying

**Issue:** Thumbnails show as broken images

**Solutions:**
- Check file permissions on `thumbnails/` directory
- Verify paths in database match actual file locations
- Ensure web server can read thumbnail files

## Performance Tips

1. **Batch processing**: Process multiple videos in one pipeline run rather than individually
2. **Adjust sampling**: For faster processing, increase frame sampling interval in `find_best_face_frame()`
3. **Index optimization**: Database indexes are already created for common queries
4. **Parallel processing**: Modify pipeline to use multiprocessing for video processing (advanced)

## Future Enhancements

Potential additions you could implement:

- [ ] Video playback in web interface
- [ ] Manual face tagging interface
- [ ] Face clustering for unknown individuals
- [ ] Export functionality (CSV, JSON)
- [ ] Duplicate video detection
- [ ] Quality scoring for clips
- [ ] Multi-language support
- [ ] REST API
- [ ] Batch upload via web interface

## License

This project is provided as-is for personal use.

## Credits

- **face_recognition** library by Adam Geitgey
- **OpenCV** for video processing
- **SQLite** for database