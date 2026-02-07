/**
 * Options page controller.
 * Handles target settings, LLM config, and data management.
 */

(async function() {
  'use strict';

  // ── Targets ──

  const result = await chrome.storage.local.get('targets');
  const targets = result.targets || { kcal: 2000, protein: 150, carbs: 250, fat: 65 };

  document.getElementById('target-kcal').value = targets.kcal;
  document.getElementById('target-protein').value = targets.protein;
  document.getElementById('target-carbs').value = targets.carbs;
  document.getElementById('target-fat').value = targets.fat;

  document.getElementById('targets-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const newTargets = {
      kcal: Number(document.getElementById('target-kcal').value),
      protein: Number(document.getElementById('target-protein').value),
      carbs: Number(document.getElementById('target-carbs').value),
      fat: Number(document.getElementById('target-fat').value)
    };
    await chrome.storage.local.set({ targets: newTargets });
    showToast('Targets saved');
  });

  // ── LLM Config ──

  const HELP_TEXT = {
    gemini: 'Get a free API key from <a href="https://aistudio.google.com/apikey" target="_blank">Google AI Studio</a>. The free tier gives you 15 requests/minute - more than enough for food tracking.',
    openai: 'Get an API key from <a href="https://platform.openai.com/api-keys" target="_blank">OpenAI Platform</a>. Uses GPT-4o-mini by default (~$0.15/M tokens).',
    anthropic: 'Get an API key from <a href="https://console.anthropic.com/" target="_blank">Anthropic Console</a>. Uses Claude Haiku by default (~$0.25/M tokens).'
  };

  const llmResult = await chrome.storage.local.get('llmConfig');
  const llmConfig = llmResult.llmConfig || { provider: '', apiKey: '', model: '' };

  const providerSelect = document.getElementById('llm-provider');
  const keySection = document.getElementById('llm-key-section');
  const helpText = document.getElementById('llm-help');
  const modelGroup = document.getElementById('llm-model-group');
  const apiKeyInput = document.getElementById('llm-api-key');
  const modelInput = document.getElementById('llm-model');

  // Load saved config
  providerSelect.value = llmConfig.provider || '';
  apiKeyInput.value = llmConfig.apiKey || '';
  modelInput.value = llmConfig.model || '';
  updateProviderUI();

  providerSelect.addEventListener('change', updateProviderUI);

  function updateProviderUI() {
    const provider = providerSelect.value;
    if (provider) {
      keySection.classList.remove('hidden');
      helpText.innerHTML = HELP_TEXT[provider] || '';
      // Show model override for openai/anthropic
      modelGroup.style.display = (provider === 'openai' || provider === 'anthropic') ? 'block' : 'none';
    } else {
      keySection.classList.add('hidden');
    }
  }

  // Test connection
  document.getElementById('llm-test').addEventListener('click', async () => {
    const provider = providerSelect.value;
    const apiKey = apiKeyInput.value.trim();
    const resultEl = document.getElementById('llm-test-result');

    if (!provider || !apiKey) {
      resultEl.textContent = 'Select a provider and enter an API key first.';
      resultEl.className = 'help-text error';
      return;
    }

    resultEl.textContent = 'Testing...';
    resultEl.className = 'help-text';

    try {
      // Save config temporarily to test
      await chrome.storage.local.set({
        llmConfig: { provider, apiKey, model: modelInput.value.trim() }
      });

      // Make a test estimation call
      const testResult = await testLLMConnection(provider, apiKey, modelInput.value.trim());

      if (testResult) {
        resultEl.innerHTML = `Connected! Test: "1 banana" = ${testResult.kcal} kcal, ${testResult.protein}g protein, ${testResult.carbs}g carbs, ${testResult.fat}g fat`;
        resultEl.className = 'help-text success';
      } else {
        resultEl.textContent = 'Connection succeeded but response could not be parsed.';
        resultEl.className = 'help-text error';
      }
    } catch (err) {
      resultEl.textContent = `Error: ${err.message}`;
      resultEl.className = 'help-text error';
    }
  });

  async function testLLMConnection(provider, apiKey, model) {
    const prompt = 'Estimate the nutritional macros for this food. Return ONLY a JSON object.\n\nFood: "1 banana"\n\nReturn exactly this JSON format, nothing else:\n{"name":"banana","kcal":89,"protein":1.1,"carbs":23,"fat":0.3,"serving":"1 medium banana"}';

    if (provider === 'gemini') {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 200 }
        })
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data = await res.json();
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
      return parseJSON(text);
    }

    if (provider === 'openai') {
      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
        body: JSON.stringify({
          model: model || 'gpt-4o-mini',
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.1, max_tokens: 200
        })
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data = await res.json();
      const text = data.choices?.[0]?.message?.content || '';
      return parseJSON(text);
    }

    if (provider === 'anthropic') {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
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
          messages: [{ role: 'user', content: prompt }]
        })
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data = await res.json();
      const text = data.content?.[0]?.text || '';
      return parseJSON(text);
    }
  }

  function parseJSON(text) {
    const match = text.match(/\{[\s\S]*?\}/);
    if (!match) return null;
    try {
      const data = JSON.parse(match[0]);
      return data.kcal !== undefined ? data : null;
    } catch { return null; }
  }

  // Save LLM config
  document.getElementById('llm-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const config = {
      provider: providerSelect.value,
      apiKey: apiKeyInput.value.trim(),
      model: modelInput.value.trim()
    };
    await chrome.storage.local.set({ llmConfig: config });
    showToast(config.provider ? 'AI estimation enabled' : 'AI estimation disabled');
  });

  // ── Data Management ──

  document.getElementById('export-data').addEventListener('click', async () => {
    const allData = await chrome.storage.local.get(null);
    // Don't export API keys
    const exportData = { ...allData };
    if (exportData.llmConfig) {
      exportData.llmConfig = { ...exportData.llmConfig, apiKey: '***' };
    }
    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `nutrition-data-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Data exported');
  });

  document.getElementById('clear-today').addEventListener('click', async () => {
    if (!confirm('Clear all food and exercise data for today?')) return;
    const today = new Date().toISOString().split('T')[0];
    await chrome.storage.local.remove(`day_${today}`);
    showToast('Today\'s data cleared');
  });

  document.getElementById('clear-all').addEventListener('click', async () => {
    if (!confirm('This will delete ALL your nutrition data. Are you sure?')) return;
    if (!confirm('This cannot be undone. Really delete everything?')) return;
    // Preserve LLM config and targets
    const llm = await chrome.storage.local.get('llmConfig');
    await chrome.storage.local.clear();
    await chrome.storage.local.set({ targets: { kcal: 2000, protein: 150, carbs: 250, fat: 65 } });
    if (llm.llmConfig) await chrome.storage.local.set({ llmConfig: llm.llmConfig });
    showToast('All data cleared');
  });

  function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 2500);
  }
})();
