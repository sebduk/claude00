# Force Re-match Individual Feature

## Overview
Added a "Force Re-match" button to the admin_individual.php page that allows you to re-run face matching for a specific individual against ALL clips in your database, including:
- Unknown clips
- Known clips (from other individuals)
- Previously rejected matches

## Files Modified/Created

### 1. `/admin/actions/force_rematch_individual.php` (NEW)
**Purpose:** Backend endpoint that handles the force re-matching logic

**What it does:**
1. Clears all rejected matches (from `known_error_matches` table) for the specified individual
2. Retrieves the individual's face encoding
3. Scans ALL clips in the database (except those already in this individual's known folder)
4. For each clip:
   - Retrieves all face profiles
   - Calculates Euclidean distance between clip faces and individual's face encoding
   - Keeps the best (lowest) distance
5. Filters matches by confidence threshold (default: 0.6, user-configurable)
6. Clears existing `clip_individuals` entries for this individual
7. Inserts new matches into `clip_individuals` table

**Parameters:**
- `individual_id` (required): The individual to re-match
- `threshold` (optional): Matching threshold (0.0-1.0, default 0.6)

**Returns:**
```json
{
  "success": true,
  "message": "Re-matched successfully",
  "data": {
    "cleared_rejections": 15,
    "clips_evaluated": 2847,
    "new_matches": 23,
    "threshold": 0.6
  }
}
```

### 2. `/admin/admin_individual.php` (MODIFIED)
**Changes:**

#### UI Change (Line ~598):
Added a button next to the "AI Match Suggestions" section title:
```php
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
    <div class="section-title" style="margin-bottom: 0;">🤖 AI Match Suggestions (...)</div>
    <button class="btn btn-merge" onclick="forceRematch()">
        🔄 Force Re-match
    </button>
</div>
```

#### JavaScript Function (Line ~1125):
Added `forceRematch()` function that:
1. Shows confirmation dialog explaining the action
2. Prompts for threshold value (default 0.6)
3. Validates threshold input
4. Calls the backend endpoint
5. Shows progress ("Re-matching...")
6. Displays summary of results
7. Reloads page to show new matches

## Usage

1. Navigate to any individual's detail page in admin interface
2. Scroll to the "AI Match Suggestions" section
3. Click the "🔄 Force Re-match" button
4. Confirm the action (dialog explains what will happen)
5. Enter matching threshold (or press Enter for default 0.6)
6. Wait for re-matching to complete
7. Review the summary showing:
   - How many rejected matches were cleared
   - How many clips were evaluated
   - How many new matches were found
8. Page auto-reloads to show new match suggestions

## How Matching Works

### Distance Calculation
Uses Euclidean distance between 128-dimensional face encodings:
```php
distance = sqrt(sum((encoding_a[i] - encoding_b[i])^2))
```

### Confidence Conversion
```php
confidence = max(0, 1 - (distance / threshold))
```

For threshold=0.6:
- distance=0.0 → confidence=1.0 (100%)
- distance=0.3 → confidence=0.5 (50%)
- distance=0.6 → confidence=0.0 (0%)
- distance>0.6 → no match

### Threshold Guidelines
- **0.4**: Very strict, only very close matches
- **0.5**: Strict, good for high confidence
- **0.6**: Default, balanced
- **0.7**: Permissive, may include false positives
- **0.8**: Very permissive, many false positives

## Technical Notes

### Database Operations
1. DELETE from `known_error_matches` WHERE individual_id = X
2. SELECT all clips not in individual's known folder
3. For each clip: SELECT face_profiles, calculate distances
4. DELETE from `clip_individuals` WHERE individual_id = X
5. INSERT new matches into `clip_individuals`

### Performance
- Evaluates ALL clips in database (could be 1000s)
- For each clip, compares against all face profiles
- May take several seconds for large databases
- Button is disabled during processing to prevent double-submission

### Why This is Useful
1. **Recover from overzealous rejection:** If you rejected too many matches, start fresh
2. **Test different thresholds:** Try stricter or looser matching
3. **Include known clips:** Match against clips that are already assigned to other individuals (useful for finding duplicates or misidentifications)
4. **Clean slate:** Remove all previous matching decisions and re-evaluate

## Installation

1. Place `force_rematch_individual.php` in `/admin/actions/` directory
2. Replace `/admin/admin_individual.php` with the updated version
3. No database schema changes required (uses existing tables)

## Database Schema Used

### Tables
- `individuals` - Individual profiles with face encodings
- `clips` - Video clips (known and unknown)
- `face_profiles` - Face encodings extracted from clips
- `clip_individuals` - Match associations (confidence scores)
- `known_error_matches` - Rejected matches (prevents future suggestions)

### Key Queries
```sql
-- Clear rejected matches
DELETE FROM known_error_matches WHERE individual_id = ?

-- Get all non-owned clips
SELECT * FROM clips WHERE NOT EXISTS (
  SELECT 1 FROM clips c2 
  WHERE c2.clip_id = clips.clip_id 
  AND c2.clip_type = 'known' 
  AND c2.folder_person = 'IndividualName'
)

-- Store matches
INSERT INTO clip_individuals (clip_id, individual_id, confidence)
VALUES (?, ?, ?)
```

## Error Handling
- Validates individual exists
- Checks for face encoding presence
- Validates threshold range (0.0-1.0)
- Handles PHP serialization of encodings
- Returns detailed error messages
- Graceful fallback on frontend errors

## Future Enhancements
Possible improvements:
1. Add option to only re-match unknown clips (skip known)
2. Add option to preserve existing rejections
3. Show preview of matches before committing
4. Batch re-match multiple individuals
5. Add progress bar for long operations
6. Log re-match operations for audit trail
