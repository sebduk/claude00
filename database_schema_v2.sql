-- Face Recognition Project Database Schema v2
-- SQLite database structure for managing video clips and face profiles
-- NEW: Tags system and star ratings

-- Table: clips
-- Stores metadata for each video clip
CREATE TABLE IF NOT EXISTS clips (
    clip_id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,                    -- Original filename (e.g., "meeting_2024.mp4")
    filepath TEXT NOT NULL UNIQUE,             -- Full path relative to project root
    filesize INTEGER,                          -- File size in bytes
    file_date TEXT,                            -- File modification date (ISO 8601 format)
    width INTEGER,                             -- Video width in pixels
    height INTEGER,                            -- Video height in pixels
    diagonal_size REAL,                        -- Diagonal size in pixels (calculated)
    duration REAL,                             -- Duration in seconds
    duration_text TEXT,                        -- Duration in HH:MM:SS format
    thumbnail_path TEXT,                       -- Path to primary thumbnail image
    mosaic_path TEXT,                          -- Path to mosaic screenshot image
    clip_type TEXT CHECK(clip_type IN ('known', 'unknown')),  -- Classification
    folder_person TEXT,                        -- Person name from folder (for known clips)
    date_added TEXT DEFAULT CURRENT_TIMESTAMP, -- When added to database
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Table: individuals
-- Stores information about known individuals
CREATE TABLE IF NOT EXISTS individuals (
    individual_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,                 -- Person's name (from folder name)
    profile_created TEXT,                      -- Timestamp of profile creation
    num_clips INTEGER DEFAULT 0,               -- Count of clips featuring this person
    default_thumbnail_clip_id INTEGER,         -- Clip ID for default thumbnail
    notes TEXT,                                -- Optional notes about the individual
    star_rating INTEGER DEFAULT 0,             -- Star rating: 0=none, 1=blue, 2=yellow, 3=red
    FOREIGN KEY (default_thumbnail_clip_id) REFERENCES clips(clip_id) ON DELETE SET NULL
);

-- Table: face_profiles
-- Stores face encoding data for each detected face in each clip
CREATE TABLE IF NOT EXISTS face_profiles (
    profile_id INTEGER PRIMARY KEY AUTOINCREMENT,
    clip_id INTEGER NOT NULL,                  -- Which clip this face was found in
    face_encoding BLOB NOT NULL,               -- face_recognition 128-d encoding (pickled)
    face_location TEXT,                        -- JSON: {"top": y, "right": x, "bottom": y, "left": x}
    confidence REAL,                           -- Detection confidence score
    is_primary BOOLEAN DEFAULT 0,              -- Is this the primary face for thumbnail?
    individual_id INTEGER,                     -- Link to known individual (NULL if unknown)
    match_confidence REAL,                     -- Confidence of match to individual
    date_created TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
    FOREIGN KEY (individual_id) REFERENCES individuals(individual_id) ON DELETE SET NULL
);

-- Table: clip_individuals
-- Many-to-many relationship: which individuals appear in which clips
CREATE TABLE IF NOT EXISTS clip_individuals (
    clip_id INTEGER NOT NULL,
    individual_id INTEGER NOT NULL,
    confidence REAL,                           -- Average match confidence for this person in clip
    PRIMARY KEY (clip_id, individual_id),
    FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
    FOREIGN KEY (individual_id) REFERENCES individuals(individual_id) ON DELETE CASCADE
);

-- Table: known_error_matches
-- Stores known false positive matches to prevent them from reappearing
CREATE TABLE IF NOT EXISTS known_error_matches (
    error_id INTEGER PRIMARY KEY AUTOINCREMENT,
    clip_id INTEGER NOT NULL,
    individual_id INTEGER NOT NULL,
    date_added TEXT DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,                                -- Optional note about why this is a false positive
    UNIQUE(clip_id, individual_id),
    FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
    FOREIGN KEY (individual_id) REFERENCES individuals(individual_id) ON DELETE CASCADE
);

-- Table: tags
-- Stores tag definitions
CREATE TABLE IF NOT EXISTS tags (
    tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL UNIQUE,             -- Tag name (e.g., "Family", "Work")
    tag_color TEXT DEFAULT '#3498db',          -- Hex color for display
    tag_type TEXT CHECK(tag_type IN ('individual', 'clip', 'both')) DEFAULT 'both',
    created_date TEXT DEFAULT CURRENT_TIMESTAMP,
    notes TEXT                                 -- Optional description
);

-- Table: individual_tags
-- Many-to-many: tags assigned to individuals
CREATE TABLE IF NOT EXISTS individual_tags (
    individual_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    date_added TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (individual_id, tag_id),
    FOREIGN KEY (individual_id) REFERENCES individuals(individual_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

-- Table: clip_tags
-- Many-to-many: tags assigned to clips
CREATE TABLE IF NOT EXISTS clip_tags (
    clip_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    date_added TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (clip_id, tag_id),
    FOREIGN KEY (clip_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_clips_filepath ON clips(filepath);
CREATE INDEX IF NOT EXISTS idx_clips_type ON clips(clip_type);
CREATE INDEX IF NOT EXISTS idx_clips_person ON clips(folder_person);
CREATE INDEX IF NOT EXISTS idx_clips_date ON clips(file_date);
CREATE INDEX IF NOT EXISTS idx_face_profiles_clip ON face_profiles(clip_id);
CREATE INDEX IF NOT EXISTS idx_face_profiles_individual ON face_profiles(individual_id);
CREATE INDEX IF NOT EXISTS idx_clip_individuals_clip ON clip_individuals(clip_id);
CREATE INDEX IF NOT EXISTS idx_clip_individuals_individual ON clip_individuals(individual_id);
CREATE INDEX IF NOT EXISTS idx_known_error_matches_clip ON known_error_matches(clip_id);
CREATE INDEX IF NOT EXISTS idx_known_error_matches_individual ON known_error_matches(individual_id);
CREATE INDEX IF NOT EXISTS idx_individuals_star ON individuals(star_rating);
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(tag_name);
CREATE INDEX IF NOT EXISTS idx_individual_tags_individual ON individual_tags(individual_id);
CREATE INDEX IF NOT EXISTS idx_individual_tags_tag ON individual_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_clip_tags_clip ON clip_tags(clip_id);
CREATE INDEX IF NOT EXISTS idx_clip_tags_tag ON clip_tags(tag_id);

-- View: clip_summary
-- Convenient view joining clips with individual associations
CREATE VIEW IF NOT EXISTS clip_summary AS
SELECT 
    c.clip_id,
    c.filename,
    c.filepath,
    c.filesize,
    c.file_date,
    c.width,
    c.height,
    c.diagonal_size,
    c.duration,
    c.thumbnail_path,
    c.mosaic_path,
    c.clip_type,
    c.folder_person,
    GROUP_CONCAT(DISTINCT i.name, ', ') AS individuals,
    COUNT(DISTINCT fp.profile_id) AS num_faces,
    GROUP_CONCAT(DISTINCT t.tag_name, ', ') AS tags
FROM clips c
LEFT JOIN face_profiles fp ON c.clip_id = fp.clip_id
LEFT JOIN individuals i ON fp.individual_id = i.individual_id
LEFT JOIN clip_tags ct ON c.clip_id = ct.clip_id
LEFT JOIN tags t ON ct.tag_id = t.tag_id
GROUP BY c.clip_id;
