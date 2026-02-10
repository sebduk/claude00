<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['clip_id']) || !isset($data['tag_id'])) {
    jsonResponse(false, 'Missing parameters');
}

$clip_id = intval($data['clip_id']);
$tag_id = intval($data['tag_id']);

try {
    $db = getDB();
    
    $stmt = $db->prepare("DELETE FROM clip_tags WHERE clip_id = ? AND tag_id = ?");
    $stmt->execute([$clip_id, $tag_id]);
    
    jsonResponse(true, 'Tag removed');
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
