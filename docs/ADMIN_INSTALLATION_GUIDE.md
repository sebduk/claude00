# Admin Section - Installation & Setup

## ✅ Files Created

### Main Pages (2 of 5)
1. **admin/individuals.php** - Individuals grid with clickable stars
2. **admin/individual.php** - File management + AI suggestions

### Action Handlers (6 total)
1. **admin/actions/update_star.php** - Update star ratings (no confirmation)
2. **admin/actions/move_to_unknown.php** - Move clip to unknown folder (with confirmation)
3. **admin/actions/delete_clip.php** - Delete clip permanently (with confirmation)
4. **admin/actions/set_default_thumbnail.php** - Set default thumbnail (no confirmation)
5. **admin/actions/accept_match.php** - Accept AI match and move clip (with confirmation)
6. **admin/actions/reject_match.php** - Reject AI match (with confirmation)

## 📁 Directory Structure

```
your-project/
├── config.php
├── navbar.php
├── navigate/
│   ├── individuals.php
│   └── individual.php
└── admin/
    ├── individuals.php          ✅ DONE
    ├── individual.php           ✅ DONE
    ├── matches.php              TODO
    ├── unknown.php              TODO
    ├── duplicates.php           TODO
    └── actions/
        ├── update_star.php      ✅ DONE
        ├── move_to_unknown.php  ✅ DONE
        ├── delete_clip.php      ✅ DONE
        ├── set_default_thumbnail.php  ✅ DONE
        ├── accept_match.php     ✅ DONE
        └── reject_match.php     ✅ DONE
```

## 🔧 Installation Steps

### 1. Create admin directory
```bash
mkdir -p admin/actions
```

### 2. Place main pages
- `admin_individuals.php` → `admin/individuals.php`
- `admin_individual.php` → `admin/individual.php`

### 3. Place action handlers
All `*.php` files → `admin/actions/`
- `update_star.php`
- `move_to_unknown.php`
- `delete_clip.php`
- `set_default_thumbnail.php`
- `accept_match.php`
- `reject_match.php`

### 4. Verify permissions
```bash
chmod 755 admin/
chmod 755 admin/actions/
chmod 644 admin/*.php
chmod 644 admin/actions/*.php
```

## 🎨 Confirmation Behavior

### ✅ NO Confirmation (Instant)
- **Star ratings** - Click to cycle through ratings
- **Set default thumbnail** - Instant update
- Tag additions/removals (when implemented)

### ⚠️ WITH Confirmation (Destructive)
- **Move to Unknown** - "Move [filename] to unknown folder?"
- **Delete clip** - "Delete [filename]? This cannot be undone."
- **Accept match** - "Accept and move [filename] to folder?"
- **Reject match** - "Reject match for [filename]?"

All confirmations show:
- ⚠️ Warning icon
- Clear message with filename
- "Cancel" button (gray)
- "Yes, Continue" button (red)

## 🔗 Link Structure (All Relative)

### From admin/individuals.php
- `individual.php?id=123` → Detail page for individual
- `unknown.php` → Unknown clips page
- `actions/update_star.php` → AJAX star update

### From admin/individual.php
- `individuals.php` → Back to list
- `actions/move_to_unknown.php` → Move clip
- `actions/delete_clip.php` → Delete clip
- `actions/set_default_thumbnail.php` → Set default
- `actions/accept_match.php` → Accept AI match
- `actions/reject_match.php` → Reject AI match

All action handlers are in `actions/` subdirectory, accessed via relative paths.

## 🎯 Features Implemented

### admin/individuals.php
✅ Grid layout with alphabet ruler
✅ Clickable star ratings (no confirmation)
✅ Star filter (All/Red/Yellow/Blue/None)
✅ Tag filter
✅ Search by name
✅ Tag display on cards
✅ Link to individual detail page
✅ "Unknown" card links to unknown.php
✅ Red admin theme
✅ Mobile responsive

### admin/individual.php
✅ Large profile thumbnail (200x300px)
✅ Clickable star rating (no confirmation)
✅ Stats: Folder clips, Duration, AI matches
✅ Tag display

**Section 1: Folder Files**
✅ Sortable table (filename, duration, dimensions, date)
✅ Thumbnail preview
✅ Click filename to open video
✅ Show folder path
✅ Tag badges
✅ Three action buttons:
  - **Unknown** - Move to unknown (confirmation)
  - **Delete** - Delete clip (confirmation)
  - **Default** - Set as profile pic (no confirmation, shows ★ DEFAULT when active)

**Section 2: AI Match Suggestions**
✅ Shows pending AI matches
✅ Confidence badges (color-coded)
  - Green: 80%+ (high confidence)
  - Yellow: 60-79% (medium confidence)
  - Red: <60% (low confidence)
✅ Thumbnail preview
✅ Click filename to open video
✅ Show folder path
✅ Tag badges
✅ Three action buttons:
  - **Accept** - Move to folder (confirmation)
  - **Reject** - Add to error list (confirmation)
  - **Delete** - Delete clip (confirmation)

## 🚀 How It Works

### File Movement
When accepting a match or moving to unknown:
1. Physical file is moved (not copied)
2. Database `filepath` updated
3. Database `clip_type` updated
4. Database `folder_person` updated
5. Page reloads to show changes

### File Deletion
When deleting a clip:
1. Physical video file deleted
2. Thumbnail file deleted
3. Mosaic file deleted
4. Database record deleted
5. Cascade deletes handle related records:
   - `face_profiles` (CASCADE DELETE)
   - `clip_individuals` (CASCADE DELETE)
   - `clip_tags` (CASCADE DELETE)
   - `known_error_matches` (CASCADE DELETE)

### Match Rejection
When rejecting an AI match:
1. Record added to `known_error_matches`
2. Match won't appear again
3. Clip stays in unknown folder
4. User can still manually assign later

## ⚠️ Important Notes

### Path Configuration
Make sure your `config.php` has correct paths:
```php
define('KNOWN_DIR', __DIR__ . '/videos/known');
define('UNKNOWN_DIR', __DIR__ . '/videos/unknown');
define('THUMBNAILS_DIR', __DIR__ . '/thumbnails');
define('MOSAICS_DIR', __DIR__ . '/mosaics');
```

### File Permissions
Ensure PHP can:
- Read/write to `videos/known/` and `videos/unknown/`
- Create subdirectories (for new individuals, YYYYMM folders)
- Delete files (for clip deletion)

### Database CASCADE
Verify your database has CASCADE DELETE on foreign keys:
```sql
FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE
```

## 🐛 Troubleshooting

### Actions not working
- Check `admin/actions/` directory exists
- Verify file permissions (644)
- Check browser console for JavaScript errors
- Verify AJAX URLs are correct (relative paths)

### Files not moving
- Check directory permissions (755)
- Verify PHP has write access
- Check `KNOWN_DIR` and `UNKNOWN_DIR` in config.php
- Look for PHP errors in server logs

### Confirmations not showing
- Check modal HTML is present
- Verify JavaScript is not blocked
- Check browser console for errors
- Test with simple alert() first

## 📋 Next Steps

To complete the admin section, still need to build:
1. **admin/matches.php** - Review all AI matches across all individuals
2. **admin/unknown.php** - Bulk assign unknown clips to individuals
3. **admin/duplicates.php** - Find and remove duplicate clips

All patterns and components are established. These pages will use the same:
- Red admin theme
- Confirmation modals for destructive actions
- AJAX action handlers
- Relative paths
- Mobile-responsive design

## ✨ Current Status

**2 of 5 admin pages complete** (40%)
**6 of 6 action handlers complete** (100%)

The core file management functionality is fully operational. Individual page management is complete with all CRUD operations working.
