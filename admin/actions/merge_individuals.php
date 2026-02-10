<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['source_id']) || !isset($data['target_id'])) {
    jsonResponse(false, 'Missing parameters');
}

$source_id = intval($data['source_id']);
$target_id = intval($data['target_id']);

if ($source_id === $target_id) {
    jsonResponse(false, 'Cannot merge individual with itself');
}

try {
    $db = getDB();
    
    // Get both individuals
    $stmt = $db->prepare("SELECT * FROM individuals WHERE individual_id = ?");
    $stmt->execute([$source_id]);
    $source = $stmt->fetch();
    
    $stmt->execute([$target_id]);
    $target = $stmt->fetch();
    
    if (!$source || !$target) {
        jsonResponse(false, 'Individual not found');
    }
    
    // Move all clips from source to target
    $source_dir = KNOWN_DIR . '/' . $source['name'];
    $target_dir = KNOWN_DIR . '/' . $target['name'];
    
    if (!is_dir($target_dir)) {
        mkdir($target_dir, 0755, true);
    }
    
    // Get all clips from source individual
    $clips_stmt = $db->prepare("
        SELECT * FROM clips 
        WHERE folder_person = ? AND clip_type = 'known'
    ");
    $clips_stmt->execute([$source['name']]);
    $clips = $clips_stmt->fetchAll();
    
    $moved_count = 0;
    foreach ($clips as $clip) {
        $old_path = KNOWN_DIR . '/' . $clip['filepath'];
        $new_filename = basename($clip['filepath']);
        
        // Handle filename conflicts
        $counter = 1;
        $base_name = pathinfo($new_filename, PATHINFO_FILENAME);
        $extension = pathinfo($new_filename, PATHINFO_EXTENSION);
        
        while (file_exists($target_dir . '/' . $new_filename)) {
            $new_filename = $base_name . '_' . $counter . '.' . $extension;
            $counter++;
        }
        
        $new_path = $target_dir . '/' . $new_filename;
        $new_filepath = $target['name'] . '/' . $new_filename;
        
        // Move file
        if (file_exists($old_path)) {
            if (rename($old_path, $new_path)) {
                // Update database
                $update_stmt = $db->prepare("
                    UPDATE clips 
                    SET folder_person = ?, filepath = ?
                    WHERE clip_id = ?
                ");
                $update_stmt->execute([$target['name'], $new_filepath, $clip['clip_id']]);
                $moved_count++;
            }
        }
    }
    
    // Merge tags (avoid duplicates)
    $db->exec("
        INSERT OR IGNORE INTO individual_tags (individual_id, tag_id)
        SELECT $target_id, tag_id 
        FROM individual_tags 
        WHERE individual_id = $source_id
    ");
    
    // Update face profiles to point to target
    $db->prepare("
        UPDATE face_profiles 
        SET individual_id = ? 
        WHERE individual_id = ?
    ")->execute([$target_id, $source_id]);
    
    // Update clip_individuals - use INSERT OR REPLACE to handle duplicates
    // First, delete any existing matches for target that would conflict
    $db->exec("
        DELETE FROM clip_individuals
        WHERE individual_id = $target_id
        AND clip_id IN (
            SELECT clip_id FROM clip_individuals WHERE individual_id = $source_id
        )
    ");
    
    // Now update the source matches to point to target
    $db->prepare("
        UPDATE clip_individuals 
        SET individual_id = ? 
        WHERE individual_id = ?
    ")->execute([$target_id, $source_id]);
    
    // Update known_error_matches - use INSERT OR REPLACE to handle duplicates
    // First, delete any existing error matches for target that would conflict
    $db->exec("
        DELETE FROM known_error_matches
        WHERE individual_id = $target_id
        AND clip_id IN (
            SELECT clip_id FROM known_error_matches WHERE individual_id = $source_id
        )
    ");
    
    // Now update the source error matches to point to target
    $db->prepare("
        UPDATE known_error_matches 
        SET individual_id = ? 
        WHERE individual_id = ?
    ")->execute([$target_id, $source_id]);
    
    // Delete source individual
    $db->prepare("DELETE FROM individuals WHERE individual_id = ?")->execute([$source_id]);
    
    // Remove source directory if empty
    if (is_dir($source_dir)) {
        @rmdir($source_dir);
    }
    
    jsonResponse(true, "Merged successfully. Moved $moved_count clips from {$source['name']} to {$target['name']}", [
        'target_id' => $target_id,
        'moved_clips' => $moved_count
    ]);
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}