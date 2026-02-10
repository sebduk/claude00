<?php
/**
 * Navigate - Unknown Clips Page
 * Display all unknown clips as if they were an individual's clips
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get sort parameters - default: filename ASC
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

// Get all unknown clips
$clips_sql = "
    SELECT c.* FROM clips c
    WHERE c.clip_type = 'unknown'
    ORDER BY $sort_sql
";

$clips = $db->query($clips_sql)->fetchAll();

// Get tags for each clip
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

// Calculate stats
$total_duration = array_sum(array_column($clips, 'duration'));
$total_size = array_sum(array_column($clips, 'filesize'));

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unknown Clips - Navigate</title>
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
            background: linear-gradient(135deg, #95a5a6 0%, #7f8c8d 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 96px;
            font-weight: bold;
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
        
        .back-link {
            padding: 10px 20px;
            background: var(--primary-color);
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: 600;
            display: inline-block;
        }
        
        .back-link:hover { opacity: 0.9; }
        
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
        
        .tags-container {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        
        .tag-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            color: white;
        }
        
        .no-clips {
            text-align: center;
            padding: 60px 20px;
            color: #95a5a6;
        }
        
        @media (max-width: 767px) {
            .header-top { flex-direction: column; }
            .profile-thumbnail { width: 150px; height: 225px; font-size: 64px; }
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
                        <h1>❓ Unknown</h1>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-box">
                            <div class="stat-label">Total Clips</div>
                            <div class="stat-value"><?= count($clips) ?></div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Total Duration</div>
                            <div class="stat-value"><?= formatDuration($total_duration) ?></div>
                        </div>
                        <div class="stat-box">
                            <div class="stat-label">Total Size</div>
                            <div class="stat-value"><?= formatFileSize($total_size) ?></div>
                        </div>
                    </div>
                </div>
                
                <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 15px;">
                    <div class="profile-thumbnail">
                        ❓
                    </div>
                    
                    <a href="individuals.php" class="back-link">← Back to List</a>
                </div>
            </div>
        </div>
        
        <!-- Clips Table -->
        <div class="section">
            <div class="section-title">📁 All Unknown Clips (<?= count($clips) ?>)</div>
            
            <?php if (count($clips) > 0): ?>
                <table>
                    <thead>
                        <tr>
                            <th style="width: 100px;">Thumbnail</th>
                            <th>
                                <a href="?sort=filename&order=<?= $sort === 'filename' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Filename <?= $sort === 'filename' ? ($order === 'ASC' ? '▲' : '▼') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?sort=duration&order=<?= $sort === 'duration' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Duration <?= $sort === 'duration' ? ($order === 'ASC' ? '▲' : '▼') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?sort=dimensions&order=<?= $sort === 'dimensions' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Dimensions <?= $sort === 'dimensions' ? ($order === 'ASC' ? '▲' : '▼') : '' ?>
                                </a>
                            </th>
                            <th>
                                <a href="?sort=file_date&order=<?= $sort === 'file_date' && $order === 'ASC' ? 'DESC' : 'ASC' ?>">
                                    Date <?= $sort === 'file_date' ? ($order === 'ASC' ? '▲' : '▼') : '' ?>
                                </a>
                            </th>
                            <th>Tags</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($clips as $clip): ?>
                            <?php
                            $video_path = '../videos/unknown/' . $clip['filepath'];
                            $thumb_path = '../' . $clip['thumbnail_path'];
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
                                    <div class="folder-path">videos/unknown/<?= htmlspecialchars($clip['filepath']) ?></div>
                                </td>
                                <td><?= htmlspecialchars($clip['duration_text']) ?></td>
                                <td><?= $clip['width'] ?> × <?= $clip['height'] ?></td>
                                <td><?= date('Y-m-d', strtotime($clip['file_date'])) ?></td>
                                <td>
                                    <?php if (!empty($clip['tags'])): ?>
                                        <?= getTagsHTML($clip['tags'], false) ?>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="no-clips">
                    <h2>No unknown clips</h2>
                    <p>All clips have been assigned to individuals!</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>