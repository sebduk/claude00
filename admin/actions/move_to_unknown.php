<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['clip_id'])) {
    jsonResponse(false, 'Missing clip_id');
}

$clip_id = intval($data['clip_id']);

try {
    $db = getDB();
    
    // Get clip info
    $stmt = $db->prepare("SELECT * FROM clips WHERE clip_id = ?");
    $stmt->execute([$clip_id]);
    $clip = $stmt->fetch();
    
    if (!$clip) {
        jsonResponse(false, 'Clip not found');
    }
    
    // Generate unknown folder path (videos/unknown/YYYYMM/)
    $file_date = new DateTime($clip['file_date']);
    $yyyymm = $file_date->format('Ym');
    $unknown_dir = UNKNOWN_DIR . '/' . $yyyymm;
    
    // Create directory if it doesn't exist
    if (!is_dir($unknown_dir)) {
        mkdir($unknown_dir, 0755, true);
    }
    
    // Old and new paths
    $old_path = KNOWN_DIR . '/' . $clip['filepath'];
    $new_path = $unknown_dir . '/' . basename($clip['filepath']);
    $new_filepath = $yyyymm . '/' . basename($clip['filepath']);
    
    // Move file
    if (file_exists($old_path)) {
        if (!rename($old_path, $new_path)) {
            jsonResponse(false, 'Failed to move file');
        }
    }
    
    // Update database
    $update_stmt = $db->prepare("
        UPDATE clips 
        SET clip_type = 'unknown', 
            folder_person = NULL,
            filepath = ?
        WHERE clip_id = ?
    ");
    $update_stmt->execute([$new_filepath, $clip_id]);
    
    jsonResponse(true, 'Clip moved to unknown');
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
