# Face Recognition System - Match Denial & Cascade Delete Documentation

## How Denied Matches Are Prevented

### Overview
When you click "Unbind Match" on a clip-individual pairing, the system ensures that this incorrect match will NEVER appear again, even after running the pipeline multiple times.

### The `known_error_matches` Table

This table stores all denied matches:

```sql
CREATE TABLE known_error_matches (
    error_id INTEGER PRIMARY KEY AUTOINCREMENT,
    clip_id INTEGER NOT NULL,
    individual_id INTEGER NOT NULL,
    date_added TEXT DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    UNIQUE(clip_id, individual_id),
    FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
    FOREIGN KEY (individual_id) REFERENCES individuals(individual_id) ON DELETE CASCADE
);
```

### What Happens When You Unbind a Match

When you click "Unbind Match" in `matches.php` or `individual.php`, the system performs these operations:

1. **Remove from `clip_individuals`**
   ```sql
   DELETE FROM clip_individuals 
   WHERE clip_id = ? AND individual_id = ?
   ```

2. **Clear face profile assignments**
   ```sql
   UPDATE face_profiles 
   SET individual_id = NULL, match_confidence = NULL 
   WHERE clip_id = ? AND individual_id = ?
   ```

3. **Add to `known_error_matches`** (THIS IS THE KEY!)
   ```sql
   INSERT OR IGNORE INTO known_error_matches (clip_id, individual_id, notes) 
   VALUES (?, ?, 'Unbinded via web interface')
   ```

### How the Pipeline Respects Denied Matches

In `face_matcher.py`, the `process_unknown_clip()` method checks for denied matches:

```python
def process_unknown_clip(self, clip_id: int, face_encodings: List[np.ndarray]):
    # Get known error matches for this clip
    cursor = self.db.connection.cursor()
    cursor.execute("""
        SELECT individual_id FROM known_error_matches WHERE clip_id = ?
    """, (clip_id,))
    error_matches = set(row[0] for row in cursor.fetchall())
    
    # ... matching logic ...
    
    for individual_id, distance in matches:
        # Skip if this is a known error match
        if individual_id in error_matches:
            print(f"  Face {idx} skipping known error match to individual {individual_id}")
            continue
```

**This means:**
- When you run `python3 main_pipeline.py --action match`, it processes unknown clips
- For each clip, it retrieves the list of denied individuals
- Any match to a denied individual is skipped
- The system will try the next best match instead

### Why You Might See "New" Matches

If you're seeing more matches each time you run the pipeline, it's because:

1. **You added new clips** - New unknown clips will be matched
2. **Better matches found** - If Individual A was denied, the system matches to Individual B instead
3. **Threshold changes** - Different confidence thresholds might allow previously excluded matches
4. **New individuals** - Adding new known individuals creates new potential matches

**NOT because denied matches are reappearing!**

## Cascade Delete Behavior

### What Gets Deleted When You Delete a Clip

The database uses `ON DELETE CASCADE` constraints to automatically clean up related records:

```
DELETE clips WHERE clip_id = X
    ↓ CASCADE
    ├─ DELETE face_profiles WHERE clip_id = X
    ├─ DELETE clip_individuals WHERE clip_id = X
    └─ DELETE known_error_matches WHERE clip_id = X
```

### Tables with CASCADE DELETE:

1. **`face_profiles`**
   - `FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE`
   - When a clip is deleted, all its face profiles are deleted

2. **`clip_individuals`**
   - `FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE`
   - When a clip is deleted, all its individual associations are deleted

3. **`known_error_matches`**
   - `FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE`
   - When a clip is deleted, all its error match records are deleted

### How to Verify Everything Is Working

Run the diagnostic script:

```bash
python3 verify_system.py
```

This will:
1. ✅ Verify all denied matches are properly excluded
2. ✅ Confirm cascade deletes are configured correctly
3. ✅ Check for any contradictory data (matches that shouldn't exist)

### How to Clean Up Inconsistencies

If you suspect there are problems, run:

```bash
python3 cleanup_database.py
```

This will:
1. Remove any matches that should have been denied
2. Clean up orphaned records
3. Verify cascade delete constraints

## Common Questions

### Q: I denied a match, but it appeared again. Why?

**A:** This should NOT happen. If it does:
1. Run `python3 verify_system.py` to diagnose
2. Check if the unbind action completed successfully
3. Look in `known_error_matches` table to confirm the denial was recorded:
   ```sql
   SELECT * FROM known_error_matches WHERE clip_id = ? AND individual_id = ?;
   ```

### Q: I deleted a clip, but its face profiles are still in the database

**A:** This should NOT happen due to CASCADE DELETE. If it does:
1. Check if foreign keys are enabled:
   ```sql
   PRAGMA foreign_keys;  -- Should return 1
   ```
2. If disabled, enable them:
   ```sql
   PRAGMA foreign_keys = ON;
   ```
3. Run `python3 cleanup_database.py` to remove orphaned records

### Q: Why do I keep getting more matches each time I run the pipeline?

**A:** This is normal and expected if:
1. You're adding new clips to the `videos/unknown/` folder
2. You're improving your known individual profiles (more training data = better matches)
3. You denied match to Person A, so now it's matching to Person B

**This is NOT because denied matches are reappearing.**

To verify, run:
```bash
python3 verify_system.py
```

If it reports contradictory matches, then there's a problem. Otherwise, the new matches are legitimate new discoveries.

## Database Integrity Commands

### Check for Contradictory Matches
```sql
-- Find clips that have BOTH denied AND active matches to same person
SELECT c.filename, i.name, kem.date_added as denied_on
FROM clip_individuals ci
JOIN known_error_matches kem 
    ON ci.clip_id = kem.clip_id 
    AND ci.individual_id = kem.individual_id
JOIN clips c ON ci.clip_id = c.clip_id
JOIN individuals i ON ci.individual_id = i.individual_id;
```

If this returns any rows, you have inconsistent data that needs cleanup.

### Manual Cleanup (if needed)
```sql
-- Remove all matches that were previously denied
DELETE FROM clip_individuals
WHERE (clip_id, individual_id) IN (
    SELECT clip_id, individual_id FROM known_error_matches
);

-- Clear face profile individual assignments for denied matches
UPDATE face_profiles
SET individual_id = NULL, match_confidence = NULL
WHERE (clip_id, individual_id) IN (
    SELECT clip_id, individual_id FROM known_error_matches
);
```

## Testing Cascade Deletes

You can test cascade deletes safely:

```python
import sqlite3

conn = sqlite3.connect('face_recognition.db')
cursor = conn.cursor()

# Find a test clip
cursor.execute("SELECT clip_id, filename FROM clips WHERE clip_type='unknown' LIMIT 1")
clip_id, filename = cursor.fetchone()

# Check what will be deleted
cursor.execute("SELECT COUNT(*) FROM face_profiles WHERE clip_id = ?", (clip_id,))
face_count = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM clip_individuals WHERE clip_id = ?", (clip_id,))
ci_count = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM known_error_matches WHERE clip_id = ?", (clip_id,))
error_count = cursor.fetchone()[0]

print(f"Deleting {filename} would also delete:")
print(f"  - {face_count} face profiles")
print(f"  - {ci_count} clip-individual links")
print(f"  - {error_count} error match records")

# DON'T actually delete unless you want to test
# cursor.execute("DELETE FROM clips WHERE clip_id = ?", (clip_id,))
# conn.commit()

conn.close()
```

## Summary

✅ **Denied matches are properly prevented** through the `known_error_matches` table
✅ **Cascade deletes work automatically** through foreign key constraints
✅ **The system is designed correctly** to prevent re-matching

If you see issues, use the diagnostic and cleanup scripts to identify and fix them.
