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
    'filesize' => 'c.filesize'
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

// Get AI suggestions
$stmt = $db->prepare("
    SELECT 
        c.*,
        ci.confidence
    FROM clips c
    JOIN clip_individuals ci ON c.clip_id = ci.clip_id
    WHERE ci.individual_id = ?
    AND c.clip_type = 'unknown'
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem 
        WHERE kem.clip_id = c.clip_id 
        AND kem.individual_id = ci.individual_id
    )
    ORDER BY ci.confidence DESC
");
$stmt->execute([$individual_id]);
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
        }
        .back-link:hover { opacity: 0.9; }
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
                    </div>
                    
                    <?php if (!empty($individual['tags'])): ?>
                        <?= getTagsHTML($individual['tags'], false) ?>
                    <?php endif; ?>
                    
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
                    ?>
                    <div class="profile-thumbnail">
                        <?php if (!empty($thumbnail)): ?>
                            <img src="../<?= htmlspecialchars($thumbnail) ?>" alt="<?= htmlspecialchars($individual['name']) ?>">
                        <?php else: ?>
                            <?= htmlspecialchars(substr($individual['name'], 0, 1)) ?>
                        <?php endif; ?>
                    </div>
                    
                    <a href="individuals.php" class="back-link">&#8592; Back</a>
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
                            <th>Duration</th>
                            <th>Dimensions</th>
                            <th>Date</th>
                            <th>Tags</th>
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
                                    <?php if (!empty($clip['tags'])): ?>
                                        <?= getTagsHTML($clip['tags'], false) ?>
                                    <?php endif; ?>
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
            <div class="section-title">&#129302; AI Match Suggestions (<?= count($suggestions) ?>)</div>
            
            <?php if (count($suggestions) > 0): ?>
                <table>
                    <thead>
                        <tr>
                            <th style="width: 100px;">Thumbnail</th>
                            <th>Filename</th>
                            <th>Duration</th>
                            <th>Dimensions</th>
                            <th>Date</th>
                            <th>Confidence</th>
                            <th>Tags</th>
                            <th style="width: 200px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($suggestions as $sug): ?>
                            <?php
                            $video_path = '../videos/unknown/' . $sug['filepath'];
                            $thumb_path = '../' . $sug['thumbnail_path'];
                            $conf_pct = round($sug['confidence'] * 100);
                            $conf_class = $conf_pct >= 80 ? 'confidence-high' : ($conf_pct >= 60 ? 'confidence-medium' : 'confidence-low');
                            ?>
                            <tr>
                                <td>
                                    <?php if (!empty($sug['thumbnail_path'])): ?>
                                        <a href="<?= htmlspecialchars($video_path) ?>" target="_blank">
                                            <img src="<?= htmlspecialchars($thumb_path) ?>" class="thumbnail">
                                        </a>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <a href="<?= htmlspecialchars($video_path) ?>" class="filename-link" target="_blank">
                                        <?= htmlspecialchars($sug['filename']) ?>
                                    </a>
                                    <div class="folder-path">videos/unknown/<?= htmlspecialchars($sug['filepath']) ?></div>
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
    
    <script>
    // Star rating toggle - no confirmation needed
    function toggleStar(id, curr) {
        const next = (curr + 1) % 4;
        
        fetch('../admin/actions/update_star.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ individual_id: id, star_rating: next })
        })
        .then(r => r.json())
        .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
    }
    
    function moveToUnknown(id, name) {
        showConfirm(`Move "${name}" to unknown folder?`, () => {
            fetch('../admin/actions/move_to_unknown.php', {
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
            fetch('../admin/actions/delete_clip.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: id })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function setDefault(clipId, indId) {
        showConfirm('Set as default thumbnail?', () => {
            fetch('../admin/actions/set_default_thumbnail.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: clipId, individual_id: indId })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function acceptMatch(clipId, indId, name) {
        showConfirm(`Accept and move "${name}" to folder?`, () => {
            fetch('../admin/actions/accept_match.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: clipId, individual_id: indId })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function rejectMatch(clipId, indId, name) {
        showConfirm(`Reject match for "${name}"?`, () => {
            fetch('../admin/actions/reject_match.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: clipId, individual_id: indId })
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