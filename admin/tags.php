<?php
/**
 * Admin - Tags Management Page
 * Create, edit, and manage tags for individuals and clips
 */

require_once __DIR__ . '/../config.php';

$db = getDB();

// Get all tags
$tags = $db->query("
    SELECT 
        t.*,
        (SELECT COUNT(*) FROM individual_tags it WHERE it.tag_id = t.tag_id) as individual_count,
        (SELECT COUNT(*) FROM clip_tags ct WHERE ct.tag_id = t.tag_id) as clip_count
    FROM tags t
    ORDER BY t.tag_name
")->fetchAll();

$colors = getColorScheme();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tags - Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 { color: var(--primary-color); }
        
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        
        .btn:hover { opacity: 0.8; }
        .btn-primary { background: var(--primary-color); color: white; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-delete { background: #e74c3c; color: white; }
        
        .tags-container {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        table { width: 100%; border-collapse: collapse; }
        
        thead {
            background: var(--secondary-color);
            color: white;
        }
        
        th {
            padding: 15px 12px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #ecf0f1;
            vertical-align: middle;
        }
        
        tbody tr:hover { background: #f8f9fa; }
        
        .tag-preview {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 15px;
            font-size: 13px;
            font-weight: 600;
            color: white;
        }
        
        .tag-type {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .tag-type-individual { background: #3498db; color: white; }
        .tag-type-clip { background: #9b59b6; color: white; }
        .tag-type-both { background: #2ecc71; color: white; }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-edit { background: #3498db; color: white; }
        
        .no-tags {
            text-align: center;
            padding: 60px 20px;
            color: #95a5a6;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0,0,0,0.7);
            z-index: 10000;
            align-items: center;
            justify-content: center;
        }
        
        .modal.active { display: flex; }
        
        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            max-width: 500px;
            width: 90%;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        
        .modal-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 20px;
            color: var(--primary-color);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #666;
            margin-bottom: 5px;
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
            font-family: inherit;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 80px;
        }
        
        .color-picker-wrapper {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        
        .color-picker-wrapper input[type="color"] {
            width: 60px;
            height: 40px;
            border: 1px solid #ddd;
            border-radius: 4px;
            cursor: pointer;
        }
        
        .color-preview {
            flex: 1;
            padding: 10px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            text-align: center;
            font-weight: 600;
            color: white;
        }
        
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 20px;
        }
        
        .confirm-modal .modal-message {
            margin-bottom: 20px;
            line-height: 1.6;
        }
        
        @media (max-width: 767px) {
            .tags-container { overflow-x: auto; }
            table { min-width: 700px; }
        }
    </style>
</head>
<body>
    <?php include __DIR__ . '/../navbar.php'; ?>
    
    <div class="container">
        <div class="header">
            <div class="header-top">
                <h1>&#127991;&#65039; Tags Management (<?= count($tags) ?>)</h1>
                <button class="btn btn-primary" onclick="openCreateModal()">
                    + Create New Tag
                </button>
            </div>
        </div>
        
        <div class="tags-container">
            <?php if (count($tags) > 0): ?>
                <table>
                    <thead>
                        <tr>
                            <th style="width: 200px;">Tag Name</th>
                            <th style="width: 120px;">Preview</th>
                            <th style="width: 100px;">Type</th>
                            <th style="width: 100px;">Individuals</th>
                            <th style="width: 100px;">Clips</th>
                            <th>Notes</th>
                            <th style="width: 150px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($tags as $tag): ?>
                            <tr>
                                <td><?= htmlspecialchars($tag['tag_name']) ?></td>
                                <td>
                                    <span class="tag-preview" style="background-color: <?= htmlspecialchars($tag['tag_color']) ?>">
                                        <?= htmlspecialchars($tag['tag_name']) ?>
                                    </span>
                                </td>
                                <td>
                                    <span class="tag-type tag-type-<?= $tag['tag_type'] ?>">
                                        <?= ucfirst($tag['tag_type']) ?>
                                    </span>
                                </td>
                                <td><?= $tag['individual_count'] ?></td>
                                <td><?= $tag['clip_count'] ?></td>
                                <td style="font-size: 12px; color: #666;">
                                    <?= htmlspecialchars($tag['notes'] ?: '&#8212;') ?>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-sm btn-edit" onclick='openEditModal(<?= json_encode($tag) ?>)'>
                                            Edit
                                        </button>
                                        <button class="btn btn-sm btn-delete" onclick="deleteTag(<?= $tag['tag_id'] ?>, '<?= addslashes($tag['tag_name']) ?>')">
                                            Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="no-tags">
                    <h2>No tags yet</h2>
                    <p>Create your first tag to get started.</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <!-- Create/Edit Tag Modal -->
    <div id="tagModal" class="modal">
        <div class="modal-content">
            <div class="modal-title" id="modalTitle">Create New Tag</div>
            
            <form id="tagForm">
                <input type="hidden" id="tagId" name="tag_id">
                
                <div class="form-group">
                    <label for="tagName">Tag Name *</label>
                    <input type="text" id="tagName" name="tag_name" required maxlength="50">
                </div>
                
                <div class="form-group">
                    <label for="tagColor">Tag Color *</label>
                    <div class="color-picker-wrapper">
                        <input type="color" id="tagColor" name="tag_color" value="#3498db">
                        <div class="color-preview" id="colorPreview" style="background-color: #3498db;">
                            Preview
                        </div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="tagType">Tag Type *</label>
                    <select id="tagType" name="tag_type" required>
                        <option value="individual">Individual (for people)</option>
                        <option value="clip">Clip (for videos)</option>
                        <option value="both">Both (for people & videos)</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="tagNotes">Notes (optional)</label>
                    <textarea id="tagNotes" name="notes" placeholder="Add any notes about this tag..."></textarea>
                </div>
                
                <div class="modal-buttons">
                    <button type="button" class="btn btn-secondary" onclick="closeTagModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Tag</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Confirmation Modal -->
    <div id="confirmModal" class="modal confirm-modal">
        <div class="modal-content">
            <div class="modal-title">&#9888; Confirm Action</div>
            <div class="modal-message" id="confirmMessage"></div>
            <div class="modal-buttons">
                <button class="btn btn-secondary" onclick="closeConfirmModal()">Cancel</button>
                <button class="btn btn-delete" id="confirmButton">Yes, Delete</button>
            </div>
        </div>
    </div>
    
    <script>
    // Update color preview when color changes
    document.getElementById('tagColor').addEventListener('input', function(e) {
        document.getElementById('colorPreview').style.backgroundColor = e.target.value;
    });
    
    // Open create modal
    function openCreateModal() {
        document.getElementById('modalTitle').textContent = 'Create New Tag';
        document.getElementById('tagForm').reset();
        document.getElementById('tagId').value = '';
        document.getElementById('tagColor').value = '#3498db';
        document.getElementById('colorPreview').style.backgroundColor = '#3498db';
        document.getElementById('tagModal').classList.add('active');
    }
    
    // Open edit modal
    function openEditModal(tag) {
        document.getElementById('modalTitle').textContent = 'Edit Tag';
        document.getElementById('tagId').value = tag.tag_id;
        document.getElementById('tagName').value = tag.tag_name;
        document.getElementById('tagColor').value = tag.tag_color;
        document.getElementById('colorPreview').style.backgroundColor = tag.tag_color;
        document.getElementById('tagType').value = tag.tag_type;
        document.getElementById('tagNotes').value = tag.notes || '';
        document.getElementById('tagModal').classList.add('active');
    }
    
    // Close tag modal
    function closeTagModal() {
        document.getElementById('tagModal').classList.remove('active');
    }
    
    // Handle form submission
    document.getElementById('tagForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = new FormData(this);
        const data = {
            tag_id: formData.get('tag_id') || null,
            tag_name: formData.get('tag_name'),
            tag_color: formData.get('tag_color'),
            tag_type: formData.get('tag_type'),
            notes: formData.get('notes')
        };
        
        fetch('actions/save_tag.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        })
        .then(r => r.json())
        .then(d => {
            if (d.success) {
                location.reload();
            } else {
                alert('Error: ' + d.message);
            }
        })
        .catch(err => {
            alert('Error saving tag');
            console.error(err);
        });
    });
    
    // Delete tag
    function deleteTag(tagId, tagName) {
        showConfirm(`Delete tag "${tagName}"? This will remove it from all individuals and clips.`, () => {
            fetch('actions/delete_tag.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ tag_id: tagId })
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) {
                    location.reload();
                } else {
                    alert('Error: ' + d.message);
                }
            });
        });
    }
    
    // Confirmation modal
    function showConfirm(msg, cb) {
        document.getElementById('confirmMessage').textContent = msg;
        document.getElementById('confirmModal').classList.add('active');
        document.getElementById('confirmButton').onclick = () => { closeConfirmModal(); cb(); };
    }
    
    function closeConfirmModal() {
        document.getElementById('confirmModal').classList.remove('active');
    }
    
    // Close modals on escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeTagModal();
            closeConfirmModal();
        }
    });
    
    // Close modals on background click
    document.getElementById('tagModal').addEventListener('click', function(e) {
        if (e.target === this) closeTagModal();
    });
    
    document.getElementById('confirmModal').addEventListener('click', function(e) {
        if (e.target === this) closeConfirmModal();
    });
    </script>
</body>
</html>
