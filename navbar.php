<?php
/**
 * Shared Navbar Component
 * Responsive navigation bar for Navigate and Admin sections
 */

$section = getCurrentSection();
$colors = getColorScheme();
$theme = getCurrentTheme();
?>

<nav class="navbar">
    <div class="nav-container">
        <div class="nav-brand">
            <?php if ($section === 'navigate'): ?>
                <a href="individuals.php">
                    &#127968; <span>Navigate</span>
                </a>
            <?php else: ?>
                <a href="individuals.php">
                    &#9881;&#65039; <span>Admin</span>
                </a>
            <?php endif; ?>
        </div>
        
        <button class="nav-toggle" id="navToggle" aria-label="Toggle navigation">
            <span></span>
            <span></span>
            <span></span>
        </button>
        
        <div class="nav-menu" id="navMenu">
            <?php if ($section === 'navigate'): ?>
                <!-- Navigate Menu -->
                <a href="../admin/individuals.php" class="nav-link nav-switch">Switch to Admin</a>
                
            <?php else: ?>
                <!-- Admin Menu -->
                <a href="individuals.php" class="nav-link">Individuals</a>
                <a href="mosaic.php" class="nav-link">Mosaic</a>
                <a href="matches.php" class="nav-link">Matches</a>
                <a href="duplicates.php" class="nav-link">Duplicates</a>
                <a href="tags.php" class="nav-link">Tags</a>
                <a href="clusters.php" class="nav-link">Clusters</a>
                <a href="known_matches.php" class="nav-link">Known Matches</a>
                <a href="../navigate/individuals.php" class="nav-link nav-switch">Switch to Navigate</a>
            <?php endif; ?>
            
            <button class="theme-toggle" id="themeToggle" title="Toggle dark mode">
                <span class="theme-icon">&#127763;</span>
            </button>
        </div>
    </div>
</nav>

<style>
:root {
    --primary-color: <?= $colors['primary'] ?>;
    --secondary-color: <?= $colors['secondary'] ?>;
    --background-color: <?= $colors['background'] ?>;
    --text-color: <?= $colors['text'] ?>;
    --accent-color: <?= $colors['accent'] ?>;
}

.navbar {
    background-color: var(--secondary-color);
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    position: sticky;
    top: 0;
    z-index: 1000;
}

.nav-container {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    height: 60px;
}

.nav-brand a {
    color: white;
    text-decoration: none;
    font-size: 20px;
    font-weight: bold;
    display: flex;
    align-items: center;
    gap: 8px;
}

.nav-brand a:hover {
    opacity: 0.9;
}

.nav-toggle {
    display: none;
    flex-direction: column;
    background: none;
    border: none;
    cursor: pointer;
    padding: 5px;
}

.nav-toggle span {
    width: 25px;
    height: 3px;
    background-color: white;
    margin: 3px 0;
    transition: 0.3s;
    border-radius: 3px;
}

.nav-menu {
    display: flex;
    align-items: center;
    gap: 5px;
}

.nav-link {
    color: white;
    text-decoration: none;
    padding: 8px 16px;
    border-radius: 4px;
    transition: background-color 0.2s;
    font-size: 14px;
    font-weight: 500;
}

.nav-link:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

.nav-link.active {
    background-color: var(--primary-color);
}

.nav-link.nav-switch {
    background-color: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.3);
}

.theme-toggle {
    background: none;
    border: none;
    color: white;
    font-size: 20px;
    cursor: pointer;
    padding: 8px 12px;
    border-radius: 4px;
    transition: background-color 0.2s;
}

.theme-toggle:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

/* Mobile Responsive */
@media (max-width: 767px) {
    .nav-toggle {
        display: flex;
    }
    
    .nav-menu {
        position: absolute;
        top: 60px;
        left: 0;
        right: 0;
        background-color: var(--secondary-color);
        flex-direction: column;
        align-items: stretch;
        gap: 0;
        max-height: 0;
        overflow: hidden;
        transition: max-height 0.3s ease;
    }
    
    .nav-menu.active {
        max-height: 500px;
        border-top: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .nav-link {
        padding: 15px 20px;
        border-radius: 0;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }
    
    .theme-toggle {
        margin: 10px 20px;
        align-self: flex-start;
    }
    
    .nav-toggle.active span:nth-child(1) {
        transform: rotate(-45deg) translate(-5px, 6px);
    }
    
    .nav-toggle.active span:nth-child(2) {
        opacity: 0;
    }
    
    .nav-toggle.active span:nth-child(3) {
        transform: rotate(45deg) translate(-5px, -6px);
    }
}

/* Tablet */
@media (min-width: 768px) and (max-width: 1024px) {
    .nav-link {
        font-size: 13px;
        padding: 8px 12px;
    }
    
    .nav-brand a span {
        display: none;
    }
}
</style>

<script>
// Mobile menu toggle
document.getElementById('navToggle').addEventListener('click', function() {
    this.classList.toggle('active');
    document.getElementById('navMenu').classList.toggle('active');
});

// Theme toggle
document.getElementById('themeToggle').addEventListener('click', function() {
    const currentTheme = document.cookie.replace(/(?:(?:^|.*;\s*)theme\s*\=\s*([^;]*).*$)|^.*$/, "$1") || 'light';
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    
    // Set cookie for 1 year
    document.cookie = `theme=${newTheme}; path=/; max-age=31536000`;
    
    // Reload page to apply new theme
    location.reload();
});

// Highlight current page
const currentPath = window.location.pathname;
const currentPage = currentPath.split('/').pop(); // Get just the filename
document.querySelectorAll('.nav-link').forEach(link => {
    const linkPage = link.getAttribute('href').split('/').pop();
    if (linkPage === currentPage) {
        link.classList.add('active');
    }
});

// Close mobile menu when clicking outside
document.addEventListener('click', function(event) {
    const navToggle = document.getElementById('navToggle');
    const navMenu = document.getElementById('navMenu');
    
    if (!navToggle.contains(event.target) && !navMenu.contains(event.target)) {
        navToggle.classList.remove('active');
        navMenu.classList.remove('active');
    }
});
</script>
