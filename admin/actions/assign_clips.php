<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['clip_ids']) || !isset($data['mode'])) {
    jsonResponse(false, 'Missing parameters');
}

$clip_ids = $data['clip_ids'];
$mode = $data['mode'];

if (empty($clip_ids) || !is_array($clip_ids)) {
    jsonResponse(false, 'Invalid clip IDs');
}

try {
    $db = getDB();
    
    if ($mode === 'new') {
        // Create new individual with custom name or zz-XXX
        if (isset($data['individual_name']) && !empty(trim($data['individual_name']))) {
            // Use provided name
            $new_name = trim($data['individual_name']);
        } else {
            // Auto-generate zz-XXX name
            $stmt = $db->query("
                SELECT name FROM individuals 
                WHERE name LIKE 'zz-%' 
                ORDER BY name DESC 
                LIMIT 1
            ");
            $last_zz = $stmt->fetchColumn();
            
            if ($last_zz && preg_match('/zz-(\d+)/', $last_zz, $matches)) {
                $next_index = intval($matches[1]) + 1;
            } else {
                $next_index = 1;
            }
            
            $new_name = 'zz-' . str_pad($next_index, 3, '0', STR_PAD_LEFT);
        }
        
        // Create individual
        $create_stmt = $db->prepare("
            INSERT INTO individuals (name, profile_created) 
            VALUES (?, datetime('now'))
        ");
        $create_stmt->execute([$new_name]);
        $individual_id = $db->lastInsertId();
        
        // Create directory
        $new_dir = KNOWN_DIR . '/' . $new_name;
        if (!is_dir($new_dir)) {
            mkdir($new_dir, 0755, true);
        }
        
    } elseif ($mode === 'existing') {
        if (!isset($data['individual_id'])) {
            jsonResponse(false, 'Missing individual_id');
        }
        
        $individual_id = intval($data['individual_id']);
        
        // Get individual
        $stmt = $db->prepare("SELECT name FROM individuals WHERE individual_id = ?");
        $stmt->execute([$individual_id]);
        $individual = $stmt->fetch();
        
        if (!$individual) {
            jsonResponse(false, 'Individual not found');
        }
        
        $new_name = $individual['name'];
        $new_dir = KNOWN_DIR . '/' . $new_name;
        
        if (!is_dir($new_dir)) {
            mkdir($new_dir, 0755, true);
        }
        
    } else {
        jsonResponse(false, 'Invalid mode');
    }
    
    // Move all selected clips
    $moved_count = 0;
    foreach ($clip_ids as $clip_id) {
        $clip_id = intval($clip_id);
        
        // Get clip
        $clip_stmt = $db->prepare("
            SELECT * FROM clips 
            WHERE clip_id = ? AND clip_type = 'unknown'
        ");
        $clip_stmt->execute([$clip_id]);
        $clip = $clip_stmt->fetch();
        
        if (!$clip) continue;
        
        // Move file
        $old_path = UNKNOWN_DIR . '/' . $clip['filepath'];
        $new_path = $new_dir . '/' . basename($clip['filepath']);
        $new_filepath = $new_name . '/' . basename($clip['filepath']);
        
        if (file_exists($old_path)) {
            if (rename($old_path, $new_path)) {
                // Update database
                $update_stmt = $db->prepare("
                    UPDATE clips 
                    SET clip_type = 'known',
                        folder_person = ?,
                        filepath = ?
                    WHERE clip_id = ?
                ");
                $update_stmt->execute([$new_name, $new_filepath, $clip_id]);
                $moved_count++;
            }
        }
    }
    
    jsonResponse(true, "$moved_count clip(s) assigned", [
        'individual_id' => $individual_id,
        'name' => $new_name
    ]);
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
