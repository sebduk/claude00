/**
 * Main popup controller.
 * Handles UI interactions, tab switching, data rendering, and form submissions.
 */

(async function() {
  'use strict';

  // ── State ──
  let currentDate = Storage.today();
  let targets = await Storage.getTargets();
  let pendingImport = [];

  // ── Init ──
  await initTabs();
  await initDateNav();
  await initQuickFoods();
  await initQuickExercises();
  await initForms();
  await refreshDashboard();

  document.getElementById('btn-settings').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
  });

  // ── Tab Navigation ──
  function initTabs() {
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
      });
    });
  }

  // ── Date Navigation ──
  function initDateNav() {
    renderDate();
    document.getElementById('prev-day').addEventListener('click', () => {
      const d = new Date(currentDate);
      d.setDate(d.getDate() - 1);
      currentDate = Storage.formatDate(d);
      renderDate();
      refreshDashboard();
    });
    document.getElementById('next-day').addEventListener('click', () => {
      const d = new Date(currentDate);
      d.setDate(d.getDate() + 1);
      const today = new Date();
      if (d <= today) {
        currentDate = Storage.formatDate(d);
        renderDate();
        refreshDashboard();
      }
    });
  }

  function renderDate() {
    const d = new Date(currentDate + 'T12:00:00');
    const today = Storage.today();
    const yesterday = Storage.formatDate(new Date(Date.now() - 86400000));
    let label;
    if (currentDate === today) label = 'Today';
    else if (currentDate === yesterday) label = 'Yesterday';
    else label = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    document.getElementById('current-date').textContent = label;
  }

  // ── Dashboard Refresh ──
  async function refreshDashboard() {
    targets = await Storage.getTargets();
    const data = await Storage.getDayData(currentDate);
    const totals = Nutrition.calculateTotals(data.foods);
    const exerciseCals = Nutrition.calculateExerciseCalories(data.exercises);

    // Update macro cards
    updateMacroCard('kcal', totals.kcal, targets.kcal, 'kcal');
    updateMacroCard('protein', totals.protein, targets.protein, 'g');
    updateMacroCard('carbs', totals.carbs, targets.carbs, 'g');
    updateMacroCard('fat', totals.fat, targets.fat, 'g');

    // Update exercise summary
    document.getElementById('exercise-kcal').textContent = `${exerciseCals} kcal`;

    // Update net calories
    const netKcal = Nutrition.calculateNetCalories(totals.kcal, exerciseCals);
    const netEl = document.getElementById('net-kcal');
    netEl.textContent = `${Math.round(netKcal)} kcal`;
    netEl.className = netKcal > targets.kcal ? 'net-positive' : '';

    // Update tips
    renderTips(totals, targets, data.exercises);

    // Update food log
    renderFoodLog(data.foods);

    // Update exercise log
    renderExerciseLog(data.exercises);
  }

  function updateMacroCard(macro, current, target, unit) {
    const pct = Nutrition.calculatePercentage(current, target);
    const remaining = target - current;
    const isOver = current > target;

    document.getElementById(`${macro}-current`).textContent =
      unit === 'kcal' ? Math.round(current) : current.toFixed(1);
    document.getElementById(`${macro}-target`).textContent =
      unit === 'kcal' ? Math.round(target) : target;

    const bar = document.getElementById(`${macro}-bar`);
    bar.style.width = `${Math.min(pct, 100)}%`;
    bar.classList.toggle('over', isOver);

    const remainingEl = document.getElementById(`${macro}-remaining`);
    if (isOver) {
      remainingEl.textContent = `${Math.abs(remaining).toFixed(unit === 'kcal' ? 0 : 1)}${unit === 'kcal' ? '' : unit} over`;
      remainingEl.style.color = '#ef4444';
    } else {
      remainingEl.textContent = `${remaining.toFixed(unit === 'kcal' ? 0 : 1)}${unit === 'kcal' ? '' : unit} remaining`;
      remainingEl.style.color = '';
    }
  }

  // ── Tips ──
  function renderTips(totals, targets, exercises) {
    const tips = Tips.generate(totals, targets, exercises);
    const container = document.getElementById('tips-content');

    if (tips.length === 0) {
      container.innerHTML = '<div class="tip-item">Log some food to get personalized tips.</div>';
      return;
    }

    container.innerHTML = tips.map(tip =>
      `<div class="tip-item">${tip.text}</div>`
    ).join('');
  }

  // ── Food Log ──
  function renderFoodLog(foods) {
    const container = document.getElementById('food-log');
    if (foods.length === 0) {
      container.innerHTML = '<div class="empty-state">No food logged yet</div>';
      return;
    }

    container.innerHTML = foods.map(food => {
      const time = food.timestamp ? new Date(food.timestamp).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }) : '';
      return `
        <div class="log-item" data-id="${food.id}">
          <div class="log-item-info">
            <span class="log-item-name">${escapeHtml(food.name)}</span>
            <span class="log-item-macros">${Math.round(food.kcal)} kcal | P: ${Number(food.protein).toFixed(1)}g | C: ${Number(food.carbs).toFixed(1)}g | F: ${Number(food.fat).toFixed(1)}g</span>
          </div>
          <span class="log-item-time">${time}</span>
          <div class="log-item-actions">
            <button class="delete-btn" data-food-id="${food.id}" title="Remove">&times;</button>
          </div>
        </div>`;
    }).join('');

    // Attach delete handlers
    container.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const foodId = e.target.dataset.foodId;
        await Storage.removeFood(currentDate, foodId);
        await refreshDashboard();
        showToast('Food removed', 'success');
      });
    });
  }

  // ── Exercise Log ──
  function renderExerciseLog(exercises) {
    const container = document.getElementById('exercise-log');
    if (exercises.length === 0) {
      container.innerHTML = '';
      return;
    }

    container.innerHTML = exercises.map(ex => {
      const time = ex.timestamp ? new Date(ex.timestamp).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }) : '';
      return `
        <div class="log-item exercise-item" data-id="${ex.id}">
          <div class="log-item-info">
            <span class="log-item-name">${escapeHtml(ex.name)}</span>
            <span class="log-item-macros">${ex.duration} min | ${ex.calories} kcal burned${ex.notes ? ' | ' + escapeHtml(ex.notes) : ''}</span>
          </div>
          <span class="log-item-time">${time}</span>
          <div class="log-item-actions">
            <button class="delete-btn" data-exercise-id="${ex.id}" title="Remove">&times;</button>
          </div>
        </div>`;
    }).join('');

    container.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const exerciseId = e.target.dataset.exerciseId;
        await Storage.removeExercise(currentDate, exerciseId);
        await refreshDashboard();
        showToast('Exercise removed', 'success');
      });
    });
  }

  // ── Quick Foods ──
  async function initQuickFoods() {
    const quickFoods = await Storage.getQuickFoods();
    const container = document.getElementById('quick-foods');
    container.innerHTML = quickFoods.map((food, i) =>
      `<button class="quick-item" data-index="${i}">${escapeHtml(food.name)}</button>`
    ).join('');

    container.addEventListener('click', async (e) => {
      const btn = e.target.closest('.quick-item');
      if (!btn) return;
      const food = quickFoods[btn.dataset.index];
      await Storage.addFood(currentDate, { ...food });
      await refreshDashboard();
      showToast(`Added ${food.name}`, 'success');
    });

    // Also render recent foods
    await renderRecentFoods();
  }

  async function renderRecentFoods() {
    const recent = await Storage.getRecentFoods();
    const container = document.getElementById('recent-foods');
    if (recent.length === 0) {
      container.innerHTML = '<div class="empty-state">No recent foods</div>';
      return;
    }

    container.innerHTML = recent.map((food, i) =>
      `<div class="recent-item" data-index="${i}">
        <div class="log-item-info">
          <span class="log-item-name">${escapeHtml(food.name)}</span>
          <span class="log-item-macros">${Math.round(food.kcal)} kcal | P: ${Number(food.protein).toFixed(1)}g</span>
        </div>
        <span style="color: var(--accent); font-size: 16px;">+</span>
      </div>`
    ).join('');

    container.addEventListener('click', async (e) => {
      const item = e.target.closest('.recent-item');
      if (!item) return;
      const food = recent[item.dataset.index];
      await Storage.addFood(currentDate, { ...food });
      await refreshDashboard();
      showToast(`Added ${food.name}`, 'success');
      // Switch to dashboard
      document.querySelector('.tab[data-tab="dashboard"]').click();
    });
  }

  // ── Quick Exercises ──
  async function initQuickExercises() {
    const quickExercises = await Storage.getQuickExercises();
    const container = document.getElementById('quick-exercises');
    container.innerHTML = quickExercises.map((ex, i) =>
      `<button class="quick-item" data-index="${i}">${escapeHtml(ex.name)}</button>`
    ).join('');

    container.addEventListener('click', async (e) => {
      const btn = e.target.closest('.quick-item');
      if (!btn) return;
      const ex = quickExercises[btn.dataset.index];
      await Storage.addExercise(currentDate, { ...ex });
      await refreshDashboard();
      showToast(`Added ${ex.name}`, 'success');
    });
  }

  // ── Forms ──
  function initForms() {
    // Food form
    document.getElementById('food-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const food = {
        name: document.getElementById('food-name').value.trim(),
        kcal: Number(document.getElementById('food-kcal').value),
        protein: Number(document.getElementById('food-protein').value),
        carbs: Number(document.getElementById('food-carbs').value),
        fat: Number(document.getElementById('food-fat').value),
        serving: document.getElementById('food-serving').value.trim()
      };
      await Storage.addFood(currentDate, food);
      e.target.reset();
      await refreshDashboard();
      showToast(`Added ${food.name}`, 'success');
      document.querySelector('.tab[data-tab="dashboard"]').click();
    });

    // Exercise form
    document.getElementById('exercise-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const exercise = {
        name: document.getElementById('exercise-name').value.trim(),
        duration: Number(document.getElementById('exercise-duration').value),
        calories: Number(document.getElementById('exercise-calories').value),
        notes: document.getElementById('exercise-notes').value.trim()
      };
      await Storage.addExercise(currentDate, exercise);
      e.target.reset();
      await refreshDashboard();
      showToast(`Added ${exercise.name}`, 'success');
      document.querySelector('.tab[data-tab="dashboard"]').click();
    });

    // Import form
    document.getElementById('import-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const text = document.getElementById('import-data').value;
      pendingImport = ImportParser.parse(text);

      if (pendingImport.length === 0) {
        showToast('No food entries found in the data. Check the supported formats.', 'warning');
        return;
      }

      renderImportPreview(pendingImport);
    });

    // Import date default
    document.getElementById('import-date').value = currentDate;

    // Import confirm
    document.getElementById('import-confirm').addEventListener('click', async () => {
      const importDate = document.getElementById('import-date').value || currentDate;
      await Storage.importFoods(importDate, pendingImport);
      currentDate = importDate;
      renderDate();
      pendingImport = [];
      document.getElementById('import-preview').classList.add('hidden');
      document.getElementById('import-data').value = '';
      await refreshDashboard();
      showToast(`Imported ${pendingImport.length || 'all'} items`, 'success');
      document.querySelector('.tab[data-tab="dashboard"]').click();
    });

    // Import cancel
    document.getElementById('import-cancel').addEventListener('click', () => {
      pendingImport = [];
      document.getElementById('import-preview').classList.add('hidden');
    });
  }

  function renderImportPreview(items) {
    const container = document.getElementById('import-items');
    document.getElementById('import-count').textContent = items.length;

    container.innerHTML = items.map(food =>
      `<div class="log-item">
        <div class="log-item-info">
          <span class="log-item-name">${escapeHtml(food.name)}</span>
          <span class="log-item-macros">${Math.round(food.kcal)} kcal | P: ${Number(food.protein).toFixed(1)}g | C: ${Number(food.carbs).toFixed(1)}g | F: ${Number(food.fat).toFixed(1)}g</span>
        </div>
      </div>`
    ).join('');

    document.getElementById('import-preview').classList.remove('hidden');
  }

  // ── Utilities ──
  function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 2500);
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
})();
