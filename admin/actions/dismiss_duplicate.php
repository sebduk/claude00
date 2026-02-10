<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['clip1_id']) || !isset($data['clip2_id'])) {
    jsonResponse(false, 'Missing clip IDs');
}

$clip1_id = intval($data['clip1_id']);
$clip2_id = intval($data['clip2_id']);

// Ensure clip1_id < clip2_id for consistency
if ($clip1_id > $clip2_id) {
    $temp = $clip1_id;
    $clip1_id = $clip2_id;
    $clip2_id = $temp;
}

try {
    $db = getDB();
    
    // Create table if it doesn't exist
    $db->exec("
        CREATE TABLE IF NOT EXISTS dismissed_duplicates (
            clip1_id INTEGER NOT NULL,
            clip2_id INTEGER NOT NULL,
            dismissed_date DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (clip1_id, clip2_id),
            FOREIGN KEY (clip1_id) REFERENCES clips(clip_id) ON DELETE CASCADE,
            FOREIGN KEY (clip2_id) REFERENCES clips(clip_id) ON DELETE CASCADE
        )
    ");
    
    // Insert dismissal
    $stmt = $db->prepare("
        INSERT OR IGNORE INTO dismissed_duplicates (clip1_id, clip2_id)
        VALUES (?, ?)
    ");
    $stmt->execute([$clip1_id, $clip2_id]);
    
    jsonResponse(true, 'Duplicate pair dismissed');
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}