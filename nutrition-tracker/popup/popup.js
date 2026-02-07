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
  let currentLookup = null;  // Current food-db lookup result
  let suggestIndex = -1;     // Active suggestion index for keyboard nav

  // ── Init ──
  initTabs();
  initDateNav();
  initSmartFoodInput();
  await initMealPresets();
  await initQuickExercises();
  initExerciseForm();
  initPresetForm();
  initImportForm();
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

        // Refresh presets list when switching to presets tab
        if (tab.dataset.tab === 'presets') renderPresetsList();
        // Refresh recent foods when switching to food tab
        if (tab.dataset.tab === 'log-food') renderRecentFoods();
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

    updateMacroCard('kcal', totals.kcal, targets.kcal, 'kcal');
    updateMacroCard('protein', totals.protein, targets.protein, 'g');
    updateMacroCard('carbs', totals.carbs, targets.carbs, 'g');
    updateMacroCard('fat', totals.fat, targets.fat, 'g');

    document.getElementById('exercise-kcal').textContent = `${exerciseCals} kcal`;

    const netKcal = Nutrition.calculateNetCalories(totals.kcal, exerciseCals);
    const netEl = document.getElementById('net-kcal');
    netEl.textContent = `${Math.round(netKcal)} kcal`;
    netEl.className = netKcal > targets.kcal ? 'net-positive' : '';

    renderTips(totals, targets, data.exercises);
    renderFoodLog(data.foods);
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
    container.innerHTML = tips.map(tip => `<div class="tip-item">${tip.text}</div>`).join('');
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

    container.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        await Storage.removeFood(currentDate, e.target.dataset.foodId);
        await refreshDashboard();
        showToast('Food removed', 'success');
      });
    });
  }

  // ── Exercise Log ──
  function renderExerciseLog(exercises) {
    const container = document.getElementById('exercise-log');
    if (exercises.length === 0) { container.innerHTML = ''; return; }

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
        await Storage.removeExercise(currentDate, e.target.dataset.exerciseId);
        await refreshDashboard();
        showToast('Exercise removed', 'success');
      });
    });
  }

  // ══════════════════════════════════════════════
  // ── Smart Food Input (the main new feature) ──
  // ══════════════════════════════════════════════

  function initSmartFoodInput() {
    const input = document.getElementById('food-input');
    const suggestionsEl = document.getElementById('food-suggestions');
    const addBtn = document.getElementById('food-input-add');

    let debounceTimer;

    // As user types, show suggestions + preview
    input.addEventListener('input', () => {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => onFoodInputChange(input.value), 150);
    });

    // Keyboard navigation in suggestions
    input.addEventListener('keydown', (e) => {
      const items = suggestionsEl.querySelectorAll('.suggestion-item');
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        suggestIndex = Math.min(suggestIndex + 1, items.length - 1);
        updateSuggestionHighlight(items);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        suggestIndex = Math.max(suggestIndex - 1, -1);
        updateSuggestionHighlight(items);
      } else if (e.key === 'Enter') {
        e.preventDefault();
        if (suggestIndex >= 0 && items[suggestIndex]) {
          items[suggestIndex].click();
        } else if (currentLookup) {
          addCurrentLookup();
        } else {
          // Try lookup on current text
          const text = input.value.trim();
          if (text) {
            onFoodInputChange(text);
            if (currentLookup) addCurrentLookup();
          }
        }
      } else if (e.key === 'Escape') {
        hideSuggestions();
      }
    });

    // Close suggestions on blur (with delay for click)
    input.addEventListener('blur', () => {
      setTimeout(() => hideSuggestions(), 200);
    });

    // + button
    addBtn.addEventListener('click', () => {
      if (currentLookup) {
        addCurrentLookup();
      } else {
        const text = input.value.trim();
        if (text) {
          onFoodInputChange(text);
          if (currentLookup) addCurrentLookup();
        }
      }
    });

    // Preview: Add This
    document.getElementById('preview-add').addEventListener('click', () => addCurrentLookup());

    // Preview: Edit Macros
    document.getElementById('preview-edit').addEventListener('click', () => {
      if (!currentLookup) return;
      const r = currentLookup.result;
      document.getElementById('override-kcal').value = r.kcal;
      document.getElementById('override-protein').value = r.protein;
      document.getElementById('override-carbs').value = r.carbs;
      document.getElementById('override-fat').value = r.fat;
      document.getElementById('food-manual-override').classList.remove('hidden');
    });

    // Override: Add with Custom Macros
    document.getElementById('override-add').addEventListener('click', async () => {
      if (!currentLookup) return;
      const food = {
        name: currentLookup.result.name,
        kcal: Number(document.getElementById('override-kcal').value) || 0,
        protein: Number(document.getElementById('override-protein').value) || 0,
        carbs: Number(document.getElementById('override-carbs').value) || 0,
        fat: Number(document.getElementById('override-fat').value) || 0,
        serving: currentLookup.result.serving
      };
      await Storage.addFood(currentDate, food);
      await refreshDashboard();
      resetFoodInput();
      showToast(`Added ${food.name}`, 'success');
    });

    // Manual add (no match)
    document.getElementById('manual-add').addEventListener('click', async () => {
      const name = document.getElementById('manual-name').value.trim() ||
                   document.getElementById('food-input').value.trim() || 'Custom food';
      const food = {
        name,
        kcal: Number(document.getElementById('manual-kcal').value) || 0,
        protein: Number(document.getElementById('manual-protein').value) || 0,
        carbs: Number(document.getElementById('manual-carbs').value) || 0,
        fat: Number(document.getElementById('manual-fat').value) || 0,
        serving: ''
      };
      await Storage.addFood(currentDate, food);
      await refreshDashboard();
      resetFoodInput();
      showToast(`Added ${food.name}`, 'success');
    });
  }

  function onFoodInputChange(text) {
    text = text.trim();
    if (!text) {
      hideSuggestions();
      hideAllPreviews();
      currentLookup = null;
      return;
    }

    // Show autocomplete suggestions
    const suggestions = FoodDB.suggest(text);
    renderSuggestions(suggestions, text);

    // Try to lookup the full text
    const lookup = FoodDB.lookup(text);
    currentLookup = lookup;

    if (lookup) {
      showFoodPreview(lookup);
      document.getElementById('food-no-match').classList.add('hidden');
    } else {
      document.getElementById('food-preview').classList.add('hidden');
      document.getElementById('food-manual-override').classList.add('hidden');
      // Show manual entry if we have text but no match
      if (text.length >= 2) {
        document.getElementById('food-no-match').classList.remove('hidden');
        document.getElementById('manual-name').value = text;
      }
    }
  }

  function renderSuggestions(foods, query) {
    const el = document.getElementById('food-suggestions');
    if (foods.length === 0) { hideSuggestions(); return; }

    suggestIndex = -1;
    el.innerHTML = foods.map((f, i) => {
      const info = f.per === 1 && f.unit
        ? `${f.kcal} kcal / ${f.unit}`
        : `${f.kcal} kcal / 100g`;
      return `<div class="suggestion-item" data-index="${i}">
        <span class="suggestion-name">${escapeHtml(f.name)}</span>
        <span class="suggestion-info">${info}</span>
      </div>`;
    }).join('');

    el.classList.remove('hidden');

    // Click handler for each suggestion
    el.querySelectorAll('.suggestion-item').forEach((item, i) => {
      item.addEventListener('click', () => {
        const food = foods[i];
        const input = document.getElementById('food-input');
        // Preserve any quantity prefix the user typed
        const { quantity, unit } = FoodDB.parseQuantity(input.value);
        let newText = food.name;
        if (quantity && unit) newText = `${quantity}${unit} ${food.name}`;
        else if (quantity) newText = `${quantity} ${food.name}`;

        input.value = newText;
        hideSuggestions();
        onFoodInputChange(newText);
      });
    });
  }

  function updateSuggestionHighlight(items) {
    items.forEach((item, i) => {
      item.classList.toggle('active', i === suggestIndex);
    });
  }

  function hideSuggestions() {
    document.getElementById('food-suggestions').classList.add('hidden');
    suggestIndex = -1;
  }

  function showFoodPreview(lookup) {
    const r = lookup.result;
    document.getElementById('preview-name').textContent = r.name;
    document.getElementById('preview-serving').textContent = r.serving;
    document.getElementById('preview-kcal').textContent = Math.round(r.kcal);
    document.getElementById('preview-protein').textContent = r.protein.toFixed(1);
    document.getElementById('preview-carbs').textContent = r.carbs.toFixed(1);
    document.getElementById('preview-fat').textContent = r.fat.toFixed(1);
    document.getElementById('food-preview').classList.remove('hidden');
    document.getElementById('food-manual-override').classList.add('hidden');
  }

  function hideAllPreviews() {
    document.getElementById('food-preview').classList.add('hidden');
    document.getElementById('food-manual-override').classList.add('hidden');
    document.getElementById('food-no-match').classList.add('hidden');
  }

  async function addCurrentLookup() {
    if (!currentLookup) return;
    const r = currentLookup.result;
    await Storage.addFood(currentDate, { ...r });
    await refreshDashboard();
    resetFoodInput();
    showToast(`Added ${r.name}`, 'success');
  }

  function resetFoodInput() {
    document.getElementById('food-input').value = '';
    currentLookup = null;
    hideAllPreviews();
    hideSuggestions();
  }

  // ══════════════════════════
  // ── Meal Presets ──
  // ══════════════════════════

  async function initMealPresets() {
    await renderMealPresetsQuick();
    await renderPresetsList();
    await renderRecentFoods();
  }

  async function renderMealPresetsQuick() {
    const presets = await Storage.getMealPresets();
    const container = document.getElementById('meal-presets-quick');
    const section = document.getElementById('presets-quick-section');

    if (presets.length === 0) {
      section.classList.add('hidden');
      return;
    }

    section.classList.remove('hidden');
    container.innerHTML = presets.map((p, i) =>
      `<button class="quick-item preset-item" data-index="${i}">
        ${escapeHtml(p.name)}
        <span class="preset-sub">${Math.round(p.kcal)} kcal</span>
      </button>`
    ).join('');

    container.addEventListener('click', async (e) => {
      const btn = e.target.closest('.preset-item');
      if (!btn) return;
      const preset = presets[btn.dataset.index];
      await Storage.addFood(currentDate, {
        name: preset.name,
        kcal: preset.kcal,
        protein: preset.protein,
        carbs: preset.carbs,
        fat: preset.fat,
        serving: preset.description || ''
      });
      await refreshDashboard();
      showToast(`Added ${preset.name}`, 'success');
    });
  }

  async function renderPresetsList() {
    const presets = await Storage.getMealPresets();
    const container = document.getElementById('presets-list');

    if (presets.length === 0) {
      container.innerHTML = '<div class="empty-state">No presets yet. Create one above.</div>';
      return;
    }

    container.innerHTML = presets.map(p =>
      `<div class="preset-list-item">
        <div class="preset-list-info">
          <div class="preset-list-name">${escapeHtml(p.name)}</div>
          ${p.description ? `<div class="preset-list-desc">${escapeHtml(p.description)}</div>` : ''}
          <div class="preset-list-macros">${Math.round(p.kcal)} kcal | P: ${Number(p.protein).toFixed(1)}g | C: ${Number(p.carbs).toFixed(1)}g | F: ${Number(p.fat).toFixed(1)}g</div>
        </div>
        <div class="preset-list-actions">
          <button class="delete-btn" data-preset-id="${p.id}" title="Delete">&times;</button>
        </div>
      </div>`
    ).join('');

    container.querySelectorAll('.delete-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        await Storage.removeMealPreset(e.target.dataset.presetId);
        await renderPresetsList();
        await renderMealPresetsQuick();
        showToast('Preset deleted', 'success');
      });
    });
  }

  function initPresetForm() {
    document.getElementById('preset-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const preset = {
        name: document.getElementById('preset-name').value.trim(),
        description: document.getElementById('preset-description').value.trim(),
        kcal: Number(document.getElementById('preset-kcal').value),
        protein: Number(document.getElementById('preset-protein').value),
        carbs: Number(document.getElementById('preset-carbs').value),
        fat: Number(document.getElementById('preset-fat').value),
      };
      await Storage.addMealPreset(preset);
      e.target.reset();
      await renderPresetsList();
      await renderMealPresetsQuick();
      showToast(`Saved "${preset.name}" preset`, 'success');
    });
  }

  // ── Recent Foods ──
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

    // Re-attach click handler (avoid duplicate listeners by using a fresh clone approach)
    const newContainer = container.cloneNode(true);
    container.parentNode.replaceChild(newContainer, container);

    newContainer.addEventListener('click', async (e) => {
      const item = e.target.closest('.recent-item');
      if (!item) return;
      const food = recent[item.dataset.index];
      await Storage.addFood(currentDate, { ...food });
      await refreshDashboard();
      showToast(`Added ${food.name}`, 'success');
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

  // ── Exercise Form ──
  function initExerciseForm() {
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
  }

  // ── Import Form ──
  function initImportForm() {
    document.getElementById('import-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const text = document.getElementById('import-data').value;
      pendingImport = ImportParser.parse(text);
      if (pendingImport.length === 0) {
        showToast('No food entries found. Check the supported formats.', 'warning');
        return;
      }
      renderImportPreview(pendingImport);
    });

    document.getElementById('import-date').value = currentDate;

    document.getElementById('import-confirm').addEventListener('click', async () => {
      const importDate = document.getElementById('import-date').value || currentDate;
      const count = pendingImport.length;
      await Storage.importFoods(importDate, pendingImport);
      currentDate = importDate;
      renderDate();
      pendingImport = [];
      document.getElementById('import-preview').classList.add('hidden');
      document.getElementById('import-data').value = '';
      await refreshDashboard();
      showToast(`Imported ${count} items`, 'success');
      document.querySelector('.tab[data-tab="dashboard"]').click();
    });

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
