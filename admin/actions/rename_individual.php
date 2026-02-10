<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['individual_id']) || !isset($data['new_name'])) {
    jsonResponse(false, 'Missing parameters');
}

$individual_id = intval($data['individual_id']);
$new_name = trim($data['new_name']);

// Validate new name
if (empty($new_name)) {
    jsonResponse(false, 'Name cannot be empty');
}

if (strlen($new_name) > 255) {
    jsonResponse(false, 'Name too long (max 255 characters)');
}

// Check for invalid characters in folder names
if (preg_match('/[\/\\\\:*?"<>|]/', $new_name)) {
    jsonResponse(false, 'Name contains invalid characters (/ \\ : * ? " < > |)');
}

try {
    $db = getDB();
    
    // Get current individual
    $stmt = $db->prepare("SELECT * FROM individuals WHERE individual_id = ?");
    $stmt->execute([$individual_id]);
    $individual = $stmt->fetch();
    
    if (!$individual) {
        jsonResponse(false, 'Individual not found');
    }
    
    $old_name = $individual['name'];
    
    // Check if new name is same as old name
    if ($new_name === $old_name) {
        jsonResponse(false, 'New name is the same as current name');
    }
    
    // Check if new name already exists
    $check_stmt = $db->prepare("SELECT individual_id FROM individuals WHERE name = ? AND individual_id != ?");
    $check_stmt->execute([$new_name, $individual_id]);
    $existing = $check_stmt->fetch();
    
    if ($existing) {
        jsonResponse(false, "Name '{$new_name}' already exists. Please choose a different name or merge these individuals instead.");
    }
    
    // Rename folder if it exists
    $old_dir = KNOWN_DIR . '/' . $old_name;
    $new_dir = KNOWN_DIR . '/' . $new_name;
    
    if (is_dir($old_dir)) {
        if (is_dir($new_dir)) {
            jsonResponse(false, "Folder '{$new_name}' already exists on filesystem");
        }
        
        if (!rename($old_dir, $new_dir)) {
            jsonResponse(false, 'Failed to rename folder');
        }
    }
    
    // Update database
    $db->beginTransaction();
    
    try {
        // Update individual name
        $update_individual = $db->prepare("UPDATE individuals SET name = ? WHERE individual_id = ?");
        $update_individual->execute([$new_name, $individual_id]);
        
        // Update all clips' folder_person and filepath
        $clips_stmt = $db->prepare("
            SELECT clip_id, filepath FROM clips 
            WHERE folder_person = ? AND clip_type = 'known'
        ");
        $clips_stmt->execute([$old_name]);
        $clips = $clips_stmt->fetchAll();
        
        foreach ($clips as $clip) {
            // Update filepath (change folder name)
            $old_filepath = $clip['filepath'];
            $new_filepath = $new_name . '/' . basename($old_filepath);
            
            $update_clip = $db->prepare("
                UPDATE clips 
                SET folder_person = ?, filepath = ? 
                WHERE clip_id = ?
            ");
            $update_clip->execute([$new_name, $new_filepath, $clip['clip_id']]);
        }
        
        $db->commit();
        
        jsonResponse(true, "Individual renamed from '{$old_name}' to '{$new_name}'", [
            'new_name' => $new_name,
            'clips_updated' => count($clips)
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        
        // Rollback folder rename if database update failed
        if (is_dir($new_dir) && !is_dir($old_dir)) {
            rename($new_dir, $old_dir);
        }
        
        throw $e;
    }
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}