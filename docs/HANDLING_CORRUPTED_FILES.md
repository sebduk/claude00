# Handling Corrupted Video Files

## The Problem

Error message: `[mov,mp4,m4a,3gp,3g2,mj2 @ 0x...] stream 0, offset 0x...: partial file`

This means the video file is:
- Incomplete (download interrupted)
- Corrupted (data corruption)
- Damaged header/metadata
- Unsupported codec

## Solution 1: Find and Quarantine Corrupted Files

Use the new `check_corrupted_videos.py` script:

### Scan for Corrupted Files

```bash
# Scan known videos directory
python3 check_corrupted_videos.py videos/known/

# Scan unknown videos directory
python3 check_corrupted_videos.py videos/unknown/

# Scan both (run twice)
python3 check_corrupted_videos.py videos/known/ --report known_report.txt
python3 check_corrupted_videos.py videos/unknown/ --report unknown_report.txt
```

### Output Example:

```
Scanning: videos/known/
============================================================
Found 1500 video files

[1/1500] Checking: meeting.mp4... ✓
[2/1500] Checking: interview.mp4... ✓
[3/1500] Checking: corrupted.mp4... ✗ CORRUPTED: Cannot open video file
[4/1500] Checking: partial.mp4... ✗ CORRUPTED: Invalid video metadata
...

============================================================
VIDEO FILE SCAN REPORT
============================================================

Total files scanned: 1500
  ✓ OK: 1485 (99.0%)
  ✗ Corrupted: 12 (0.8%)
  ⚠ Other errors: 3 (0.2%)

Quarantine corrupted files? (y/n): y
Moving 15 corrupted files to: quarantine/
  [1/15] Moved: corrupted.mp4
  ...
```

### Options:

```bash
# Just scan and report (don't quarantine)
python3 check_corrupted_videos.py videos/known/ --no-quarantine

# Copy instead of move (keep originals)
python3 check_corrupted_videos.py videos/known/ --quarantine-dir bad_videos/

# Move files to quarantine (removes from source)
python3 check_corrupted_videos.py videos/known/ --quarantine-dir bad_videos/ --move

# Save detailed report
python3 check_corrupted_videos.py videos/known/ --report corruption_report.txt
```

## Solution 2: Try to Repair Files

### Using FFmpeg (if installed):

```bash
# Try to repair by re-encoding
ffmpeg -i corrupted.mp4 -c copy repaired.mp4

# If that fails, force decode and re-encode
ffmpeg -i corrupted.mp4 -c:v libx264 -c:a aac repaired.mp4
```

### Batch Repair:

```bash
# For all files in quarantine/
for file in quarantine/*.mp4; do
    ffmpeg -i "$file" -c copy "repaired/$(basename "$file")" 2>/dev/null
done
```

## Solution 3: Skip Corrupted Files in Pipeline

The pipeline now automatically skips corrupted files and continues processing:

```bash
# Run pipeline - corrupted files will be logged and skipped
python3 parallel_pipeline.py --action full --workers 6
```

**What happens:**
- Corrupted file detected during metadata extraction
- Error logged: `✗ video.mp4 - ERROR: Cannot open video file`
- Pipeline continues with next file
- Corrupted file remains unprocessed (not in database)

## Finding Unprocessed Files

After pipeline completes, find files that weren't processed:

```bash
# Compare filesystem to database
python3 main_pipeline.py --action sync

# Look for files not in database
python3 check_corrupted_videos.py videos/known/ --no-quarantine
```

## Recommended Workflow

### For Initial Processing:

1. **Run pipeline first** (let it skip corrupted files naturally)
   ```bash
   python3 parallel_pipeline.py --action full --workers 6
   ```

2. **After completion, scan for corrupted files**
   ```bash
   python3 check_corrupted_videos.py videos/known/ --report corrupted_known.txt
   python3 check_corrupted_videos.py videos/unknown/ --report corrupted_unknown.txt
   ```

3. **Review reports** and decide what to do with corrupted files

4. **Quarantine them**
   ```bash
   python3 check_corrupted_videos.py videos/known/ --move --quarantine-dir quarantine/
   python3 check_corrupted_videos.py videos/unknown/ --move --quarantine-dir quarantine/
   ```

5. **Attempt repair** (optional)
   ```bash
   # Try to repair files in quarantine
   for file in quarantine/*.mp4; do
       ffmpeg -i "$file" -c copy "repaired/$(basename "$file")"
   done
   
   # Move successfully repaired files back
   mv repaired/*.mp4 videos/known/Person_Name/
   
   # Re-run pipeline to process repaired files
   python3 parallel_pipeline.py --action process --workers 6
   ```

### For Ongoing Maintenance:

```bash
# Monthly check for corrupted files
python3 check_corrupted_videos.py videos/ --report monthly_check.txt

# Quarantine any found
python3 check_corrupted_videos.py videos/ --move --quarantine-dir quarantine/
```

## Statistics from Your Run

Based on your results:
- **Total clips processed: 4075**
- **Failed clips: ~25** (estimated based on "partial file" errors)
- **Success rate: 99.4%**

This is excellent! Most files processed successfully.

## What to Do with Quarantined Files

### Option 1: Delete Them
If they're clearly corrupted and have no value:
```bash
rm quarantine/*.mp4
```

### Option 2: Try to Re-download
If they're from a source you can access again

### Option 3: Keep for Reference
Some might be partially playable in certain players

### Option 4: Report to Source
If files came from a vendor/service, report corruption

## Prevention

To prevent future corruption:

1. **Verify downloads** - Use checksums if available
2. **Check during transfer** - Verify files after copying
3. **Regular backups** - Keep originals safe
4. **Monitor storage** - Check disk health (SMART status)

## Summary

**You have two new tools:**

1. **check_corrupted_videos.py** - Scan and quarantine bad files
2. **Updated video_processor.py** - Gracefully handles corrupted files

The pipeline will now skip corrupted files automatically, so your processing can complete even with some bad files in the mix!






SD Notes:
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -c:a aac output.mp4