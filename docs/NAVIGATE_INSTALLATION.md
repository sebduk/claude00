# Navigate Section - Installation Guide

## ✅ Files Created

### Core Files (place in project root)
- `config.php` - Shared configuration
- `navbar.php` - Navigation component
- `database_schema_v2.sql` - New database schema
- `migrate_database.sql` - Database upgrade script

### Navigate Section Files (place in /navigate/ folder)
- `navigate_individuals.php` → save as `/navigate/individuals.php`
- `navigate_individual.php` → save as `/navigate/individual.php`

## 📁 Directory Structure

Create this structure:
```
your-project/
├── config.php
├── navbar.php
├── face_recognition.db
├── videos/
│   ├── known/
│   └── unknown/
├── thumbnails/
├── mosaics/
└── navigate/
    ├── individuals.php
    └── individual.php
```

## 🔧 Installation Steps

### Step 1: Upgrade Database
Run the migration to add tags and star ratings:
```bash
sqlite3 face_recognition.db < migrate_database.sql
```

This adds:
- ✅ `star_rating` column to `individuals` table
- ✅ `tags` table
- ✅ `individual_tags` table
- ✅ `clip_tags` table
- ✅ All necessary indexes
- ✅ 8 default tags

### Step 2: Place Files
1. Copy `config.php` to project root
2. Copy `navbar.php` to project root
3. Create `/navigate/` directory
4. Copy `navigate_individuals.php` to `/navigate/individuals.php`
5. Copy `navigate_individual.php` to `/navigate/individual.php`

### Step 3: Update config.php Paths
Edit `config.php` and verify these paths match your setup:
```php
define('DB_PATH', __DIR__ . '/face_recognition.db');
define('KNOWN_DIR', __DIR__ . '/videos/known');
define('UNKNOWN_DIR', __DIR__ . '/videos/unknown');
define('THUMBNAILS_DIR', __DIR__ . '/thumbnails');
define('MOSAICS_DIR', __DIR__ . '/mosaics');
```

### Step 4: Fix File Paths in PHP
Both navigate pages reference files with `/` prefix. Update if needed:
- Thumbnails: `/<?= $thumbnail_path ?>` → adjust if stored elsewhere
- Videos: `/<?= $filepath ?>` → adjust based on your structure

### Step 5: Test
1. Navigate to: `http://localhost/navigate/individuals.php`
2. You should see:
   - All individuals in a grid
   - "Unknown" card (if you have unknown clips)
   - Alphabet ruler on the right
   - Star ratings and tags
   - Filters for stars and tags

## 🎨 Features Included

### individuals.php
✅ Responsive grid layout (1-4 columns based on screen size)
✅ Alphabet ruler (A-Z navigation)
✅ Star rating display (red/yellow/blue)
✅ Tag badges with colors
✅ Filters: Star rating, Tags
✅ Sort: Star (desc), Name (asc)
✅ Special "Unknown" virtual individual
✅ Mobile-friendly (hamburger menu)
✅ Dark mode toggle

### individual.php
✅ Individual header with star rating
✅ Statistics (clip count, total duration, total size)
✅ Tag display
✅ Sortable table:
  - Filename (default)
  - Duration
  - Dimensions
  - File Date
  - File Size
✅ Click thumbnail to open video in new tab
✅ Show folder path
✅ Tag badges on clips
✅ Back to list button

## 🎨 Color Scheme

Navigate uses **blue theme**:
- Primary: #3498db
- Secondary: #2c3e50
- Accent: #1abc9c

Light/Dark mode supported (toggle in navbar)

## 🔄 Integration with Existing System

### Compatible with current database
All existing data preserved. New columns/tables added:
- `individuals.star_rating` (defaults to 0)
- `tags`, `individual_tags`, `clip_tags`

### No conflicts
- Uses shared `config.php`
- References existing thumbnails/videos
- Works with current folder structure

## 🐛 Troubleshooting

### Images not showing
1. Check file paths in `config.php`
2. Verify thumbnails exist in `/thumbnails/` directory
3. Check file permissions (readable by web server)

### Database errors
1. Ensure migration ran successfully
2. Check `face_recognition.db` has write permissions
3. Verify SQLite extension is enabled in PHP

### Alphabet ruler not working
1. JavaScript errors? Check browser console
2. Ensure individuals exist with those letters
3. Try smooth scroll polyfill if needed

### Dark mode not saving
1. Check cookies are enabled
2. Verify browser allows cookies
3. Cookie expires in 1 year (can adjust)

## 📱 Responsive Breakpoints

- Mobile (< 768px): 1 column, hamburger menu, no alphabet ruler
- Tablet (768-1024px): 2 columns
- Laptop (1025-1440px): 3 columns
- Desktop (> 1440px): 4 columns

## 🚀 Next Steps

After Navigate section is working, build Admin section:
1. admin/individuals.php (editable stars/tags)
2. admin/individual.php (file management)
3. admin/matches.php (AI match review)
4. admin/unknown.php (bulk assign clips)
5. admin/duplicates.php (find duplicates)

## 📝 Notes

- Read-only section (no edit capabilities)
- Perfect for browsing/viewing
- Admin section will add management features
- All confirmation dialogs in Admin only
- Navigate = Blue, Admin = Red (as specified)
