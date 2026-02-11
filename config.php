<?php
/**
 * Configuration File
 * Shared settings for Navigate and Admin sections
 */

// Database configuration
define('DB_PATH', __DIR__ . '/face_recognition.db');

// Directory paths
define('KNOWN_DIR', __DIR__ . '/videos/known');
define('UNKNOWN_DIR', __DIR__ . '/videos/unknown');
define('THUMBNAILS_DIR', __DIR__ . '/thumbnails');
define('MOSAICS_DIR', __DIR__ . '/mosaics');

// Application settings
define('ITEMS_PER_PAGE', 50);
define('THUMBNAIL_MAX_WIDTH', 300);
define('THUMBNAIL_MAX_HEIGHT', 400);

// Star rating values
define('STAR_NONE', 0);
define('STAR_BLUE', 1);
define('STAR_YELLOW', 2);
define('STAR_RED', 3);

// Color schemes
$COLOR_SCHEMES = [
    'navigate' => [
        'light' => [
            'primary' => '#3498db',
            'secondary' => '#2c3e50',
            'background' => '#ecf0f1',
            'text' => '#2c3e50',
            'accent' => '#1abc9c',
        ],
        'dark' => [
            'primary' => '#3498db',
            'secondary' => '#34495e',
            'background' => '#1a1a2e',
            'text' => '#ecf0f1',
            'accent' => '#16a085',
        ]
    ],
    'admin' => [
        'light' => [
            'primary' => '#e74c3c',
            'secondary' => '#c0392b',
            'background' => '#ecf0f1',
            'text' => '#2c3e50',
            'accent' => '#e67e22',
        ],
        'dark' => [
            'primary' => '#e74c3c',
            'secondary' => '#a93226',
            'background' => '#1a1a1a',
            'text' => '#ecf0f1',
            'accent' => '#d35400',
        ]
    ]
];

/**
 * Get database connection
 */
function getDB() {
    try {
        $db = new PDO('sqlite:' . DB_PATH);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        return $db;
    } catch (PDOException $e) {
        die("Database connection failed: " . htmlspecialchars($e->getMessage()));
    }
}

/**
 * Get current theme (light/dark) from cookie
 */
function getCurrentTheme() {
    return isset($_COOKIE['theme']) && $_COOKIE['theme'] === 'dark' ? 'dark' : 'light';
}

/**
 * Get current section (navigate/admin)
 */
function getCurrentSection() {
    $path = $_SERVER['PHP_SELF'];
    return strpos($path, '/admin/') !== false ? 'admin' : 'navigate';
}

/**
 * Get color scheme for current section and theme
 */
function getColorScheme() {
    global $COLOR_SCHEMES;
    $section = getCurrentSection();
    $theme = getCurrentTheme();
    return $COLOR_SCHEMES[$section][$theme];
}

/**
 * Format file size in human-readable format
 */
function formatFileSize($bytes) {
    if ($bytes >= 1073741824) {
        return number_format($bytes / 1073741824, 2) . ' GB';
    } elseif ($bytes >= 1048576) {
        return number_format($bytes / 1048576, 2) . ' MB';
    } elseif ($bytes >= 1024) {
        return number_format($bytes / 1024, 2) . ' KB';
    } else {
        return $bytes . ' bytes';
    }
}

/**
 * Format duration in HH:MM:SS or MM:SS
 */
function formatDuration($seconds) {
    $seconds = (int)round($seconds); // Convert to integer
    if ($seconds >= 3600) {
        return gmdate('H:i:s', $seconds);
    } else {
        return gmdate('i:s', $seconds);
    }
}

/**
 * Get star rating HTML
 */
function getStarHTML($rating, $clickable = false, $individual_id = null) {
    $stars = [
        0 => ['icon' => '&#9734;', 'color' => '#95a5a6', 'title' => 'No rating'],
        1 => ['icon' => '&#9733;', 'color' => '#3498db', 'title' => 'Blue star'],
        2 => ['icon' => '&#9733;', 'color' => '#f1c40f', 'title' => 'Yellow star'],
        3 => ['icon' => '&#9733;', 'color' => '#e74c3c', 'title' => 'Red star'],
    ];
    
    $star = $stars[$rating] ?? $stars[0];
    $class = $clickable ? 'star-rating clickable' : 'star-rating';
    $onclick = $clickable && $individual_id ? "onclick=\"toggleStar($individual_id, $rating)\"" : '';
    
    return sprintf(
        '<span class="%s" style="color: %s;" title="%s" data-rating="%d" %s>%s</span>',
        $class,
        $star['color'],
        $star['title'],
        $rating,
        $onclick,
        $star['icon']
    );
}

/**
 * Get tag badges HTML
 */
function getTagsHTML($tags, $clickable = false) {
    if (empty($tags)) {
        return '';
    }
    
    $html = '<div class="tags-container">';
    foreach ($tags as $tag) {
        $style = sprintf('background-color: %s;', htmlspecialchars($tag['tag_color']));
        $class = $clickable ? 'tag-badge clickable' : 'tag-badge';
        $onclick = $clickable ? sprintf('onclick="filterByTag(%d)"', $tag['tag_id']) : '';
        
        $html .= sprintf(
            '<span class="%s" style="%s" %s>%s</span>',
            $class,
            $style,
            $onclick,
            htmlspecialchars($tag['tag_name'])
        );
    }
    $html .= '</div>';
    
    return $html;
}

/**
 * Sanitize and validate sort parameters
 */
function getSortParams($allowed_columns, $default_sort = 'name', $default_order = 'ASC') {
    $sort = isset($_GET['sort']) && in_array($_GET['sort'], $allowed_columns) 
        ? $_GET['sort'] 
        : $default_sort;
    
    $order = isset($_GET['order']) && strtoupper($_GET['order']) === 'DESC' 
        ? 'DESC' 
        : 'ASC';
    
    return [$sort, $order];
}

/**
 * Build sort URL for column headers
 */
function getSortURL($column, $current_sort, $current_order) {
    $params = $_GET;
    $params['sort'] = $column;
    
    // Toggle order if clicking same column
    if ($column === $current_sort) {
        $params['order'] = $current_order === 'ASC' ? 'DESC' : 'ASC';
    } else {
        $params['order'] = 'ASC';
    }
    
    return '?' . http_build_query($params);
}

/**
 * Get sort indicator for column header
 */
function getSortIndicator($column, $current_sort, $current_order) {
    if ($column !== $current_sort) {
        return '';
    }
    return $current_order === 'ASC' ? ' &#9650;' : ' &#9660;';
}

/**
 * JSON response helper
 */
function jsonResponse($success, $message = '', $data = []) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}
