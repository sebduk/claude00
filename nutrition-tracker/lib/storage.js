/**
 * Storage abstraction layer using Chrome's storage.local API.
 * All data is keyed by date (YYYY-MM-DD) for daily tracking.
 */

const Storage = {
  // Get data for a specific date
  async getDayData(dateStr) {
    const key = `day_${dateStr}`;
    const result = await chrome.storage.local.get(key);
    return result[key] || { foods: [], exercises: [], date: dateStr };
  },

  // Save data for a specific date
  async saveDayData(dateStr, data) {
    const key = `day_${dateStr}`;
    await chrome.storage.local.set({ [key]: { ...data, date: dateStr } });
  },

  // Add a food entry. If food.timestamp is already set, it is preserved.
  async addFood(dateStr, food) {
    const data = await this.getDayData(dateStr);
    food.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    if (!food.timestamp) food.timestamp = new Date().toISOString();
    data.foods.push(food);
    await this.saveDayData(dateStr, data);
    await this.addToRecentFoods(food);
    return food;
  },

  // Remove a food entry
  async removeFood(dateStr, foodId) {
    const data = await this.getDayData(dateStr);
    data.foods = data.foods.filter(f => f.id !== foodId);
    await this.saveDayData(dateStr, data);
  },

  // Add an exercise entry. If exercise.timestamp is already set, it is preserved.
  async addExercise(dateStr, exercise) {
    const data = await this.getDayData(dateStr);
    exercise.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    if (!exercise.timestamp) exercise.timestamp = new Date().toISOString();
    data.exercises.push(exercise);
    await this.saveDayData(dateStr, data);
    return exercise;
  },

  // Remove an exercise entry
  async removeExercise(dateStr, exerciseId) {
    const data = await this.getDayData(dateStr);
    data.exercises = data.exercises.filter(e => e.id !== exerciseId);
    await this.saveDayData(dateStr, data);
  },

  // Import multiple food entries at once (preserves existing timestamps)
  async importFoods(dateStr, foods) {
    const data = await this.getDayData(dateStr);
    for (const food of foods) {
      food.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6) + Math.random().toString(36).slice(2, 4);
      if (!food.timestamp) food.timestamp = new Date().toISOString();
      food.imported = true;
      data.foods.push(food);
    }
    await this.saveDayData(dateStr, data);
  },

  // Import multiple exercise entries at once (preserves existing timestamps)
  async importExercises(dateStr, exercises) {
    const data = await this.getDayData(dateStr);
    for (const exercise of exercises) {
      exercise.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6) + Math.random().toString(36).slice(2, 4);
      if (!exercise.timestamp) exercise.timestamp = new Date().toISOString();
      exercise.imported = true;
      data.exercises.push(exercise);
    }
    await this.saveDayData(dateStr, data);
  },

  // Get/set daily targets
  async getTargets() {
    const result = await chrome.storage.local.get('targets');
    return result.targets || {
      kcal: 2000,
      protein: 150,
      carbs: 250,
      fat: 65
    };
  },

  async saveTargets(targets) {
    await chrome.storage.local.set({ targets });
  },

  // Recent foods (for quick re-adding)
  async getRecentFoods() {
    const result = await chrome.storage.local.get('recentFoods');
    return result.recentFoods || [];
  },

  async addToRecentFoods(food) {
    let recent = await this.getRecentFoods();
    // Remove duplicates by name
    recent = recent.filter(f => f.name.toLowerCase() !== food.name.toLowerCase());
    // Add to front
    recent.unshift({
      name: food.name,
      kcal: food.kcal,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      serving: food.serving || ''
    });
    // Keep only last 20
    recent = recent.slice(0, 20);
    await chrome.storage.local.set({ recentFoods: recent });
  },

  // ── Meal Presets ──
  // User-defined meals (e.g. "Breakfast", "ProteinShake") with full macro breakdowns
  async getMealPresets() {
    const result = await chrome.storage.local.get('mealPresets');
    return result.mealPresets || [];
  },

  async saveMealPresets(presets) {
    await chrome.storage.local.set({ mealPresets: presets });
  },

  async addMealPreset(preset) {
    const presets = await this.getMealPresets();
    preset.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    presets.push(preset);
    await this.saveMealPresets(presets);
    return preset;
  },

  async updateMealPreset(id, updates) {
    const presets = await this.getMealPresets();
    const idx = presets.findIndex(p => p.id === id);
    if (idx >= 0) {
      presets[idx] = { ...presets[idx], ...updates };
      await this.saveMealPresets(presets);
    }
  },

  async removeMealPreset(id) {
    let presets = await this.getMealPresets();
    presets = presets.filter(p => p.id !== id);
    await this.saveMealPresets(presets);
  },

  // ── Custom Foods (learned from AI estimates) ──
  async getCustomFoods() {
    const result = await chrome.storage.local.get('customFoods');
    return result.customFoods || [];
  },

  async addCustomFood(food) {
    let foods = await this.getCustomFoods();
    // Remove existing entry with same name (case-insensitive)
    foods = foods.filter(f => f.name.toLowerCase() !== food.name.toLowerCase());
    foods.unshift({
      name: food.name.toLowerCase(),
      kcal: Number(food.kcal) || 0,
      protein: Number(food.protein) || 0,
      carbs: Number(food.carbs) || 0,
      fat: Number(food.fat) || 0,
      serving: food.serving || '',
      per: 1,
      unit: food.serving || 'serving',
      custom: true
    });
    // Keep max 100 custom foods
    foods = foods.slice(0, 100);
    await chrome.storage.local.set({ customFoods: foods });
  },

  // Quick exercises
  async getQuickExercises() {
    const result = await chrome.storage.local.get('quickExercises');
    return result.quickExercises || [
      { name: 'Running (30min)', duration: 30, calories: 300 },
      { name: 'Walking (30min)', duration: 30, calories: 150 },
      { name: 'Weight Training (45min)', duration: 45, calories: 250 },
      { name: 'Cycling (30min)', duration: 30, calories: 280 },
      { name: 'Swimming (30min)', duration: 30, calories: 350 },
      { name: 'HIIT (20min)', duration: 20, calories: 250 },
      { name: 'Yoga (45min)', duration: 45, calories: 180 },
    ];
  },

  // Helper: format date as YYYY-MM-DD
  formatDate(date) {
    return date.toISOString().split('T')[0];
  },

  // Helper: get today's date string
  today() {
    return this.formatDate(new Date());
  }
};
