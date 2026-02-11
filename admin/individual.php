<?php
/**
 * Admin - Individual Detail Page
 * File management with Unknown/Delete/Default buttons + AI match suggestions
 */

require_once __DIR__ . '/../config.php';

$db = getDB();
$individual_id = isset($_GET['id']) ? $_GET['id'] : null;

if (!$individual_id) {
    header('Location: individuals.php');
    exit;
}

// Get individual
$stmt = $db->prepare("SELECT i.* FROM individuals i WHERE i.individual_id = ?");
$stmt->execute([$individual_id]);
$individual = $stmt->fetch();

if (!$individual) {
    header('Location: individuals.php');
    exit;
}

// Get tags
$tag_stmt = $db->prepare("
    SELECT t.* FROM tags t
    JOIN individual_tags it ON t.tag_id = it.tag_id
    WHERE it.individual_id = ?
");
$tag_stmt->execute([$individual_id]);
$individual['tags'] = $tag_stmt->fetchAll();

// Get all available tags for tagging
$all_individual_tags = $db->query("
    SELECT * FROM tags 
    WHERE tag_type IN ('individual', 'both')
    ORDER BY tag_name
")->fetchAll();

$all_clip_tags = $db->query("
    SELECT * FROM tags 
    WHERE tag_type IN ('clip', 'both')
    ORDER BY tag_name
")->fetchAll();

// Get all other individuals for merge dropdown
$other_individuals = $db->query("
    SELECT individual_id, name, 
           (SELECT COUNT(*) FROM clips WHERE folder_person = i.name AND clip_type = 'known') as clip_count
    FROM individuals i
    WHERE individual_id != $individual_id
    ORDER BY name
")->fetchAll();

// Get sort parameters
list($sort, $order) = getSortParams(
    ['filename', 'duration', 'dimensions', 'file_date', 'filesize'],
    'filename',
    'ASC'
);

$sort_map = [
    'filename' => 'c.filename',
    'duration' => 'c.duration',
    'dimensions' => '(c.width * c.height)',
    'file_date' => 'c.file_date',
    'filesize' => 'c.filesize',
    'tags' => '(SELECT COUNT(*) FROM clip_tags ct WHERE ct.clip_id = c.clip_id)'
];

$sort_sql = $sort_map[$sort] . ' ' . $order;

// Get folder clips
$stmt = $db->prepare("
    SELECT c.* FROM clips c
    WHERE c.clip_type = 'known' AND c.folder_person = ?
    ORDER BY $sort_sql
");
$stmt->execute([$individual['name']]);
$clips = $stmt->fetchAll();

// Get tags for clips
foreach ($clips as &$clip) {
    $tag_stmt = $db->prepare("
        SELECT t.* FROM tags t
        JOIN clip_tags ct ON t.tag_id = ct.tag_id
        WHERE ct.clip_id = ?
    ");
    $tag_stmt->execute([$clip['clip_id']]);
    $clip['tags'] = $tag_stmt->fetchAll();
}
unset($clip);

// Get AI suggestions - ALL matches including known clips from other individuals
$stmt = $db->prepare("
    SELECT 
        c.*,
        ci.confidence
    FROM clips c
    JOIN clip_individuals ci ON c.clip_id = ci.clip_id
    WHERE ci.individual_id = ?
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem 
        WHERE kem.clip_id = c.clip_id 
        AND kem.individual_id = ci.individual_id
    )
    AND NOT (c.clip_type = 'known' AND c.folder_person = ?)
    ORDER BY ci.confidence DESC
");
$stmt->execute([$individual_id, $individual['name']]);
$suggestions = $stmt->fetchAll();

// Get tags for suggestions
foreach ($suggestions as &$sug) {
    $tag_stmt = $db->prepare("
        SELECT t.* FROM tags t
        JOIN clip_tags ct ON t.tag_id = ct.tag_id
        WHERE ct.clip_id = ?
    ");
    $tag_stmt->execute([$sug['clip_id']]);
    $sug['tags'] = $tag_stmt->fetchAll();
}
unset($sug);

// Stats
$total_duration = array_sum(array_column($clips, 'duration'));
$total_size = array_sum(array_column($clips, 'filesize'));

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($individual['name']) ?> - Admin</title>
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
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header-top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
            gap: 30px;
        }
        .header-left { flex: 1; }
        .profile-thumbnail {
            width: 200px;
            height: 300px;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 72px;
            font-weight: bold;
        }
        .profile-thumbnail img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        .header-title {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 15px;
        }
        .header-title h1 {
            font-size: 32px;
            color: var(--primary-color);
        }
        .star-rating {
            font-size: 32px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .star-rating:hover { transform: scale(1.2); }
        .back-link {
            padding: 10px 20px;
            background: var(--primary-color);
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: 600;
            text-align: center;
            display: block;
        }
        .back-link:hover { opacity: 0.9; }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            font-size: 14px;
            text-align: center;
            transition: opacity 0.2s;
        }
        
        .btn:hover { opacity: 0.8; }
        
        .btn-merge {
            background: #3498db;
            color: white;
        }
        
        .btn-delete {
            background: #e74c3c;
            color: white;
        }
        
        .btn-icon {
            background: none;
            border: none;
            font-size: 20px;
            cursor: pointer;
            padding: 5px;
            opacity: 0.6;
            transition: opacity 0.2s;
        }
        
        .btn-icon:hover {
            opacity: 1;
        }
        
        .tags-container {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 15px;
        }
        .tag-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
            color: white;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-top: 20px;
        }
        .stat-box {
            background: var(--background-color);
            padding: 15px;
            border-radius: 8px;
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
        .section {
            background: white;
            border-radius: 8px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .section-title {
            font-size: 20px;
            font-weight: bold;
            color: var(--primary-color);
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--primary-color);
        }
        table { width: 100%; border-collapse: collapse; }
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
        }
        th a {
            color: white;
            text-decoration: none;
        }
        th a:hover { opacity: 0.8; }
        td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
            vertical-align: middle;
        }
        tbody tr:hover { background: #f8f9fa; }
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
        }
        .filename-link:hover { text-decoration: underline; }
        .folder-path {
            font-size: 11px;
            color: #95a5a6;
            margin-top: 3px;
        }
        .action-buttons {
            display: flex;
            gap: 5px;
            flex-wrap: wrap;
        }
        .btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        .btn:hover { opacity: 0.8; }
        .btn-unknown { background: #95a5a6; color: white; }
        .btn-delete { background: #e74c3c; color: white; }
        .btn-default { background: #3498db; color: white; }
        .btn-accept { background: #27ae60; color: white; }
        .btn-reject { background: #e67e22; color: white; }
        .confidence-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            color: white;
        }
        .confidence-high { background: #27ae60; }
        .confidence-medium { background: #f39c12; }
        .confidence-low { background: #e74c3c; }
        .no-data {
            text-align: center;
            padding: 40px 20px;
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
        .modal-message {
            margin-bottom: 20px;
            line-height: 1.6;
        }
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        @media (max-width: 767px) {
            .header-top { flex-direction: column; }
            .profile-thumbnail { width: 150px; height: 225px; font-size: 48px; }
            .stats-grid { grid-template-columns: 1fr; }
            .section { overflow-x: auto; }
            table { min-width: 800px; }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="header">
            <div class="header-top">
                <div class="header-left">
                    <div class="header-title">
                        <span class="star-rating" onclick="toggleStar(<?= $individual['individual_id'] ?>, <?= $individual['star_rating'] ?>)">
                            <?= getStarHTML($individual['star_rating'], false) ?>
                        </span>
                        <h1><?= htmlspecialchars($individual['name']) ?></h1>
                        <button class="btn-icon" onclick="openRenameModal()" title="Rename individual">
                            &#9999;&#65039;
                        </button>
                    </div>
                    
                    <div style="margin-bottom: 15px;">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
                            <strong>Tags:</strong>
                            <button class="btn-sm btn-primary" onclick="openIndividualTagModal()" style="font-size: 11px; padding: 4px 8px;">
                                + Add Tag
                            </button>
                        </div>
                        <div class="tags-container" id="individualTags">
                            <?php if (!empty($individual['tags'])): ?>
                                <?php foreach ($individual['tags'] as $tag): ?>
                                    <span class="tag-badge" style="background-color: <?= $tag['color'] ?? '#95a5a6' ?>; position: relative; padding-right: 25px;">
                                        <?= htmlspecialchars($tag['tag_name']) ?>
                                        <span onclick="removeIndividualTag(<?= $tag['tag_id'] ?>)" 
                                              style="position: absolute; right: 5px; top: 50%; transform: translateY(-50%); cursor: pointer; font-weight: bold; opacity: 0.8;"
                                              title="Remove tag">
                                            &#8592;
                                        </span>
                                    </span>
                                <?php endforeach; ?>
                            <?php else: ?>
                                <span style="color: #999; font-size: 13px;">No tags</span>
                            <?php endif; ?>
                        </div>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-box">
                            <div class="stat-label">Folder Clips</div>
                            <div class="stat-value"><?= count($clips) ?></div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Total Duration</div>
                            <div class="stat-value"><?= formatDuration($total_duration) ?></div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">AI Matches</div>
                            <div class="stat-value"><?= count($suggestions) ?></div>
                        </div>
                    </div>
                </div>
                
                <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 15px;">
                    <?php
                    $thumb_stmt = $db->prepare("SELECT c.thumbnail_path FROM clips c WHERE c.clip_id = ?");
                    $thumb_stmt->execute([$individual['default_thumbnail_clip_id']]);
                    $thumbnail = $thumb_stmt->fetchColumn();
                    
                    // Check if individual can be deleted (no clips, no pending matches)
                    $can_delete = (count($clips) === 0 && count($suggestions) === 0);
                    ?>
                    <div class="profile-thumbnail">
                        <?php if (!empty($thumbnail)): ?>
                            <img src="../<?= htmlspecialchars($thumbnail) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                        <?php else: ?>
                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                        <?php endif; ?>
                    </div>
                    
                    <div style="display: flex; flex-direction: column; gap: 10px; width: 100%;">
                        <button class="btn btn-merge" onclick="openMergeModal()">
                            &#128256; Merge Into Another
                        </button>
                        
                        <?php if ($can_delete): ?>
                            <button class="btn btn-delete" onclick="deleteIndividual(<?= $individual_id ?>, '<?= addslashes($individual['name']) ?>')">
                                &#128465;&#65039; Delete Individual
                            </button>
                        <?php endif; ?>
                        
                        <a href="individuals.php" class="back-link">&#8592; Back</a>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Section 1: Folder Files -->
        <div class="section">
            <div class="section-title">&#128193; Clips in Folder (<?= count($clips) ?>)</div>
            
            <?php if (count($clips) > 0): ?>
                <table>
                    <thead>
                        <tr>
                            <th style="width: 100px;">Thumbnail</th>
                            <th>
                                <a href="?id=<?= $individual_id ?>&sort=filename&order=<?= $sort === 'filename' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Filename <?= $sort === 'filename' ? ($order === 'ASC' ? '&#9650;' : '&#9660;') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?id=<?= $individual_id ?>&sort=duration&order=<?= $sort === 'duration' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Duration <?= $sort === 'duration' ? ($order === 'ASC' ? '&#9650;' : '&#9660;') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?id=<?= $individual_id ?>&sort=dimensions&order=<?= $sort === 'dimensions' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Dimensions <?= $sort === 'dimensions' ? ($order === 'ASC' ? '&#9650;' : '&#9660;') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?id=<?= $individual_id ?>&sort=file_date&order=<?= $sort === 'file_date' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Date <?= $sort === 'file_date' ? ($order === 'ASC' ? '&#9650;' : '&#9660;') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?id=<?= $individual_id ?>&sort=tags&order=<?= $sort === 'tags' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Tags <?= $sort === 'tags' ? ($order === 'ASC' ? '&#9650;' : '&#9660;') : '' ?>
                                </a>
                            </th>
                            <th style="width: 200px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($clips as $clip): ?>
                            <?php
                            $video_path = '../videos/known/' . $clip['filepath'];
                            $thumb_path = '../' . $clip['thumbnail_path'];
                            $is_default = ($clip['clip_id'] == $individual['default_thumbnail_clip_id']);
                            ?>
                            <tr>
                                <td>
                                    <?php if (!empty($clip['thumbnail_path'])): ?>
                                        <a href="<?= htmlspecialchars($video_path) ?>" target="_blank">
                                            <img src="<?= htmlspecialchars($thumb_path) ?>" class="thumbnail">
                                        </a>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="<?= htmlspecialchars($video_path) ?>" class="filename-link" target="_blank">
                                        <?= htmlspecialchars($clip['filename']) ?>
                                    </a>
                                    <div class="folder-path">videos/known/<?= htmlspecialchars($clip['filepath']) ?></div>
                                </td>
                                <td><?= htmlspecialchars($clip['duration_text']) ?></td>
                                <td><?= $clip['width'] ?> &#215; <?= $clip['height'] ?></td>
                                <td><?= date('Y-m-d', strtotime($clip['file_date'])) ?></td>
                                <td>
                                    <div style="display: flex; flex-wrap: wrap; gap: 5px; align-items: center;">
                                        <?php if (!empty($clip['tags'])): ?>
                                            <?php foreach ($clip['tags'] as $tag): ?>
                                                <span class="tag-badge" style="background-color: <?= $tag['color'] ?? '#95a5a6' ?>; position: relative; padding-right: 25px;">
                                                    <?= htmlspecialchars($tag['tag_name']) ?>
                                                    <span onclick="removeClipTag(<?= $clip['clip_id'] ?>, <?= $tag['tag_id'] ?>)" 
                                                          style="position: absolute; right: 5px; top: 50%; transform: translateY(-50%); cursor: pointer; font-weight: bold; opacity: 0.8;"
                                                          title="Remove tag">
                                                        &#8592;
                                                    </span>
                                                </span>
                                            <?php endforeach; ?>
                                        <?php endif; ?>
                                        <button class="btn-sm btn-secondary" onclick="openClipTagModal(<?= $clip['clip_id'] ?>)" style="font-size: 10px; padding: 3px 6px;">
                                            + Tag
                                        </button>
                                    </div>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-unknown" onclick="moveToUnknown(<?= $clip['clip_id'] ?>, '<?= addslashes($clip['filename']) ?>')">Unknown</button>
                                        <button class="btn btn-delete" onclick="deleteClip(<?= $clip['clip_id'] ?>, '<?= addslashes($clip['filename']) ?>')">Delete</button>
                                        <?php if (!$is_default): ?>
                                            <button class="btn btn-default" onclick="setDefault(<?= $clip['clip_id'] ?>, <?= $individual_id ?>)">Default</button>
                                        <?php else: ?>
                                            <span style="color: #3498db; font-size: 11px; font-weight: 600;">&#9733; DEFAULT</span>
                                        <?php endif; ?>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="no-data">
                    <h3>No clips in folder</h3>
                </div>
            <?php endif; ?>
        </div>
        
        <!-- Section 2: AI Suggestions -->
        <div class="section">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                <div class="section-title" style="margin-bottom: 0;">&#129302; AI Match Suggestions - All Clips (<?= count($suggestions) ?>)</div>
                <button class="btn btn-merge" onclick="forceRematch()" style="padding: 8px 16px;">
                    &#128260; Force Re-match
                </button>
            </div>
            
            <?php if (count($suggestions) > 0): ?>
                <!-- Bulk Actions -->
                <div style="margin-bottom: 15px; padding: 15px; background: #f8f9fa; border-radius: 4px; display: flex; gap: 10px; align-items: center;">
                    <button class="btn-sm btn-secondary" onclick="selectAllMatches()">Select All</button>
                    <button class="btn-sm btn-secondary" onclick="selectKnownMatches()">Select Known</button>
                    <button class="btn-sm btn-secondary" onclick="selectUnknownMatches()">Select Unknown</button>
                    <button class="btn-sm btn-secondary" onclick="selectNoneMatches()">Select None</button>
                    <span style="margin-left: 10px; color: #666;" id="selectedCount">0 selected</span>
                    <div style="margin-left: auto; display: flex; gap: 10px;">
                        <button class="btn btn-accept" onclick="acceptSelectedMatches()" id="acceptSelectedBtn" disabled>Accept Selected</button>
                        <button class="btn btn-reject" onclick="rejectSelectedMatches()" id="rejectSelectedBtn" disabled>Reject Selected</button>
                    </div>
                </div>
                
                <table>
                    <thead>
                        <tr>
                            <th style="width: 40px;"><input type="checkbox" id="selectAllCheckbox" onchange="toggleAllMatches(this)"></th>
                            <th style="width: 100px;">Thumbnail</th>
                            <th style="cursor: pointer;" onclick="sortMatches()">
                                <span id="sortLabel">Filename &#9660;</span>
                            </th>
                            <th style="cursor: pointer;" onclick="sortByColumn('duration')">
                                <span id="durationSortLabel">Duration</span>
                            </th>
                            <th style="cursor: pointer;" onclick="sortByColumn('dimensions')">
                                <span id="dimensionsSortLabel">Dimensions</span>
                            </th>
                            <th style="cursor: pointer;" onclick="sortByColumn('date')">
                                <span id="dateSortLabel">Date</span>
                            </th>
                            <th style="cursor: pointer;" onclick="sortByConfidence()">
                                <span id="confidenceSortLabel">Confidence &#9660;</span>
                            </th>
                            <th style="cursor: pointer;" onclick="sortByColumn('tags')">
                                <span id="tagsSortLabel">Tags</span>
                            </th>
                            <th style="width: 200px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="matchesTableBody">
                        <?php foreach ($suggestions as $sug): ?>
                            <?php
                            // Determine video path based on clip type
                            $is_known = ($sug['clip_type'] === 'known');
                            $video_dir = $is_known ? '../videos/known/' : '../videos/unknown/';
                            $video_path = $video_dir . $sug['filepath'];
                            $thumb_path = '../' . $sug['thumbnail_path'];
                            $conf_pct = round($sug['confidence'] * 100);
                            $conf_class = $conf_pct >= 80 ? 'confidence-high' : ($conf_pct >= 60 ? 'confidence-medium' : 'confidence-low');
                            ?>
                            <tr data-clip-id="<?= $sug['clip_id'] ?>" 
                                data-filename="<?= htmlspecialchars($sug['filename']) ?>" 
                                data-filepath="<?= htmlspecialchars($sug['filepath']) ?>"
                                data-confidence="<?= $sug['confidence'] ?>"
                                data-clip-type="<?= $sug['clip_type'] ?>"
                                data-duration="<?= $sug['duration'] ?>"
                                data-dimensions="<?= $sug['width'] * $sug['height'] ?>"
                                data-date="<?= $sug['file_date'] ?>"
                                data-tags="<?= count($sug['tags'] ?? []) ?>">
                                <td>
                                    <input type="checkbox" class="match-checkbox" value="<?= $sug['clip_id'] ?>" onchange="updateSelectedCount()">
                                </td>
                                <td>
                                    <?php if (!empty($sug['thumbnail_path'])): ?>
                                        <a href="<?= htmlspecialchars($video_path) ?>" target="_blank">
                                            <img src="<?= htmlspecialchars($thumb_path) ?>" class="thumbnail">
                                        </a>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="<?= htmlspecialchars($video_path) ?>" class="filename-link" target="_blank" style="display: block; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<?= htmlspecialchars($sug['filename']) ?>">
                                        <?= htmlspecialchars($sug['filename']) ?>
                                    </a>
                                    <div class="folder-path" style="max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<?= $is_known ? 'videos/known/' : 'videos/unknown/' ?><?= htmlspecialchars($sug['filepath']) ?>">
                                        <?php if ($is_known): ?>
                                            <strong style="color: #e67e22;">KNOWN:</strong> videos/known/<?= htmlspecialchars($sug['filepath']) ?>
                                        <?php else: ?>
                                            videos/unknown/<?= htmlspecialchars($sug['filepath']) ?>
                                        <?php endif; ?>
                                    </div>
                                </td>
                                <td><?= htmlspecialchars($sug['duration_text']) ?></td>
                                <td><?= $sug['width'] ?> &#215; <?= $sug['height'] ?></td>
                                <td><?= date('Y-m-d', strtotime($sug['file_date'])) ?></td>
                                <td>
                                    <span class="confidence-badge <?= $conf_class ?>">
                                        <?= $conf_pct ?>%
                                    </span>
                                </td>
                                <td>
                                    <?php if (!empty($sug['tags'])): ?>
                                        <?= getTagsHTML($sug['tags'], false) ?>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-accept" onclick="acceptMatch(<?= $sug['clip_id'] ?>, <?= $individual_id ?>, '<?= addslashes($sug['filename']) ?>')">Accept</button>
                                        <button class="btn btn-reject" onclick="rejectMatch(<?= $sug['clip_id'] ?>, <?= $individual_id ?>, '<?= addslashes($sug['filename']) ?>')">Reject</button>
                                        <button class="btn btn-delete" onclick="deleteClip(<?= $sug['clip_id'] ?>, '<?= addslashes($sug['filename']) ?>')">Delete</button>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="no-data">
                    <h3>No AI match suggestions</h3>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <div id="confirmModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">&#9888; Confirm Action</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-unknown" onclick="closeModal()">Cancel</button>
                <button class="btn btn-delete" id="confirmButton">Yes, Continue</button>
            </div>
        </div>
    </div>
    
    <!-- Merge Modal -->
    <div id="mergeModal" class="modal">
        <div class="modal-content" style="max-width: 600px;">
            <div class="modal-title">&#128256; Merge Individual</div>
            <div class="modal-message">
                <p style="margin-bottom: 15px;">
                    Merge <strong><?= htmlspecialchars($individual['name']) ?></strong> into another individual. This will:
                </p>
                <ul style="margin-left: 20px; margin-bottom: 20px; line-height: 1.8;">
                    <li>Move all <?= count($clips) ?> clip(s) to the target individual's folder</li>
                    <li>Transfer all tags</li>
                    <li>Update all face profiles and AI matches</li>
                    <li>Delete this individual</li>
                </ul>
                
                <div style="margin-bottom: 15px;">
                    <label style="display: block; font-weight: 600; margin-bottom: 5px;">Merge into:</label>
                    <select id="mergeTarget" style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px;">
                        <option value="">-- Select Individual --</option>
                        <?php foreach ($other_individuals as $other): ?>
                            <option value="<?= $other['individual_id'] ?>">
                                <?= htmlspecialchars($other['name']) ?> (<?= $other['clip_count'] ?> clips)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                
                <div style="background: #fff3cd; border: 1px solid #ffc107; color: #856404; padding: 15px; border-radius: 4px; margin-top: 15px;">
                    <strong>&#9888; Warning:</strong> This action cannot be undone!
                </div>
            </div>
            <div class="modal-buttons" style="margin-top: 20px;">
                <button class="btn btn-unknown" onclick="closeMergeModal()">Cancel</button>
                <button class="btn btn-delete" onclick="confirmMerge()">Merge</button>
            </div>
        </div>
    </div>
    
    <!-- Rename Modal -->
    <div id="renameModal" class="modal">
        <div class="modal-content" style="max-width: 500px;">
            <div class="modal-title">&#9999;&#65039; Rename Individual</div>
            <div class="modal-message">
                <p style="margin-bottom: 15px;">
                    Current name: <strong><?= htmlspecialchars($individual['name']) ?></strong>
                </p>
                
                <div style="margin-bottom: 15px;">
                    <label style="display: block; font-weight: 600; margin-bottom: 5px;">New name:</label>
                    <input type="text" id="newName" 
                           value="<?= htmlspecialchars($individual['name']) ?>" 
                           style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px;">
                    <div id="nameError" style="color: #e74c3c; margin-top: 5px; font-size: 13px; display: none;"></div>
                </div>
                
                <div style="background: #e3f2fd; border: 1px solid #2196f3; color: #1565c0; padding: 15px; border-radius: 4px;">
                    <strong>&#9999;&#65039; This will:</strong>
                    <ul style="margin: 10px 0 0 20px; line-height: 1.8;">
                        <li>Rename the folder (videos/known/<?= htmlspecialchars($individual['name']) ?>)</li>
                        <li>Update <?= count($clips) ?> clip(s) in database</li>
                        <li>Update all references</li>
                    </ul>
                </div>
            </div>
            <div class="modal-buttons" style="margin-top: 20px;">
                <button class="btn btn-unknown" onclick="closeRenameModal()">Cancel</button>
                <button class="btn btn-primary" onclick="confirmRename()">Rename</button>
            </div>
        </div>
    </div>
    
    <!-- Add Individual Tag Modal -->
    <div id="individualTagModal" class="modal">
        <div class="modal-content" style="max-width: 400px;">
            <div class="modal-title">&#9999;&#65039; Add Tag to Individual</div>
            <div class="modal-message">
                <p style="margin-bottom: 10px;">Select a tag to add:</p>
                <div style="max-height: 300px; overflow-y: auto;">
                    <?php foreach ($all_individual_tags as $tag): ?>
                        <div class="tag-option" onclick="addIndividualTag(<?= $tag['tag_id'] ?>)" 
                             style="padding: 10px; margin: 5px 0; border-radius: 4px; cursor: pointer; background: #f8f9fa;">
                            <span class="tag-badge" style="background-color: <?= $tag['color'] ?? '#95a5a6' ?>">
                                <?= htmlspecialchars($tag['tag_name']) ?>
                            </span>
                        </div>
                    <?php endforeach; ?>
                    <?php if (empty($all_individual_tags)): ?>
                        <p style="color: #999;">No tags available. Create tags in the Tags page first.</p>
                    <?php endif; ?>
                </div>
            </div>
            <div class="modal-buttons" style="margin-top: 15px;">
                <button class="btn btn-secondary" onclick="closeIndividualTagModal()">Cancel</button>
            </div>
        </div>
    </div>
    
    <!-- Add Clip Tag Modal -->
    <div id="clipTagModal" class="modal">
        <div class="modal-content" style="max-width: 400px;">
            <div class="modal-title">&#9999;&#65039; Add Tag to Clip</div>
            <div class="modal-message">
                <input type="hidden" id="tagClipId" value="">
                <p style="margin-bottom: 10px;">Select a tag to add:</p>
                <div style="max-height: 300px; overflow-y: auto;">
                    <?php foreach ($all_clip_tags as $tag): ?>
                        <div class="tag-option" onclick="addClipTag(<?= $tag['tag_id'] ?>)" 
                             style="padding: 10px; margin: 5px 0; border-radius: 4px; cursor: pointer; background: #f8f9fa;">
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
                <button class="btn btn-secondary" onclick="closeClipTagModal()">Cancel</button>
            </div>
        </div>
    </div>
    
    <script>
    // Star rating toggle - no confirmation needed
    function toggleStar(id, curr) {
        const next = (curr + 1) % 4;
        
        fetch('actions/update_star.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ individual_id: id, star_rating: next })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function moveToUnknown(id, name) {
        showConfirm(`Move "${name}" to unknown folder?`, () => {
            fetch('actions/move_to_unknown.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: id })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function deleteClip(id, name) {
        showConfirm(`Delete "${name}"? This cannot be undone.`, () => {
            fetch('actions/delete_clip.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: id })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function setDefault(clipId, indId) {
        fetch('actions/set_default_thumbnail.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip_id: clipId, individual_id: indId })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function acceptMatch(clipId, indId, name) {
        fetch('actions/accept_match.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip_id: clipId, individual_id: indId })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function rejectMatch(clipId, indId, name) {
        fetch('actions/reject_match.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip_id: clipId, individual_id: indId })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function showConfirm(msg, cb) {
        document.getElementById('confirmMessage').textContent = msg;
        document.getElementById('confirmModal').classList.add('active');
        document.getElementById('confirmButton').onclick = () => { closeModal(); cb(); };
    }
    
    function closeModal() {
        document.getElementById('confirmModal').classList.remove('active');
    }
    
    // Merge individual functions
    function openMergeModal() {
        document.getElementById('mergeModal').classList.add('active');
        document.getElementById('mergeTarget').value = '';
    }
    
    function closeMergeModal() {
        document.getElementById('mergeModal').classList.remove('active');
    }
    
    function confirmMerge() {
        const targetId = document.getElementById('mergeTarget').value;
        
        if (!targetId) {
            alert('Please select an individual to merge into');
            return;
        }
        
        const targetName = document.getElementById('mergeTarget').selectedOptions[0].text;
        
        if (!confirm(`Are you absolutely sure you want to merge into "${targetName}"? This cannot be undone!`)) {
            return;
        }
        
        fetch('actions/merge_individuals.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                source_id: <?= $individual_id ?>,
                target_id: parseInt(targetId)
            })
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                window.location.href = 'individual.php?id=' + targetId;
            } else {
                alert('Error: ' + d.message);
            }
        });
    }
    
    // Delete individual function
    function deleteIndividual(id, name) {
        if (!confirm(`Delete individual "${name}"? This cannot be undone!`)) {
            return;
        }
        
        fetch('actions/delete_individual.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ individual_id: id })
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                window.location.href = 'individuals.php';
            } else {
                alert('Error: ' + d.message);
            }
        });
    }
    
    document.addEventListener('keydown', e => { 
        if (e.key === 'Escape') {
            closeModal();
            closeMergeModal();
            closeRenameModal();
        }
    });
    document.getElementById('confirmModal').addEventListener('click', e => { if (e.target.id === 'confirmModal') closeModal(); });
    document.getElementById('mergeModal').addEventListener('click', e => { if (e.target.id === 'mergeModal') closeMergeModal(); });
    document.getElementById('renameModal').addEventListener('click', e => { if (e.target.id === 'renameModal') closeRenameModal(); });
    
    // Rename individual functions
    function openRenameModal() {
        document.getElementById('renameModal').classList.add('active');
        document.getElementById('newName').focus();
        document.getElementById('newName').select();
        document.getElementById('nameError').style.display = 'none';
    }
    
    function closeRenameModal() {
        document.getElementById('renameModal').classList.remove('active');
        document.getElementById('nameError').style.display = 'none';
    }
    
    function confirmRename() {
        const newName = document.getElementById('newName').value.trim();
        const errorDiv = document.getElementById('nameError');
        
        if (!newName) {
            errorDiv.textContent = 'Name cannot be empty';
            errorDiv.style.display = 'block';
            return;
        }
        
        if (newName === '<?= addslashes($individual['name']) ?>') {
            errorDiv.textContent = 'New name is the same as current name';
            errorDiv.style.display = 'block';
            return;
        }
        
        // Check for invalid characters
        if (/[\/\\:*?"<>|]/.test(newName)) {
            errorDiv.textContent = 'Name contains invalid characters (/ \\ : * ? " < > |)';
            errorDiv.style.display = 'block';
            return;
        }
        
        if (!confirm(`Rename individual to "${newName}"?`)) {
            return;
        }
        
        fetch('actions/rename_individual.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                individual_id: <?= $individual_id ?>,
                new_name: newName
            })
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                // Reload page to show new name
                location.reload();
            } else {
                errorDiv.textContent = d.message;
                errorDiv.style.display = 'block';
            }
        })
        .catch(err => {
            errorDiv.textContent = 'Error: ' + err.message;
            errorDiv.style.display = 'block';
        });
    }
    
    // Allow Enter key to confirm rename
    document.addEventListener('DOMContentLoaded', function() {
        const renameInput = document.getElementById('newName');
        if (renameInput) {
            renameInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    confirmRename();
                }
            });
        }
    });
    
    // Individual tag management
    function openIndividualTagModal() {
        document.getElementById('individualTagModal').classList.add('active');
    }
    
    function closeIndividualTagModal() {
        document.getElementById('individualTagModal').classList.remove('active');
    }
    
    function addIndividualTag(tagId) {
        fetch('actions/add_individual_tag.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                individual_id: <?= $individual_id ?>,
                tag_id: tagId
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
    
    function removeIndividualTag(tagId) {
        if (!confirm('Remove this tag?')) return;
        
        fetch('actions/remove_individual_tag.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                individual_id: <?= $individual_id ?>,
                tag_id: tagId
            })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    // Clip tag management
    function openClipTagModal(clipId) {
        document.getElementById('tagClipId').value = clipId;
        document.getElementById('clipTagModal').classList.add('active');
    }
    
    function closeClipTagModal() {
        document.getElementById('clipTagModal').classList.remove('active');
    }
    
    function addClipTag(tagId) {
        const clipId = document.getElementById('tagClipId').value;
        
        fetch('actions/add_clip_tag.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                clip_id: parseInt(clipId),
                tag_id: tagId
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
    
    function removeClipTag(clipId, tagId) {
        if (!confirm('Remove this tag?')) return;
        
        fetch('actions/remove_clip_tag.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                clip_id: clipId,
                tag_id: tagId
            })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    // Force re-match individual
    function forceRematch() {
        if (!confirm(
            'This will:\n' +
            '1. Clear all rejected matches for this individual\n' +
            '2. Re-run matching against ALL clips (known and unknown)\n' +
            '3. Refresh the page to show new matches\n\n' +
            'Continue?'
        )) {
            return;
        }
        
        const thresholdHelp = 
            'Matching Threshold (0.0 to 1.0):\n\n' +
            'Lower values = stricter matching (fewer false positives)\n' +
            'Higher values = looser matching (may include false positives)\n\n' +
            'Recommended values:\n' +
            '\u2022 0.4-0.5 = Very strict (high confidence only)\n' +
            '\u2022 0.6 = Default (balanced)\n' +
            '\u2022 0.7-0.8 = Permissive (more matches, check carefully)\n\n' +
            'Enter threshold value:';
        
        const threshold = prompt(thresholdHelp, '0.6');
        if (threshold === null) return; // User cancelled
        
        const thresholdFloat = parseFloat(threshold);
        if (isNaN(thresholdFloat) || thresholdFloat < 0 || thresholdFloat > 1) {
            alert('Invalid threshold. Please enter a number between 0.0 and 1.0');
            return;
        }
        
        // Show loading indicator
        const btn = event.target;
        btn.disabled = true;
        btn.textContent = 'Re-matching...';
        
        fetch('actions/force_rematch_individual.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                individual_id: <?= $individual_id ?>,
                threshold: thresholdFloat
            })
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                alert(
                    'Re-match completed!\n\n' +
                    'Cleared rejections: ' + d.data.cleared_rejections + '\n' +
                    'Clips evaluated: ' + d.data.clips_evaluated + '\n' +
                    'New matches found: ' + d.data.new_matches + '\n' +
                    'Threshold used: ' + d.data.threshold
                );
                location.reload();
            } else {
                let errorMsg = 'Error: ' + d.message;
                if (d.data && d.data.output) {
                    errorMsg += '\n\nDebug info:\n' + d.data.output.join('\n');
                }
                alert(errorMsg);
                btn.disabled = false;
                btn.textContent = '&#128260; Force Re-match';
            }
        })
        .catch(err => {
            alert('Error: ' + err.message);
            btn.disabled = false;
            btn.textContent = '&#128260; Force Re-match';
        });
    }
    
    // Bulk match selection functions
    let sortState = 0; // 0=filename asc, 1=path asc, 2=filename desc, 3=path desc
    
    function updateSelectedCount() {
        const checkboxes = document.querySelectorAll('.match-checkbox');
        const checked = Array.from(checkboxes).filter(cb => cb.checked);
        document.getElementById('selectedCount').textContent = checked.length + ' selected';
        document.getElementById('acceptSelectedBtn').disabled = checked.length === 0;
        document.getElementById('rejectSelectedBtn').disabled = checked.length === 0;
        
        // Update select all checkbox state
        const selectAll = document.getElementById('selectAllCheckbox');
        if (checked.length === 0) {
            selectAll.checked = false;
            selectAll.indeterminate = false;
        } else if (checked.length === checkboxes.length) {
            selectAll.checked = true;
            selectAll.indeterminate = false;
        } else {
            selectAll.checked = false;
            selectAll.indeterminate = true;
        }
    }
    
    function toggleAllMatches(checkbox) {
        const checkboxes = document.querySelectorAll('.match-checkbox');
        checkboxes.forEach(cb => cb.checked = checkbox.checked);
        updateSelectedCount();
    }
    
    function selectAllMatches() {
        document.querySelectorAll('.match-checkbox').forEach(cb => cb.checked = true);
        updateSelectedCount();
    }
    
    function selectNoneMatches() {
        document.querySelectorAll('.match-checkbox').forEach(cb => cb.checked = false);
        updateSelectedCount();
    }
    
    function selectKnownMatches() {
        document.querySelectorAll('.match-checkbox').forEach(cb => {
            const row = cb.closest('tr');
            cb.checked = (row.dataset.clipType === 'known');
        });
        updateSelectedCount();
    }
    
    function selectUnknownMatches() {
        document.querySelectorAll('.match-checkbox').forEach(cb => {
            const row = cb.closest('tr');
            cb.checked = (row.dataset.clipType === 'unknown');
        });
        updateSelectedCount();
    }
    
    function acceptSelectedMatches() {
        const checked = Array.from(document.querySelectorAll('.match-checkbox:checked'));
        if (checked.length === 0) return;
        
        if (!confirm(`Accept ${checked.length} match(es)?`)) return;
        
        let completed = 0;
        checked.forEach(cb => {
            const clipId = parseInt(cb.value);
            const row = cb.closest('tr');
            const filename = row.dataset.filename;
            
            fetch('actions/accept_match.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    clip_id: clipId,
                    individual_id: <?= $individual_id ?>
                })
            })
            .then(r => r.json())
            .then(d => {
                completed++;
                if (completed === checked.length) {
                    location.reload();
                }
            });
        });
    }
    
    function rejectSelectedMatches() {
        const checked = Array.from(document.querySelectorAll('.match-checkbox:checked'));
        if (checked.length === 0) return;
        
        if (!confirm(`Reject ${checked.length} match(es)?`)) return;
        
        let completed = 0;
        checked.forEach(cb => {
            const clipId = parseInt(cb.value);
            const row = cb.closest('tr');
            const filename = row.dataset.filename;
            
            fetch('actions/reject_match.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    clip_id: clipId,
                    individual_id: <?= $individual_id ?>
                })
            })
            .then(r => r.json())
            .then(d => {
                completed++;
                if (completed === checked.length) {
                    location.reload();
                }
            });
        });
    }
    
    function sortMatches() {
        const tbody = document.getElementById('matchesTableBody');
        const rows = Array.from(tbody.querySelectorAll('tr'));
        
        const labels = [
            'Filename &#9660;', 
            'Path &#9660;', 
            'Filename &#9650;', 
            'Path &#9650;'
        ];
        
        rows.sort((a, b) => {
            const aFilename = a.dataset.filename;
            const bFilename = b.dataset.filename;
            const aPath = a.dataset.filepath;
            const bPath = b.dataset.filepath;
            
            switch(sortState) {
                case 0: // filename asc
                    return aFilename.localeCompare(bFilename);
                case 1: // path asc
                    return aPath.localeCompare(bPath);
                case 2: // filename desc
                    return bFilename.localeCompare(aFilename);
                case 3: // path desc
                    return bPath.localeCompare(aPath);
            }
        });
        
        rows.forEach(row => tbody.appendChild(row));
        
        sortState = (sortState + 1) % 4;
        document.getElementById('sortLabel').textContent = labels[sortState];
    }
    
    // Confidence sorting
    let confidenceSortDescending = true; // Start with high to low
    
    function sortByConfidence() {
        const tbody = document.getElementById('matchesTableBody');
        const rows = Array.from(tbody.querySelectorAll('tr'));
        
        rows.sort((a, b) => {
            const aConf = parseFloat(a.dataset.confidence);
            const bConf = parseFloat(b.dataset.confidence);
            
            if (confidenceSortDescending) {
                return bConf - aConf; // High to low
            } else {
                return aConf - bConf; // Low to high
            }
        });
        
        rows.forEach(row => tbody.appendChild(row));
        
        confidenceSortDescending = !confidenceSortDescending;
        document.getElementById('confidenceSortLabel').textContent = 
            confidenceSortDescending ? 'Confidence &#9660;' : 'Confidence &#9650;';
    }
    
    // Generic column sorting
    let columnSortState = {};
    
    function sortByColumn(column) {
        const tbody = document.getElementById('matchesTableBody');
        const rows = Array.from(tbody.querySelectorAll('tr'));
        
        // Initialize sort state for this column
        if (!columnSortState[column]) {
            columnSortState[column] = { descending: true };
        }
        
        const descending = columnSortState[column].descending;
        
        rows.sort((a, b) => {
            let aVal = a.dataset[column];
            let bVal = b.dataset[column];
            
            // Convert to numbers for numeric sorting
            if (column === 'duration' || column === 'dimensions' || column === 'tags') {
                aVal = parseFloat(aVal) || 0;
                bVal = parseFloat(bVal) || 0;
                return descending ? bVal - aVal : aVal - bVal;
            }
            
            // String sorting for date
            return descending ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);
        });
        
        rows.forEach(row => tbody.appendChild(row));
        
        // Toggle sort direction
        columnSortState[column].descending = !descending;
        
        // Update label
        const labelId = column + 'SortLabel';
        const label = document.getElementById(labelId);
        const columnName = column.charAt(0).toUpperCase() + column.slice(1);
        label.textContent = columnName + (descending ? ' &#9650;' : ' &#9660;');
    }
    
    // Close tag modals on Escape
    document.addEventListener('keydown', e => { 
        if (e.key === 'Escape') {
            closeModal();
            closeMergeModal();
            closeRenameModal();
            closeIndividualTagModal();
            closeClipTagModal();
        }
    });
    document.getElementById('individualTagModal').addEventListener('click', e => { if (e.target.id === 'individualTagModal') closeIndividualTagModal(); });
    document.getElementById('clipTagModal').addEventListener('click', e => { if (e.target.id === 'clipTagModal') closeClipTagModal(); });
    </script>
</body>
</html>