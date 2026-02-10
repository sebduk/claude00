<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['individual_id'])) {
    jsonResponse(false, 'Missing individual_id');
}

$individual_id = intval($data['individual_id']);

try {
    $db = getDB();
    
    // Get individual
    $stmt = $db->prepare("SELECT * FROM individuals WHERE individual_id = ?");
    $stmt->execute([$individual_id]);
    $individual = $stmt->fetch();
    
    if (!$individual) {
        jsonResponse(false, 'Individual not found');
    }
    
    // Check if individual has clips
    $clips_stmt = $db->prepare("
        SELECT COUNT(*) FROM clips 
        WHERE folder_person = ? AND clip_type = 'known'
    ");
    $clips_stmt->execute([$individual['name']]);
    $clip_count = $clips_stmt->fetchColumn();
    
    if ($clip_count > 0) {
        jsonResponse(false, "Cannot delete. Individual has $clip_count clip(s) in folder. Move or delete clips first.");
    }
    
    // Check for pending AI matches
    $matches_stmt = $db->prepare("
        SELECT COUNT(*) FROM clip_individuals ci
        JOIN clips c ON ci.clip_id = c.clip_id
        WHERE ci.individual_id = ? AND c.clip_type = 'unknown'
        AND NOT EXISTS (
            SELECT 1 FROM known_error_matches kem 
            WHERE kem.clip_id = ci.clip_id 
            AND kem.individual_id = ci.individual_id
        )
    ");
    $matches_stmt->execute([$individual_id]);
    $match_count = $matches_stmt->fetchColumn();
    
    if ($match_count > 0) {
        jsonResponse(false, "Cannot delete. Individual has $match_count pending AI match(es). Review matches first.");
    }
    
    // Safe to delete - no clips, no pending matches
    // Delete will CASCADE to:
    // - individual_tags
    // - face_profiles (if any exist without clips)
    // - clip_individuals (rejected matches)
    // - known_error_matches
    
    $db->prepare("DELETE FROM individuals WHERE individual_id = ?")->execute([$individual_id]);
    
    // Remove directory if it exists and is empty
    $dir = KNOWN_DIR . '/' . $individual['name'];
    if (is_dir($dir)) {
        @rmdir($dir);
    }
    
    jsonResponse(true, "Individual '{$individual['name']}' deleted successfully");
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}