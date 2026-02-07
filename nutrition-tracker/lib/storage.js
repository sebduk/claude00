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

  // Add a food entry
  async addFood(dateStr, food) {
    const data = await this.getDayData(dateStr);
    food.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    food.timestamp = new Date().toISOString();
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

  // Add an exercise entry
  async addExercise(dateStr, exercise) {
    const data = await this.getDayData(dateStr);
    exercise.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    exercise.timestamp = new Date().toISOString();
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

  // Import multiple food entries at once
  async importFoods(dateStr, foods) {
    const data = await this.getDayData(dateStr);
    for (const food of foods) {
      food.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6) + Math.random().toString(36).slice(2, 4);
      food.timestamp = new Date().toISOString();
      food.imported = true;
      data.foods.push(food);
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

  // Quick foods (customizable presets)
  async getQuickFoods() {
    const result = await chrome.storage.local.get('quickFoods');
    return result.quickFoods || [
      { name: 'Chicken Breast (150g)', kcal: 248, protein: 46, carbs: 0, fat: 5.4 },
      { name: 'Rice (200g cooked)', kcal: 260, protein: 5.4, carbs: 56, fat: 0.6 },
      { name: 'Eggs (2 large)', kcal: 156, protein: 12, carbs: 1.1, fat: 10.6 },
      { name: 'Banana', kcal: 105, protein: 1.3, carbs: 27, fat: 0.4 },
      { name: 'Greek Yogurt (200g)', kcal: 130, protein: 20, carbs: 8, fat: 0.8 },
      { name: 'Oatmeal (50g dry)', kcal: 190, protein: 7, carbs: 34, fat: 3.4 },
      { name: 'Salmon (150g)', kcal: 312, protein: 34, carbs: 0, fat: 18.6 },
      { name: 'Avocado (half)', kcal: 160, protein: 2, carbs: 8.5, fat: 14.7 },
      { name: 'Protein Shake', kcal: 150, protein: 30, carbs: 5, fat: 2 },
      { name: 'Almonds (30g)', kcal: 173, protein: 6, carbs: 6, fat: 15 },
      { name: 'Sweet Potato (200g)', kcal: 172, protein: 3.2, carbs: 40, fat: 0.2 },
      { name: 'Broccoli (150g)', kcal: 51, protein: 4.2, carbs: 10, fat: 0.6 },
    ];
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
