<?php
/**
 * Clusters - Find groups of similar faces in unknown clips
 * Helps identify new individuals that should be added
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get confidence threshold for clustering
$min_confidence = isset($_GET['min_confidence']) ? intval($_GET['min_confidence']) : 70;
$min_cluster_size = isset($_GET['min_size']) ? intval($_GET['min_size']) : 2;

// Strategy: Find unknown clips that share the same suggested individual
// with high confidence - these are likely the same unknown person
$clusters_sql = "
    SELECT 
        ci1.clip_id as clip1_id,
        ci2.clip_id as clip2_id,
        ci1.individual_id,
        i.name as suggested_name,
        MIN(ci1.confidence, ci2.confidence) as min_confidence
    FROM clip_individuals ci1
    JOIN clip_individuals ci2 ON ci1.individual_id = ci2.individual_id AND ci1.clip_id < ci2.clip_id
    JOIN individuals i ON ci1.individual_id = i.individual_id
    JOIN clips c1 ON ci1.clip_id = c1.clip_id
    JOIN clips c2 ON ci2.clip_id = c2.clip_id
    WHERE c1.clip_type = 'unknown' 
    AND c2.clip_type = 'unknown'
    AND ci1.confidence >= :min_conf / 100.0
    AND ci2.confidence >= :min_conf / 100.0
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem1 
        WHERE kem1.clip_id = ci1.clip_id AND kem1.individual_id = ci1.individual_id
    )
    AND NOT EXISTS (
        SELECT 1 FROM known_error_matches kem2 
        WHERE kem2.clip_id = ci2.clip_id AND kem2.individual_id = ci2.individual_id
    )
    ORDER BY ci1.individual_id, min_confidence DESC
";

$stmt = $db->prepare($clusters_sql);
$stmt->execute([':min_conf' => $min_confidence]);
$connections = $stmt->fetchAll();

// Build clusters from connections using union-find approach
$clip_to_cluster = [];
$clusters = [];
$cluster_id = 0;

foreach ($connections as $conn) {
    $clip1 = $conn['clip1_id'];
    $clip2 = $conn['clip2_id'];
    
    $cluster1 = $clip_to_cluster[$clip1] ?? null;
    $cluster2 = $clip_to_cluster[$clip2] ?? null;
    
    if ($cluster1 === null && $cluster2 === null) {
        // Both clips are new - create new cluster
        $clusters[$cluster_id] = [
            'clips' => [$clip1, $clip2],
            'suggested_name' => $conn['suggested_name'],
            'individual_id' => $conn['individual_id']
        ];
        $clip_to_cluster[$clip1] = $cluster_id;
        $clip_to_cluster[$clip2] = $cluster_id;
        $cluster_id++;
    } elseif ($cluster1 === null) {
        // clip1 is new, add to clip2's cluster
        $clusters[$cluster2]['clips'][] = $clip1;
        $clip_to_cluster[$clip1] = $cluster2;
    } elseif ($cluster2 === null) {
        // clip2 is new, add to clip1's cluster
        $clusters[$cluster1]['clips'][] = $clip2;
        $clip_to_cluster[$clip2] = $cluster1;
    } elseif ($cluster1 !== $cluster2) {
        // Merge two clusters
        $clusters[$cluster1]['clips'] = array_merge(
            $clusters[$cluster1]['clips'],
            $clusters[$cluster2]['clips']
        );
        foreach ($clusters[$cluster2]['clips'] as $clip_id) {
            $clip_to_cluster[$clip_id] = $cluster1;
        }
        unset($clusters[$cluster2]);
    }
}

// Get full clip details for each cluster
foreach ($clusters as &$cluster) {
    $cluster['clips'] = array_unique($cluster['clips']);
    
    if (count($cluster['clips']) < $min_cluster_size) {
        continue;
    }
    
    $clip_ids = implode(',', $cluster['clips']);
    $clips_sql = "
        SELECT 
            c.*,
            ci.confidence
        FROM clips c
        LEFT JOIN clip_individuals ci ON c.clip_id = ci.clip_id AND ci.individual_id = {$cluster['individual_id']}
        WHERE c.clip_id IN ($clip_ids)
        ORDER BY ci.confidence DESC
    ";
    
    $cluster['clip_details'] = $db->query($clips_sql)->fetchAll();
}
unset($cluster);

// Filter clusters by minimum size
$clusters = array_filter($clusters, fn($c) => count($c['clips']) >= $min_cluster_size);

// Sort by cluster size (largest first)
usort($clusters, fn($a, $b) => count($b['clips']) - count($a['clips']));

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Face Clusters - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1600px; margin: 0 auto; padding: 20px; }
        
        .page-header {
            background: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .page-header h1 {
            font-size: 28px;
            color: var(--primary-color);
            margin-bottom: 10px;
        }
        
        .page-header p {
            color: #666;
            line-height: 1.6;
        }
        
        .info-box {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            border-radius: 4px;
            margin-top: 15px;
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
        
        .filter-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 5px;
            color: var(--text-color);
        }
        
        .filter-group select {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        
        .filter-actions {
            display: flex;
            gap: 10px;
        }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            font-size: 14px;
        }
        
        .btn-primary { background: var(--primary-color); color: white; }
        .btn-secondary { background: #95a5a6; color: white; }
        
        .cluster {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .cluster-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--primary-color);
        }
        
        .cluster-title {
            font-size: 20px;
            font-weight: bold;
            color: var(--primary-color);
        }
        
        .cluster-stats {
            color: #666;
            font-size: 14px;
        }
        
        .cluster-actions {
            display: flex;
            gap: 10px;
        }
        
        .faces-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .face-card {
            border: 2px solid #ecf0f1;
            border-radius: 8px;
            overflow: hidden;
            transition: all 0.2s;
        }
        
        .face-card:hover {
            border-color: var(--primary-color);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        
        .face-thumbnail {
            width: 100%;
            height: 150px;
            object-fit: cover;
            background: #ecf0f1;
        }
        
        .face-info {
            padding: 10px;
        }
        
        .face-filename {
            font-size: 12px;
            color: var(--text-color);
            font-weight: 500;
            margin-bottom: 5px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        
        .face-meta {
            font-size: 11px;
            color: #95a5a6;
        }
        
        .confidence-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 600;
            color: white;
            margin-top: 5px;
        }
        
        .confidence-high { background: #27ae60; }
        .confidence-medium { background: #f39c12; }
        .confidence-low { background: #e67e22; }
        
        .no-clusters {
            background: white;
            padding: 60px;
            text-align: center;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .no-clusters h2 {
            color: #95a5a6;
            margin-bottom: 10px;
        }
        
        @media (max-width: 768px) {
            .faces-grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="page-header">
            <h1>🔍 Face Clusters</h1>
            <p>
                Discover groups of similar faces in unknown clips. Each cluster represents a potential new individual
                that you can add to your database.
            </p>
            
            <div class="info-box">
                <strong>💡 How it works:</strong> The system compares all unknown faces and groups those that match above
                your confidence threshold. Larger clusters with high confidence likely represent the same person appearing
                in multiple clips.
            </div>
        </div>
        
        <div class="filters">
            <form method="GET">
                <div class="filters-grid">
                    <div class="filter-group">
                        <label>Minimum Confidence</label>
                        <select name="min_confidence">
                            <option value="90" <?= $min_confidence == 90 ? 'selected' : '' ?>>90% - Very Strict</option>
                            <option value="80" <?= $min_confidence == 80 ? 'selected' : '' ?>>80% - Strict</option>
                            <option value="70" <?= $min_confidence == 70 ? 'selected' : '' ?>>70% - Balanced (Recommended)</option>
                            <option value="60" <?= $min_confidence == 60 ? 'selected' : '' ?>>60% - Relaxed</option>
                            <option value="50" <?= $min_confidence == 50 ? 'selected' : '' ?>>50% - Very Relaxed</option>
                        </select>
                    </div>
                    
                    <div class="filter-group">
                        <label>Minimum Cluster Size</label>
                        <select name="min_size">
                            <option value="2" <?= $min_cluster_size == 2 ? 'selected' : '' ?>>2+ faces</option>
                            <option value="3" <?= $min_cluster_size == 3 ? 'selected' : '' ?>>3+ faces</option>
                            <option value="5" <?= $min_cluster_size == 5 ? 'selected' : '' ?>>5+ faces</option>
                            <option value="10" <?= $min_cluster_size == 10 ? 'selected' : '' ?>>10+ faces</option>
                        </select>
                    </div>
                </div>
                
                <div class="filter-actions">
                    <button type="submit" class="btn btn-primary">Apply Filters</button>
                    <a href="?" class="btn btn-secondary">Reset</a>
                </div>
            </form>
        </div>
        
        <?php if (count($clusters) > 0): ?>
            <?php foreach ($clusters as $idx => $cluster): ?>
                <?php
                $avg_confidence = 0;
                if (!empty($cluster['clip_details'])) {
                    $confidences = array_filter(array_column($cluster['clip_details'], 'confidence'));
                    $avg_confidence = !empty($confidences) ? round(array_sum($confidences) / count($confidences) * 100, 1) : 0;
                }
                ?>
                <div class="cluster">
                    <div class="cluster-header">
                        <div>
                            <div class="cluster-title">Cluster #<?= $idx + 1 ?></div>
                            <div class="cluster-stats">
                                <?= count($cluster['clips']) ?> clips • 
                                Suggested as: <strong><?= htmlspecialchars($cluster['suggested_name']) ?></strong>
                                <?php if ($avg_confidence > 0): ?>
                                    • Avg confidence: <?= $avg_confidence ?>%
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="cluster-actions">
                            <span style="color: #666; font-size: 13px;">
                                These clips likely show the same unknown person
                            </span>
                        </div>
                    </div>
                    
                    <div class="faces-grid">
                        <?php foreach ($cluster['clip_details'] as $clip): ?>
                            <?php
                            $video_path = '../videos/unknown/' . $clip['filepath'];
                            $thumb_path = '../' . $clip['thumbnail_path'];
                            $conf = round(($clip['confidence'] ?? 0) * 100, 1);
                            $conf_class = $conf >= 80 ? 'confidence-high' : ($conf >= 60 ? 'confidence-medium' : 'confidence-low');
                            ?>
                            <div class="face-card">
                                <a href="<?= htmlspecialchars($video_path) ?>" target="_blank">
                                    <?php if (!empty($clip['thumbnail_path'])): ?>
                                        <img src="<?= htmlspecialchars($thumb_path) ?>" class="face-thumbnail">
                                    <?php endif; ?>
                                </a>
                                <div class="face-info">
                                    <div class="face-filename" title="<?= htmlspecialchars($clip['filename']) ?>">
                                        <?= htmlspecialchars($clip['filename']) ?>
                                    </div>
                                    <div class="face-meta">
                                        <?= $clip['width'] ?>×<?= $clip['height'] ?> • <?= $clip['duration_text'] ?>
                                    </div>
                                    <?php if ($conf > 0): ?>
                                        <span class="confidence-badge <?= $conf_class ?>">
                                            <?= $conf ?>% match to <?= htmlspecialchars($cluster['suggested_name']) ?>
                                        </span>
                                    <?php endif; ?>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php endforeach; ?>
        <?php else: ?>
            <div class="no-clusters">
                <h2>No clusters found</h2>
                <p>Try lowering the confidence threshold or minimum cluster size.</p>
                <p style="margin-top: 10px; color: #95a5a6; font-size: 14px;">
                    Clusters are found when multiple unknown clips are suggested to match the same known individual.
                </p>
            </div>
        <?php endif; ?>
    </div>
</body>
</html>