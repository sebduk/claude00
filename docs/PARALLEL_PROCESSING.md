# Parallel Processing Guide

## Speed Comparison

Your current processing speed: **~1100 clips in 48 hours = ~23 clips/hour**

With parallel processing on a typical 8-core CPU:
- **Expected: ~160-184 clips/hour** (7-8x faster)
- **5000 clips estimated: ~27-31 hours** instead of 218 hours

## Quick Start

### Use Parallel Pipeline (Recommended for Large Batches)

```bash
# Full pipeline with automatic worker detection
python3 parallel_pipeline.py --action full

# Specify number of workers (e.g., 6 workers)
python3 parallel_pipeline.py --action full --workers 6

# Process only new files
python3 parallel_pipeline.py --action process --workers 6

# Regenerate missing assets only
python3 parallel_pipeline.py --action regenerate --workers 6
```

### How Many Workers Should You Use?

```bash
# Check your CPU count
python3 -c "import multiprocessing; print(f'CPUs: {multiprocessing.cpu_count()}')"

# Recommended: CPU count - 1 (leaves one free for system)
# Example: 8 CPUs → use 7 workers
python3 parallel_pipeline.py --action full --workers 7
```

## What Gets Parallelized?

### ✅ **Parallelized (Much Faster)**
- Video processing (thumbnails, mosaics)
- Face detection and encoding
- File metadata extraction
- Database writes (per clip)

### ⚠️ **Sequential (Already Fast)**
- File system sync
- Building individual profiles
- Matching unknown clips
- Database consolidation

## Performance Tips

### 1. **Optimal Worker Count**
```bash
# Conservative (stable, good for 4-8 cores)
--workers 4

# Aggressive (maximum speed, good for 8+ cores)
--workers $(python3 -c "import multiprocessing; print(multiprocessing.cpu_count() - 1)")

# Custom (if you know your system)
--workers 6
```

### 2. **Monitor Progress**
The parallel pipeline shows:
- Real-time progress: `[145/1100] ✓ video.mp4 - 2 faces`
- Time estimates: `Progress: 150/1100 | Elapsed: 12.5m | ETA: 78.3m`
- Summary statistics at completion

### 3. **Handle Interruptions**
If interrupted, just restart - it picks up where it left:
```bash
# First run (interrupted at 500/1100)
python3 parallel_pipeline.py --action full --workers 6
^C

# Resume (will skip first 500, process remaining 600)
python3 parallel_pipeline.py --action full --workers 6
```

### 4. **Process in Stages for Very Large Batches**
For 5000+ clips, you can process in stages:

```bash
# Stage 1: Process new files only (parallel)
python3 parallel_pipeline.py --action process --workers 7

# Stage 2: Build profiles (fast, sequential)
python3 main_pipeline.py --action build-profiles

# Stage 3: Match unknowns (fast, sequential)
python3 main_pipeline.py --action match
```

## Technical Details

### Database Concurrency
- Each worker has its own database connection
- SQLite handles concurrent writes safely
- WAL mode ensures no conflicts

### Memory Usage
- Each worker loads: VideoProcessor + face_recognition model
- Approximate: **500MB per worker**
- Example: 6 workers ≈ 3GB RAM usage
- Your system should have: **(workers × 500MB) + 2GB** free RAM

### CPU Usage
- Each worker: **~90-100% of one CPU core**
- During processing: expect **90-95% total CPU usage**
- This is normal and desired for maximum speed

## Troubleshooting

### Issue: "Out of Memory" errors
**Solution:** Reduce workers
```bash
python3 parallel_pipeline.py --action full --workers 3
```

### Issue: System becomes unresponsive
**Solution:** Leave more CPUs free
```bash
# On 8-core system, use only 5 workers instead of 7
python3 parallel_pipeline.py --action full --workers 5
```

### Issue: Database lock errors
**Solution:** This shouldn't happen with the parallel pipeline, but if it does:
```bash
# Enable WAL mode manually
sqlite3 face_recognition.db "PRAGMA journal_mode=WAL;"
```

### Issue: Some clips fail to process
**Check the error messages** - common causes:
- Corrupted video files
- Unsupported video codecs
- Insufficient disk space for thumbnails/mosaics

Failed clips are logged but don't stop the pipeline.

## Comparison: Sequential vs Parallel

| Aspect | Sequential (`main_pipeline.py`) | Parallel (`parallel_pipeline.py`) |
|--------|--------------------------------|-----------------------------------|
| **Speed** | 1x (baseline) | 6-8x faster (typical 8-core CPU) |
| **CPU Usage** | ~12-15% (1 core) | ~90% (most cores) |
| **Memory** | ~500MB | ~3-4GB (6-8 workers) |
| **Progress** | Per-clip messages | Batch progress with ETA |
| **Best for** | Small batches (<100 clips) | Large batches (500+ clips) |
| **Resuming** | Manual tracking | Automatic skip of completed |

## Real-World Example

Your 5000 clips scenario:

**Sequential Pipeline:**
```bash
python3 main_pipeline.py --action full
# Estimated: 218 hours (9 days)
```

**Parallel Pipeline (6 workers):**
```bash
python3 parallel_pipeline.py --action full --workers 6
# Estimated: 30 hours (1.25 days)
# Saves: 188 hours (7.8 days)
```

## Recommended Workflow

For your 5000+ clips, I recommend:

```bash
# 1. Initial run with parallel processing
python3 parallel_pipeline.py --action full --workers 6

# 2. If interrupted, just restart (auto-resumes)
python3 parallel_pipeline.py --action full --workers 6

# 3. After completion, verify with stats
python3 main_pipeline.py --action stats

# 4. If you delete bad thumbnails later
rm thumbnails/thumb_*.jpg  # Delete specific bad ones
python3 parallel_pipeline.py --action regenerate --workers 6
```

## Safety Notes

✅ **Safe to use parallel pipeline when:**
- Processing large batches (100+ clips)
- System has sufficient RAM
- You need results faster

⚠️ **Consider sequential pipeline when:**
- Testing with small batches (<50 clips)
- System has limited RAM (<4GB)
- Running on shared/production server
- Debugging processing issues

The parallel pipeline is production-ready and safe - it uses the same underlying code, just runs multiple instances simultaneously!