<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['tag_name']) || !isset($data['tag_color']) || !isset($data['tag_type'])) {
    jsonResponse(false, 'Missing required fields');
}

$tag_name = trim($data['tag_name']);
$tag_color = $data['tag_color'];
$tag_type = $data['tag_type'];
$notes = isset($data['notes']) ? trim($data['notes']) : null;
$tag_id = isset($data['tag_id']) && $data['tag_id'] ? intval($data['tag_id']) : null;

// Validate
if (empty($tag_name) || strlen($tag_name) > 50) {
    jsonResponse(false, 'Tag name must be 1-50 characters');
}

if (!in_array($tag_type, ['individual', 'clip', 'both'])) {
    jsonResponse(false, 'Invalid tag type');
}

if (!preg_match('/^#[0-9A-Fa-f]{6}$/', $tag_color)) {
    jsonResponse(false, 'Invalid color format');
}

try {
    $db = getDB();
    
    if ($tag_id) {
        // Update existing tag
        $stmt = $db->prepare("
            UPDATE tags 
            SET tag_name = ?, tag_color = ?, tag_type = ?, notes = ?
            WHERE tag_id = ?
        ");
        $stmt->execute([$tag_name, $tag_color, $tag_type, $notes, $tag_id]);
        $message = 'Tag updated successfully';
    } else {
        // Create new tag
        $stmt = $db->prepare("
            INSERT INTO tags (tag_name, tag_color, tag_type, notes, created_date)
            VALUES (?, ?, ?, ?, datetime('now'))
        ");
        $stmt->execute([$tag_name, $tag_color, $tag_type, $notes]);
        $tag_id = $db->lastInsertId();
        $message = 'Tag created successfully';
    }
    
    jsonResponse(true, $message, ['tag_id' => $tag_id]);
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
