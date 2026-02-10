# Managing Clip Matches Guide

## Two Common Scenarios

### Scenario 1: Good Match - Move to Known Folder ✅
Unknown clip correctly matched to a person → Move to their known folder

### Scenario 2: False Positive - Remove Match ❌
Unknown clip incorrectly matched to wrong person → Unbind the match

---

## Method 1: Web Interface (Easiest for Unbinding)

### Remove False Positive Matches

1. **Go to Matches Page**
   ```
   http://localhost:8000/matches.php
   ```

2. **Find the incorrect match**
   - Filter by individual or browse list
   - Look for low confidence scores (likely false positives)

3. **Click "✗ Unbind" button**
   - Confirms before removing
   - Removes database link instantly
   - Clip stays in unknown folder

**What happens:**
- Match removed from database
- Clip remains in `videos/unknown/`
- Face profiles updated (individual_id set to NULL)
- Clip becomes "unmatched" again

---

## Method 2: Command Line (Best for Confirming & Moving)

### A. Confirm Good Match and Move to Known

When you find a good match that you want to make permanent:

```bash
# Find the clip ID and individual ID from matches.php
# Then run:
python3 manage_clips.py confirm CLIP_ID INDIVIDUAL_ID

# Example:
python3 manage_clips.py confirm 1234 5
```

**What happens:**
1. Shows you the details and asks for confirmation
2. **Moves the video file** from `unknown/` to `known/PersonName/`
3. Updates database: changes clip_type to 'known'
4. Sets folder_person to the individual's name
5. Records match with 100% confidence (manual confirmation)

**Example output:**
```
Moving clip to known folder:
  Clip: video_2024.mp4
  Current type: unknown
  Assign to: John Doe

Proceed? (y/n): y
✓ Moved file to: videos/known/John_Doe/video_2024.mp4
✓ Database updated

Clip successfully moved to John Doe's folder
```

### B. Remove False Positive Match

```bash
# Unbind specific individual from clip
python3 manage_clips.py unbind CLIP_ID INDIVIDUAL_ID

# Example: Remove incorrect match to person ID 7
python3 manage_clips.py unbind 1234 7
```

**What happens:**
1. Asks for confirmation
2. Removes match from database
3. Clip stays in `unknown/` folder
4. Face profiles updated

### C. Remove All Matches (Reset to Unmatched)

```bash
# Remove all matches for a clip
python3 manage_clips.py unbind-all CLIP_ID

# Example:
python3 manage_clips.py unbind-all 1234
```

**Use when:**
- Clip has multiple incorrect matches
- Want to start fresh with matching

---

## Useful Commands

### Find Clip ID by Filename

```bash
python3 manage_clips.py find "video_name"

# Example:
python3 manage_clips.py find "meeting"
```

**Output:**
```
Found 3 matching clip(s):
  ID: 1234 | meeting_2024.mp4 | Type: unknown
  ID: 1235 | meeting_jan.mp4 | Type: known
  ID: 1236 | team_meeting.mp4 | Type: unknown
```

### List All Matches for a Clip

```bash
python3 manage_clips.py list CLIP_ID

# Example:
python3 manage_clips.py list 1234
```

**Output:**
```
Clip: video_2024.mp4
Type: unknown
Path: 2024-01/video_2024.mp4

Matched to 2 individual(s):
  - John Doe (ID: 5, Confidence: 85.3%)
  - Jane Smith (ID: 12, Confidence: 45.2%)
```

---

## Complete Workflows

### Workflow 1: Review and Confirm Good Matches

```bash
# 1. Open matches page in browser
firefox http://localhost:8000/matches.php

# 2. Filter "Matched Only" and sort by "Confidence" (descending)
#    This shows best matches first

# 3. For each good match (high confidence):
#    - Note the clip ID and individual ID from the page
#    - Copy the command shown on the page

# 4. Run command to confirm and move:
python3 manage_clips.py confirm 1234 5
python3 manage_clips.py confirm 1235 5
python3 manage_clips.py confirm 1240 8
# etc...

# 5. Rebuild profiles to include newly confirmed clips
python3 main_pipeline.py --action build-profiles
```

### Workflow 2: Clean Up False Positives

```bash
# 1. Open matches page
# 2. Filter "Matched Only" and sort by "Confidence" (ascending)
#    This shows worst matches first (likely false positives)

# 3. For each false positive:
#    Click "✗ Unbind" button in web interface
#    OR use command line:

python3 manage_clips.py unbind 1236 7

# 4. After cleaning up, re-run matching
python3 main_pipeline.py --action match
```

### Workflow 3: Batch Process High-Confidence Matches

Create a script to confirm multiple matches:

```bash
#!/bin/bash
# confirm_matches.sh

# High confidence matches from matches.php
python3 manage_clips.py confirm 1234 5  # John Doe, 95%
python3 manage_clips.py confirm 1235 5  # John Doe, 92%
python3 manage_clips.py confirm 1240 8  # Alice, 88%
python3 manage_clips.py confirm 1241 8  # Alice, 91%
python3 manage_clips.py confirm 1250 12 # Bob, 87%

# Rebuild profiles after batch move
python3 main_pipeline.py --action build-profiles
```

Run it:
```bash
chmod +x confirm_matches.sh
./confirm_matches.sh
```

---

## Manual File Movement (Not Recommended)

**Question:** Can I just move the file manually?

**Answer:** Yes, but you need to update the database after:

```bash
# 1. Move file manually
mv videos/unknown/2024-01/video.mp4 videos/known/John_Doe/

# 2. Update database
python3 main_pipeline.py --action sync

# 3. The file will be detected in new location
#    But the match won't be automatically recorded
#    You still need to ensure the match is in database
```

**Better approach:** Use `manage_clips.py confirm` which does both steps atomically.

---

## Quick Reference

| Task | Web Interface | Command Line |
|------|--------------|--------------|
| **Remove false positive** | Click "✗ Unbind" | `manage_clips.py unbind CLIP_ID IND_ID` |
| **Confirm & move to known** | Not available | `manage_clips.py confirm CLIP_ID IND_ID` |
| **Find clip ID** | View in matches.php | `manage_clips.py find "filename"` |
| **List matches** | View in matches.php | `manage_clips.py list CLIP_ID` |
| **Remove all matches** | Click unbind for each | `manage_clips.py unbind-all CLIP_ID` |

---

## Tips

### Finding High-Confidence Matches to Confirm

```sql
# Direct SQL query (if comfortable)
sqlite3 face_recognition.db "
SELECT c.clip_id, c.filename, i.individual_id, i.name, ci.confidence
FROM clips c
JOIN clip_individuals ci ON c.clip_id = ci.clip_id
JOIN individuals i ON ci.individual_id = i.individual_id
WHERE c.clip_type = 'unknown' AND ci.confidence > 0.85
ORDER BY ci.confidence DESC;
"
```

### Finding Likely False Positives

```sql
sqlite3 face_recognition.db "
SELECT c.clip_id, c.filename, i.individual_id, i.name, ci.confidence
FROM clips c
JOIN clip_individuals ci ON c.clip_id = ci.clip_id
JOIN individuals i ON ci.individual_id = i.individual_id
WHERE c.clip_type = 'unknown' AND ci.confidence < 0.5
ORDER BY ci.confidence ASC;
"
```

### After Making Changes

Always rebuild profiles and re-match:

```bash
# After confirming matches and moving files
python3 main_pipeline.py --action build-profiles
python3 main_pipeline.py --action match
```

---

## Summary

**To move unknown → known (good match):**
```bash
python3 manage_clips.py confirm CLIP_ID INDIVIDUAL_ID
```

**To remove false positive:**
- Web: Click "✗ Unbind" button
- CLI: `python3 manage_clips.py unbind CLIP_ID INDIVIDUAL_ID`

Both methods update the database correctly. Use the web interface for quick unbinding, command line for confirming and moving clips.