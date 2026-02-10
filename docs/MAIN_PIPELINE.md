🎯 How to Use It
Available commands with your existing pipeline:

# Process new files only (extract faces, thumbnails)
python3 main_pipeline.py --action process

# Run AI matching only (refresh matches)
python3 main_pipeline.py --action match

# Build known individual profiles
python3 main_pipeline.py --action build-profiles

# Sync filesystem with database
python3 main_pipeline.py --action sync

# Show statistics
python3 main_pipeline.py --action stats

# Regenerate missing thumbnails/mosaics
python3 main_pipeline.py --action regenerate

# Run FULL pipeline (sync → process → build → match)
python3 main_pipeline.py --action full

# Or just run with defaults (full pipeline)
python3 main_pipeline.py


🔧 Optional Flags
# Custom directories
python3 main_pipeline.py --known-dir videos/known --unknown-dir videos/unknown

# Custom database
python3 main_pipeline.py --db face_recognition.db

# Combined
python3 main_pipeline.py --action process --known-dir videos/known --db face_recognition.db


📋 Common Workflows
# Daily workflow (new videos added):
python3 main_pipeline.py --action process
# Then visit admin/matches.php to review AI suggestions

# Refresh AI matches after rejecting some:
python3 main_pipeline.py --action match

# Rebuild everything from scratch:
python3 main_pipeline.py --action build-profiles
python3 main_pipeline.py --action match

# Full sync and process:
python3 main_pipeline.py --action full

This is the pipeline you already have - no changes needed! Just use it directly. 🚀