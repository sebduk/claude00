<?php
/**
 * Mosaic View - Grid view of all clips with filtering, sorting, and batch operations
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get filter parameters
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$clip_type_filter = isset($_GET['clip_type']) ? $_GET['clip_type'] : 'all';
$tag_filter = isset($_GET['tag']) ? $_GET['tag'] : null;

// Get sort parameter
$sort_by = isset($_GET['sort_by']) ? $_GET['sort_by'] : 'file_date';
$sort_order = isset($_GET['sort_order']) ? $_GET['sort_order'] : 'DESC';

// Build WHERE clause
$where = [];
$params = [];

if (!empty($search)) {
    $where[] = "(c.filepath LIKE :search OR c.filename LIKE :search)";
    $params[':search'] = '%' . $search . '%';
}

if ($clip_type_filter !== 'all') {
    $where[] = "c.clip_type = :clip_type";
    $params[':clip_type'] = $clip_type_filter;
}

if ($tag_filter === 'no_tag') {
    // Special case: filter for clips with NO tags
    $where[] = "NOT EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id)";
} elseif ($tag_filter) {
    // Regular case: filter for clips with specific tag
    $where[] = "EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id AND ct.tag_id = :tag_id)";
    $params[':tag_id'] = intval($tag_filter);
}

$where_sql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

// Determine ORDER BY
$order_map = [
    'filepath' => 'c.filepath',
    'filename' => 'c.filename',
    'clip_type' => 'c.clip_type',
    'file_date' => 'c.file_date',
    'filesize' => 'c.filesize',
    'duration' => 'c.duration',
    'dimensions' => 'c.width * c.height',
    'tags' => '(SELECT COUNT(*) FROM clip_tags ct WHERE ct.clip_id = c.clip_id)'
];

$order_column = $order_map[$sort_by] ?? 'c.file_date';
$order_sql = "ORDER BY $order_column $sort_order, c.clip_id $sort_order";

// Get all clips
$clips_sql = "
    SELECT 
        c.*
    FROM clips c
    $where_sql
    $order_sql
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
    WHERE t.tag_type IN ('clip', 'both')
    GROUP BY t.tag_id
    ORDER BY t.tag_name
")->fetchAll();

// Get count of clips with no tags
$untagged_count = $db->query("
    SELECT COUNT(*) 
    FROM clips c 
    WHERE NOT EXISTS (SELECT 1 FROM clip_tags ct WHERE ct.clip_id = c.clip_id)
")->fetchColumn();

// Get all clip tags for tagging dropdown
$all_clip_tags = $db->query("
    SELECT * FROM tags 
    WHERE tag_type IN ('clip', 'both')
    ORDER BY tag_name
")->fetchAll();

$colors = getColorScheme();

// Get all individuals for assignment dropdown
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
    <title>Mosaic View - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1800px; margin: 0 auto; padding: 20px; }
        
        .page-header {
            background: white;
            padding: 20px 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
        }
        
        .page-header h1 {
            font-size: 28px;
            color: var(--primary-color);
            margin-bottom: 5px;
        }
        
        .page-header .stats {
            color: #666;
            font-size: 14px;
        }
        
        .controls {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .controls-row {
            display: flex;
            gap: 15px;
            margin-bottom: 15px;
            flex-wrap: wrap;
            align-items: flex-end;
        }
        
        .control-group {
            flex: 1;
            min-width: 200px;
        }
        
        .control-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 5px;
            font-size: 13px;
        }
        
        .control-group input,
        .control-group select {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
            transition: opacity 0.2s;
        }
        
        .btn:hover { opacity: 0.8; }
        .btn-primary { background: var(--primary-color); color: white; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-success { background: #27ae60; color: white; }
        
        .assignment-panel {
            background: white;
            padding: 25px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .assignment-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .assignment-header h3 {
            font-size: 20px;
            color: var(--primary-color);
            margin: 0;
        }
        
        .assignment-options {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 30px;
        }
        
        .assignment-option {
            padding: 20px;
            background: #f8f9fa;
            border-radius: 6px;
        }
        
        .assignment-option h4 {
            font-size: 16px;
            margin-bottom: 15px;
            color: #333;
        }
        
        .selection-bar {
            background: #3498db;
            color: white;
            padding: 15px 20px;
            border-radius: 0;
            margin-bottom: 0;
            display: none;
            align-items: center;
            justify-content: space-between;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            position: sticky;
            top: 60px;
            z-index: 999;
        }
        
        .selection-bar.active {
            display: flex;
        }
        
        .selection-info {
            font-weight: 600;
            font-size: 15px;
            flex: 1;
        }
        
        .selection-tag {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            background: rgba(255,255,255,0.2);
            cursor: pointer;
            transition: background 0.2s;
        }
        
        .selection-tag:hover {
            background: rgba(255,255,255,0.3);
        }
        
        .selection-tag-remove {
            font-weight: bold;
            font-size: 14px;
            line-height: 1;
            opacity: 0.8;
        }
        
        .selection-tag-remove:hover {
            opacity: 1;
        }
        
        .selection-actions {
            display: flex;
            gap: 10px;
        }
        
        .mosaic-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        
        .clip-card {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: all 0.2s;
            position: relative;
            cursor: pointer;
        }
        
        .clip-card:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            transform: translateY(-2px);
        }
        
        .clip-card.selected {
            outline: 4px solid #3498db;
            outline-offset: -4px;
        }
        
        .clip-checkbox {
            position: absolute;
            top: 8px;
            left: 8px;
            width: 24px;
            height: 24px;
            cursor: pointer;
            z-index: 10;
            accent-color: #3498db;
        }
        
        .clip-thumbnail {
            width: 100%;
            height: 120px;
            object-fit: cover;
            background: #ecf0f1;
            display: block;
        }
        
        .clip-info {
            padding: 10px;
        }
        
        .clip-filename {
            font-size: 11px;
            font-weight: 500;
            margin-bottom: 4px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            color: var(--text-color);
        }
        
        .clip-meta {
            font-size: 10px;
            color: #95a5a6;
            margin-bottom: 4px;
        }
        
        .clip-type-badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 9px;
            font-weight: 600;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        
        .badge-known { background: #27ae60; color: white; }
        .badge-unknown { background: #e67e22; color: white; }
        
        .clip-tags {
            display: flex;
            flex-wrap: wrap;
            gap: 3px;
            margin-top: 5px;
        }
        
        .tag-badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 9px;
            font-weight: 600;
            color: white;
        }
        
        .no-clips {
            background: white;
            padding: 60px;
            text-align: center;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .no-clips h2 {
            color: #95a5a6;
            margin-bottom: 10px;
        }
        
        /* Modal */
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
        
        .tag-option {
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            cursor: pointer;
            background: #f8f9fa;
            transition: background 0.2s;
        }
        
        .tag-option:hover {
            background: #e9ecef;
        }
        
        @media (max-width: 768px) {
            .mosaic-grid {
                grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
                gap: 10px;
            }
            
            .controls-row {
                flex-direction: column;
            }
            
            .control-group {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="page-header">
            <div>
                <h1>&#127902;&#65039; Mosaic View</h1>
                <div class="stats">
                    Showing <?= count($clips) ?> clip<?= count($clips) !== 1 ? 's' : '' ?>
                </div>
            </div>
        </div>
        
        <div class="controls">
            <form method="GET" id="filterForm">
                <div class="controls-row">
                    <div class="control-group">
                        <label>Search Path/Filename</label>
                        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="Search...">
                    </div>
                    
                    <div class="control-group">
                        <label>Clip Type</label>
                        <select name="clip_type">
                            <option value="all" <?= $clip_type_filter === 'all' ? 'selected' : '' ?>>All</option>
                            <option value="known" <?= $clip_type_filter === 'known' ? 'selected' : '' ?>>Known</option>
                            <option value="unknown" <?= $clip_type_filter === 'unknown' ? 'selected' : '' ?>>Unknown</option>
                        </select>
                    </div>
                    
                    <div class="control-group">
                        <label>Filter by Tag</label>
                        <select name="tag">
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
                </div>
                
                <div class="controls-row">
                    <div class="control-group">
                        <label>Sort By</label>
                        <select name="sort_by">
                            <option value="filepath" <?= $sort_by === 'filepath' ? 'selected' : '' ?>>Path/Filename</option>
                            <option value="filename" <?= $sort_by === 'filename' ? 'selected' : '' ?>>Filename Only</option>
                            <option value="clip_type" <?= $sort_by === 'clip_type' ? 'selected' : '' ?>>Known/Unknown</option>
                            <option value="file_date" <?= $sort_by === 'file_date' ? 'selected' : '' ?>>Date</option>
                            <option value="filesize" <?= $sort_by === 'filesize' ? 'selected' : '' ?>>Size</option>
                            <option value="duration" <?= $sort_by === 'duration' ? 'selected' : '' ?>>Duration</option>
                            <option value="dimensions" <?= $sort_by === 'dimensions' ? 'selected' : '' ?>>Dimensions</option>
                            <option value="tags" <?= $sort_by === 'tags' ? 'selected' : '' ?>>Tag Count</option>
                        </select>
                    </div>
                    
                    <div class="control-group">
                        <label>Order</label>
                        <select name="sort_order">
                            <option value="ASC" <?= $sort_order === 'ASC' ? 'selected' : '' ?>>Ascending</option>
                            <option value="DESC" <?= $sort_order === 'DESC' ? 'selected' : '' ?>>Descending</option>
                        </select>
                    </div>
                    
                    <div class="control-group">
                        <label>&nbsp;</label>
                        <div style="display: flex; gap: 10px;">
                            <button type="submit" class="btn btn-primary">Apply</button>
                            <a href="?" class="btn btn-secondary">Reset</a>
                        </div>
                    </div>
                </div>
            </form>
        </div>
        
        <!-- Assignment Panel -->
        <div class="assignment-panel" id="assignmentPanel" style="display: none;">
            <div class="assignment-header">
                <h3>&#128203; Assign Selected Clips</h3>
                <button class="btn btn-secondary" onclick="closeAssignmentPanel()">Close</button>
            </div>
            
            <div class="assignment-options">
                <div class="assignment-option">
                    <h4>&#128194; Assign to Existing Individual</h4>
                    <select id="existingIndividual" style="width: 100%; padding: 8px; margin-bottom: 10px; border: 1px solid #ddd; border-radius: 4px;">
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
                    <h4>&#10133; Create New Individual</h4>
                    <input 
                        type="text" 
                        id="newIndividualName" 
                        value="<?= htmlspecialchars($next_zz_name) ?>" 
                        placeholder="Enter individual name"
                        style="width: 100%; padding: 8px; margin-bottom: 10px; border: 1px solid #ddd; border-radius: 4px;"
                    />
                    <button class="btn btn-primary" onclick="createNewIndividual()">
                        Create & Assign Selected
                    </button>
                </div>
            </div>
        </div>
        
        <!-- Selection Bar -->
        <div class="selection-bar" id="selectionBar">
            <div class="selection-info">
                <div style="margin-bottom: 5px;">
                    <span id="selectedCount">0</span> clip(s) selected
                </div>
                <div id="commonTags" style="display: flex; flex-wrap: wrap; gap: 5px; align-items: center;">
                    <!-- Tags will be inserted here by JavaScript -->
                </div>
            </div>
            <div class="selection-actions">
                <button class="btn btn-primary" onclick="selectAll()">Select All</button>
                <button class="btn btn-secondary" onclick="selectNone()">Select None</button>
                <button class="btn btn-success" onclick="openAssignmentPanel()">&#128100; Assign to Individual</button>
                <button class="btn btn-success" onclick="openBatchTagModal()">&#127991;&#65039; Add Tag</button>
            </div>
        </div>
        
        <?php if (count($clips) > 0): ?>
            <div class="mosaic-grid">
                <?php foreach ($clips as $clip): ?>
                    <?php
                    $video_path = '../videos/' . $clip['clip_type'] . '/' . $clip['filepath'];
                    $thumb_path = '../' . $clip['thumbnail_path'];
                    $tags_json = json_encode($clip['tags']);
                    ?>
                    <div class="clip-card" 
                         data-clip-id="<?= $clip['clip_id'] ?>"
                         data-tags='<?= htmlspecialchars($tags_json, ENT_QUOTES) ?>'>
                        <input type="checkbox" 
                               class="clip-checkbox" 
                               data-clip-id="<?= $clip['clip_id'] ?>"
                               onclick="event.stopPropagation(); toggleSelection(this);">
                        
                        <a href="<?= htmlspecialchars($video_path) ?>" target="_blank" onclick="if(event.target.tagName !== 'INPUT') return true; event.preventDefault();">
                            <?php if (!empty($clip['thumbnail_path'])): ?>
                                <img src="<?= htmlspecialchars($thumb_path) ?>" class="clip-thumbnail" alt="<?= htmlspecialchars($clip['filename']) ?>">
                            <?php endif; ?>
                        </a>
                        
                        <div class="clip-info">
                            <span class="clip-type-badge badge-<?= $clip['clip_type'] ?>">
                                <?= $clip['clip_type'] ?>
                            </span>
                            
                            <div class="clip-filename" title="<?= htmlspecialchars($clip['filepath']) ?>">
                                <?= htmlspecialchars($clip['filename']) ?>
                            </div>
                            
                            <div class="clip-meta">
                                <?= $clip['width'] ?> &#215; <?= $clip['height'] ?> &#8212; <?= $clip['duration_text'] ?>
                            </div>
                            
                            <?php if (!empty($clip['tags'])): ?>
                                <div class="clip-tags">
                                    <?php foreach ($clip['tags'] as $tag): ?>
                                        <span class="tag-badge" style="background-color: <?= $tag['color'] ?? '#95a5a6' ?>">
                                            <?= htmlspecialchars($tag['tag_name']) ?>
                                        </span>
                                    <?php endforeach; ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php else: ?>
            <div class="no-clips">
                <h2>No clips found</h2>
                <p>Try adjusting your filters or search criteria.</p>
            </div>
        <?php endif; ?>
    </div>
    
    <!-- Batch Tag Modal -->
    <div id="batchTagModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">&#127991;&#65039; Add Tag to Selected Clips</div>
            <div class="modal-message">
                <p style="margin-bottom: 10px;">Select a tag to add to <span id="batchCount">0</span> clip(s):</p>
                <div style="max-height: 300px; overflow-y: auto;">
                    <?php foreach ($all_clip_tags as $tag): ?>
                        <div class="tag-option" onclick="batchAddTag(<?= $tag['tag_id'] ?>)">
                            <span class="tag-badge" style="background-color: <?= $tag['color'] ?? '#95a5a6' ?>">
                                <?= htmlspecialchars($tag['tag_name']) ?>
                            </span>
                        </div>
                    <?php endforeach; ?>
                    <?php if (empty($all_clip_tags)): ?>
                        <p style="color: #999;">No clip tags available. Create tags in the Tags page first.</p>
                    <?php endif; ?>
                </div>
            </div>
            <div class="modal-buttons" style="margin-top: 15px;">
                <button class="btn btn-secondary" onclick="closeBatchTagModal()">Cancel</button>
            </div>
        </div>
    </div>
    
    <script>
    let selectedClips = new Set();
    
    function getSelectedClips() {
        return Array.from(selectedClips);
    }
    
    function toggleSelection(checkbox) {
        const clipId = parseInt(checkbox.dataset.clipId);
        const card = checkbox.closest('.clip-card');
        
        if (checkbox.checked) {
            selectedClips.add(clipId);
            card.classList.add('selected');
        } else {
            selectedClips.delete(clipId);
            card.classList.remove('selected');
        }
        
        updateSelectionBar();
    }
    
    function updateSelectionBar() {
        const count = selectedClips.size;
        document.getElementById('selectedCount').textContent = count;
        document.getElementById('selectionBar').classList.toggle('active', count > 0);
        
        if (count > 0) {
            updateCommonTags();
        }
    }
    
    function updateCommonTags() {
        // Get tags from all selected clips
        const tagCounts = new Map(); // tag_id -> {tag_data, count}
        
        document.querySelectorAll('.clip-card.selected').forEach(card => {
            const tagsData = card.dataset.tags;
            if (!tagsData) return;
            
            try {
                const tags = JSON.parse(tagsData);
                tags.forEach(tag => {
                    if (!tagCounts.has(tag.tag_id)) {
                        tagCounts.set(tag.tag_id, { tag: tag, count: 0 });
                    }
                    tagCounts.get(tag.tag_id).count++;
                });
            } catch (e) {
                console.error('Error parsing tags:', e);
            }
        });
        
        // Display tags (show any tag that appears in at least one selected clip)
        const commonTagsDiv = document.getElementById('commonTags');
        commonTagsDiv.innerHTML = '';
        
        if (tagCounts.size === 0) {
            return;
        }
        
        // Sort by count (most common first)
        const sortedTags = Array.from(tagCounts.values())
            .sort((a, b) => b.count - a.count);
        
        sortedTags.forEach(({tag, count}) => {
            const tagSpan = document.createElement('span');
            tagSpan.className = 'selection-tag';
            tagSpan.style.backgroundColor = tag.color || '#95a5a6';
            tagSpan.title = `${tag.tag_name} appears in ${count} of ${selectedClips.size} selected clip(s). Click to remove from all.`;
            tagSpan.innerHTML = `
                ${tag.tag_name} (${count})
                <span class="selection-tag-remove">&#215;</span>
            `;
            tagSpan.onclick = () => batchRemoveTag(tag.tag_id, tag.tag_name);
            commonTagsDiv.appendChild(tagSpan);
        });
    }
    
    async function batchRemoveTag(tagId, tagName) {
        if (!confirm(`Remove tag "${tagName}" from all ${selectedClips.size} selected clip(s)?`)) {
            return;
        }
        
        const clipIds = Array.from(selectedClips);
        let successCount = 0;
        let errorCount = 0;
        const errors = [];
        
        console.log(`Removing tag from ${clipIds.length} clip(s) sequentially to avoid DB locking...`);
        
        // Process sequentially instead of parallel to avoid SQLite locking
        for (const clipId of clipIds) {
            try {
                const response = await fetch('actions/remove_clip_tag.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ clip_id: clipId, tag_id: tagId })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    successCount++;
                } else {
                    errorCount++;
                    errors.push(`Clip ${clipId}: ${data.message}`);
                }
            } catch (err) {
                errorCount++;
                errors.push(`Clip ${clipId}: Network error - ${err.message}`);
            }
        }
        
        console.log(`Completed: Success: ${successCount}, Errors: ${errorCount}`);
        
        if (errorCount > 0) {
            console.error('Errors:', errors);
            
            // Show first few errors in alert
            const errorSample = errors.slice(0, 5).join('\n');
            const moreErrors = errorCount > 5 ? `\n... and ${errorCount - 5} more errors` : '';
            alert(`Removed tag from ${successCount} of ${clipIds.length} clip(s) successfully.\n\nErrors:\n${errorSample}${moreErrors}\n\nFull error list in browser console (F12).`);
        }
        
        location.reload();
    }
    
    function clearSelection() {
        selectedClips.clear();
        document.querySelectorAll('.clip-checkbox').forEach(cb => cb.checked = false);
        document.querySelectorAll('.clip-card').forEach(card => card.classList.remove('selected'));
        updateSelectionBar();
    }
    
    function selectAll() {
        // Select all visible clips on the current page
        document.querySelectorAll('.clip-card').forEach(card => {
            const checkbox = card.querySelector('.clip-checkbox');
            const clipId = parseInt(checkbox.dataset.clipId);
            
            if (!checkbox.checked) {
                checkbox.checked = true;
                selectedClips.add(clipId);
                card.classList.add('selected');
            }
        });
        updateSelectionBar();
    }
    
    function selectNone() {
        clearSelection();
    }
    
    function openBatchTagModal() {
        if (selectedClips.size === 0) return;
        document.getElementById('batchCount').textContent = selectedClips.size;
        document.getElementById('batchTagModal').classList.add('active');
    }
    
    function closeBatchTagModal() {
        document.getElementById('batchTagModal').classList.remove('active');
    }
    
    async function batchAddTag(tagId) {
        const clipIds = Array.from(selectedClips);
        let successCount = 0;
        let errorCount = 0;
        const errors = [];
        
        // Show progress
        closeBatchTagModal();
        console.log(`Adding tag to ${clipIds.length} clip(s) sequentially to avoid DB locking...`);
        
        // Process sequentially instead of parallel to avoid SQLite locking
        for (const clipId of clipIds) {
            try {
                const response = await fetch('actions/add_clip_tag.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ clip_id: clipId, tag_id: tagId })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    successCount++;
                } else {
                    errorCount++;
                    errors.push(`Clip ${clipId}: ${data.message}`);
                }
            } catch (err) {
                errorCount++;
                errors.push(`Clip ${clipId}: Network error - ${err.message}`);
            }
        }
        
        console.log(`Completed: Success: ${successCount}, Errors: ${errorCount}`);
        
        if (errorCount > 0) {
            console.error('Errors:', errors);
            
            // Show first few errors in alert
            const errorSample = errors.slice(0, 5).join('\n');
            const moreErrors = errorCount > 5 ? `\n... and ${errorCount - 5} more errors` : '';
            alert(`Tagged ${successCount} of ${clipIds.length} clip(s) successfully.\n\nErrors:\n${errorSample}${moreErrors}\n\nFull error list in browser console (F12).`);
        }
        
        location.reload();
    }
    
    // Close modal on escape
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            closeBatchTagModal();
        }
    });
    
    // Close modal on background click
    document.getElementById('batchTagModal').addEventListener('click', e => {
        if (e.target.id === 'batchTagModal') closeBatchTagModal();
    });
    
    // Assignment Panel Functions
    function openAssignmentPanel() {
        const selectedClips = getSelectedClips();
        if (selectedClips.length === 0) {
            alert('Please select at least one clip');
            return;
        }
        document.getElementById('assignmentPanel').style.display = 'block';
    }
    
    function closeAssignmentPanel() {
        document.getElementById('assignmentPanel').style.display = 'none';
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
        
        if (confirm(`Assign ${clipIds.length} clip(s) to "${individualName}"?`)) {
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
            .then(d => {
                if (d.success) {
                    location.reload();
                } else {
                    alert('Error: ' + d.message);
                }
            });
        }
    }
    
    function createNewIndividual() {
        const clipIds = getSelectedClips();
        const newName = document.getElementById('newIndividualName').value.trim();
        
        if (clipIds.length === 0) {
            alert('Please select at least one clip');
            return;
        }
        
        if (!newName) {
            alert('Please enter a name for the new individual');
            return;
        }
        
        if (confirm(`Create new individual "${newName}" and assign ${clipIds.length} clip(s)?`)) {
            fetch('actions/assign_clips.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    clip_ids: clipIds, 
                    individual_name: newName,
                    mode: 'new' 
                })
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) {
                    location.reload();
                } else {
                    alert('Error: ' + d.message);
                }
            });
        }
    }
    </script>
</body>
</html>
