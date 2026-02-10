<?php
/**
 * Update Star Rating Action
 * AJAX endpoint for updating individual star ratings
 */

require_once __DIR__ . '/../../config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['individual_id']) || !isset($data['star_rating'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required parameters']);
    exit;
}

$individual_id = intval($data['individual_id']);
$star_rating = intval($data['star_rating']);

// Validate star rating (0-3)
if ($star_rating < 0 || $star_rating > 3) {
    echo json_encode(['success' => false, 'message' => 'Invalid star rating']);
    exit;
}

try {
    $db = getDB();
    
    $stmt = $db->prepare("UPDATE individuals SET star_rating = ? WHERE individual_id = ?");
    $stmt->execute([$star_rating, $individual_id]);
    
    echo json_encode(['success' => true, 'message' => 'Star rating updated']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
