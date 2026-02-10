<?php
require_once __DIR__ . '/../../config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Invalid request method');
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['individual_id'])) {
    jsonResponse(false, 'Missing individual_id parameter');
}

$individual_id = intval($data['individual_id']);
$threshold = isset($data['threshold']) ? floatval($data['threshold']) : 0.6;

// Validate threshold
if ($threshold < 0 || $threshold > 1) {
    jsonResponse(false, 'Threshold must be between 0.0 and 1.0');
}

try {
    // Build the Python command
    $script_path = __DIR__ . '/../../force_rematch_individual.py';
    $db_path = DB_PATH;
    
    // Check if script exists
    if (!file_exists($script_path)) {
        jsonResponse(false, "Python script not found at: $script_path");
    }
    
    // Set PYTHONPATH to include common user package locations
    // This allows Apache to find numpy installed in user directories
    $user_home = getenv('HOME') ?: '/Users/' . get_current_user();
    $python_paths = [
        "$user_home/Library/Python/3.9/lib/python/site-packages",
        "$user_home/Library/Python/3.10/lib/python/site-packages",
        "$user_home/Library/Python/3.11/lib/python/site-packages",
        "$user_home/Library/Python/3.12/lib/python/site-packages",
        "$user_home/.local/lib/python3.9/site-packages",
        "$user_home/.local/lib/python3.10/site-packages",
        "$user_home/.local/lib/python3.11/site-packages",
        "$user_home/.local/lib/python3.12/site-packages"
    ];
    
    // Add existing PYTHONPATH if set
    $existing_path = getenv('PYTHONPATH');
    if ($existing_path) {
        array_unshift($python_paths, $existing_path);
    }
    
    putenv('PYTHONPATH=' . implode(':', $python_paths));
    
    // Use system Python which has numpy, not Homebrew Python
    $python_cmd = '/usr/bin/python3';
    
    $command = sprintf(
        '%s %s %d --threshold %f --db %s 2>&1',
        $python_cmd,
        escapeshellarg($script_path),
        $individual_id,
        $threshold,
        escapeshellarg($db_path)
    );
    
    // Execute the Python script
    exec($command, $output, $return_code);
    
    // Parse output
    $output_text = implode("\n", $output);
    
    if ($return_code !== 0) {
        // Error occurred - return full output for debugging
        $error_msg = 'Python script failed';
        foreach ($output as $line) {
            if (strpos($line, 'ERROR:') === 0) {
                $error_msg = substr($line, 6);
                break;
            }
        }
        
        // If still unknown, include raw output
        if ($error_msg === 'Python script failed' && !empty($output)) {
            $error_msg .= ': ' . implode(' | ', array_slice($output, 0, 3));
        }
        
        jsonResponse(false, $error_msg, ['output' => $output, 'return_code' => $return_code]);
    }
    
    // Check if we got SUCCESS
    if (strpos($output_text, 'SUCCESS') === false) {
        jsonResponse(false, 'Script did not return SUCCESS', ['output' => $output]);
    }
    
    // Parse success output
    $result_data = [];
    foreach ($output as $line) {
        if (strpos($line, ':') !== false && strpos($line, 'SUCCESS') === false) {
            list($key, $value) = explode(':', $line, 2);
            $result_data[$key] = is_numeric($value) ? floatval($value) : $value;
        }
    }
    
    jsonResponse(true, 'Re-matched successfully', $result_data);
    
} catch (Exception $e) {
    jsonResponse(false, 'Error: ' . $e->getMessage());
}