'use strict';

/*
 * Background Service Worker
 *
 * Manages a URL queue persisted in chrome.storage.session (survives worker restarts).
 * Processes one tab at a time: opens URL → content script runs → closes tab → next.
 *
 * Modes:
 *   auto (addToNextTab=true)  — content script's "next chapter" URL is queued automatically
 *   list (addToNextTab=false) — only URLs from the popup's todo list are processed
 */

async function getState() {
  return chrome.storage.session.get({ urlStack: [], addToNextTab: true });
}

async function savePageToDisk(tabId) {
  try {
    const tab = await chrome.tabs.get(tabId);
    const blob = await chrome.pageCapture.saveAsMHTML({ tabId });
    const url = URL.createObjectURL(blob);

    // Derive filename from URL path: /read/manga-name/chapter-1 → webtoons/manga-name/chapter-1.mhtml
    const urlPath = new URL(tab.url).pathname;
    const pathParts = urlPath.replace(/^\/read\//, '').replace(/\/$/, '');
    const safeName = pathParts.replace(/[<>:"|?*]/g, '_');
    const filename = 'webtoons/' + safeName + '.mhtml';

    const downloadId = await chrome.downloads.download({
      url: url,
      filename: filename,
      conflictAction: 'uniquify'
    });

    // Wait for the download to finish before moving on
    await new Promise(resolve => {
      function listener(delta) {
        if (delta.id === downloadId && delta.state) {
          chrome.downloads.onChanged.removeListener(listener);
          resolve();
        }
      }
      chrome.downloads.onChanged.addListener(listener);
      // Safety timeout so we never hang forever
      setTimeout(() => { chrome.downloads.onChanged.removeListener(listener); resolve(); }, 30000);
    });

    URL.revokeObjectURL(url);
    console.log('bg - Saved:', filename);
  } catch (e) {
    console.log('bg - Save failed:', e);
  }
}

async function processNext(closingTabId) {
  if (closingTabId) {
    await savePageToDisk(closingTabId);
    try { await chrome.tabs.remove(closingTabId); } catch (e) { /* already closed */ }
  }

  const { urlStack } = await getState();
  if (urlStack.length === 0) {
    console.log('bg - Queue empty.');
    return;
  }

  const nextUrl = urlStack.shift();
  await chrome.storage.session.set({ urlStack });
  console.log('bg - Opening:', nextUrl, '| Remaining:', urlStack.length);
  chrome.tabs.create({ url: nextUrl });
}

async function loadUrlList(text) {
  const lines = text.split('\n').map(l => l.trim());
  const noLimit = lines[0] === 'off';
  const start = noLimit ? 1 : 0;
  const max = noLimit ? Infinity : 50;

  const urls = [];
  for (let i = start; i < lines.length && urls.length < max; i++) {
    if (lines[i].startsWith('http')) urls.push(lines[i]);
  }

  await chrome.storage.session.set({ urlStack: urls });
  console.log('bg - Loaded', urls.length, 'URLs');
}

chrome.runtime.onMessage.addListener((message, sender) => {
  (async () => {
    console.log('bg - Received:', JSON.stringify(message));

    // Mode control from popup (reset or stop)
    if (message.addToNextTab != null) {
      const addToNextTab = message.addToNextTab !== 'stop';
      await chrome.storage.session.set({ addToNextTab, urlStack: [] });
      console.log('bg - Mode:', addToNextTab ? 'auto' : 'list');
    }

    // URL list from popup
    if (message.urlList != null) {
      await loadUrlList(message.urlList);
      processNext(null);
      return;
    }

    // Content script signals page is done
    if (message.pageDone) {
      const { addToNextTab, urlStack } = await getState();
      if (addToNextTab && message.nextURL && message.nextURL.startsWith('http')) {
        urlStack.push(message.nextURL);
        await chrome.storage.session.set({ urlStack });
      }
      processNext(sender.tab?.id);
    }
  })();
});
