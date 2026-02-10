<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['clip_id']) || !isset($data['individual_id'])) {
    jsonResponse(false, 'Missing parameters');
}

$clip_id = intval($data['clip_id']);
$individual_id = intval($data['individual_id']);

try {
    $db = getDB();
    
    // Get clip and individual info
    $clip_stmt = $db->prepare("SELECT * FROM clips WHERE clip_id = ?");
    $clip_stmt->execute([$clip_id]);
    $clip = $clip_stmt->fetch();
    
    if (!$clip || $clip['clip_type'] !== 'unknown') {
        jsonResponse(false, 'Invalid clip');
    }
    
    $ind_stmt = $db->prepare("SELECT name FROM individuals WHERE individual_id = ?");
    $ind_stmt->execute([$individual_id]);
    $individual = $ind_stmt->fetch();
    
    if (!$individual) {
        jsonResponse(false, 'Individual not found');
    }
    
    // Move file from unknown to known
    $old_path = UNKNOWN_DIR . '/' . $clip['filepath'];
    $new_dir = KNOWN_DIR . '/' . $individual['name'];
    
    if (!is_dir($new_dir)) {
        mkdir($new_dir, 0755, true);
    }
    
    $new_path = $new_dir . '/' . basename($clip['filepath']);
    $new_filepath = $individual['name'] . '/' . basename($clip['filepath']);
    
    if (file_exists($old_path)) {
        if (!rename($old_path, $new_path)) {
            jsonResponse(false, 'Failed to move file');
        }
    }
    
    // Update database
    $update_stmt = $db->prepare("
        UPDATE clips 
        SET clip_type = 'known',
            folder_person = ?,
            filepath = ?
        WHERE clip_id = ?
    ");
    $update_stmt->execute([$individual['name'], $new_filepath, $clip_id]);
    
    jsonResponse(true, 'Match accepted and clip moved');
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
