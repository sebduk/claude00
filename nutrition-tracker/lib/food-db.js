/**
 * Local food database with nutritional values.
 * Values are per 100g unless noted otherwise with a `unit` field.
 * When a `unit` is present, macros are per 1 unit (e.g. 1 egg, 1 banana).
 */

const FoodDB = {
  // ── Database ──
  foods: [
    // Proteins
    { name: 'chicken breast', kcal: 165, protein: 31, carbs: 0, fat: 3.6, per: 100 },
    { name: 'chicken thigh', kcal: 209, protein: 26, carbs: 0, fat: 10.9, per: 100 },
    { name: 'turkey breast', kcal: 135, protein: 30, carbs: 0, fat: 1, per: 100 },
    { name: 'salmon', kcal: 208, protein: 22, carbs: 0, fat: 12.4, per: 100 },
    { name: 'tuna', kcal: 130, protein: 29, carbs: 0, fat: 0.6, per: 100 },
    { name: 'tuna can', kcal: 116, protein: 25.5, carbs: 0, fat: 0.8, per: 100 },
    { name: 'cod', kcal: 82, protein: 18, carbs: 0, fat: 0.7, per: 100 },
    { name: 'shrimp', kcal: 99, protein: 24, carbs: 0.2, fat: 0.3, per: 100 },
    { name: 'beef steak', kcal: 271, protein: 26, carbs: 0, fat: 18, per: 100 },
    { name: 'ground beef', kcal: 254, protein: 17, carbs: 0, fat: 20, per: 100 },
    { name: 'lean ground beef', kcal: 176, protein: 20, carbs: 0, fat: 10, per: 100 },
    { name: 'pork chop', kcal: 231, protein: 25, carbs: 0, fat: 14, per: 100 },
    { name: 'lamb', kcal: 282, protein: 25, carbs: 0, fat: 20, per: 100 },
    { name: 'tofu', kcal: 76, protein: 8, carbs: 1.9, fat: 4.8, per: 100 },
    { name: 'tempeh', kcal: 192, protein: 20, carbs: 7.6, fat: 11, per: 100 },

    // Eggs & Dairy
    { name: 'egg', kcal: 78, protein: 6, carbs: 0.6, fat: 5.3, per: 1, unit: 'egg (50g)' },
    { name: 'eggs', kcal: 78, protein: 6, carbs: 0.6, fat: 5.3, per: 1, unit: 'egg (50g)' },
    { name: 'egg white', kcal: 17, protein: 3.6, carbs: 0.2, fat: 0.1, per: 1, unit: 'white (33g)' },
    { name: 'greek yogurt', kcal: 59, protein: 10, carbs: 3.6, fat: 0.4, per: 100 },
    { name: 'yogurt', kcal: 61, protein: 3.5, carbs: 4.7, fat: 3.3, per: 100 },
    { name: 'cottage cheese', kcal: 98, protein: 11, carbs: 3.4, fat: 4.3, per: 100 },
    { name: 'mozzarella', kcal: 280, protein: 28, carbs: 3.1, fat: 17, per: 100 },
    { name: 'cheddar', kcal: 403, protein: 25, carbs: 1.3, fat: 33, per: 100 },
    { name: 'parmesan', kcal: 431, protein: 38, carbs: 4.1, fat: 29, per: 100 },
    { name: 'milk', kcal: 42, protein: 3.4, carbs: 5, fat: 1, per: 100 },
    { name: 'whole milk', kcal: 61, protein: 3.2, carbs: 4.8, fat: 3.3, per: 100 },
    { name: 'butter', kcal: 717, protein: 0.9, carbs: 0.1, fat: 81, per: 100 },
    { name: 'cream cheese', kcal: 342, protein: 6, carbs: 4.1, fat: 34, per: 100 },

    // Grains & Carbs
    { name: 'rice', kcal: 130, protein: 2.7, carbs: 28, fat: 0.3, per: 100, note: 'cooked' },
    { name: 'white rice', kcal: 130, protein: 2.7, carbs: 28, fat: 0.3, per: 100, note: 'cooked' },
    { name: 'brown rice', kcal: 123, protein: 2.7, carbs: 26, fat: 1, per: 100, note: 'cooked' },
    { name: 'pasta', kcal: 131, protein: 5, carbs: 25, fat: 1.1, per: 100, note: 'cooked' },
    { name: 'spaghetti', kcal: 131, protein: 5, carbs: 25, fat: 1.1, per: 100, note: 'cooked' },
    { name: 'bread', kcal: 265, protein: 9, carbs: 49, fat: 3.2, per: 100 },
    { name: 'bread slice', kcal: 79, protein: 2.7, carbs: 15, fat: 1, per: 1, unit: 'slice (30g)' },
    { name: 'whole wheat bread', kcal: 247, protein: 13, carbs: 41, fat: 3.4, per: 100 },
    { name: 'oatmeal', kcal: 68, protein: 2.4, carbs: 12, fat: 1.4, per: 100, note: 'cooked' },
    { name: 'oats', kcal: 389, protein: 17, carbs: 66, fat: 6.9, per: 100, note: 'dry' },
    { name: 'quinoa', kcal: 120, protein: 4.4, carbs: 21, fat: 1.9, per: 100, note: 'cooked' },
    { name: 'tortilla', kcal: 218, protein: 5.7, carbs: 36, fat: 5.3, per: 1, unit: 'tortilla (64g)' },
    { name: 'bagel', kcal: 270, protein: 10, carbs: 53, fat: 1.6, per: 1, unit: 'bagel (105g)' },
    { name: 'croissant', kcal: 406, protein: 8.2, carbs: 45, fat: 21, per: 1, unit: 'croissant (67g)' },
    { name: 'potato', kcal: 77, protein: 2, carbs: 17, fat: 0.1, per: 100 },
    { name: 'sweet potato', kcal: 86, protein: 1.6, carbs: 20, fat: 0.1, per: 100 },

    // Fruits
    { name: 'banana', kcal: 89, protein: 1.1, carbs: 23, fat: 0.3, per: 1, unit: 'banana (118g)' },
    { name: 'apple', kcal: 52, protein: 0.3, carbs: 14, fat: 0.2, per: 1, unit: 'apple (182g)' },
    { name: 'orange', kcal: 62, protein: 1.2, carbs: 15, fat: 0.2, per: 1, unit: 'orange (131g)' },
    { name: 'strawberries', kcal: 32, protein: 0.7, carbs: 7.7, fat: 0.3, per: 100 },
    { name: 'blueberries', kcal: 57, protein: 0.7, carbs: 14, fat: 0.3, per: 100 },
    { name: 'grapes', kcal: 69, protein: 0.7, carbs: 18, fat: 0.2, per: 100 },
    { name: 'mango', kcal: 60, protein: 0.8, carbs: 15, fat: 0.4, per: 100 },
    { name: 'avocado', kcal: 160, protein: 2, carbs: 8.5, fat: 15, per: 1, unit: 'half avocado (100g)' },
    { name: 'pineapple', kcal: 50, protein: 0.5, carbs: 13, fat: 0.1, per: 100 },

    // Vegetables
    { name: 'broccoli', kcal: 34, protein: 2.8, carbs: 7, fat: 0.4, per: 100 },
    { name: 'spinach', kcal: 23, protein: 2.9, carbs: 3.6, fat: 0.4, per: 100 },
    { name: 'kale', kcal: 49, protein: 4.3, carbs: 9, fat: 0.9, per: 100 },
    { name: 'tomato', kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2, per: 100 },
    { name: 'cucumber', kcal: 16, protein: 0.7, carbs: 3.6, fat: 0.1, per: 100 },
    { name: 'carrot', kcal: 41, protein: 0.9, carbs: 10, fat: 0.2, per: 100 },
    { name: 'bell pepper', kcal: 31, protein: 1, carbs: 6, fat: 0.3, per: 100 },
    { name: 'onion', kcal: 40, protein: 1.1, carbs: 9.3, fat: 0.1, per: 100 },
    { name: 'mushroom', kcal: 22, protein: 3.1, carbs: 3.3, fat: 0.3, per: 100 },
    { name: 'mushrooms', kcal: 22, protein: 3.1, carbs: 3.3, fat: 0.3, per: 100 },
    { name: 'zucchini', kcal: 17, protein: 1.2, carbs: 3.1, fat: 0.3, per: 100 },
    { name: 'green beans', kcal: 31, protein: 1.8, carbs: 7, fat: 0.1, per: 100 },
    { name: 'corn', kcal: 86, protein: 3.3, carbs: 19, fat: 1.4, per: 100 },
    { name: 'salad', kcal: 15, protein: 1.3, carbs: 2.5, fat: 0.2, per: 100, note: 'mixed greens' },

    // Legumes
    { name: 'lentils', kcal: 116, protein: 9, carbs: 20, fat: 0.4, per: 100, note: 'cooked' },
    { name: 'chickpeas', kcal: 164, protein: 8.9, carbs: 27, fat: 2.6, per: 100, note: 'cooked' },
    { name: 'black beans', kcal: 132, protein: 8.9, carbs: 24, fat: 0.5, per: 100, note: 'cooked' },
    { name: 'kidney beans', kcal: 127, protein: 8.7, carbs: 23, fat: 0.5, per: 100, note: 'cooked' },
    { name: 'edamame', kcal: 121, protein: 12, carbs: 9, fat: 5.2, per: 100 },
    { name: 'hummus', kcal: 166, protein: 7.9, carbs: 14, fat: 9.6, per: 100 },

    // Nuts & Seeds
    { name: 'almonds', kcal: 579, protein: 21, carbs: 22, fat: 50, per: 100 },
    { name: 'walnuts', kcal: 654, protein: 15, carbs: 14, fat: 65, per: 100 },
    { name: 'peanuts', kcal: 567, protein: 26, carbs: 16, fat: 49, per: 100 },
    { name: 'peanut butter', kcal: 588, protein: 25, carbs: 20, fat: 50, per: 100 },
    { name: 'almond butter', kcal: 614, protein: 21, carbs: 19, fat: 56, per: 100 },
    { name: 'cashews', kcal: 553, protein: 18, carbs: 30, fat: 44, per: 100 },
    { name: 'chia seeds', kcal: 486, protein: 17, carbs: 42, fat: 31, per: 100 },
    { name: 'flax seeds', kcal: 534, protein: 18, carbs: 29, fat: 42, per: 100 },
    { name: 'sunflower seeds', kcal: 584, protein: 21, carbs: 20, fat: 51, per: 100 },

    // Oils & Fats
    { name: 'olive oil', kcal: 119, protein: 0, carbs: 0, fat: 13.5, per: 1, unit: 'tbsp (15ml)' },
    { name: 'coconut oil', kcal: 121, protein: 0, carbs: 0, fat: 13.5, per: 1, unit: 'tbsp (15ml)' },

    // Drinks & Supplements
    { name: 'protein shake', kcal: 150, protein: 30, carbs: 5, fat: 2, per: 1, unit: 'shake' },
    { name: 'protein powder', kcal: 120, protein: 24, carbs: 3, fat: 1.5, per: 1, unit: 'scoop (30g)' },
    { name: 'whey protein', kcal: 120, protein: 24, carbs: 3, fat: 1.5, per: 1, unit: 'scoop (30g)' },
    { name: 'orange juice', kcal: 45, protein: 0.7, carbs: 10, fat: 0.2, per: 100 },
    { name: 'coffee', kcal: 2, protein: 0.3, carbs: 0, fat: 0, per: 1, unit: 'cup (240ml)' },
    { name: 'coffee with milk', kcal: 30, protein: 1.5, carbs: 2.5, fat: 1.2, per: 1, unit: 'cup' },
    { name: 'latte', kcal: 150, protein: 8, carbs: 13, fat: 6, per: 1, unit: 'large (360ml)' },
    { name: 'cappuccino', kcal: 80, protein: 4, carbs: 6, fat: 4, per: 1, unit: 'cup (240ml)' },

    // Snacks & Other
    { name: 'dark chocolate', kcal: 546, protein: 5, carbs: 60, fat: 31, per: 100 },
    { name: 'rice cake', kcal: 35, protein: 0.7, carbs: 7.3, fat: 0.3, per: 1, unit: 'cake (9g)' },
    { name: 'granola bar', kcal: 190, protein: 4, carbs: 29, fat: 7, per: 1, unit: 'bar (40g)' },
    { name: 'protein bar', kcal: 220, protein: 20, carbs: 22, fat: 8, per: 1, unit: 'bar (60g)' },
    { name: 'trail mix', kcal: 462, protein: 14, carbs: 44, fat: 29, per: 100 },
    { name: 'popcorn', kcal: 375, protein: 11, carbs: 74, fat: 4.3, per: 100, note: 'air-popped' },
    { name: 'chips', kcal: 536, protein: 7, carbs: 53, fat: 35, per: 100 },
    { name: 'crackers', kcal: 421, protein: 10, carbs: 72, fat: 10, per: 100 },

    // Common meals (rough estimates)
    { name: 'pizza slice', kcal: 266, protein: 11, carbs: 33, fat: 10, per: 1, unit: 'slice' },
    { name: 'burger', kcal: 540, protein: 34, carbs: 40, fat: 27, per: 1, unit: 'burger' },
    { name: 'sandwich', kcal: 350, protein: 18, carbs: 38, fat: 13, per: 1, unit: 'sandwich' },
    { name: 'salad bowl', kcal: 250, protein: 12, carbs: 20, fat: 14, per: 1, unit: 'bowl' },
    { name: 'sushi roll', kcal: 255, protein: 9, carbs: 38, fat: 7, per: 1, unit: 'roll (6-8 pcs)' },
    { name: 'burrito', kcal: 580, protein: 28, carbs: 60, fat: 22, per: 1, unit: 'burrito' },
    { name: 'wrap', kcal: 410, protein: 22, carbs: 42, fat: 16, per: 1, unit: 'wrap' },
    { name: 'soup', kcal: 80, protein: 4, carbs: 12, fat: 2, per: 100 },
  ],

  // ── Search & Match ──

  /**
   * Find the best matching food from a text query.
   * Returns { food, quantity, totalMacros } or null.
   */
  lookup(query) {
    query = query.trim().toLowerCase();
    if (!query) return null;

    // Extract quantity and unit from the query
    const { quantity, unit, foodText } = this.parseQuantity(query);

    // Find best matching food
    const match = this.findFood(foodText);
    if (!match) return null;

    // Calculate macros based on quantity
    const multiplier = this.calculateMultiplier(match, quantity, unit);

    return {
      food: match,
      quantity,
      unit,
      multiplier,
      result: {
        name: this.formatName(match, quantity, unit),
        kcal: round(match.kcal * multiplier),
        protein: round(match.protein * multiplier),
        carbs: round(match.carbs * multiplier),
        fat: round(match.fat * multiplier),
        serving: this.formatServing(match, quantity, unit)
      }
    };
  },

  /**
   * Parse quantity and unit from user input.
   * Supports: "150g chicken", "chicken 150g", "2 eggs", "chicken breast", "3 slices bread"
   */
  parseQuantity(text) {
    let quantity = null;
    let unit = null;
    let foodText = text;

    // Pattern: number + unit at start or end
    // e.g. "150g chicken breast" or "chicken breast 150g"
    const qtyPatterns = [
      // "150g", "200ml", "2.5kg"
      /(\d+(?:\.\d+)?)\s*(g|kg|ml|l|oz)\b/i,
      // "2 cups", "1 tbsp", "3 slices", "2 pieces", "1 scoop"
      /(\d+(?:\.\d+)?)\s*(cups?|tbsp|tsp|tablespoons?|teaspoons?|slices?|pieces?|pcs?|scoops?|servings?|portions?|handfuls?)\b/i,
      // bare number: "2 eggs", "3 bananas"
      /^(\d+(?:\.\d+)?)\s+/,
      // number at end: "eggs 2"
      /\s+(\d+(?:\.\d+)?)$/,
    ];

    for (const pattern of qtyPatterns) {
      const match = text.match(pattern);
      if (match) {
        quantity = parseFloat(match[1]);
        unit = match[2] ? match[2].toLowerCase().replace(/s$/, '') : null;
        foodText = text.replace(match[0], '').trim();
        break;
      }
    }

    // Clean up food text
    foodText = foodText.replace(/^(of|with)\s+/i, '').trim();
    if (!foodText) foodText = text.replace(/[\d.]+\s*(g|kg|ml|l|oz)?\s*/i, '').trim();

    return { quantity, unit, foodText };
  },

  /**
   * Find the best matching food entry using fuzzy matching.
   */
  findFood(text) {
    text = text.toLowerCase().trim();
    if (!text) return null;

    // Exact match
    let match = this.foods.find(f => f.name === text);
    if (match) return match;

    // Starts-with match
    match = this.foods.find(f => f.name.startsWith(text) || text.startsWith(f.name));
    if (match) return match;

    // Contains match (prefer shorter names = more specific)
    const containsMatches = this.foods
      .filter(f => f.name.includes(text) || text.includes(f.name))
      .sort((a, b) => {
        // Prefer the one where the match is tighter
        const aDist = Math.abs(a.name.length - text.length);
        const bDist = Math.abs(b.name.length - text.length);
        return aDist - bDist;
      });
    if (containsMatches.length > 0) return containsMatches[0];

    // Word overlap scoring
    const queryWords = text.split(/\s+/);
    let bestScore = 0;
    let bestMatch = null;

    for (const food of this.foods) {
      const foodWords = food.name.split(/\s+/);
      let score = 0;
      for (const qw of queryWords) {
        for (const fw of foodWords) {
          if (fw === qw) score += 3;
          else if (fw.startsWith(qw) || qw.startsWith(fw)) score += 2;
          else if (fw.includes(qw) || qw.includes(fw)) score += 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = food;
      }
    }

    return bestScore >= 2 ? bestMatch : null;
  },

  /**
   * Calculate the multiplier for macros based on quantity and the food's base unit.
   */
  calculateMultiplier(food, quantity, unit) {
    // If food is per-unit (e.g. 1 egg, 1 banana)
    if (food.per === 1 && food.unit) {
      // User gave a count (e.g. "2 eggs")
      if (quantity && (!unit || unit === 'piece' || unit === 'pc' || unit === 'serving' || unit === 'scoop' || unit === 'slice' || unit === 'cup')) {
        return quantity;
      }
      // User gave grams - we need to estimate from unit description
      if (quantity && (unit === 'g' || unit === 'kg' || unit === 'oz')) {
        const grams = this.toGrams(quantity, unit);
        // Try to extract weight from unit description e.g. "egg (50g)"
        const weightMatch = food.unit && food.unit.match(/(\d+)g/);
        if (weightMatch) {
          return grams / parseFloat(weightMatch[1]);
        }
        return grams / 100; // fallback
      }
      // No quantity given = 1 unit
      return quantity || 1;
    }

    // Food is per 100g
    if (quantity) {
      if (!unit || unit === 'g') return quantity / 100;
      if (unit === 'kg') return (quantity * 1000) / 100;
      if (unit === 'oz') return (quantity * 28.35) / 100;
      if (unit === 'cup') return (quantity * 200) / 100; // rough estimate
      if (unit === 'tbsp' || unit === 'tablespoon') return (quantity * 15) / 100;
      if (unit === 'tsp' || unit === 'teaspoon') return (quantity * 5) / 100;
      if (unit === 'serving' || unit === 'portion') return quantity; // 1 serving ≈ 100g
      if (unit === 'handful') return (quantity * 30) / 100;
      if (unit === 'slice') return (quantity * 30) / 100;
      if (unit === 'piece') return quantity; // 1 piece ≈ 100g
      // Bare number for per-100g foods: treat as grams
      return quantity / 100;
    }

    // No quantity: default serving of 100g
    return 1;
  },

  toGrams(qty, unit) {
    if (!unit || unit === 'g') return qty;
    if (unit === 'kg') return qty * 1000;
    if (unit === 'oz') return qty * 28.35;
    if (unit === 'l') return qty * 1000;
    if (unit === 'ml') return qty;
    return qty;
  },

  formatName(food, quantity, unit) {
    if (food.per === 1 && food.unit) {
      const qty = quantity || 1;
      return qty === 1 ? food.name : `${food.name} x${qty}`;
    }
    if (quantity && unit) {
      return `${food.name} (${quantity}${unit})`;
    }
    if (quantity) {
      return `${food.name} (${quantity}g)`;
    }
    return `${food.name} (100g)`;
  },

  formatServing(food, quantity, unit) {
    if (food.per === 1 && food.unit) {
      const qty = quantity || 1;
      return `${qty} ${food.unit}`;
    }
    if (quantity && unit) {
      return `${quantity}${unit}`;
    }
    if (quantity) {
      return `${quantity}g`;
    }
    return food.note ? `100g (${food.note})` : '100g';
  },

  /**
   * Get autocomplete suggestions for a partial query.
   */
  suggest(partial, limit = 8) {
    partial = partial.toLowerCase().trim();
    if (!partial) return [];

    const { foodText } = this.parseQuantity(partial);
    const search = foodText || partial;

    const scored = this.foods.map(f => {
      let score = 0;
      if (f.name === search) score = 100;
      else if (f.name.startsWith(search)) score = 80;
      else if (f.name.includes(search)) score = 60;
      else {
        const words = search.split(/\s+/);
        for (const w of words) {
          if (f.name.includes(w)) score += 20;
        }
      }
      return { food: f, score };
    });

    return scored
      .filter(s => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map(s => s.food);
  }
};

function round(n) {
  return Math.round(n * 10) / 10;
}
