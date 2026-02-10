/**
 * Smart tips engine.
 * Generates contextual eating suggestions based on:
 * - Remaining macros for the day
 * - Time of day
 * - Current macro balance
 */

const Tips = {
  // Food suggestions mapped to macro needs
  suggestions: {
    highProtein: [
      'Chicken breast, fish, or tofu',
      'Greek yogurt or cottage cheese',
      'Protein shake or eggs',
      'Lean beef or turkey',
    ],
    highCarbs: [
      'Rice, pasta, or potatoes',
      'Oatmeal or whole grain bread',
      'Fruits like bananas or berries',
      'Sweet potatoes or quinoa',
    ],
    highFat: [
      'Avocado or nuts',
      'Olive oil or nut butter',
      'Cheese or dark chocolate',
      'Salmon or mackerel',
    ],
    lowCalorie: [
      'Salad with lean protein',
      'Vegetables with hummus',
      'Broth-based soup',
      'Egg whites with spinach',
    ],
    balanced: [
      'Chicken stir-fry with rice and vegetables',
      'Salmon with sweet potato and greens',
      'Turkey sandwich on whole grain bread',
      'Burrito bowl with beans, rice, and salsa',
    ]
  },

  // Generate tips based on current state
  generate(totals, targets, exercises, hour) {
    const tips = [];
    const remaining = {
      kcal: targets.kcal - totals.kcal,
      protein: targets.protein - totals.protein,
      carbs: targets.carbs - totals.carbs,
      fat: targets.fat - totals.fat
    };

    const exerciseCals = exercises.reduce((t, e) => t + (Number(e.calories) || 0), 0);
    if (typeof hour === 'undefined') {
      hour = new Date().getHours();
    }

    // Time-based meal suggestions
    if (hour < 10 && totals.kcal === 0) {
      tips.push({
        type: 'timing',
        text: 'Start your day with a balanced breakfast to kickstart your metabolism.'
      });
    } else if (hour >= 10 && hour < 12 && totals.kcal < targets.kcal * 0.25) {
      tips.push({
        type: 'timing',
        text: 'You\'re behind on intake for this time of day. Consider a substantial mid-morning meal.'
      });
    } else if (hour >= 12 && hour < 14 && totals.kcal < targets.kcal * 0.4) {
      tips.push({
        type: 'timing',
        text: 'Lunchtime - aim for a meal covering ~35% of your daily targets.'
      });
    } else if (hour >= 17 && hour < 20) {
      if (remaining.kcal > targets.kcal * 0.4) {
        tips.push({
          type: 'timing',
          text: `You still have ${Math.round(remaining.kcal)} kcal remaining. Plan a solid dinner.`
        });
      }
    } else if (hour >= 21 && remaining.kcal > targets.kcal * 0.3) {
      tips.push({
        type: 'warning',
        text: `Late in the day with ${Math.round(remaining.kcal)} kcal remaining. Consider a lighter approach tomorrow.`
      });
    }

    // Macro-specific tips
    const proteinPct = targets.protein > 0 ? totals.protein / targets.protein : 1;
    const carbsPct = targets.carbs > 0 ? totals.carbs / targets.carbs : 1;
    const fatPct = targets.fat > 0 ? totals.fat / targets.fat : 1;

    // Find the most deficient macro
    const deficits = [
      { macro: 'protein', pct: proteinPct, remaining: remaining.protein },
      { macro: 'carbs', pct: carbsPct, remaining: remaining.carbs },
      { macro: 'fat', pct: fatPct, remaining: remaining.fat }
    ].sort((a, b) => a.pct - b.pct);

    const mostDeficient = deficits[0];

    if (remaining.kcal > 0 && mostDeficient.remaining > 0) {
      const suggestKey = mostDeficient.macro === 'protein' ? 'highProtein'
        : mostDeficient.macro === 'carbs' ? 'highCarbs'
        : 'highFat';

      const suggestion = this.suggestions[suggestKey][Math.floor(Math.random() * this.suggestions[suggestKey].length)];

      tips.push({
        type: 'macro',
        text: `You need more <strong>${mostDeficient.macro}</strong> (${Math.round(mostDeficient.remaining)}${mostDeficient.macro === 'kcal' ? '' : 'g'} remaining). Try: ${suggestion}`
      });
    }

    // Over-target warnings
    if (totals.kcal > targets.kcal) {
      tips.push({
        type: 'warning',
        text: `You're ${Math.round(totals.kcal - targets.kcal)} kcal over your target. Consider lighter choices for the rest of the day.`
      });
    }

    if (totals.fat > targets.fat) {
      tips.push({
        type: 'warning',
        text: `Fat intake is over target by ${(totals.fat - targets.fat).toFixed(1)}g. Choose leaner options.`
      });
    }

    // Exercise-adjusted tip
    if (exerciseCals > 0 && remaining.kcal + exerciseCals > targets.kcal * 0.3) {
      tips.push({
        type: 'exercise',
        text: `You burned ${exerciseCals} kcal through exercise. You may eat back some of those calories to fuel recovery.`
      });
    }

    // Balance tip
    if (tips.length === 0 && remaining.kcal > 0) {
      const suggestion = this.suggestions.balanced[Math.floor(Math.random() * this.suggestions.balanced.length)];
      tips.push({
        type: 'balanced',
        text: `You're on track! For your next meal, try: ${suggestion}`
      });
    }

    // All targets met
    if (remaining.kcal <= 0 && remaining.protein <= 0) {
      tips.push({
        type: 'success',
        text: 'You\'ve hit your calorie and protein targets for today. Nice work!'
      });
    }

    return tips;
  }
};
