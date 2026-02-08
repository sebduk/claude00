/**
 * Import parser supporting multiple formats:
 * 1. Export JSON format (multi-day with foods + exercises)
 * 2. JSON array of food entries
 * 3. Structured text with optional date headers, times, and exercises
 * 4. Free-form ChatGPT/Gemini conversation text
 *
 * Always returns: { days: { "YYYY-MM-DD": { foods: [], exercises: [] }, ... } }
 * When no date is detected, entries go under the "_default" key.
 */

const ImportParser = {
  // Main parse function - auto-detects format
  parse(text) {
    text = text.trim();
    if (!text) return { days: {} };

    // Try export JSON format first (multi-day with day_ keys)
    const exportResult = this.tryParseExportJSON(text);
    if (exportResult) return exportResult;

    // Try JSON array format
    const jsonResult = this.tryParseJSONArray(text);
    if (jsonResult) return jsonResult;

    // Parse as text (structured, free-form, with date/time/exercise support)
    return this.parseText(text);
  },

  // ── Export JSON format ──
  // { "day_2026-02-07": { foods: [...], exercises: [...], date: "..." }, "targets": {...}, ... }
  tryParseExportJSON(text) {
    try {
      const data = JSON.parse(text);
      if (typeof data !== 'object' || Array.isArray(data)) return null;

      const days = {};
      let found = false;

      for (const [key, value] of Object.entries(data)) {
        const dateMatch = key.match(/^day_(\d{4}-\d{2}-\d{2})$/);
        if (!dateMatch || !value || typeof value !== 'object') continue;

        const dateStr = dateMatch[1];
        const dayData = { foods: [], exercises: [] };

        if (Array.isArray(value.foods)) {
          dayData.foods = value.foods.map(f => ({
            name: f.name || 'Unknown',
            kcal: Number(f.kcal || f.calories || 0),
            protein: Number(f.protein || 0),
            carbs: Number(f.carbs || 0),
            fat: Number(f.fat || 0),
            serving: f.serving || '',
            timestamp: f.timestamp || ''
          }));
        }

        if (Array.isArray(value.exercises)) {
          dayData.exercises = value.exercises.map(e => ({
            name: e.name || 'Unknown',
            duration: Number(e.duration || 0),
            calories: Number(e.calories || 0),
            notes: e.notes || '',
            timestamp: e.timestamp || ''
          }));
        }

        if (dayData.foods.length > 0 || dayData.exercises.length > 0) {
          days[dateStr] = dayData;
          found = true;
        }
      }

      return found ? { days } : null;
    } catch {
      return null;
    }
  },

  // ── JSON array format ──
  // [{ name, kcal, protein, carbs, fat }]
  tryParseJSONArray(text) {
    try {
      const jsonMatch = text.match(/\[[\s\S]*\]/);
      if (!jsonMatch) return null;

      const data = JSON.parse(jsonMatch[0]);
      if (!Array.isArray(data)) return null;

      const foods = data
        .filter(item => item.name || item.food || item.meal)
        .map(item => ({
          name: item.name || item.food || item.meal || 'Unknown',
          kcal: Number(item.kcal || item.calories || item.cal || 0),
          protein: Number(item.protein || item.prot || 0),
          carbs: Number(item.carbs || item.carbohydrates || item.carb || 0),
          fat: Number(item.fat || item.fats || 0),
          serving: item.serving || item.portion || '',
          timestamp: item.timestamp || item.time || ''
        }));

      if (foods.length === 0) return null;
      return { days: { _default: { foods, exercises: [] } } };
    } catch {
      return null;
    }
  },

  // ── Text parsing (structured + free-form, with dates, times, exercises) ──
  parseText(text) {
    const lines = text.split('\n');
    const days = {};
    let currentDate = '_default';

    for (const rawLine of lines) {
      // Strip chat prefixes
      let line = rawLine.replace(/^(User|Assistant|ChatGPT|You|AI|Human)\s*:\s*/i, '').trim();
      if (!line || line.length < 3) continue;

      // Check for date header
      const dateStr = this.parseDateHeader(line);
      if (dateStr) {
        currentDate = dateStr;
        continue;
      }

      // Strip list markers (bullets, numbers) but not date-like patterns
      line = line.replace(/^[-*•]\s+/, '').replace(/^\d+[.)]\s+/, '');

      // Initialize day bucket
      if (!days[currentDate]) days[currentDate] = { foods: [], exercises: [] };

      // Try exercise first
      const exercise = this.parseExerciseLine(line);
      if (exercise) {
        days[currentDate].exercises.push(exercise);
        continue;
      }

      // Try food
      const food = this.parseFoodLine(line);
      if (food) {
        days[currentDate].foods.push(food);
      }
    }

    // Remove empty day buckets
    for (const key of Object.keys(days)) {
      if (days[key].foods.length === 0 && days[key].exercises.length === 0) {
        delete days[key];
      }
    }

    return { days };
  },

  // ── Date header detection ──
  // Returns YYYY-MM-DD string or null
  parseDateHeader(line) {
    // Clean markdown/separator formatting
    let clean = line
      .replace(/^#+\s*/, '')
      .replace(/[*_`]/g, '')
      .replace(/^[-–—\s]+|[-–—\s]+$/g, '')
      .trim();

    // Remove "Date:" prefix
    clean = clean.replace(/^date\s*:\s*/i, '');

    // Must look like a date line (not a food/exercise entry with numbers everywhere)
    // Date-only lines shouldn't have calorie/macro data
    if (/\d+\s*(?:kcal|cal|calories|protein|carbs|fat)/i.test(clean)) return null;

    // ISO date: 2026-02-07
    const isoMatch = clean.match(/^(\d{4}-\d{2}-\d{2})\s*[:.]?\s*$/);
    if (isoMatch) return isoMatch[1];

    // Full month name: "February 7, 2026" or "February 7"
    const fullMonthMatch = clean.match(
      /^((?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(?:,?\s*\d{4})?)\s*[:.]?\s*$/i
    );
    if (fullMonthMatch) return this._tryParseDate(fullMonthMatch[1]);

    // Abbreviated month: "Feb 7, 2026" or "Feb 7"
    const shortMonthMatch = clean.match(
      /^((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}(?:,?\s*\d{4})?)\s*[:.]?\s*$/i
    );
    if (shortMonthMatch) return this._tryParseDate(shortMonthMatch[1]);

    // US slash format: 2/7/2026 or 2/7
    const slashMatch = clean.match(/^(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?\s*[:.]?\s*$/);
    if (slashMatch) {
      const month = parseInt(slashMatch[1]) - 1;
      const day = parseInt(slashMatch[2]);
      let year = new Date().getFullYear();
      if (slashMatch[3]) {
        year = slashMatch[3].length === 2 ? 2000 + parseInt(slashMatch[3]) : parseInt(slashMatch[3]);
      }
      const d = new Date(year, month, day);
      if (!isNaN(d.getTime())) return this._formatDate(d);
    }

    return null;
  },

  _tryParseDate(str) {
    let d = new Date(str);
    if (!isNaN(d.getTime())) return this._formatDate(d);
    // Try adding current year
    d = new Date(str + ', ' + new Date().getFullYear());
    if (!isNaN(d.getTime())) return this._formatDate(d);
    return null;
  },

  _formatDate(d) {
    return d.toISOString().split('T')[0];
  },

  // ── Exercise line detection ──
  parseExerciseLine(line) {
    let time = '';
    let rest = line;

    // Time prefix: "14:30 - Running..." or "14:30 Running..."
    const timeMatch = line.match(/^(\d{1,2}:\d{2})\s*[-–]?\s*/);
    if (timeMatch) {
      time = timeMatch[1];
      rest = line.slice(timeMatch[0].length);
    }

    // Must contain exercise indicators
    const isExercise =
      /^exercise\s*:/i.test(rest) ||
      /\bburned\b/i.test(rest) ||
      /\b(?:workout|training|run(?:ning)?|walk(?:ing)?|swim(?:ming)?|cycling|biking|hiit|yoga|gym|cardio)\b.*\d+\s*min/i.test(rest);
    if (!isExercise) return null;

    // Remove "Exercise:" prefix
    rest = rest.replace(/^exercise\s*:\s*/i, '');

    // Extract name (before first dash separator or numbers with "min")
    let name = rest.split(/\s*[-–]\s*/)[0].replace(/\(exercise\)/i, '').trim();

    // Extract duration
    const durMatch = rest.match(/(\d+)\s*min/i);
    const duration = durMatch ? Number(durMatch[1]) : 0;

    // Extract calories
    const calMatch = rest.match(/(\d+)\s*(?:kcal|cal|calories)/i);
    const calories = calMatch ? Number(calMatch[1]) : 0;

    // Extract notes
    const notesMatch = rest.match(/notes?\s*:\s*(.+)/i);
    const notes = notesMatch ? notesMatch[1].trim() : '';

    if (!name || (!duration && !calories)) return null;

    const exercise = { name, duration, calories, notes };
    if (time) exercise.timeHint = time;
    return exercise;
  },

  // ── Food line parsing ──
  parseFoodLine(line) {
    let time = '';
    let rest = line;

    // Time prefix: "12:30 - Lunch: ..." or "12:30 Oatmeal ..."
    const timeMatch = line.match(/^(\d{1,2}:\d{2})\s*[-–]?\s*/);
    if (timeMatch) {
      time = timeMatch[1];
      rest = line.slice(timeMatch[0].length);
    }

    // Remove meal label prefixes
    rest = rest.replace(
      /^(?:breakfast|lunch|dinner|snack|meal\s*\d*|brunch|supper|pre[- ]?workout|post[- ]?workout)\s*[:]\s*/i, ''
    );

    const food = this.parseNutritionLine(rest);
    if (!food) return null;

    if (time) food.timeHint = time;
    return food;
  },

  // Parse a single line with nutrition info
  parseNutritionLine(line) {
    let name = '';
    let rest = line;

    // Try "Food - macros" or "Food: macros" format
    const separatorMatch = rest.match(/^(.+?)(?:\s*[-–:]\s*|\s+)(\d)/);
    if (separatorMatch) {
      name = separatorMatch[1].trim();
      rest = rest.slice(rest.indexOf(separatorMatch[2]));
    }

    // Extract macros using flexible patterns
    const kcalMatch = rest.match(/(\d+(?:\.\d+)?)\s*(?:kcal|cal|calories)/i);
    const proteinMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:protein|prot|p\b)/i);
    const carbsMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:carbs?|carbohydrates?|c\b)/i);
    const fatMatch = rest.match(/(\d+(?:\.\d+)?)\s*g?\s*(?:fat|fats?|f\b)/i);

    // Must have at least calories or protein to count as a valid entry
    if (!kcalMatch && !proteinMatch) return null;

    if (!name) {
      name = line.split(/\d/)[0].replace(/[-–:,]\s*$/, '').trim() || 'Imported food';
    }

    return {
      name,
      kcal: kcalMatch ? Number(kcalMatch[1]) : 0,
      protein: proteinMatch ? Number(proteinMatch[1]) : 0,
      carbs: carbsMatch ? Number(carbsMatch[1]) : 0,
      fat: fatMatch ? Number(fatMatch[1]) : 0,
      serving: ''
    };
  }
};
