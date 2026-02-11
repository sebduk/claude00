<?php
/**
 * Known Matches - Find potential duplicate individuals
 * Helps identify when the same person has been added twice under different names
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get confidence threshold
$min_confidence = isset($_GET['min_confidence']) ? intval($_GET['min_confidence']) : 80;

// Get all known individuals with their consolidated face profiles
$individuals_sql = "
    SELECT 
        i.individual_id,
        i.name,
        i.star_rating,
        it.thumbnail_path as default_thumbnail,
        COUNT(DISTINCT c.clip_id) as clip_count
    FROM individuals i
    LEFT JOIN clips it ON i.default_thumbnail_clip_id = it.clip_id
    LEFT JOIN clips c ON c.folder_person = i.name AND c.clip_type = 'known'
    GROUP BY i.individual_id
    ORDER BY i.name
";

$individuals = $db->query($individuals_sql)->fetchAll();

// Strategy: Find individuals whose clips frequently match the OTHER individual
// If Individual A's clips often suggest Individual B, they might be duplicates

$matches = [];

foreach ($individuals as $ind1) {
    foreach ($individuals as $ind2) {
        if ($ind1['individual_id'] >= $ind2['individual_id']) {
            continue; // Skip same individual and avoid duplicates
        }
        
        // Count how many of ind1's clips match ind2 with high confidence
        $cross_match_sql = $db->prepare("
            SELECT COUNT(DISTINCT ci.clip_id) as match_count,
                   AVG(ci.confidence) as avg_confidence
            FROM clip_individuals ci
            JOIN clips c ON ci.clip_id = c.clip_id
            WHERE c.folder_person = ?
            AND c.clip_type = 'known'
            AND ci.individual_id = ?
            AND ci.confidence >= :min_conf / 100.0
            AND NOT EXISTS (
                SELECT 1 FROM known_error_matches kem 
                WHERE kem.clip_id = ci.clip_id AND kem.individual_id = ci.individual_id
            )
        ");
        
        $cross_match_sql->execute([
            $ind1['name'], 
            $ind2['individual_id'],
            ':min_conf' => $min_confidence
        ]);
        $result1 = $cross_match_sql->fetch();
        
        // Also check the reverse
        $cross_match_sql->execute([
            $ind2['name'], 
            $ind1['individual_id'],
            ':min_conf' => $min_confidence
        ]);
        $result2 = $cross_match_sql->fetch();
        
        $total_matches = ($result1['match_count'] ?? 0) + ($result2['match_count'] ?? 0);
        
        if ($total_matches > 0) {
            $avg_conf = (
                (($result1['avg_confidence'] ?? 0) * ($result1['match_count'] ?? 0)) +
                (($result2['avg_confidence'] ?? 0) * ($result2['match_count'] ?? 0))
            ) / $total_matches;
            
            $confidence = round($avg_conf * 100, 1);
            
            if ($confidence >= $min_confidence) {
                $matches[] = [
                    'individual1' => $ind1,
                    'individual2' => $ind2,
                    'confidence' => $confidence,
                    'cross_matches' => $total_matches,
                    'ind1_clips_matching_ind2' => $result1['match_count'] ?? 0,
                    'ind2_clips_matching_ind1' => $result2['match_count'] ?? 0
                ];
            }
        }
    }
}

// Sort by confidence (highest first)
usort($matches, fn($a, $b) => $b['confidence'] <=> $a['confidence']);

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Known Individual Matches - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        
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
            background: #fff3cd;
            border-left: 4px solid #ffc107;
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
        
        .filter-group {
            margin-bottom: 15px;
        }
        
        .filter-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .filter-group select {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            min-width: 250px;
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
        .btn-merge { background: #3498db; color: white; }
        
        .match-card {
            background: white;
            border-radius: 8px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .match-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #ecf0f1;
        }
        
        .confidence-large {
            font-size: 32px;
            font-weight: bold;
            color: #27ae60;
        }
        
        .individuals-comparison {
            display: grid;
            grid-template-columns: 1fr auto 1fr;
            gap: 30px;
            align-items: center;
        }
        
        .individual-side {
            text-align: center;
        }
        
        .individual-thumbnail {
            width: 200px;
            height: 300px;
            object-fit: cover;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            margin-bottom: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 64px;
            font-weight: bold;
        }
        
        .individual-thumbnail img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 8px;
        }
        
        .individual-name {
            font-size: 20px;
            font-weight: bold;
            color: var(--text-color);
            margin-bottom: 5px;
        }
        
        .individual-stats {
            color: #666;
            font-size: 14px;
        }
        
        .vs-divider {
            font-size: 24px;
            font-weight: bold;
            color: #95a5a6;
            padding: 0 20px;
        }
        
        .match-actions {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #ecf0f1;
            display: flex;
            gap: 10px;
            justify-content: center;
        }
        
        .no-matches {
            background: white;
            padding: 60px;
            text-align: center;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .no-matches h2 {
            color: #27ae60;
            margin-bottom: 10px;
        }
        
        @media (max-width: 768px) {
            .individuals-comparison {
                grid-template-columns: 1fr;
            }
            .vs-divider {
                transform: rotate(90deg);
                padding: 20px 0;
            }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="page-header">
            <h1>&#128101; Known Individual Matches</h1>
            <p>
                Find potential duplicate individuals in your database. These are known individuals whose faces 
                match at high confidence, suggesting they might be the same person added under different names.
            </p>
            
            <div class="info-box">
                <strong>&#9888; Important:</strong> High confidence matches may indicate duplicates that should be merged.
                Review each match carefully before merging, as this action cannot be undone.
            </div>
        </div>
        
        <div class="filters">
            <form method="GET">
                <div class="filter-group">
                    <label>Minimum Confidence</label>
                    <select name="min_confidence">
                        <option value="95" <?= $min_confidence == 95 ? 'selected' : '' ?>>95% - Almost Certain</option>
                        <option value="90" <?= $min_confidence == 90 ? 'selected' : '' ?>>90% - Very Likely</option>
                        <option value="80" <?= $min_confidence == 80 ? 'selected' : '' ?>>80% - Likely (Recommended)</option>
                        <option value="70" <?= $min_confidence == 70 ? 'selected' : '' ?>>70% - Possible</option>
                        <option value="60" <?= $min_confidence == 60 ? 'selected' : '' ?>>60% - Maybe</option>
                    </select>
                </div>
                
                <div class="filter-actions">
                    <button type="submit" class="btn btn-primary">Apply Filter</button>
                    <a href="?" class="btn btn-secondary">Reset</a>
                </div>
            </form>
        </div>
        
        <?php if (count($matches) > 0): ?>
            <?php foreach ($matches as $match): ?>
                <?php
                $ind1 = $match['individual1'];
                $ind2 = $match['individual2'];
                ?>
                <div class="match-card">
                    <div class="match-header">
                        <div>
                            <div style="color: #666; font-size: 13px; margin-bottom: 5px;">Potential Duplicate</div>
                            <div style="font-size: 14px; color: #95a5a6;">
                                <?= $match['ind1_clips_matching_ind2'] ?> clips from <?= htmlspecialchars($ind1['name']) ?> match <?= htmlspecialchars($ind2['name']) ?>
                                <?php if ($match['ind2_clips_matching_ind1'] > 0): ?>
                                    <br><?= $match['ind2_clips_matching_ind1'] ?> clips from <?= htmlspecialchars($ind2['name']) ?> match <?= htmlspecialchars($ind1['name']) ?>
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="confidence-large">
                            <?= $match['confidence'] ?>%
                        </div>
                    </div>
                    
                    <div class="individuals-comparison">
                        <!-- Individual 1 -->
                        <div class="individual-side">
                            <div class="individual-thumbnail">
                                <?php if (!empty($ind1['default_thumbnail'])): ?>
                                    <img src="../<?= htmlspecialchars($ind1['default_thumbnail']) ?>" alt="<?= htmlspecialchars($ind1['name']) ?>">
                                <?php else: ?>
                                    <?= htmlspecialchars(substr($ind1['name'], 0, 1)) ?>
                                <?php endif; ?>
                            </div>
                            <div class="individual-name"><?= htmlspecialchars($ind1['name']) ?></div>
                            <div class="individual-stats">
                                <?= $ind1['clip_count'] ?> clips
                                <?php if ($ind1['star_rating'] > 0): ?>
                                    &#8226; <?= str_repeat('&#11088;', $ind1['star_rating']) ?>
                                <?php endif; ?>
                            </div>
                            <div style="margin-top: 10px;">
                                <a href="individual.php?id=<?= $ind1['individual_id'] ?>" class="btn btn-secondary" style="font-size: 12px;">
                                    View Profile
                                </a>
                            </div>
                        </div>
                        
                        <div class="vs-divider">vs</div>
                        
                        <!-- Individual 2 -->
                        <div class="individual-side">
                            <div class="individual-thumbnail">
                                <?php if (!empty($ind2['default_thumbnail'])): ?>
                                    <img src="../<?= htmlspecialchars($ind2['default_thumbnail']) ?>" alt="<?= htmlspecialchars($ind2['name']) ?>">
                                <?php else: ?>
                                    <?= htmlspecialchars(substr($ind2['name'], 0, 1)) ?>
                                <?php endif; ?>
                            </div>
                            <div class="individual-name"><?= htmlspecialchars($ind2['name']) ?></div>
                            <div class="individual-stats">
                                <?= $ind2['clip_count'] ?> clips
                                <?php if ($ind2['star_rating'] > 0): ?>
                                    &#8226; <?= str_repeat('&#11088;', $ind2['star_rating']) ?>
                                <?php endif; ?>
                            </div>
                            <div style="margin-top: 10px;">
                                <a href="individual.php?id=<?= $ind2['individual_id'] ?>" class="btn btn-secondary" style="font-size: 12px;">
                                    View Profile
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div class="match-actions">
                        <span style="color: #666; font-size: 14px;">
                            If these are the same person, you can merge them on either individual's page
                        </span>
                    </div>
                </div>
            <?php endforeach; ?>
        <?php else: ?>
            <div class="no-matches">
                <h2>&#10003; No duplicate individuals found!</h2>
                <p>All known individuals appear to be unique at the selected confidence threshold.</p>
            </div>
        <?php endif; ?>
    </div>
</body>
</html>