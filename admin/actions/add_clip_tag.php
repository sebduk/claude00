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
    
    // Verify tag type allows clips
    $tag_stmt = $db->prepare("SELECT tag_type FROM tags WHERE tag_id = ?");
    $tag_stmt->execute([$tag_id]);
    $tag = $tag_stmt->fetch();
    
    if (!$tag) {
        jsonResponse(false, 'Tag not found');
    }
    
    if ($tag['tag_type'] === 'individual') {
        jsonResponse(false, 'This tag can only be applied to individuals');
    }
    
    // Add tag (INSERT OR IGNORE prevents duplicates)
    $stmt = $db->prepare("INSERT OR IGNORE INTO clip_tags (clip_id, tag_id) VALUES (?, ?)");
    $stmt->execute([$clip_id, $tag_id]);
    
    jsonResponse(true, 'Tag added');
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
