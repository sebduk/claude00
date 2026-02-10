<?php
/**
 * Admin - Matches Page
 * Review all AI match suggestions across all individuals
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get filter parameters
$individual_filter = isset($_GET['individual']) ? intval($_GET['individual']) : null;
$min_confidence = isset($_GET['min_confidence']) ? intval($_GET['min_confidence']) : 0;
$sort_by = isset($_GET['sort_by']) ? $_GET['sort_by'] : 'confidence';

// Build WHERE clause
$where = ["c.clip_type = 'unknown'"];
$params = [];

if ($individual_filter) {
    $where[] = "ci.individual_id = :individual_id";
    $params[':individual_id'] = $individual_filter;
}

if ($min_confidence > 0) {
    $where[] = "ci.confidence >= :min_confidence";
    $params[':min_confidence'] = $min_confidence / 100;
}

$where_sql = 'WHERE ' . implode(' AND ', $where);

// Determine ORDER BY based on sort selection
$order_by = match($sort_by) {
    'individual' => 'i.name ASC, ci.confidence DESC',
    'filename' => 'c.filename ASC, ci.confidence DESC',
    default => 'ci.confidence DESC, i.name ASC'
};

// Get all pending matches
$matches_sql = "
    SELECT 
        c.*,
        ci.individual_id,
        ci.confidence,
        i.name as individual_name,
        it.thumbnail_path as individual_thumbnail
    FROM clips c
    JOIN clip_individuals ci ON c.clip_id = ci.clip_id
    JOIN individuals i ON ci.individual_id = i.individual_id
    LEFT JOIN clips it ON i.default_thumbnail_clip_id = it.clip_id
    $where_sql
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem 
        WHERE kem.clip_id = c.clip_id 
        AND kem.individual_id = ci.individual_id
    )
    ORDER BY $order_by
";

$stmt = $db->prepare($matches_sql);
foreach ($params as $key => $value) {
    $stmt->bindValue($key, $value);
}
$stmt->execute();
$matches = $stmt->fetchAll();

// Get tags for each match
foreach ($matches as &$match) {
    // Clip tags
    $clip_tag_stmt = $db->prepare("
        SELECT t.* FROM tags t
        JOIN clip_tags ct ON t.tag_id = ct.tag_id
        WHERE ct.clip_id = ?
    ");
    $clip_tag_stmt->execute([$match['clip_id']]);
    $match['clip_tags'] = $clip_tag_stmt->fetchAll();
    
    // Individual tags
    $ind_tag_stmt = $db->prepare("
        SELECT t.* FROM tags t
        JOIN individual_tags it ON t.tag_id = it.tag_id
        WHERE it.individual_id = ?
    ");
    $ind_tag_stmt->execute([$match['individual_id']]);
    $match['individual_tags'] = $ind_tag_stmt->fetchAll();
}
unset($match);

// Get individuals with pending matches for filter dropdown
$individuals_with_matches = $db->query("
    SELECT DISTINCT
        i.individual_id,
        i.name,
        COUNT(DISTINCT ci.clip_id) as match_count
    FROM individuals i
    JOIN clip_individuals ci ON i.individual_id = ci.individual_id
    JOIN clips c ON ci.clip_id = c.clip_id
    WHERE c.clip_type = 'unknown'
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem 
        WHERE kem.clip_id = ci.clip_id 
        AND kem.individual_id = ci.individual_id
    )
    GROUP BY i.individual_id
    ORDER BY i.name
")->fetchAll();

// Calculate stats
$stats = [
    'total_matches' => count($matches),
    'high_confidence' => 0,
    'medium_confidence' => 0,
    'low_confidence' => 0
];

foreach ($matches as $match) {
    $conf_pct = $match['confidence'] * 100;
    if ($conf_pct >= 80) {
        $stats['high_confidence']++;
    } elseif ($conf_pct >= 60) {
        $stats['medium_confidence']++;
    } else {
        $stats['low_confidence']++;
    }
}

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Matches - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header h1 { color: var(--primary-color); margin-bottom: 15px; }
        
        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .stat-box {
            padding: 15px;
            border-radius: 8px;
            background: var(--background-color);
        }
        
        .stat-label {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #666;
            margin-bottom: 5px;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: var(--primary-color);
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
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-group label { font-size: 13px; font-weight: 600; color: #666; }
        .filter-group select {
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
            transition: opacity 0.2s;
        }
        
        .btn:hover { opacity: 0.8; }
        .btn-primary { background: var(--primary-color); color: white; }
        .btn-secondary { background: #95a5a6; color: white; }
        
        .matches-container {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .match-row {
            display: flex;
            align-items: center;
            gap: 20px;
            padding: 15px;
            border-bottom: 1px solid #ecf0f1;
        }
        
        .match-row:hover { background: #f8f9fa; }
        
        .individual-section {
            display: flex;
            align-items: center;
            gap: 15px;
            min-width: 250px;
        }
        
        .thumbnail {
            width: 80px;
            height: 120px;
            object-fit: cover;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .thumbnail-placeholder {
            width: 80px;
            height: 120px;
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            border-radius: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 32px;
            font-weight: bold;
        }
        
        .arrow {
            font-size: 24px;
            color: #95a5a6;
            flex-shrink: 0;
        }
        
        .clip-section {
            display: flex;
            align-items: center;
            gap: 15px;
            flex: 1;
        }
        
        .info {
            flex: 1;
        }
        
        .name {
            font-weight: 600;
            font-size: 16px;
            color: var(--primary-color);
            margin-bottom: 5px;
        }
        
        .name a {
            color: var(--primary-color);
            text-decoration: none;
        }
        
        .name a:hover { text-decoration: underline; }
        
        .filename {
            font-size: 14px;
            color: #666;
            margin-bottom: 3px;
        }
        
        .filename a {
            color: var(--text-color);
            text-decoration: none;
        }
        
        .filename a:hover { text-decoration: underline; }
        
        .meta {
            font-size: 12px;
            color: #95a5a6;
        }
        
        .confidence-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 15px;
            font-size: 14px;
            font-weight: 600;
            color: white;
            flex-shrink: 0;
        }
        
        .confidence-high { background: #27ae60; }
        .confidence-medium { background: #f39c12; }
        .confidence-low { background: #e74c3c; }
        
        .actions {
            display: flex;
            gap: 8px;
            flex-shrink: 0;
        }
        
        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-accept { background: #27ae60; color: white; }
        .btn-reject { background: #e67e22; color: white; }
        .btn-delete { background: #e74c3c; color: white; }
        
        .tags-container {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
            margin-top: 5px;
        }
        
        .tag-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: 600;
            color: white;
        }
        
        .no-matches {
            text-align: center;
            padding: 60px 20px;
            color: #95a5a6;
        }
        
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
        
        .modal-message { margin-bottom: 20px; line-height: 1.6; }
        .modal-buttons { display: flex; gap: 10px; justify-content: flex-end; }
        
        @media (max-width: 767px) {
            .match-row { flex-direction: column; align-items: stretch; }
            .individual-section, .clip-section { min-width: 100%; }
            .arrow { display: none; }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="header">
            <h1>🤖 AI Match Suggestions</h1>
            
            <div class="stats-row">
                <div class="stat-box">
                    <div class="stat-label">Total Matches</div>
                    <div class="stat-value"><?= $stats['total_matches'] ?></div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">High Confidence (80%+)</div>
                    <div class="stat-value" style="color: #27ae60;"><?= $stats['high_confidence'] ?></div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">Medium (60-79%)</div>
                    <div class="stat-value" style="color: #f39c12;"><?= $stats['medium_confidence'] ?></div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">Low (<60%)</div>
                    <div class="stat-value" style="color: #e74c3c;"><?= $stats['low_confidence'] ?></div>
                </div>
            </div>
        </div>
        
        <div class="filters">
            <form method="GET">
                <div class="filters-grid">
                    <div class="filter-group">
                        <label>Filter by Individual</label>
                        <select name="individual">
                            <option value="">All Individuals</option>
                            <?php foreach ($individuals_with_matches as $ind): ?>
                                <option value="<?= $ind['individual_id'] ?>" <?= $individual_filter == $ind['individual_id'] ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($ind['name']) ?> (<?= $ind['match_count'] ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="filter-group">
                        <label>Minimum Confidence</label>
                        <select name="min_confidence">
                            <option value="0" <?= $min_confidence == 0 ? 'selected' : '' ?>>All Confidence Levels</option>
                            <option value="80" <?= $min_confidence == 80 ? 'selected' : '' ?>>80% and above</option>
                            <option value="60" <?= $min_confidence == 60 ? 'selected' : '' ?>>60% and above</option>
                            <option value="40" <?= $min_confidence == 40 ? 'selected' : '' ?>>40% and above</option>
                        </select>
                    </div>
                    
                    <div class="filter-group">
                        <label>Sort By</label>
                        <select name="sort_by">
                            <option value="confidence" <?= $sort_by == 'confidence' ? 'selected' : '' ?>>Confidence (High to Low)</option>
                            <option value="individual" <?= $sort_by == 'individual' ? 'selected' : '' ?>>Individual Name</option>
                            <option value="filename" <?= $sort_by == 'filename' ? 'selected' : '' ?>>Filename</option>
                        </select>
                    </div>
                </div>
                
                <div class="filter-actions">
                    <button type="submit" class="btn btn-primary">Apply Filters</button>
                    <a href="?" class="btn btn-secondary">Clear</a>
                </div>
            </form>
        </div>
        
        <div class="matches-container">
            <?php if (count($matches) > 0): ?>
                <?php foreach ($matches as $match): ?>
                    <?php
                    $conf_pct = round($match['confidence'] * 100);
                    $conf_class = $conf_pct >= 80 ? 'confidence-high' : ($conf_pct >= 60 ? 'confidence-medium' : 'confidence-low');
                    $clip_video_path = '../videos/unknown/' . $match['filepath'];
                    $clip_thumb_path = '../' . $match['thumbnail_path'];
                    $ind_thumb_path = !empty($match['individual_thumbnail']) ? '../' . $match['individual_thumbnail'] : null;
                    ?>
                    <div class="match-row">
                        <!-- Individual Section -->
                        <div class="individual-section">
                            <?php if ($ind_thumb_path): ?>
                                <img src="<?= htmlspecialchars($ind_thumb_path) ?>" class="thumbnail" alt="<?= htmlspecialchars($match['individual_name']) ?>">
                            <?php else: ?>
                                <div class="thumbnail-placeholder">
                                    <?= htmlspecialchars(substr($match['individual_name'], 0, 1)) ?>
                                </div>
                            <?php endif; ?>
                            
                            <div class="info">
                                <div class="name">
                                    <a href="individual.php?id=<?= $match['individual_id'] ?>">
                                        <?= htmlspecialchars($match['individual_name']) ?>
                                    </a>
                                </div>
                                <?php if (!empty($match['individual_tags'])): ?>
                                    <?= getTagsHTML($match['individual_tags'], false) ?>
                                <?php endif; ?>
                            </div>
                        </div>
                        
                        <div class="arrow">→</div>
                        
                        <!-- Clip Section -->
                        <div class="clip-section">
                            <?php if (!empty($match['thumbnail_path'])): ?>
                                <a href="<?= htmlspecialchars($clip_video_path) ?>" target="_blank">
                                    <img src="<?= htmlspecialchars($clip_thumb_path) ?>" class="thumbnail">
                                </a>
                            <?php endif; ?>
                            
                            <div class="info">
                                <div class="filename">
                                    <a href="<?= htmlspecialchars($clip_video_path) ?>" target="_blank">
                                        <?= htmlspecialchars($match['filename']) ?>
                                    </a>
                                </div>
                                <div class="meta">
                                    <?= $match['width'] ?> × <?= $match['height'] ?> • 
                                    <?= htmlspecialchars($match['duration_text']) ?>
                                </div>
                                <?php if (!empty($match['clip_tags'])): ?>
                                    <?= getTagsHTML($match['clip_tags'], false) ?>
                                <?php endif; ?>
                            </div>
                            
                            <span class="confidence-badge <?= $conf_class ?>">
                                <?= $conf_pct ?>%
                            </span>
                            
                            <div class="actions">
                                <button class="btn btn-sm btn-accept" onclick="acceptMatch(<?= $match['clip_id'] ?>, <?= $match['individual_id'] ?>, '<?= addslashes($match['filename']) ?>')">Accept</button>
                                <button class="btn btn-sm btn-reject" onclick="rejectMatch(<?= $match['clip_id'] ?>, <?= $match['individual_id'] ?>, '<?= addslashes($match['filename']) ?>')">Reject</button>
                                <button class="btn btn-sm btn-delete" onclick="deleteClip(<?= $match['clip_id'] ?>, '<?= addslashes($match['filename']) ?>')">Delete</button>
                            </div>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php else: ?>
                <div class="no-matches">
                    <h2>No matches found</h2>
                    <p>There are no pending AI match suggestions matching your filters.</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <div id="confirmModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">⚠️ Confirm Action</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                <button class="btn btn-delete" id="confirmButton">Yes, Continue</button>
            </div>
        </div>
    </div>
    
    <script>
    function acceptMatch(clipId, individualId, filename) {
        fetch('actions/accept_match.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip_id: clipId, individual_id: individualId })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function rejectMatch(clipId, individualId, filename) {
        fetch('actions/reject_match.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip_id: clipId, individual_id: individualId })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function deleteClip(clipId, filename) {
        showConfirm(`Delete "${filename}"? This cannot be undone.`, () => {
            fetch('actions/delete_clip.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: clipId })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function showConfirm(msg, cb) {
        document.getElementById('confirmMessage').textContent = msg;
        document.getElementById('confirmModal').classList.add('active');
        document.getElementById('confirmButton').onclick = () => { closeModal(); cb(); };
    }
    
    function closeModal() {
        document.getElementById('confirmModal').classList.remove('active');
    }
    
    document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
    document.getElementById('confirmModal').addEventListener('click', e => { if (e.target.id === 'confirmModal') closeModal(); });
    </script>
</body>
</html>