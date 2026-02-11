<?php
/**
 * Path Diagnostic Script
 * Run this to see what paths are stored in your database
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

echo "<h2>Sample Clip Paths in Database</h2>";

// Get some sample clips
$clips = $db->query("SELECT clip_id, filename, filepath, thumbnail_path, clip_type FROM clips LIMIT 10")->fetchAll();

echo "<table border='1' cellpadding='10'>";
echo "<tr><th>ID</th><th>Filename</th><th>Filepath (DB)</th><th>Thumbnail Path (DB)</th><th>Type</th><th>Full Video URL</th><th>Full Thumb URL</th></tr>";

foreach ($clips as $clip) {
    $video_url = '../' . $clip['filepath'];
    $thumb_url = '../' . $clip['thumbnail_path'];
    
    echo "<tr>";
    echo "<td>{$clip['clip_id']}</td>";
    echo "<td>{$clip['filename']}</td>";
    echo "<td>{$clip['filepath']}</td>";
    echo "<td>{$clip['thumbnail_path']}</td>";
    echo "<td>{$clip['clip_type']}</td>";
    echo "<td><a href='{$video_url}' target='_blank'>Test Link</a></td>";
    echo "<td><img src='{$thumb_url}' width='80' onerror='this.parentNode.innerHTML=\"&#10060; Not found\"'></td>";
    echo "</tr>";
}

echo "</table>";

echo "<h2>Sample Individual Thumbnails</h2>";

$individuals = $db->query("
    SELECT i.individual_id, i.name, i.default_thumbnail_clip_id, c.thumbnail_path 
    FROM individuals i 
    LEFT JOIN clips c ON i.default_thumbnail_clip_id = c.clip_id 
    LIMIT 10
")->fetchAll();

echo "<table border='1' cellpadding='10'>";
echo "<tr><th>ID</th><th>Name</th><th>Default Clip ID</th><th>Thumbnail Path (DB)</th><th>Full Thumb URL</th><th>Image</th></tr>";

foreach ($individuals as $ind) {
    $thumb_url = $ind['thumbnail_path'] ? '../' . $ind['thumbnail_path'] : '';
    
    echo "<tr>";
    echo "<td>{$ind['individual_id']}</td>";
    echo "<td>{$ind['name']}</td>";
    echo "<td>{$ind['default_thumbnail_clip_id']}</td>";
    echo "<td>{$ind['thumbnail_path']}</td>";
    echo "<td>{$thumb_url}</td>";
    if ($thumb_url) {
        echo "<td><img src='{$thumb_url}' width='80' onerror='this.parentNode.innerHTML=\"&#10060; Not found\"'></td>";
    } else {
        echo "<td>No default set</td>";
    }
    echo "</tr>";
}

echo "</table>";

echo "<h3>Current Directory: " . __DIR__ . "</h3>";
echo "<h3>Config DB Path: " . DB_PATH . "</h3>";
?>
