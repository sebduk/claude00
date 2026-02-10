# Fixing Numpy for Apache on macOS

## Your Situation

From your output:
```
Requirement already satisfied: numpy in /Users/me/Library/Python/3.9/lib/python/site-packages
```

This means numpy is installed in **YOUR user directory**, but Apache can't access it because Apache runs as a different user (`_www` on macOS).

## The Solution - Install to System Python

You have a few options:

### Option 1: Install to System-Wide Location (RECOMMENDED)

```bash
# Use -H flag to install in system location, not user directory
sudo -H pip3 install numpy --break-system-packages

# Or install directly to system Python site-packages
sudo /usr/bin/python3 -m pip install numpy --break-system-packages
```

### Option 2: Set PYTHONPATH in PHP to Include Your User Packages

Edit `/admin/actions/force_rematch_individual.php` and add this BEFORE the `exec()` call:

**Find this section (around line 35):**
```php
$command = sprintf(
    'python3 %s %d --threshold %f --db %s 2>&1',
    escapeshellarg($script_path),
    $individual_id,
    $threshold,
    escapeshellarg($db_path)
);

// Execute the Python script
exec($command, $output, $return_code);
```

**Change to:**
```php
// Set PYTHONPATH to include user packages
putenv('PYTHONPATH=/Users/me/Library/Python/3.9/lib/python/site-packages');

$command = sprintf(
    'python3 %s %d --threshold %f --db %s 2>&1',
    escapeshellarg($script_path),
    $individual_id,
    $threshold,
    escapeshellarg($db_path)
);

// Execute the Python script
exec($command, $output, $return_code);
```

Replace `/Users/me/` with your actual username.

### Option 3: Copy Numpy to System Location

```bash
# Find where system Python looks for packages
python3 -c "import sys; print([p for p in sys.path if 'site-packages' in p and '/Users/' not in p])"

# This might show something like:
# ['/Library/Python/3.9/site-packages']

# Copy numpy there
sudo cp -r ~/Library/Python/3.9/lib/python/site-packages/numpy* /Library/Python/3.9/site-packages/
```

### Option 4: Use Absolute Python Path with User Environment

Edit `force_rematch_individual.php`:

```php
// Set environment to run as your user
$home = '/Users/me';
putenv("HOME=$home");
putenv("USER=me");
putenv("PYTHONPATH=$home/Library/Python/3.9/lib/python/site-packages");

$command = sprintf(
    'python3 %s %d --threshold %f --db %s 2>&1',
    // ... rest stays the same
```

## Quick Test

After applying a solution, create this test file in `/admin/test_numpy.php`:

```php
<?php
header('Content-Type: text/plain');

// Use same environment as force_rematch_individual.php
putenv('PYTHONPATH=/Users/me/Library/Python/3.9/lib/python/site-packages');

$cmd = 'python3 -c "import numpy; print(\'SUCCESS\')" 2>&1';
exec($cmd, $output, $code);

echo "Return code: $code\n";
echo "Output: " . implode("\n", $output) . "\n";

if ($code === 0 && strpos(implode('', $output), 'SUCCESS') !== false) {
    echo "\n✓ Numpy is now accessible from Apache!\n";
} else {
    echo "\n✗ Still not working\n";
}
?>
```

Visit: `http://localhost/admin/test_numpy.php`

## My Recommendation

**Try Option 2 first** (PYTHONPATH in PHP) - it's the quickest and safest:

1. Edit `/admin/actions/force_rematch_individual.php`
2. Add this line BEFORE `exec($command, ...)`:
   ```php
   putenv('PYTHONPATH=/Users/YOURUSERNAME/Library/Python/3.9/lib/python/site-packages');
   ```
3. Replace `YOURUSERNAME` with your actual username
4. Test the Force Re-match button

This doesn't require sudo or moving files around, and it makes YOUR numpy installation accessible to the PHP script.

## If You Want System-Wide (Cleaner Long-term)

If you want to do it properly system-wide:

```bash
# Install to system location with -H flag
sudo -H pip3 install --upgrade --force-reinstall numpy --break-system-packages

# Verify it's in system location
python3 -c "import numpy; print(numpy.__file__)"
# Should show: /Library/Python/3.9/site-packages/numpy/...
# NOT /Users/me/Library/...
```

Let me know which option you'd like to try!
