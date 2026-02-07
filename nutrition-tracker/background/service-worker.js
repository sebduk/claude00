/**
 * Background service worker.
 * Handles daily reset alarm and badge updates.
 */

// Set up daily reset alarm
chrome.runtime.onInstalled.addListener(() => {
  // Create an alarm that fires every day at midnight
  chrome.alarms.create('dailyReset', {
    when: getNextMidnight(),
    periodInMinutes: 24 * 60
  });
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'dailyReset') {
    // Update badge for new day
    updateBadge();
  }
});

// Update badge with remaining calories
async function updateBadge() {
  try {
    const today = new Date().toISOString().split('T')[0];
    const dayKey = `day_${today}`;
    const result = await chrome.storage.local.get([dayKey, 'targets']);

    const dayData = result[dayKey] || { foods: [], exercises: [] };
    const targets = result.targets || { kcal: 2000 };

    const totalKcal = dayData.foods.reduce((sum, f) => sum + (Number(f.kcal) || 0), 0);
    const remaining = targets.kcal - totalKcal;

    if (remaining > 0) {
      chrome.action.setBadgeText({ text: String(Math.round(remaining)) });
      chrome.action.setBadgeBackgroundColor({ color: '#6c5ce7' });
    } else {
      chrome.action.setBadgeText({ text: 'OK' });
      chrome.action.setBadgeBackgroundColor({ color: '#34d399' });
    }
  } catch (e) {
    // Badge update is non-critical
  }
}

// Listen for storage changes to update badge in real-time
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'local') {
    const today = new Date().toISOString().split('T')[0];
    if (changes[`day_${today}`]) {
      updateBadge();
    }
  }
});

function getNextMidnight() {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0);
  return midnight.getTime();
}

// Initial badge update
updateBadge();
