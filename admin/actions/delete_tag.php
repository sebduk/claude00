<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['tag_id'])) {
    jsonResponse(false, 'Missing tag_id');
}

$tag_id = intval($data['tag_id']);

try {
    $db = getDB();
    
    // Delete tag (CASCADE will handle individual_tags and clip_tags)
    $stmt = $db->prepare("DELETE FROM tags WHERE tag_id = ?");
    $stmt->execute([$tag_id]);
    
    jsonResponse(true, 'Tag deleted successfully');
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
