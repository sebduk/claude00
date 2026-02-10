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
    
    // Verify clip exists
    $stmt = $db->prepare("SELECT clip_id FROM clips WHERE clip_id = ?");
    $stmt->execute([$clip_id]);
    if (!$stmt->fetch()) {
        jsonResponse(false, 'Clip not found');
    }
    
    // Update individual
    $update_stmt = $db->prepare("
        UPDATE individuals 
        SET default_thumbnail_clip_id = ? 
        WHERE individual_id = ?
    ");
    $update_stmt->execute([$clip_id, $individual_id]);
    
    jsonResponse(true, 'Default thumbnail updated');
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
