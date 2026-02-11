# FaceRec Repository - Code Analysis Report

## Overview

This report provides a comprehensive analysis of the FaceRec repository, identifying missing files, broken references, unused/obsolete files, schema drift, and code quality issues.

**Total files analyzed:** 59 files (16 Python, 32 PHP, 1 SQL schema, 1 README, 9 docs)

---

## 1. MISSING FILES (referenced but don't exist)

### 1.1 `database_schema.sql` -- HIGH SEVERITY
- **Referenced by:** `db_manager.py` line 37
- **What exists instead:** `database_schema_v2.sql`
- **Impact:** `db_manager.py` tries to auto-initialize the database from `database_schema.sql`. Because the file was renamed to `database_schema_v2.sql` without updating the code, schema auto-initialization silently fails (the code does `if schema_file.exists()` and skips if missing). New installations would get an empty database with no tables.

### 1.2 `index.php` -- MEDIUM SEVERITY
- **Referenced by:** `README.md` (lines 284-289) lists `index.php` as the main gallery page
- **Does not exist** in the repository
- **Impact:** README is outdated. The web interface has been restructured into `admin/` and `navigate/` sections but README still references the old single-page structure.

### 1.3 `requirements.txt` -- LOW SEVERITY
- **Referenced by:** `README.md` line 51 (`pip install -r requirements.txt`)
- **Does not exist** in the repository
- **Impact:** Users cannot install dependencies via `pip install -r requirements.txt`. The README inline-lists the dependencies but the actual file is missing.

### 1.4 `navigate/actions/` directory -- HIGH SEVERITY
- **Referenced by:** `navigate/individual.php` JavaScript fetch calls
- **Does not exist** -- only `admin/actions/` exists
- **Impact:** The navigate individual detail page has 6 action buttons (star toggle, move-to-unknown, delete clip, set default thumbnail, accept match, reject match) that make fetch requests to relative paths like `actions/update_star.php`. These resolve to `navigate/actions/...` which doesn't exist. All action buttons on this page return 404 errors.

---

## 2. UNUSED / POTENTIALLY OBSOLETE FILES

### 2.1 `navigate/navigate_path_diagnostic.php` -- ORPHAN
- Not linked from any page, not in the navbar, not referenced in any documentation
- Appears to be a developer debug tool created during development
- Also lacks XSS sanitization (outputs raw DB values without `htmlspecialchars()`)
- **Recommendation:** Remove or move to a `tools/` directory

### 2.2 `docs/` documentation files -- PARTIALLY STALE
The following 14 documentation files exist in `docs/`:
- `ADMIN_IMPLEMENTATION_STATUS.md`
- `ADMIN_INSTALLATION_GUIDE.md`
- `AI_MATCHES_ENHANCED.md`
- `COMPLETE_FIXES_SUMMARY.md`
- `FIX_MACOS_NUMPY.md`
- `FORCE_REMATCH_FEATURE_README.md`
- `HANDLING_CORRUPTED_FILES.md`
- `IMPLEMENTATION_PROGRESS.md`
- `MAIN_PIPELINE.md`
- `MANAGING_MATCHES.md`
- `MATCH_DENIAL_DOCUMENTATION.md`
- `NAVIGATE_INSTALLATION.md`
- `PARALLEL_PROCESSING.md`
- `THUMBNAIL_TUNING.md`
- `project_readme.md`

Several of these (`IMPLEMENTATION_PROGRESS.md`, `COMPLETE_FIXES_SUMMARY.md`, `ADMIN_IMPLEMENTATION_STATUS.md`) appear to be development progress logs rather than permanent documentation.

### 2.3 `README.md` -- OUTDATED
The README references:
- `database_schema.sql` (renamed to `database_schema_v2.sql`)
- `index.php` (replaced by admin/navigate structure)
- `requirements.txt` (doesn't exist)
- Does not mention the admin/navigate web architecture, tags, star ratings, parallel pipeline, or any utility scripts

---

## 3. BUGS AND CODE ISSUES

### 3.1 `manage_clips.py` -- `unbind_all_matches_for_clip` undefined -- HIGH
- **Line 504** calls `unbind_all_matches_for_clip(args.db, args.clip_id)` which is never defined
- **Lines 312-366** contain the function body but it's trapped inside `unlink_known_clip()` as dead code after a `return True` on line 311
- **Impact:** The `unbind-all` CLI subcommand will crash with `NameError`

### 3.2 `navigate/individual.php` -- broken action paths -- HIGH
- JavaScript fetch calls use relative `actions/...` paths
- These resolve to `navigate/actions/` which doesn't exist (actions are under `admin/actions/`)
- All 6 action buttons (star, move-to-unknown, delete, set-default, accept, reject) fail silently

### 3.3 `video_processor.py` -- dead import -- LOW
- Line 12: `from PIL import Image` is imported but never used anywhere in the file

### 3.4 `verify_system.py` -- inconsistent db_path -- LOW
- `check_duplicate_matches()` on line 227 hardcodes `DatabaseManager()` with no argument
- Ignores any `--db` parameter the user passes via CLI

### 3.5 `individuals.num_clips` never updated -- MEDIUM
- The `individuals` table has a `num_clips` column (default 0)
- No Python code ever updates this column
- `diagnose_missing_clips.py` reads `ind['num_clips']` expecting accurate data, but it's always 0
- Makes the diagnostic report's per-individual clip count comparison meaningless

### 3.6 `config.py` constants largely unused -- LOW
- Defines `DATABASE_PATH`, `KNOWN_VIDEOS_DIR`, `UNKNOWN_VIDEOS_DIR`, `FACE_MATCH_THRESHOLD`, `PARALLEL_WORKERS`, `MOSAIC_INTERVAL_SECONDS`
- Only `video_processor.py` imports from `config.py` (thumbnail/face detection constants)
- All other files hardcode their own defaults (`"face_recognition.db"`, `"videos/known"`, etc.)

---

## 4. SCHEMA DRIFT

### 4.1 `dismissed_duplicates` table -- NOT in schema
- Created dynamically inside `admin/actions/dismiss_duplicate.php` and `admin/duplicates.php` via `CREATE TABLE IF NOT EXISTS`
- **NOT defined** in `database_schema_v2.sql`
- If the schema is ever re-applied from scratch, this table would be missing until the duplicates page is first loaded

---

## 5. CODE DUPLICATION

### 5.1 `parallel_pipeline.py` vs `main_pipeline.py`
Both implement the full pipeline (sync, regenerate, process, build-profiles, match, stats) with the same imports and CLI structure. `parallel_pipeline.py` adds multiprocessing but re-implements all logic rather than importing from `main_pipeline.py`. Changes must be replicated in both files.

### 5.2 `force_rematch_individual.py` vs `face_matcher.py`
`force_rematch_individual.py` reimplements face matching logic (Euclidean distance, threshold) using raw sqlite3 instead of importing `FaceMatcher`.

### 5.3 `Find clusters.py` vs `face_matcher.find_similar_unknown_faces()`
`Find clusters.py` reimplements face clustering (pairwise distance) that already exists in `FaceMatcher`. Exists separately to output JSON for PHP consumption.

### 5.4 `cleanup_database.py` and `force_rematch_individual.py` bypass `db_manager.py`
Both use raw `sqlite3` directly instead of the `DatabaseManager` class. This creates maintenance burden if the schema changes.

---

## 6. PLATFORM-SPECIFIC ISSUES

### 6.1 `admin/actions/force_rematch_individual.php`
- Hardcodes macOS Python site-packages paths (`/Users/`, `Library/Python/`)
- Irrelevant on Linux systems
- Not a crash bug but adds unnecessary path entries

---

## 7. FILE INVENTORY

### Core Library Modules (5 files)
| File | Purpose | Imported by |
|------|---------|-------------|
| `config.py` | Configuration constants | `video_processor.py` |
| `db_manager.py` | Database operations (ORM-like) | 8 other Python files |
| `video_processor.py` | Video processing, thumbnails, mosaics | 4 files |
| `face_matcher.py` | Face recognition and matching | 3 files |
| `filesystem_sync.py` | File system sync | 2 files |

### Pipeline Entry Points (2 files)
| File | Purpose |
|------|---------|
| `main_pipeline.py` | Sequential processing pipeline (CLI) |
| `parallel_pipeline.py` | Parallel processing pipeline (CLI) |

### CLI Utilities (4 files)
| File | Purpose |
|------|---------|
| `manage_clips.py` | Clip-to-individual management |
| `cleanup_database.py` | Database maintenance/cleanup |
| `fix_missing_links.py` | Fix broken clip-individual links |
| `force_rematch_individual.py` | Re-run matching for one individual |

### Diagnostic Tools (3 files)
| File | Purpose |
|------|---------|
| `check_corrupted_videos.py` | Detect and quarantine corrupted videos |
| `diagnose_missing_clips.py` | Find clips missing from disk or DB |
| `verify_system.py` | System health verification |

### PHP-callable Scripts (2 files)
| File | Purpose |
|------|---------|
| `Find clusters.py` | Output face clusters as JSON |
| `Find duplicates.py` | Output duplicate individuals as JSON |

### PHP Web Interface
| Section | Files | Purpose |
|---------|-------|---------|
| Shared | `config.php`, `navbar.php` | DB connection, navigation, utilities |
| Admin Pages | 9 files in `admin/` | Full CRUD management interface |
| Admin Actions | 18 files in `admin/actions/` | AJAX API endpoints |
| Navigate Pages | 4 files in `navigate/` | Read-only browsing interface |

### Schema & Documentation
| File | Purpose |
|------|---------|
| `database_schema_v2.sql` | Database schema (8 tables, 1 view) |
| `README.md` | Project README (outdated) |
| `docs/` (14 files) | Feature documentation and guides |

---

## 8. SUMMARY OF RECOMMENDED ACTIONS

### Critical (breaks functionality)
1. Fix `db_manager.py` to reference `database_schema_v2.sql` instead of `database_schema.sql`
2. Fix `navigate/individual.php` action paths to point to `../admin/actions/` instead of `actions/`
3. Fix `manage_clips.py` to properly define `unbind_all_matches_for_clip` as a top-level function

### Important (data integrity / correctness)
4. Add `dismissed_duplicates` table to `database_schema_v2.sql`
5. Either update `individuals.num_clips` in the Python pipeline or remove the column
6. Add `requirements.txt` to the repository

### Maintenance (code quality)
7. Update `README.md` to reflect the current admin/navigate architecture
8. Remove or relocate `navigate/navigate_path_diagnostic.php`
9. Remove dead import (`PIL.Image`) from `video_processor.py`
10. Consolidate `config.py` usage -- either use it everywhere or remove unused constants
