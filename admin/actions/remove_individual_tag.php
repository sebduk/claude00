<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['individual_id']) || !isset($data['tag_id'])) {
    jsonResponse(false, 'Missing parameters');
}

$individual_id = intval($data['individual_id']);
$tag_id = intval($data['tag_id']);

try {
    $db = getDB();
    
    // Check if tag type is 'both' - if so, also remove from known clips
    $tag_stmt = $db->prepare("SELECT tag_type FROM tags WHERE tag_id = ?");
    $tag_stmt->execute([$tag_id]);
    $tag = $tag_stmt->fetch();

    $stmt = $db->prepare("DELETE FROM individual_tags WHERE individual_id = ? AND tag_id = ?");
    $stmt->execute([$individual_id, $tag_id]);

    if ($tag && $tag['tag_type'] === 'both') {
        $name_stmt = $db->prepare("SELECT name FROM individuals WHERE individual_id = ?");
        $name_stmt->execute([$individual_id]);
        $individual = $name_stmt->fetch();

        if ($individual) {
            $clips_stmt = $db->prepare("
                DELETE FROM clip_tags WHERE tag_id = ? AND clip_id IN (
                    SELECT clip_id FROM clips
                    WHERE folder_person = ? AND clip_type = 'known'
                )
            ");
            $clips_stmt->execute([$tag_id, $individual['name']]);
        }
    }

    jsonResponse(true, 'Tag removed');
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
