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
    
    // Delete physical file
    if ($clip['clip_type'] === 'known') {
        $file_path = KNOWN_DIR . '/' . $clip['filepath'];
    } else {
        $file_path = UNKNOWN_DIR . '/' . $clip['filepath'];
    }
    
    if (file_exists($file_path)) {
        unlink($file_path);
    }
    
    // Delete thumbnail
    if (!empty($clip['thumbnail_path']) && file_exists($clip['thumbnail_path'])) {
        unlink($clip['thumbnail_path']);
    }
    
    // Delete mosaic
    if (!empty($clip['mosaic_path']) && file_exists($clip['mosaic_path'])) {
        unlink($clip['mosaic_path']);
    }
    
    // Delete from database (cascade will handle related records)
    $delete_stmt = $db->prepare("DELETE FROM clips WHERE clip_id = ?");
    $delete_stmt->execute([$clip_id]);
    
    jsonResponse(true, 'Clip deleted successfully');
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
