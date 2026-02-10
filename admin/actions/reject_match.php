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
    
    // Add to known_error_matches to prevent future suggestions
    $stmt = $db->prepare("
        INSERT OR IGNORE INTO known_error_matches (clip_id, individual_id, notes)
        VALUES (?, ?, 'Rejected by user')
    ");
    $stmt->execute([$clip_id, $individual_id]);
    
    jsonResponse(true, 'Match rejected');
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
