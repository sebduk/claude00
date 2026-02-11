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
    
    // Verify tag type allows individuals
    $tag_stmt = $db->prepare("SELECT tag_type FROM tags WHERE tag_id = ?");
    $tag_stmt->execute([$tag_id]);
    $tag = $tag_stmt->fetch();
    
    if (!$tag) {
        jsonResponse(false, 'Tag not found');
    }
    
    if ($tag['tag_type'] === 'clip') {
        jsonResponse(false, 'This tag can only be applied to clips');
    }
    
    // Add tag (INSERT OR IGNORE prevents duplicates)
    $stmt = $db->prepare("INSERT OR IGNORE INTO individual_tags (individual_id, tag_id) VALUES (?, ?)");
    $stmt->execute([$individual_id, $tag_id]);

    $clips_tagged = 0;

    // If tag type is 'both', also apply to all known clips of this individual
    if ($tag['tag_type'] === 'both') {
        $name_stmt = $db->prepare("SELECT name FROM individuals WHERE individual_id = ?");
        $name_stmt->execute([$individual_id]);
        $individual = $name_stmt->fetch();

        if ($individual) {
            // Get all known clip IDs for this individual
            $clips_stmt = $db->prepare("SELECT clip_id FROM clips WHERE folder_person = ? AND clip_type = 'known'");
            $clips_stmt->execute([$individual['name']]);
            $clip_ids = $clips_stmt->fetchAll(PDO::FETCH_COLUMN);

            // Add tag to each clip
            $insert_stmt = $db->prepare("INSERT OR IGNORE INTO clip_tags (clip_id, tag_id) VALUES (?, ?)");
            foreach ($clip_ids as $clip_id) {
                $insert_stmt->execute([$clip_id, $tag_id]);
                $clips_tagged++;
            }
        }
    }

    jsonResponse(true, 'Tag added', ['tag_type' => $tag['tag_type'], 'clips_tagged' => $clips_tagged]);
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}
