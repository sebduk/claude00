/**
 * ChatGPT conversation and structured data parser.
 * Supports multiple import formats:
 * 1. JSON array of food entries
 * 2. Structured text lines (meal: food - macros)
 * 3. Free-form ChatGPT conversation text
 */

const ImportParser = {
  // Main parse function - auto-detects format
  parse(text) {
    text = text.trim();
    if (!text) return [];

    // Try JSON first
    const jsonResult = this.tryParseJSON(text);
    if (jsonResult.length > 0) return jsonResult;

    // Try structured text format
    const structuredResult = this.parseStructuredText(text);
    if (structuredResult.length > 0) return structuredResult;

    // Fall back to free-form ChatGPT conversation parsing
    return this.parseFreeForm(text);
  },

  // Try to parse as JSON
  tryParseJSON(text) {
    try {
      // Find JSON array in text
      const jsonMatch = text.match(/\[[\s\S]*?\]/);
      if (!jsonMatch) return [];

      const data = JSON.parse(jsonMatch[0]);
      if (!Array.isArray(data)) return [];

      return data
        .filter(item => item.name || item.food || item.meal)
        .map(item => ({
          name: item.name || item.food || item.meal || 'Unknown',
          kcal: Number(item.kcal || item.calories || item.cal || 0),
          protein: Number(item.protein || item.prot || 0),
          carbs: Number(item.carbs || item.carbohydrates || item.carb || 0),
          fat: Number(item.fat || item.fats || 0),
          serving: item.serving || item.portion || ''
        }));
    } catch {
      return [];
    }
  },

  // Parse structured text format
  // Supports: "Meal: Food - 300 kcal, 30g protein, 40g carbs, 10g fat"
  parseStructuredText(text) {
    const lines = text.split('\n').filter(line => line.trim());
    const entries = [];

    for (const line of lines) {
      const entry = this.parseNutritionLine(line);
      if (entry) {
        entries.push(entry);
      }
    }

    return entries;
  },

  // Parse a single line with nutrition info
  parseNutritionLine(line) {
    // Extract food name - everything before the first number or dash separator
    let name = '';
    let rest = line;

    // Try "Label: Food - macros" format
    const labelMatch = line.match(/^(?:breakfast|lunch|dinner|snack|meal\s*\d*|pre[- ]?workout|post[- ]?workout)\s*[:]\s*/i);
    if (labelMatch) {
      rest = line.slice(labelMatch[0].length);
    }

    // Try "Food - macros" or "Food: macros" format
    const separatorMatch = rest.match(/^(.+?)(?:\s*[-:]\s*|\s+)(\d+)/);
    if (separatorMatch) {
      name = separatorMatch[1].trim();
      rest = rest.slice(rest.indexOf(separatorMatch[2]));
    }

    // Extract macros using flexible patterns
    const kcalMatch = rest.match(/(\d+(?:\.\d+)?)\s*(?:kcal|cal|calories)/i);
    const proteinMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:protein|prot|p\b)/i);
    const carbsMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:carbs?|carbohydrates?|c\b)/i);
    const fatMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:fat|fats?|f\b)/i);

    // Must have at least calories to count as a valid entry
    if (!kcalMatch && !proteinMatch) return null;

    if (!name) {
      // Try to extract name from the beginning of the line
      name = line.split(/\d/)[0].replace(/[-:,]\s*$/, '').trim() || 'Imported food';
    }

    return {
      name: name,
      kcal: kcalMatch ? Number(kcalMatch[1]) : 0,
      protein: proteinMatch ? Number(proteinMatch[1]) : 0,
      carbs: carbsMatch ? Number(carbsMatch[1]) : 0,
      fat: fatMatch ? Number(fatMatch[1]) : 0,
      serving: ''
    };
  },

  // Parse free-form ChatGPT conversation
  parseFreeForm(text) {
    const entries = [];
    const lines = text.split('\n');

    // Look for lines containing calorie/macro information
    for (const line of lines) {
      // Skip very short lines and common ChatGPT prefixes
      const cleanLine = line.replace(/^(User|Assistant|ChatGPT|You|AI):\s*/i, '').trim();
      if (cleanLine.length < 5) continue;

      // Check if line contains calorie info
      if (/\d+\s*(?:kcal|cal|calories)/i.test(cleanLine) ||
          (/protein/i.test(cleanLine) && /\d+/i.test(cleanLine))) {
        const entry = this.parseNutritionLine(cleanLine);
        if (entry && (entry.kcal > 0 || entry.protein > 0)) {
          entries.push(entry);
        }
      }
    }

    // Deduplicate by name
    const seen = new Set();
    return entries.filter(e => {
      const key = e.name.toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }
};
