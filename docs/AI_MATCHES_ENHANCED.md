# AI Match Suggestions - Enhanced to Show ALL Clips

## Changes Made

### 1. Show ALL Matched Clips (Not Just Unknown)

**Before:** Only showed unknown clips
**Now:** Shows ALL clips that match this individual, including:
- Unknown clips (as before)
- Known clips from OTHER individuals (potential duplicates/mismatches!)

This helps you find:
- ✅ Clips wrongly assigned to other individuals
- ✅ Potential duplicate individuals to merge
- ✅ Misidentified clips that should be reassigned

**Visual indicator:** Known clips are marked with **"KNOWN:"** prefix in orange

### 2. Added Confidence Sorting

**New feature:** Click the "Confidence" column header to sort by match confidence

- First click: **Confidence ▼** (High to Low) - Shows best matches first
- Second click: **Confidence ▲** (Low to High) - Shows weakest matches first

Combined with the existing filename/path sorting:
- Click "Filename": Cycles through Filename/Path/Filename desc/Path desc
- Click "Confidence": Toggles High→Low / Low→High

### 3. Updated Section Title

Changed from: "🤖 AI Match Suggestions"
To: "🤖 AI Match Suggestions - All Clips"

Makes it clear this shows ALL matched clips, not just unknowns.

## SQL Query Change

**Before:**
```sql
WHERE ci.individual_id = ?
AND c.clip_type = 'unknown'
```

**After:**
```sql
WHERE ci.individual_id = ?
AND NOT (c.clip_type = 'known' AND c.folder_person = ?)
```

This excludes only clips already in THIS individual's folder, but includes:
- All unknown clips
- Known clips from OTHER individuals' folders

## Use Cases

### Finding Duplicate Individuals

1. Run Force Re-match with threshold ~0.7
2. Look for known clips in the results
3. If you see clips from "John Smith" matching "J. Smith", they might be duplicates
4. Use the Merge function to consolidate them

### Finding Misidentified Clips

1. Check the AI suggestions
2. Look for known clips with high confidence
3. If "Jane Doe" appears in "John Doe's" matches with 85% confidence...
4. She might be mislabeled - accept the match to move her to the right folder

### Reviewing Weak Matches

1. Click Confidence header twice to sort Low→High
2. Review clips with <60% confidence
3. Reject obvious false matches
4. Accept borderline ones you want to investigate further

## Table Columns

```
[☑] [Thumbnail] [Filename ▼] [Duration] [Dimensions] [Date] [Confidence ▼] [Tags] [Actions]
```

**Sortable columns:**
- Filename - 4 modes (filename asc/desc, path asc/desc)
- Confidence - 2 modes (high→low, low→high)

## Display Format

**Unknown clips:**
```
my-video.mp4
videos/unknown/2024-01-15/my-video.mp4
```

**Known clips from other individuals:**
```
other-video.mp4
KNOWN: videos/known/Other Person/other-video.mp4
```
(KNOWN prefix in orange to make them stand out)

## Example Workflow

1. **Force Re-match** with threshold 0.6
2. See results: "Found 45 matches" but only 20 show up
3. That's because 25 are already in your known folder (excluded from display)
4. The 20 shown include:
   - 15 unknown clips
   - 5 known clips from other individuals (potential issues!)
5. Click **Confidence** to sort by match quality
6. Review the known clips - are they misidentified?
7. Use **Accept** to move them to this individual
8. Or note which individual they're from and consider **merging** those individuals

## Benefits

- **Find duplicate individuals** - See clips assigned to similar-named individuals
- **Catch mistakes** - Find clips in wrong folders
- **Better matching** - See ALL matches, not just unknowns
- **Easier review** - Sort by confidence to focus on best/worst matches
- **Bulk operations** - Select and accept/reject multiple at once

## Installation

Replace `/admin/admin_individual.php` with the updated version.

No database changes required - just a better query and enhanced UI!
