<?php
/**
 * Admin - Duplicates Page
 * Find and manage potential duplicate clips based on duration, aspect ratio, and common faces
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Advanced duplicate detection based on:
// 1. Duration similarity (within 5 seconds)
// 2. Same aspect ratio
// 3. Common faces detected

// Create dismissed_duplicates table if it doesn't exist
$db->exec("
    CREATE TABLE IF NOT EXISTS dismissed_duplicates (
        clip1_id INTEGER NOT NULL,
        clip2_id INTEGER NOT NULL,
        dismissed_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (clip1_id, clip2_id),
        FOREIGN KEY (clip1_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
        FOREIGN KEY (clip2_id) REFERENCES clips(clip_id) ON DELETE CASCADE
    )
");

$potential_duplicates_raw = $db->query("
    SELECT 
        c1.clip_id as clip1_id,
        c1.filename as file1,
        c1.filepath as path1,
        c1.thumbnail_path as thumb1,
        c1.duration as dur1,
        c1.width as w1,
        c1.height as h1,
        c1.filesize as size1,
        c1.clip_type as type1,
        c1.folder_person as folder1,
        c2.clip_id as clip2_id,
        c2.filename as file2,
        c2.filepath as path2,
        c2.thumbnail_path as thumb2,
        c2.duration as dur2,
        c2.width as w2,
        c2.height as h2,
        c2.filesize as size2,
        c2.clip_type as type2,
        c2.folder_person as folder2,
        ABS(c1.duration - c2.duration) as duration_diff,
        ABS(c1.filesize - c2.filesize) as size_diff,
        CAST(c1.width AS REAL) / c1.height as aspect1,
        CAST(c2.width AS REAL) / c2.height as aspect2
    FROM clips c1
    JOIN clips c2 ON c1.clip_id < c2.clip_id
    WHERE ABS(c1.duration - c2.duration) <= 5
    AND ABS(ROUND(CAST(c1.width AS REAL) / c1.height, 3) - ROUND(CAST(c2.width AS REAL) / c2.height, 3)) < 0.0025
    AND (SELECT COUNT(DISTINCT fp1.individual_id)
         FROM face_profiles fp1
         JOIN face_profiles fp2 ON fp1.individual_id = fp2.individual_id
         WHERE fp1.clip_id = c1.clip_id 
         AND fp2.clip_id = c2.clip_id) > 0
    AND NOT EXISTS (
        SELECT 1 FROM dismissed_duplicates dd
        WHERE dd.clip1_id = c1.clip_id AND dd.clip2_id = c2.clip_id
    )
")->fetchAll();

// Get face counts for similarity calculation
foreach ($potential_duplicates_raw as &$pair) {
    // Get face counts
    $stmt1 = $db->prepare("SELECT COUNT(DISTINCT individual_id) FROM face_profiles WHERE clip_id = ?");
    $stmt1->execute([$pair['clip1_id']]);
    $pair['total_faces1'] = $stmt1->fetchColumn();
    
    $stmt2 = $db->prepare("SELECT COUNT(DISTINCT individual_id) FROM face_profiles WHERE clip_id = ?");
    $stmt2->execute([$pair['clip2_id']]);
    $pair['total_faces2'] = $stmt2->fetchColumn();
    
    // Get common faces
    $stmt_common = $db->prepare("
        SELECT COUNT(DISTINCT fp1.individual_id)
        FROM face_profiles fp1
        JOIN face_profiles fp2 ON fp1.individual_id = fp2.individual_id
        WHERE fp1.clip_id = ? AND fp2.clip_id = ?
    ");
    $stmt_common->execute([$pair['clip1_id'], $pair['clip2_id']]);
    $pair['common_faces'] = $stmt_common->fetchColumn();
}
unset($pair);

// Calculate similarity percentage for each pair and filter >= 50%
$potential_duplicates = [];
foreach ($potential_duplicates_raw as $pair) {
    // Duration similarity (0-100%)
    $max_duration = max($pair['dur1'], $pair['dur2']);
    $duration_similarity = $max_duration > 0 ? (1 - $pair['duration_diff'] / $max_duration) * 100 : 100;
    
    // Size similarity (0-100%)
    $max_size = max($pair['size1'], $pair['size2']);
    $size_similarity = $max_size > 0 ? (1 - $pair['size_diff'] / $max_size) * 100 : 100;
    
    // Aspect ratio similarity (always 100% - exact match required by query)
    $aspect_similarity = 100;
    
    // Face similarity (0-100%)
    $total_unique_faces = max($pair['total_faces1'], $pair['total_faces2']);
    $face_similarity = $total_unique_faces > 0 ? ($pair['common_faces'] / $total_unique_faces) * 100 : 0;
    
    // Overall similarity (weighted average)
    // Faces are most important (50%), then duration (40%), size (10%)
    // Aspect ratio no longer factored in since it's always 100%
    $overall_similarity = (
        $face_similarity * 0.5 +
        $duration_similarity * 0.4 +
        $size_similarity * 0.1
    );
    
    // Only include pairs with >= 50% similarity
    if ($overall_similarity >= 50) {
        $pair['similarity'] = round($overall_similarity, 1);
        $pair['duration_similarity'] = round($duration_similarity, 1);
        $pair['size_similarity'] = round($size_similarity, 1);
        $pair['aspect_similarity'] = 100; // Always 100%
        $pair['face_similarity'] = round($face_similarity, 1);
        $potential_duplicates[] = $pair;
    }
}

// Sort by similarity descending (highest first)
usort($potential_duplicates, function($a, $b) {
    return $b['similarity'] <=> $a['similarity'];
});

// Limit to top 100 for performance
$potential_duplicates = array_slice($potential_duplicates, 0, 100);

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Duplicates - Admin</title>
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
        
        .header h1 { color: var(--primary-color); margin-bottom: 10px; }
        
        .info-box {
            background: #fff3cd;
            border: 1px solid #ffc107;
            color: #856404;
            padding: 15px;
            border-radius: 6px;
            margin-top: 15px;
        }
        
        .duplicates-container {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        .duplicate-pair {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .comparison {
            display: grid;
            grid-template-columns: 1fr auto 1fr;
            gap: 30px;
            align-items: center;
        }
        
        .clip-section {
            display: flex;
            gap: 15px;
        }
        
        .thumbnail {
            width: 120px;
            height: 180px;
            object-fit: cover;
            border-radius: 6px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .clip-info {
            flex: 1;
        }
        
        .clip-filename {
            font-weight: 600;
            margin-bottom: 8px;
            color: var(--primary-color);
        }
        
        .clip-filename a {
            color: var(--primary-color);
            text-decoration: none;
        }
        
        .clip-filename a:hover { text-decoration: underline; }
        
        .clip-meta {
            font-size: 13px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .clip-path {
            font-size: 11px;
            color: #95a5a6;
            margin-top: 8px;
        }
        
        .quality-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 8px;
        }
        
        .quality-higher {
            background: #27ae60;
            color: white;
        }
        
        .quality-lower {
            background: #e74c3c;
            color: white;
        }
        
        .quality-same {
            background: #95a5a6;
            color: white;
        }
        
        .vs-divider {
            font-size: 24px;
            font-weight: bold;
            color: #95a5a6;
            text-align: center;
        }
        
        .similarity {
            text-align: center;
            margin: 15px 0;
            font-weight: 600;
            color: var(--primary-color);
        }
        
        .actions {
            display: flex;
            gap: 10px;
            justify-content: center;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #ecf0f1;
        }
        
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
        .btn-delete { background: #e74c3c; color: white; }
        .btn-keep { background: #95a5a6; color: white; }
        
        .no-duplicates {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 8px;
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
        
        @media (max-width: 1024px) {
            .comparison { grid-template-columns: 1fr; }
            .vs-divider { transform: rotate(90deg); }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="header">
            <h1>🔍 Potential Duplicates</h1>
            
            <div class="info-box">
                <strong>🔍 Smart Duplicate Detection:</strong> Finds clips with ≥50% similarity based on 
                matching faces (50% weight), duration (40%), and file size (10%). 
                <strong>Requires exact aspect ratio match.</strong> Results sorted by similarity (highest first).
            </div>
        </div>
        
        <div class="duplicates-container">
            <?php if (count($potential_duplicates) > 0): ?>
                <?php foreach ($potential_duplicates as $pair): ?>
                    <?php
                    // Determine quality (higher resolution or larger file = better)
                    $res1 = $pair['w1'] * $pair['h1'];
                    $res2 = $pair['w2'] * $pair['h2'];
                    
                    if ($res1 > $res2 || ($res1 == $res2 && $pair['size1'] > $pair['size2'])) {
                        $quality1 = 'higher';
                        $quality2 = 'lower';
                        $delete_suggestion = $pair['clip2_id'];
                    } elseif ($res2 > $res1 || ($res2 == $res1 && $pair['size2'] > $pair['size1'])) {
                        $quality1 = 'lower';
                        $quality2 = 'higher';
                        $delete_suggestion = $pair['clip1_id'];
                    } else {
                        $quality1 = 'same';
                        $quality2 = 'same';
                        $delete_suggestion = $pair['clip1_id']; // Default to deleting first
                    }
                    
                    // Use precalculated similarity from earlier
                    $similarity = $pair['similarity'];
                    
                    $video_path1 = $pair['type1'] === 'known' ? '../videos/known/' . $pair['path1'] : '../videos/unknown/' . $pair['path1'];
                    $video_path2 = $pair['type2'] === 'known' ? '../videos/known/' . $pair['path2'] : '../videos/unknown/' . $pair['path2'];
                    ?>
                    <div class="duplicate-pair">
                        <div class="comparison">
                            <!-- Clip 1 -->
                            <div class="clip-section">
                                <?php if (!empty($pair['thumb1'])): ?>
                                    <a href="<?= htmlspecialchars($video_path1) ?>" target="_blank">
                                        <img src="../<?= htmlspecialchars($pair['thumb1']) ?>" class="thumbnail">
                                    </a>
                                <?php endif; ?>
                                
                                <div class="clip-info">
                                    <div class="clip-filename">
                                        <a href="<?= htmlspecialchars($video_path1) ?>" target="_blank">
                                            <?= htmlspecialchars($pair['file1']) ?>
                                        </a>
                                    </div>
                                    <div class="clip-meta">
                                        📐 <?= $pair['w1'] ?> × <?= $pair['h1'] ?>
                                    </div>
                                    <div class="clip-meta">
                                        ⏱️ <?= gmdate('i:s', (int)round($pair['dur1'])) ?>
                                    </div>
                                    <div class="clip-meta">
                                        💾 <?= formatFileSize($pair['size1']) ?>
                                    </div>
                                    <div class="clip-path">
                                        <?= $pair['type1'] === 'known' ? 'videos/known/' : 'videos/unknown/' ?><?= htmlspecialchars($pair['path1']) ?>
                                    </div>
                                    <span class="quality-badge quality-<?= $quality1 ?>">
                                        <?= ucfirst($quality1) ?> Quality
                                    </span>
                                </div>
                            </div>
                            
                            <div class="vs-divider">VS</div>
                            
                            <!-- Clip 2 -->
                            <div class="clip-section">
                                <?php if (!empty($pair['thumb2'])): ?>
                                    <a href="<?= htmlspecialchars($video_path2) ?>" target="_blank">
                                        <img src="../<?= htmlspecialchars($pair['thumb2']) ?>" class="thumbnail">
                                    </a>
                                <?php endif; ?>
                                
                                <div class="clip-info">
                                    <div class="clip-filename">
                                        <a href="<?= htmlspecialchars($video_path2) ?>" target="_blank">
                                            <?= htmlspecialchars($pair['file2']) ?>
                                        </a>
                                    </div>
                                    <div class="clip-meta">
                                        📐 <?= $pair['w2'] ?> × <?= $pair['h2'] ?>
                                    </div>
                                    <div class="clip-meta">
                                        ⏱️ <?= gmdate('i:s', (int)round($pair['dur2'])) ?>
                                    </div>
                                    <div class="clip-meta">
                                        💾 <?= formatFileSize($pair['size2']) ?>
                                    </div>
                                    <div class="clip-path">
                                        <?= $pair['type2'] === 'known' ? 'videos/known/' : 'videos/unknown/' ?><?= htmlspecialchars($pair['path2']) ?>
                                    </div>
                                    <span class="quality-badge quality-<?= $quality2 ?>">
                                        <?= ucfirst($quality2) ?> Quality
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        <div class="similarity">
                            <?= $similarity ?>% Match
                            <div style="font-size: 13px; color: #666; margin-top: 8px; line-height: 1.6;">
                                <strong>Breakdown:</strong><br>
                                👥 Faces: <?= $pair['face_similarity'] ?>% (<?= $pair['common_faces'] ?> common)<br>
                                ⏱️ Duration: <?= $pair['duration_similarity'] ?>% (diff: <?= round($pair['duration_diff'], 1) ?>s)<br>
                                📐 Aspect: <?= $pair['aspect_similarity'] ?>% (<?= round($pair['aspect1'], 2) ?> vs <?= round($pair['aspect2'], 2) ?>)<br>
                                💾 Size: <?= $pair['size_similarity'] ?>%
                            </div>
                        </div>
                        
                        <div class="actions">
                            <button class="btn btn-delete" onclick="deleteLowerQuality(<?= $delete_suggestion ?>, <?= $pair['clip1_id'] ?>, <?= $pair['clip2_id'] ?>)">
                                Delete Lower Quality
                            </button>
                            <button class="btn btn-keep" onclick="keepBoth(<?= $pair['clip1_id'] ?>, <?= $pair['clip2_id'] ?>)">
                                Keep Both
                            </button>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php else: ?>
                <div class="no-duplicates">
                    <h2>No duplicates found</h2>
                    <p>No potential duplicate clips detected.</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <div id="confirmModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">⚠️ Confirm Deletion</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-keep" onclick="closeModal()">Cancel</button>
                <button class="btn btn-delete" id="confirmButton">Yes, Delete</button>
            </div>
        </div>
    </div>
    
    <script>
    function deleteLowerQuality(clipId, clip1Id, clip2Id) {
        showConfirm('Delete the lower quality clip? This cannot be undone.', () => {
            fetch('actions/delete_clip.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ clip_id: clipId })
            })
            .then(r => r.json())
            .then(d => d.success ? location.reload() : alert('Error: ' + d.message));
        });
    }
    
    function keepBoth(clip1Id, clip2Id) {
        fetch('actions/dismiss_duplicate.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ clip1_id: clip1Id, clip2_id: clip2Id })
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                location.reload();
            } else {
                alert('Error: ' + d.message);
            }
        })
        .catch(err => {
            console.error('Error dismissing duplicate:', err);
            alert('Error dismissing duplicate');
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