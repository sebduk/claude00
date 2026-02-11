<?php
/**
 * Admin - Unknown Clips Page  
 * Bulk assign unknown clips to individuals with filtering and sorting
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get filter parameters
$tag_filter = isset($_GET['tag']) ? $_GET['tag'] : null;

// Get sort parameters - default: most recent first
list($sort, $order) = getSortParams(
    ['filename', 'duration', 'file_date', 'filesize', 'dimensions'],
    'file_date',
    'DESC'
);

$sort_map = [
    'filename' => 'c.filename',
    'duration' => 'c.duration',
    'file_date' => 'c.file_date',
    'filesize' => 'c.filesize',
    'dimensions' => 'c.width * c.height'
];

$sort_sql = $sort_map[$sort] . ' ' . $order;

// Build WHERE clause for tag filtering
$where = ["c.clip_type = 'unknown'"];
$params = [];

if ($tag_filter === 'no_tag') {
    // Special case: filter for clips with NO tags
    $where[] = "NOT EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id)";
} elseif ($tag_filter) {
    // Regular case: filter for clips with specific tag
    $where[] = "EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id AND ct.tag_id = :tag_id)";
    $params[':tag_id'] = intval($tag_filter);
}

$where_sql = 'WHERE ' . implode(' AND ', $where);

// Get all unknown clips
$clips_sql = "
    SELECT c.* FROM clips c
    $where_sql
    ORDER BY $sort_sql
";

$stmt = $db->prepare($clips_sql);
foreach ($params as $key => $value) {
    $stmt->bindValue($key, $value);
}
$stmt->execute();
$clips = $stmt->fetchAll();

// Get tags for each clip
foreach ($clips as &$clip) {
    $tags_stmt = $db->prepare("
        SELECT t.* 
        FROM tags t
        JOIN clip_tags ct ON t.tag_id = ct.tag_id
        WHERE ct.clip_id = ?
        ORDER BY t.tag_name
    ");
    $tags_stmt->execute([$clip['clip_id']]);
    $clip['tags'] = $tags_stmt->fetchAll();
}
unset($clip);

// Get all tags for filter dropdown
$all_tags = $db->query("
    SELECT t.*, COUNT(ct.clip_id) as clip_count
    FROM tags t
    LEFT JOIN clip_tags ct ON t.tag_id = ct.tag_id
    JOIN clips c ON ct.clip_id = c.clip_id AND c.clip_type = 'unknown'
    WHERE t.tag_type IN ('clip', 'both')
    GROUP BY t.tag_id
    ORDER BY t.tag_name
")->fetchAll();

// Get count of unknown clips with no tags
$untagged_count = $db->query("
    SELECT COUNT(*) 
    FROM clips c 
    WHERE c.clip_type = 'unknown'
    AND NOT EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id)
")->fetchColumn();

// Get all individuals for dropdown
$individuals = $db->query("
    SELECT individual_id, name 
    FROM individuals 
    ORDER BY name
")->fetchAll();

// Calculate next zz- index
$next_zz_stmt = $db->query("
    SELECT name FROM individuals 
    WHERE name LIKE 'zz-%' 
    ORDER BY name DESC 
    LIMIT 1
");
$last_zz = $next_zz_stmt->fetchColumn();
if ($last_zz && preg_match('/zz-(\d+)/', $last_zz, $matches)) {
    $next_zz_index = intval($matches[1]) + 1;
} else {
    $next_zz_index = 1;
}

$next_zz_name = 'zz-' . str_pad($next_zz_index, 3, '0', STR_PAD_LEFT);

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unknown Clips - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1600px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header h1 { color: var(--primary-color); margin-bottom: 5px; }
        
        .header .stats {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .filters-section {
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
        }
        
        .control-group {
            display: flex;
            flex-direction: column;
        }
        
        .control-group label {
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 5px;
            color: #555;
        }
        
        .control-group select,
        .control-group input {
            padding: 8px 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
            align-items: flex-end;
        }
        
        .assignment-panel {
            background: white;
            padding: 25px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .selection-info {
            background: var(--background-color);
            padding: 15px 20px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-weight: 600;
            text-align: center;
        }
        
        .selection-info.active {
            background: var(--primary-color);
            color: white;
        }
        
        .assignment-options {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .assignment-option {
            padding: 20px;
            border: 2px solid #ecf0f1;
            border-radius: 8px;
            transition: border-color 0.2s;
        }
        
        .assignment-option:hover {
            border-color: var(--primary-color);
        }
        
        .assignment-option h3 {
            color: var(--primary-color);
            margin-bottom: 15px;
        }
        
        .assignment-option select {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            margin-bottom: 15px;
        }
        
        .btn {
            padding: 10px 20px;
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
        
        .clips-container {
            background: white;
            border-radius: 8px;
            overflow-x: auto;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        table { 
            width: 100%; 
            border-collapse: collapse;
            min-width: 900px;
        }
        
        thead {
            background: var(--secondary-color);
            color: white;
        }
        
        th {
            padding: 15px 12px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
            white-space: nowrap;
        }
        
        th a {
            color: white;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        th a:hover { opacity: 0.8; }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
            vertical-align: middle;
        }
        
        tbody tr:hover { background: #f8f9fa; }
        
        .select-all-row {
            background: var(--background-color);
        }
        
        .select-all-row th {
            background: var(--background-color);
            color: var(--text-color);
        }
        
        .checkbox-cell {
            width: 40px;
            text-align: center;
        }
        
        .thumbnail-cell {
            width: 100px;
        }
        
        .thumbnail {
            width: 80px;
            height: auto;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .filename-link {
            color: var(--primary-color);
            text-decoration: none;
            font-weight: 500;
            display: block;
        }
        
        .filename-link:hover { text-decoration: underline; }
        
        .folder-path {
            font-size: 11px;
            color: #95a5a6;
            margin-top: 3px;
        }
        
        .tags {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        
        .tag-badge {
            display: inline-block;
            padding: 3px 8px;
            background: var(--primary-color);
            color: white;
            border-radius: 3px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .no-clips {
            text-align: center;
            padding: 60px 20px;
            color: #7f8c8d;
        }
        
        .no-clips h2 {
            color: var(--primary-color);
            margin-bottom: 10px;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            align-items: center;
            justify-content: center;
        }
        
        .modal.active { display: flex; }
        
        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            max-width: 400px;
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
        }
        
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        @media (max-width: 768px) {
            .assignment-options { grid-template-columns: 1fr; }
            .clips-container { overflow-x: auto; }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="header">
            <h1>&#63; Unknown Clips</h1>
            <div class="stats">
                Showing <?= count($clips) ?> of <?= $db->query("SELECT COUNT(*) FROM clips WHERE clip_type = 'unknown'")->fetchColumn() ?> total unknown clips
            </div>
        </div>
        
        <!-- FILTERS SECTION -->
        <div class="filters-section">
            <form method="GET" id="filterForm">
                <div class="filters-grid">
                    <div class="control-group">
                        <label>Filter by Tag</label>
                        <select name="tag" onchange="this.form.submit()">
                            <option value="">All Tags</option>
                            <option value="no_tag" <?= $tag_filter === 'no_tag' ? 'selected' : '' ?>>
                                No Tag (<?= $untagged_count ?>)
                            </option>
                            <?php foreach ($all_tags as $tag): ?>
                                <option value="<?= $tag['tag_id'] ?>" <?= $tag_filter == $tag['tag_id'] ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($tag['tag_name']) ?> (<?= $tag['clip_count'] ?>)
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    
                    <div class="control-group">
                        <label>Sort By</label>
                        <select name="sort" onchange="this.form.submit()">
                            <option value="file_date" <?= $sort === 'file_date' ? 'selected' : '' ?>>Date</option>
                            <option value="filename" <?= $sort === 'filename' ? 'selected' : '' ?>>Filename</option>
                            <option value="filesize" <?= $sort === 'filesize' ? 'selected' : '' ?>>File Size</option>
                            <option value="duration" <?= $sort === 'duration' ? 'selected' : '' ?>>Duration</option>
                            <option value="dimensions" <?= $sort === 'dimensions' ? 'selected' : '' ?>>Dimensions (pixels)</option>
                        </select>
                    </div>
                    
                    <div class="control-group">
                        <label>Order</label>
                        <select name="order" onchange="this.form.submit()">
                            <option value="ASC" <?= $order === 'ASC' ? 'selected' : '' ?>>Ascending</option>
                            <option value="DESC" <?= $order === 'DESC' ? 'selected' : '' ?>>Descending</option>
                        </select>
                    </div>
                    
                    <div class="control-group filter-buttons">
                        <label>&nbsp;</label>
                        <a href="?" class="btn btn-secondary">Reset Filters</a>
                    </div>
                </div>
            </form>
        </div>
        
        <!-- ASSIGNMENT PANEL -->
        <div class="assignment-panel">
            <div class="selection-info" id="selectionInfo">
                Select clips below to assign them
            </div>
            
            <div class="assignment-options">
                <div class="assignment-option">
                    <h3>&#128194; Assign to Existing Individual</h3>
                    <select id="existingIndividual">
                        <option value="">-- Select Individual --</option>
                        <?php foreach ($individuals as $ind): ?>
                            <option value="<?= $ind['individual_id'] ?>">
                                <?= htmlspecialchars($ind['name']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                    <button class="btn btn-primary" onclick="assignToExisting()">
                        Assign Selected Clips
                    </button>
                </div>
                
                <div class="assignment-option">
                    <h3>&#10133; Create New Individual</h3>
                    <p style="margin-bottom: 15px; color: #666;">
                        Will create: <strong><?= htmlspecialchars($next_zz_name) ?></strong>
                    </p>
                    <button class="btn btn-primary" onclick="createNewIndividual()">
                        Create & Assign Selected
                    </button>
                </div>
            </div>
        </div>
        
        <!-- CLIPS TABLE -->
        <div class="clips-container">
            <?php if (count($clips) > 0): ?>
                <table>
                    <thead>
                        <tr class="select-all-row">
                            <th class="checkbox-cell">
                                <input type="checkbox" id="selectAll" onchange="toggleSelectAll(this)">
                            </th>
                            <th colspan="7">
                                <label for="selectAll" style="cursor: pointer; user-select: none; display: block;">
                                    Select All
                                </label>
                            </th>
                        </tr>
                        <tr>
                            <th class="checkbox-cell"></th>
                            <th class="thumbnail-cell">Thumbnail</th>
                            <th>Filename</th>
                            <th>Duration</th>
                            <th>Dimensions</th>
                            <th>Date</th>
                            <th>Size</th>
                            <th>Tags</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($clips as $clip): ?>
                            <tr>
                                <td class="checkbox-cell">
                                    <input type="checkbox" class="clip-checkbox" value="<?= $clip['clip_id'] ?>" onchange="updateSelectionInfo()">
                                </td>
                                <td class="thumbnail-cell">
                                    <?php if (!empty($clip['thumbnail_path'])): ?>
                                        <a href="../videos/unknown/<?= htmlspecialchars($clip['filepath']) ?>" target="_blank">
                                            <img src="../<?= htmlspecialchars($clip['thumbnail_path']) ?>" class="thumbnail">
                                        </a>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="../videos/unknown/<?= htmlspecialchars($clip['filepath']) ?>" class="filename-link" target="_blank">
                                        <?= htmlspecialchars($clip['filename']) ?>
                                    </a>
                                    <div class="folder-path">videos/unknown/<?= htmlspecialchars($clip['filepath']) ?></div>
                                </td>
                                <td><?= htmlspecialchars($clip['duration_text']) ?></td>
                                <td><?= number_format($clip['width']) ?> &#215; <?= number_format($clip['height']) ?></td>
                                <td><?= date('Y-m-d', strtotime($clip['file_date'])) ?></td>
                                <td><?= formatFileSize($clip['filesize']) ?></td>
                                <td>
                                    <?php if (!empty($clip['tags'])): ?>
                                        <div class="tags">
                                            <?php foreach ($clip['tags'] as $tag): ?>
                                                <span class="tag-badge"><?= htmlspecialchars($tag['tag_name']) ?></span>
                                            <?php endforeach; ?>
                                        </div>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="no-clips">
                    <?php if ($tag_filter): ?>
                        <h2>No clips found</h2>
                        <p>No unknown clips match the selected filter.</p>
                        <p style="margin-top: 10px;">
                            <a href="?" class="btn btn-primary">Clear Filters</a>
                        </p>
                    <?php else: ?>
                        <h2>No unknown clips</h2>
                        <p>All clips have been assigned to individuals!</p>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <div id="confirmModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">&#9888; Confirm Action</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                <button class="btn btn-primary" id="confirmButton">Yes, Continue</button>
            </div>
        </div>
    </div>
    
    <script>
    function getSelectedClips() {
        const checkboxes = document.querySelectorAll('.clip-checkbox:checked');
        return Array.from(checkboxes).map(cb => parseInt(cb.value));
    }
    
    function updateSelectionInfo() {
        const count = getSelectedClips().length;
        const info = document.getElementById('selectionInfo');
        if (count > 0) {
            info.textContent = `${count} clip${count > 1 ? 's' : ''} selected`;
            info.classList.add('active');
        } else {
            info.textContent = 'Select clips below to assign them';
            info.classList.remove('active');
        }
    }
    
    function toggleSelectAll(checkbox) {
        document.querySelectorAll('.clip-checkbox').forEach(cb => {
            cb.checked = checkbox.checked;
        });
        updateSelectionInfo();
    }
    
    function assignToExisting() {
        const clipIds = getSelectedClips();
        const individualId = document.getElementById('existingIndividual').value;
        
        if (clipIds.length === 0) {
            alert('Please select at least one clip');
            return;
        }
        
        if (!individualId) {
            alert('Please select an individual');
            return;
        }
        
        const individualName = document.getElementById('existingIndividual').selectedOptions[0].text;
        
        showConfirm(`Assign ${clipIds.length} clip(s) to "${individualName}"?`, () => {
            fetch('actions/assign_clips.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    clip_ids: clipIds, 
                    individual_id: parseInt(individualId), 
                    mode: 'existing' 
                })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function createNewIndividual() {
        const clipIds = getSelectedClips();
        
        if (clipIds.length === 0) {
            alert('Please select at least one clip');
            return;
        }
        
        showConfirm(`Create new individual "<?= htmlspecialchars($next_zz_name) ?>" and assign ${clipIds.length} clip(s)?`, () => {
            fetch('actions/assign_clips.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    clip_ids: clipIds, 
                    mode: 'new' 
                })
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