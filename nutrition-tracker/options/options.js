/**
 * Options page controller.
 * Handles target settings and data management.
 */

(async function() {
  'use strict';

  // Load current targets
  const result = await chrome.storage.local.get('targets');
  const targets = result.targets || { kcal: 2000, protein: 150, carbs: 250, fat: 65 };

  document.getElementById('target-kcal').value = targets.kcal;
  document.getElementById('target-protein').value = targets.protein;
  document.getElementById('target-carbs').value = targets.carbs;
  document.getElementById('target-fat').value = targets.fat;

  // Save targets
  document.getElementById('targets-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const newTargets = {
      kcal: Number(document.getElementById('target-kcal').value),
      protein: Number(document.getElementById('target-protein').value),
      carbs: Number(document.getElementById('target-carbs').value),
      fat: Number(document.getElementById('target-fat').value)
    };
    await chrome.storage.local.set({ targets: newTargets });
    showToast('Targets saved');
  });

  // Export all data
  document.getElementById('export-data').addEventListener('click', async () => {
    const allData = await chrome.storage.local.get(null);
    const blob = new Blob([JSON.stringify(allData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `nutrition-data-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Data exported');
  });

  // Clear today's data
  document.getElementById('clear-today').addEventListener('click', async () => {
    if (!confirm('Clear all food and exercise data for today?')) return;
    const today = new Date().toISOString().split('T')[0];
    await chrome.storage.local.remove(`day_${today}`);
    showToast('Today\'s data cleared');
  });

  // Clear all data
  document.getElementById('clear-all').addEventListener('click', async () => {
    if (!confirm('This will delete ALL your nutrition data. Are you sure?')) return;
    if (!confirm('This cannot be undone. Really delete everything?')) return;
    await chrome.storage.local.clear();
    // Re-save default targets
    await chrome.storage.local.set({ targets: { kcal: 2000, protein: 150, carbs: 250, fat: 65 } });
    showToast('All data cleared');
  });

  function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 2500);
  }
})();
