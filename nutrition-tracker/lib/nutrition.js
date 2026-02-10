/**
 * Nutrition calculation engine.
 * Computes totals, remaining macros, and net calories.
 */

const Nutrition = {
  // Calculate totals for a day's food entries
  calculateTotals(foods) {
    return foods.reduce((totals, food) => {
      totals.kcal += Number(food.kcal) || 0;
      totals.protein += Number(food.protein) || 0;
      totals.carbs += Number(food.carbs) || 0;
      totals.fat += Number(food.fat) || 0;
      return totals;
    }, { kcal: 0, protein: 0, carbs: 0, fat: 0 });
  },

  // Calculate total exercise calories burned
  calculateExerciseCalories(exercises) {
    return exercises.reduce((total, ex) => total + (Number(ex.calories) || 0), 0);
  },

  // Calculate remaining macros
  calculateRemaining(totals, targets) {
    return {
      kcal: targets.kcal - totals.kcal,
      protein: targets.protein - totals.protein,
      carbs: targets.carbs - totals.carbs,
      fat: targets.fat - totals.fat
    };
  },

  // Calculate percentage of target achieved
  calculatePercentage(current, target) {
    if (target <= 0) return 0;
    return Math.min(Math.round((current / target) * 100), 100);
  },

  // Calculate net calories (consumed - burned)
  calculateNetCalories(foodKcal, exerciseKcal) {
    return foodKcal - exerciseKcal;
  },

  // Check if a macro is over target
  isOverTarget(current, target) {
    return current > target;
  },

  // Get macro breakdown as percentages of calories
  getMacroPercentages(totals) {
    const totalCals = (totals.protein * 4) + (totals.carbs * 4) + (totals.fat * 9);
    if (totalCals === 0) return { protein: 0, carbs: 0, fat: 0 };
    return {
      protein: Math.round((totals.protein * 4 / totalCals) * 100),
      carbs: Math.round((totals.carbs * 4 / totalCals) * 100),
      fat: Math.round((totals.fat * 9 / totalCals) * 100)
    };
  },

  // Format macro value for display
  formatMacro(value, unit = 'g') {
    if (unit === 'kcal') return Math.round(value);
    return Number(value).toFixed(1);
  }
};
