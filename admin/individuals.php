<?php
/**
 * Admin - Individuals Page
 * Editable individuals grid with star ratings and tag management
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get filter parameters
$star_filter = isset($_GET['star']) ? intval($_GET['star']) : -1;
$tag_filter = isset($_GET['tag']) ? intval($_GET['tag']) : null;
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$sort_by = isset($_GET['sort_by']) && in_array($_GET['sort_by'], ['name', 'stars']) ? $_GET['sort_by'] : 'stars';

// Build WHERE clause
$where = [];
$params = [];

if ($star_filter >= 0) {
    $where[] = "i.star_rating = :star_filter";
    $params[':star_filter'] = $star_filter;
}

if ($tag_filter) {
    // Include individuals if:
    // 1. They have the tag directly on their profile, OR
    // 2. Any of their known clips have the tag, OR
    // 3. Any of their unknown AI-matched clips have the tag
    $where[] = "(
        EXISTS (
            SELECT 1 FROM individual_tags it 
            WHERE it.individual_id = i.individual_id AND it.tag_id = :tag_filter
        )
        OR EXISTS (
            SELECT 1 FROM clips c
            JOIN clip_tags ct ON c.clip_id = ct.clip_id
            WHERE c.folder_person = i.name 
            AND c.clip_type = 'known'
            AND ct.tag_id = :tag_filter
        )
        OR EXISTS (
            SELECT 1 FROM clip_individuals ci
            JOIN clips c ON ci.clip_id = c.clip_id
            JOIN clip_tags ct ON c.clip_id = ct.clip_id
            WHERE ci.individual_id = i.individual_id
            AND c.clip_type = 'unknown'
            AND ct.tag_id = :tag_filter
        )
    )";
    $params[':tag_filter'] = $tag_filter;
}

if ($search) {
    $where[] = "i.name LIKE :search";
    $params[':search'] = '%' . $search . '%';
}

$where_sql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Build ORDER BY based on sort choice
if ($sort_by === 'name') {
    $order_sql = "ORDER BY i.name ASC";
} else {
    $order_sql = "ORDER BY i.star_rating DESC, i.name ASC";
}

// Get all individuals
$sql = "
    SELECT 
        i.*,
        (SELECT COUNT(*) FROM clips c WHERE c.folder_person = i.name AND c.clip_type = 'known') as folder_clip_count,
        (SELECT COUNT(DISTINCT ci.clip_id) FROM clip_individuals ci 
         JOIN clips c ON ci.clip_id = c.clip_id 
         WHERE ci.individual_id = i.individual_id AND c.clip_type = 'unknown'
         AND NOT EXISTS (
             SELECT 1 FROM known_error_matches kem 
             WHERE kem.clip_id = ci.clip_id AND kem.individual_id = ci.individual_id
         )) as ai_match_count,
        (SELECT c2.thumbnail_path FROM clips c2 WHERE c2.clip_id = i.default_thumbnail_clip_id) as default_thumbnail
    FROM individuals i
    $where_sql
    $order_sql
";

$stmt = $db->prepare($sql);
foreach ($params as $key => $value) {
    $stmt->bindValue($key, $value);
}
$stmt->execute();
$individuals = $stmt->fetchAll();

// Get tags for each individual
foreach ($individuals as &$individual) {
    $tag_stmt = $db->prepare("
        SELECT t.* FROM tags t
        JOIN individual_tags it ON t.tag_id = it.tag_id
        WHERE it.individual_id = ?
        ORDER BY t.tag_name
    ");
    $tag_stmt->execute([$individual['individual_id']]);
    $individual['tags'] = $tag_stmt->fetchAll();
    
    // If filtering by tag, get match details
    if ($tag_filter) {
        // Count known clips with this tag
        $known_tagged_stmt = $db->prepare("
            SELECT COUNT(*) as count
            FROM clips c
            JOIN clip_tags ct ON c.clip_id = ct.clip_id
            WHERE c.folder_person = ? 
            AND c.clip_type = 'known'
            AND ct.tag_id = ?
        ");
        $known_tagged_stmt->execute([$individual['name'], $tag_filter]);
        $individual['known_tagged_count'] = $known_tagged_stmt->fetch()['count'];
        
        // Count unknown clips with this tag
        $unknown_tagged_stmt = $db->prepare("
            SELECT COUNT(DISTINCT c.clip_id) as count
            FROM clip_individuals ci
            JOIN clips c ON ci.clip_id = c.clip_id
            JOIN clip_tags ct ON c.clip_id = ct.clip_id
            WHERE ci.individual_id = ?
            AND c.clip_type = 'unknown'
            AND ct.tag_id = ?
        ");
        $unknown_tagged_stmt->execute([$individual['individual_id'], $tag_filter]);
        $individual['unknown_tagged_count'] = $unknown_tagged_stmt->fetch()['count'];
    }
}
unset($individual);

// Get all tags for filters (all types since we filter by individual tags AND clip tags)
$all_tags = $db->query("SELECT * FROM tags ORDER BY tag_name")->fetchAll();

// Get statistics
$stats = $db->query("
    SELECT 
        COUNT(*) as total_individuals,
        SUM(CASE WHEN star_rating = 3 THEN 1 ELSE 0 END) as red_stars,
        SUM(CASE WHEN star_rating = 2 THEN 1 ELSE 0 END) as yellow_stars,
        SUM(CASE WHEN star_rating = 1 THEN 1 ELSE 0 END) as blue_stars,
        SUM(CASE WHEN star_rating = 0 THEN 1 ELSE 0 END) as no_stars
    FROM individuals
")->fetch();

$unknown_count = $db->query("SELECT COUNT(*) FROM clips WHERE clip_type = 'unknown'")->fetchColumn();

// Generate alphabet counts (only unstarred individuals)
$alphabet = range('A', 'Z');
$alphabet[] = 'ZZ'; // Add zz-xxx section
$alphabet_counts = [];
foreach ($alphabet as $letter) {
    if ($letter === 'ZZ') {
        // Count zz-xxx individuals
        $count = $db->prepare("SELECT COUNT(*) FROM individuals WHERE name LIKE 'zz-%' AND star_rating = 0");
        $count->execute();
    } else {
        $count = $db->prepare("SELECT COUNT(*) FROM individuals WHERE UPPER(name) LIKE ? AND star_rating = 0 AND name NOT LIKE 'zz-%'");
        $count->execute([$letter . '%']);
    }
    $alphabet_counts[$letter] = $count->fetchColumn();
}

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Individuals - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
            padding-bottom: 40px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
            display: flex;
            gap: 20px;
        }
        
        .main-content { flex: 1; min-width: 0; }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header h1 { color: var(--primary-color); margin-bottom: 15px; }
        
        .stats-row {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            margin-top: 15px;
        }
        
        .stat-badge {
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 600;
            background: var(--background-color);
        }
        
        .filters {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .filters-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-group label { font-size: 13px; font-weight: 600; color: #666; }
        .filter-group select, .filter-group input {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        .filter-actions { display: flex; gap: 10px; }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        
        .btn-primary { background: var(--primary-color); color: white; }
        .btn-primary:hover { opacity: 0.9; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-secondary:hover { background: #7f8c8d; }
        
        .individuals-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .individual-card {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
            position: relative;
        }
        
        .individual-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        
        .individual-thumbnail {
            width: 100%;
            height: 300px;
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 72px;
            font-weight: bold;
            position: relative;
        }
        
        .individual-thumbnail img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .star-overlay {
            position: absolute;
            top: 10px;
            right: 10px;
            font-size: 32px;
            cursor: pointer;
            text-shadow: 0 2px 4px rgba(0,0,0,0.5);
            transition: transform 0.2s;
        }
        
        .star-overlay:hover {
            transform: scale(1.2);
        }
        
        .individual-info { padding: 15px; }
        
        .individual-name {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 8px;
            color: var(--text-color);
        }
        
        .individual-name a {
            color: var(--primary-color);
            text-decoration: none;
        }
        
        .individual-name a:hover {
            text-decoration: underline;
        }
        
        .individual-stats {
            font-size: 14px;
            color: #666;
            margin-bottom: 8px;
        }
        
        .tags-container {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
            margin-top: 8px;
        }
        
        .tag-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            color: white;
        }
        
        /* Alphabet Ruler */
        .alphabet-ruler {
            position: sticky;
            top: 80px;
            width: 50px;
            background: white;
            padding: 15px 10px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            max-height: calc(100vh - 100px);
            overflow-y: auto;
        }
        
        .star-nav {
            display: block;
            width: 30px;
            height: 30px;
            line-height: 30px;
            text-align: center;
            margin: 2px 0;
            border-radius: 4px;
            text-decoration: none;
            font-size: 18px;
            transition: all 0.2s;
        }
        
        .star-nav-red {
            color: #e74c3c;
        }
        
        .star-nav-red:hover {
            background: #e74c3c;
            color: white;
        }
        
        .star-nav-yellow {
            color: #f1c40f;
        }
        
        .star-nav-yellow:hover {
            background: #f1c40f;
            color: white;
        }
        
        .star-nav-blue {
            color: #3498db;
        }
        
        .star-nav-blue:hover {
            background: #3498db;
            color: white;
        }
        
        .ruler-divider {
            height: 2px;
            background: #ecf0f1;
            margin: 10px 0;
        }
        
        .star-section-anchor {
            height: 0;
            visibility: hidden;
        }
        
        .alphabet-letter {
            display: block;
            width: 30px;
            height: 30px;
            line-height: 30px;
            text-align: center;
            margin: 2px 0;
            border-radius: 4px;
            text-decoration: none;
            color: var(--text-color);
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s;
        }
        
        .alphabet-letter:hover { background: var(--primary-color); color: white; }
        .alphabet-letter.disabled { color: #ccc; pointer-events: none; }
        
        .anchor-letter {
            scroll-margin-top: 80px;
            padding-top: 20px;
            margin-top: -20px;
        }
        
        .no-results {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 8px;
            color: #95a5a6;
        }
        
        /* Confirmation Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0,0,0,0.7);
            z-index: 10000;
            align-items: center;
            justify-content: center;
        }
        
        .modal.active { display: flex; }
        
        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            max-width: 500px;
            width: 90%;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        
        .modal-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 15px;
            color: var(--primary-color);
        }
        
        .modal-message {
            margin-bottom: 20px;
            line-height: 1.6;
        }
        
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        /* Mobile */
        @media (max-width: 767px) {
            .container { flex-direction: column; }
            .alphabet-ruler {
                position: static;
                width: 100%;
                display: flex;
                flex-wrap: wrap;
                justify-content: center;
                padding: 10px;
                margin-bottom: 20px;
            }
            .alphabet-letter { margin: 2px; }
            .individuals-grid { grid-template-columns: 1fr; }
            .filters-grid { grid-template-columns: 1fr; }
        }
        
        @media (min-width: 768px) and (max-width: 1024px) {
            .individuals-grid { grid-template-columns: repeat(2, 1fr); }
        }
        
        @media (min-width: 1441px) {
            .individuals-grid { grid-template-columns: repeat(4, 1fr); }
        }
    </style>
</head>
<body>
    <?php 
    // Helper function to display tag match info
    function getTagMatchInfo($individual, $tag_filter) {
        if (!$tag_filter) return '';
        
        $known_count = $individual['known_tagged_count'] ?? 0;
        $unknown_count = $individual['unknown_tagged_count'] ?? 0;
        
        if ($known_count == 0 && $unknown_count == 0) return '';
        
        $parts = [];
        if ($known_count > 0) $parts[] = "$known_count known";
        if ($unknown_count > 0) $parts[] = "$unknown_count unknown";
        
        return '<br>&#127991;&#65039; ' . implode(', ', $parts) . ' with tag';
    }
    ?>
    
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="main-content">
            <div class="header">
                <h1>&#128101; Individuals (<?= count($individuals) ?>)</h1>
                <div class="stats-row">
                    <div class="stat-badge">&#11088; Red: <?= $stats['red_stars'] ?></div>
                    <div class="stat-badge">&#11088; Yellow: <?= $stats['yellow_stars'] ?></div>
                    <div class="stat-badge">&#11088; Blue: <?= $stats['blue_stars'] ?></div>
                    <div class="stat-badge">&#9734; None: <?= $stats['no_stars'] ?></div>
                </div>
            </div>
            
            <div class="filters">
                <form method="GET">
                    <div class="filters-grid">
                        <div class="filter-group">
                            <label>Search</label>
                            <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="Search by name...">
                        </div>
                        <div class="filter-group">
                            <label>Sort By</label>
                            <select name="sort_by">
                                <option value="stars" <?= $sort_by === 'stars' ? 'selected' : '' ?>>Stars (High to Low)</option>
                                <option value="name" <?= $sort_by === 'name' ? 'selected' : '' ?>>Name (A to Z)</option>
                            </select>
                        </div>
                        <div class="filter-group">
                            <label>Star Rating</label>
                            <select name="star">
                                <option value="-1">All Stars</option>
                                <option value="3" <?= $star_filter === 3 ? 'selected' : '' ?>>&#11088; Red</option>
                                <option value="2" <?= $star_filter === 2 ? 'selected' : '' ?>>&#11088; Yellow</option>
                                <option value="1" <?= $star_filter === 1 ? 'selected' : '' ?>>&#11088; Blue</option>
                                <option value="0" <?= $star_filter === 0 ? 'selected' : '' ?>>&#9734; None</option>
                            </select>
                        </div>
                        <div class="filter-group">
                            <label>Tag</label>
                            <select name="tag">
                                <option value="">All Tags</option>
                                <?php foreach ($all_tags as $tag): ?>
                                    <option value="<?= $tag['tag_id'] ?>" <?= $tag_filter == $tag['tag_id'] ? 'selected' : '' ?>>
                                        <?= htmlspecialchars($tag['tag_name']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="filter-actions">
                        <button type="submit" class="btn btn-primary">Apply</button>
                        <a href="?" class="btn btn-secondary">Clear</a>
                    </div>
                </form>
            </div>
            
            <?php if (count($individuals) > 0): ?>
                <div class="individuals-grid">
                    <?php 
                    // Separate individuals into starred and unstarred
                    $starred = array_filter($individuals, fn($i) => $i['star_rating'] > 0);
                    $unstarred = array_filter($individuals, fn($i) => $i['star_rating'] == 0);
                    
                    // Group starred by rating (3=red, 2=yellow, 1=blue)
                    $red_starred = array_filter($starred, fn($i) => $i['star_rating'] == 3);
                    $yellow_starred = array_filter($starred, fn($i) => $i['star_rating'] == 2);
                    $blue_starred = array_filter($starred, fn($i) => $i['star_rating'] == 1);
                    ?>
                    
                    <?php if (count($red_starred) > 0): ?>
                        <div id="star-red" class="star-section-anchor"></div>
                        <?php foreach ($red_starred as $individual): ?>
                            <div class="individual-card">
                                <a href="individual.php?id=<?= $individual['individual_id'] ?>" style="text-decoration: none; color: inherit;">
                                    <div class="individual-thumbnail">
                                        <?php if (!empty($individual['default_thumbnail'])): ?>
                                            <img src="../<?= htmlspecialchars($individual['default_thumbnail']) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                                        <?php else: ?>
                                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                                        <?php endif; ?>
                                        
                                        <div class="star-overlay" 
                                             data-individual-id="<?= $individual['individual_id'] ?>"
                                             onclick="event.preventDefault(); event.stopPropagation(); toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)" 
                                             title="Click to change star rating">
                                            <?= getStarHTML($individual['star_rating'], false) ?>
                                        </div>
                                    </div>
                                </a>
                                
                                <div class="individual-info">
                                    <div class="individual-name">
                                        <a href="individual.php?id=<?= $individual['individual_id'] ?>">
                                            <?= htmlspecialchars($individual['name']) ?>
                                        </a>
                                    </div>
                                    <div class="individual-stats">
                                        &#128193; <?= $individual['folder_clip_count'] ?> clip<?= $individual['folder_clip_count'] != 1 ? 's' : '' ?>
                                        <?php if ($individual['ai_match_count'] > 0): ?>
                                            &#8226; &#129302; <?= $individual['ai_match_count'] ?> match<?= $individual['ai_match_count'] != 1 ? 'es' : '' ?>
                                        <?php endif; ?>
                                        <?= getTagMatchInfo($individual, $tag_filter) ?>
                                    </div>
                                    
                                    <?php if (!empty($individual['tags'])): ?>
                                        <?= getTagsHTML($individual['tags'], false) ?>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    
                    <?php if (count($yellow_starred) > 0): ?>
                        <div id="star-yellow" class="star-section-anchor"></div>
                        <?php foreach ($yellow_starred as $individual): ?>
                            <div class="individual-card">
                                <a href="individual.php?id=<?= $individual['individual_id'] ?>" style="text-decoration: none; color: inherit;">
                                    <div class="individual-thumbnail">
                                        <?php if (!empty($individual['default_thumbnail'])): ?>
                                            <img src="../<?= htmlspecialchars($individual['default_thumbnail']) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                                        <?php else: ?>
                                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                                        <?php endif; ?>
                                        
                                        <div class="star-overlay" 
                                             data-individual-id="<?= $individual['individual_id'] ?>"
                                             onclick="event.preventDefault(); event.stopPropagation(); toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)" 
                                             title="Click to change star rating">
                                            <?= getStarHTML($individual['star_rating'], false) ?>
                                        </div>
                                    </div>
                                </a>
                                
                                <div class="individual-info">
                                    <div class="individual-name">
                                        <a href="individual.php?id=<?= $individual['individual_id'] ?>">
                                            <?= htmlspecialchars($individual['name']) ?>
                                        </a>
                                    </div>
                                    <div class="individual-stats">
                                        &#128193; <?= $individual['folder_clip_count'] ?> clip<?= $individual['folder_clip_count'] != 1 ? 's' : '' ?>
                                        <?php if ($individual['ai_match_count'] > 0): ?>
                                            &#8226; &#129302; <?= $individual['ai_match_count'] ?> match<?= $individual['ai_match_count'] != 1 ? 'es' : '' ?>
                                        <?php endif; ?>
                                        <?= getTagMatchInfo($individual, $tag_filter) ?>
                                    </div>
                                    
                                    <?php if (!empty($individual['tags'])): ?>
                                        <?= getTagsHTML($individual['tags'], false) ?>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    
                    <?php if (count($blue_starred) > 0): ?>
                        <div id="star-blue" class="star-section-anchor"></div>
                        <?php foreach ($blue_starred as $individual): ?>
                            <div class="individual-card">
                                <a href="individual.php?id=<?= $individual['individual_id'] ?>" style="text-decoration: none; color: inherit;">
                                    <div class="individual-thumbnail">
                                        <?php if (!empty($individual['default_thumbnail'])): ?>
                                            <img src="../<?= htmlspecialchars($individual['default_thumbnail']) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                                        <?php else: ?>
                                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                                        <?php endif; ?>
                                        
                                        <div class="star-overlay" 
                                             data-individual-id="<?= $individual['individual_id'] ?>"
                                             onclick="event.preventDefault(); event.stopPropagation(); toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)" 
                                             title="Click to change star rating">
                                            <?= getStarHTML($individual['star_rating'], false) ?>
                                        </div>
                                    </div>
                                </a>
                                
                                <div class="individual-info">
                                    <div class="individual-name">
                                        <a href="individual.php?id=<?= $individual['individual_id'] ?>">
                                            <?= htmlspecialchars($individual['name']) ?>
                                        </a>
                                    </div>
                                    <div class="individual-stats">
                                        &#128193; <?= $individual['folder_clip_count'] ?> clip<?= $individual['folder_clip_count'] != 1 ? 's' : '' ?>
                                        <?php if ($individual['ai_match_count'] > 0): ?>
                                            &#8226; &#129302; <?= $individual['ai_match_count'] ?> match<?= $individual['ai_match_count'] != 1 ? 'es' : '' ?>
                                        <?php endif; ?>
                                    </div>
                                    
                                    <?php if (!empty($individual['tags'])): ?>
                                        <?= getTagsHTML($individual['tags'], false) ?>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    
                    <?php 
                    // Now show unstarred with letter breaks
                    $current_letter = '';
                    foreach ($unstarred as $individual):
                        if (preg_match('/^zz-/i', $individual['name'])) continue;
                        $first_letter = strtoupper(substr($individual['name'], 0, 1));
                        if ($first_letter !== $current_letter) {
                            $current_letter = $first_letter;
                            echo '<div id="letter-' . $current_letter . '" class="anchor-letter"></div>';
                        }
                    ?>
                        <div class="individual-card">
                            <a href="individual.php?id=<?= $individual['individual_id'] ?>" style="text-decoration: none; color: inherit;">
                                <div class="individual-thumbnail">
                                    <?php if (!empty($individual['default_thumbnail'])): ?>
                                        <img src="../<?= htmlspecialchars($individual['default_thumbnail']) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                                    <?php else: ?>
                                        <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                                    <?php endif; ?>
                                    
                                    <div class="star-overlay" 
                                         data-individual-id="<?= $individual['individual_id'] ?>"
                                         onclick="event.preventDefault(); event.stopPropagation(); toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)" 
                                         title="Click to change star rating">
                                        <?= getStarHTML($individual['star_rating'], false) ?>
                                    </div>
                                </div>
                            </a>
                            
                            <div class="individual-info">
                                <div class="individual-name">
                                    <a href="individual.php?id=<?= $individual['individual_id'] ?>">
                                        <?= htmlspecialchars($individual['name']) ?>
                                    </a>
                                </div>
                                <div class="individual-stats">
                                    &#128193; <?= $individual['folder_clip_count'] ?> clip<?= $individual['folder_clip_count'] != 1 ? 's' : '' ?>
                                    <?php if ($individual['ai_match_count'] > 0): ?>
                                        &#8226; &#129302; <?= $individual['ai_match_count'] ?> match<?= $individual['ai_match_count'] != 1 ? 'es' : '' ?>
                                    <?php endif; ?>
                                    <?= getTagMatchInfo($individual, $tag_filter) ?>
                                </div>
                                
                                <?php if (!empty($individual['tags'])): ?>
                                    <?= getTagsHTML($individual['tags'], false) ?>
                                <?php endif; ?>
                            </div>
                        </div>
                    <?php endforeach; ?>
                    
                    <?php 
                    // Show zz-xxx individuals in their own section
                    $zz_individuals = array_filter($unstarred, function($ind) {
                        return preg_match('/^zz-/i', $ind['name']);
                    });
                    
                    if (!empty($zz_individuals)): 
                    ?>
                        <div id="letter-ZZ" class="anchor-letter"></div>
                        <?php foreach ($zz_individuals as $individual): ?>
                            <div class="individual-card">
                                <a href="individual.php?id=<?= $individual['individual_id'] ?>" style="text-decoration: none; color: inherit;">
                                    <div class="individual-thumbnail">
                                        <?php if (!empty($individual['default_thumbnail'])): ?>
                                            <img src="../<?= htmlspecialchars($individual['default_thumbnail']) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                                        <?php else: ?>
                                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                                        <?php endif; ?>
                                        
                                        <div class="star-overlay" 
                                             data-individual-id="<?= $individual['individual_id'] ?>"
                                             onclick="event.preventDefault(); event.stopPropagation(); toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)" 
                                             title="Click to change star rating">
                                            <?= getStarHTML($individual['star_rating'], false) ?>
                                        </div>
                                    </div>
                                </a>
                                
                                <div class="individual-info">
                                    <div class="individual-name">
                                        <a href="individual.php?id=<?= $individual['individual_id'] ?>">
                                            <?= htmlspecialchars($individual['name']) ?>
                                        </a>
                                    </div>
                                    <div class="individual-stats">
                                        &#128193; <?= $individual['folder_clip_count'] ?> clip<?= $individual['folder_clip_count'] != 1 ? 's' : '' ?>
                                        <?php if ($individual['ai_match_count'] > 0): ?>
                                            &#8226; &#129302; <?= $individual['ai_match_count'] ?> match<?= $individual['ai_match_count'] != 1 ? 'es' : '' ?>
                                        <?php endif; ?>
                                        <?= getTagMatchInfo($individual, $tag_filter) ?>
                                    </div>
                                    
                                    <?php if (!empty($individual['tags'])): ?>
                                        <?= getTagsHTML($individual['tags'], false) ?>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
            <?php else: ?>
                <div class="no-results">
                    <h2>No individuals found</h2>
                    <p>Try adjusting your filters.</p>
                </div>
            <?php endif; ?>
        </div>
        
        <div class="alphabet-ruler">
            <?php 
            // Count starred individuals by color
            $red_count = count(array_filter($individuals, fn($i) => $i['star_rating'] == 3));
            $yellow_count = count(array_filter($individuals, fn($i) => $i['star_rating'] == 2));
            $blue_count = count(array_filter($individuals, fn($i) => $i['star_rating'] == 1));
            ?>
            
            <?php if ($red_count > 0): ?>
                <a href="#star-red" class="star-nav star-nav-red" title="Red starred (<?= $red_count ?>)">
                    &#9733;
                </a>
            <?php endif; ?>
            
            <?php if ($yellow_count > 0): ?>
                <a href="#star-yellow" class="star-nav star-nav-yellow" title="Yellow starred (<?= $yellow_count ?>)">
                    &#9733;
                </a>
            <?php endif; ?>
            
            <?php if ($blue_count > 0): ?>
                <a href="#star-blue" class="star-nav star-nav-blue" title="Blue starred (<?= $blue_count ?>)">
                    &#9733;
                </a>
            <?php endif; ?>
            
            <?php if ($red_count > 0 || $yellow_count > 0 || $blue_count > 0): ?>
                <div class="ruler-divider"></div>
            <?php endif; ?>
            
            <?php foreach ($alphabet as $letter): ?>
                <a href="#letter-<?= $letter ?>" class="alphabet-letter <?= $alphabet_counts[$letter] == 0 ? 'disabled' : '' ?>">
                    <?= $letter ?>
                </a>
            <?php endforeach; ?>
        </div>
    </div>
    
    <!-- Confirmation Modal -->
    <div id="confirmModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">âš ï¸ Confirm Action</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                <button class="btn btn-primary" id="confirmButton">Yes, Continue</button>
            </div>
        </div>
    </div>
    
    <script>
    // Star rating toggle - updates in-place without page reload
    function toggleStar(individualId, currentRating) {
        const nextRating = (currentRating + 1) % 4; // 0->1->2->3->0
        
        fetch('actions/update_star.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ individual_id: individualId, star_rating: nextRating })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Update the star overlay without reloading
                const starOverlays = document.querySelectorAll(`.star-overlay[data-individual-id="${individualId}"]`);
                starOverlays.forEach(overlay => {
                    // Update the onclick attribute
                    overlay.setAttribute('onclick', `event.preventDefault(); event.stopPropagation(); toggleStar(${individualId}, ${nextRating})`);
                    
                    // Update the star HTML
                    const starHTML = getStarHTML(nextRating);
                    overlay.innerHTML = starHTML;
                });
            } else {
                alert('Error: ' + data.message);
            }
        })
        .catch(error => {
            alert('Error updating star rating');
            console.error(error);
        });
    }
    
    // Get star HTML for a given rating
    function getStarHTML(rating) {
        const stars = {
            0: { icon: '&#9734;', color: '#95a5a6', title: 'No rating' },
            1: { icon: '&#9733;', color: '#3498db', title: 'Blue star' },
            2: { icon: '&#9733;', color: '#f1c40f', title: 'Yellow star' },
            3: { icon: '&#9733;', color: '#e74c3c', title: 'Red star' }
        };
        
        const star = stars[rating] || stars[0];
        return `<span style="color: ${star.color};" title="${star.title}">${star.icon}</span>`;
    }
    
    // Confirmation modal
    function showConfirmation(message, callback) {
        document.getElementById('confirmMessage').textContent = message;
        document.getElementById('confirmModal').classList.add('active');
        
        document.getElementById('confirmButton').onclick = function() {
            closeModal();
            callback();
        };
    }
    
    function closeModal() {
        document.getElementById('confirmModal').classList.remove('active');
    }
    
    // Close modal on escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeModal();
    });
    
    // Close modal on background click
    document.getElementById('confirmModal').addEventListener('click', function(e) {
        if (e.target === this) closeModal();
    });
    
    // Smooth scroll for alphabet
    document.querySelectorAll('.alphabet-letter:not(.disabled)').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.getElementById(this.getAttribute('href').substring(1));
            if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    });
    
    // Smooth scroll for star navigation
    document.querySelectorAll('.star-nav').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.getElementById(this.getAttribute('href').substring(1));
            if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    });
    </script>
</body>
</html>
