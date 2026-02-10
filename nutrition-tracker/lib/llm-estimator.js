/**
 * LLM-powered food estimation.
 * Uses Google Gemini Flash (free tier) to estimate macros from natural language.
 * Falls back gracefully if no API key is configured.
 */

const LLMEstimator = {
  // Supported providers
  PROVIDERS: {
    GEMINI: 'gemini',
    OPENAI: 'openai',
    ANTHROPIC: 'anthropic'
  },

  /**
   * Estimate macros for a food description using an LLM.
   * Returns { name, kcal, protein, carbs, fat, serving, estimated: true } or null.
   */
  async estimate(description) {
    const config = await this.getConfig();
    if (!config.apiKey || !config.provider) return null;

    try {
      switch (config.provider) {
        case this.PROVIDERS.GEMINI:
          return await this.estimateWithGemini(description, config.apiKey);
        case this.PROVIDERS.OPENAI:
          return await this.estimateWithOpenAI(description, config.apiKey, config.model);
        case this.PROVIDERS.ANTHROPIC:
          return await this.estimateWithAnthropic(description, config.apiKey, config.model);
        default:
          return null;
      }
    } catch (err) {
      console.error('LLM estimation failed:', err);
      throw err;
    }
  },

  /**
   * Check if LLM estimation is configured and available.
   */
  async isAvailable() {
    const config = await this.getConfig();
    return !!(config.apiKey && config.provider);
  },

  // ── Config ──

  async getConfig() {
    const result = await chrome.storage.local.get('llmConfig');
    return result.llmConfig || { provider: '', apiKey: '', model: '' };
  },

  async saveConfig(config) {
    await chrome.storage.local.set({ llmConfig: config });
  },

  // ── Prompt ──

  buildPrompt(description) {
    return `Estimate the nutritional macros for this food. Be concise and return ONLY a JSON object.

Food: "${description}"

Return exactly this JSON format, nothing else:
{"name":"<clean food name>","kcal":<number>,"protein":<grams>,"carbs":<grams>,"fat":<grams>,"serving":"<serving description>"}

Rules:
- Estimate based on typical homemade/standard versions if not specified
- Use reasonable portion sizes if quantity isn't explicit
- Round to nearest whole number for kcal, one decimal for grams
- For multiple items (e.g. "3 waffles"), give the TOTAL for all items
- name should be a clean readable name including quantity`;
  },

  parseResponse(text) {
    // Extract JSON from response (handle markdown code blocks, extra text, etc.)
    const jsonMatch = text.match(/\{[\s\S]*?\}/);
    if (!jsonMatch) return null;

    try {
      const data = JSON.parse(jsonMatch[0]);
      if (!data.name || data.kcal === undefined) return null;

      return {
        name: String(data.name),
        kcal: Math.round(Number(data.kcal) || 0),
        protein: Math.round((Number(data.protein) || 0) * 10) / 10,
        carbs: Math.round((Number(data.carbs) || 0) * 10) / 10,
        fat: Math.round((Number(data.fat) || 0) * 10) / 10,
        serving: String(data.serving || ''),
        estimated: true
      };
    } catch {
      return null;
    }
  },

  // ── Gemini ──

  async estimateWithGemini(description, apiKey) {
    const config = await this.getConfig();
    const model = config.model || 'gemini-2.0-flash-lite';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: this.buildPrompt(description) }]
        }],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 200
        }
      })
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Gemini API error (${response.status}): ${err}`);
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error('Empty response from Gemini');

    return this.parseResponse(text);
  },

  // ── OpenAI ──

  async estimateWithOpenAI(description, apiKey, model) {
    const url = 'https://api.openai.com/v1/chat/completions';

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: model || 'gpt-4o-mini',
        messages: [
          { role: 'user', content: this.buildPrompt(description) }
        ],
        temperature: 0.1,
        max_tokens: 200
      })
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`OpenAI API error (${response.status}): ${err}`);
    }

    const data = await response.json();
    const text = data.choices?.[0]?.message?.content;
    if (!text) throw new Error('Empty response from OpenAI');

    return this.parseResponse(text);
  },

  // ── Anthropic ──

  async estimateWithAnthropic(description, apiKey, model) {
    const url = 'https://api.anthropic.com/v1/messages';

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true'
      },
      body: JSON.stringify({
        model: model || 'claude-haiku-4-5-20251001',
        max_tokens: 200,
        messages: [
          { role: 'user', content: this.buildPrompt(description) }
        ]
      })
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Anthropic API error (${response.status}): ${err}`);
    }

    const data = await response.json();
    const text = data.content?.[0]?.text;
    if (!text) throw new Error('Empty response from Anthropic');

    return this.parseResponse(text);
  }
};
