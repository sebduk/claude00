'use strict';

/*
 * Content Script — runs on webtoon pages
 *
 * Loads all lazy images using multiple strategies (works even in background tabs),
 * confirms every image is loaded, then signals the background to close this tab
 * and open the next.
 */

const LOAD_TIMEOUT_MS = 60000;
const POLL_INTERVAL_MS = 2000;
const PRELOAD_TIMEOUT_MS = 15000;

// ---------------------------------------------------------------------------
// DOM helpers
// ---------------------------------------------------------------------------

function getMaxImg() {
  for (let i = 0; i < 500; i++) {
    if (!document.getElementById('image-' + i)) return i - 1;
  }
  return 499;
}

function getNextPage() {
  const btn = document.getElementsByClassName('btn next_page')[0];
  const url = btn ? btn.href : '';
  console.log('cs - Next page:', url);
  return url;
}

function isLoaded(img) {
  return img && img.complete && img.naturalWidth > 0;
}

function countLoaded(maxImg) {
  let n = 0;
  for (let i = 0; i <= maxImg; i++) {
    if (isLoaded(document.getElementById('image-' + i))) n++;
  }
  return n;
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

// ---------------------------------------------------------------------------
// Strategy 1 — Force lazy-load attributes into src
// Works in background tabs. Handles data-src, data-lazy-src, data-original, etc.
// ---------------------------------------------------------------------------

function forceLazyLoad(maxImg) {
  const lazyAttrs = ['data-src', 'data-lazy-src', 'data-original', 'data-url'];
  for (let i = 0; i <= maxImg; i++) {
    const img = document.getElementById('image-' + i);
    if (!img) continue;
    img.loading = 'eager';
    for (const attr of lazyAttrs) {
      const val = img.getAttribute(attr);
      if (val && val.startsWith('http')) {
        img.src = val;
        break;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Strategy 2 — Scroll through images
// Triggers scroll-event and IntersectionObserver based lazy loaders.
// Only effective when the tab is in the foreground, but costs very little.
// ---------------------------------------------------------------------------

async function scrollThrough(maxImg) {
  for (let i = 0; i <= maxImg; i++) {
    const img = document.getElementById('image-' + i);
    if (img) img.scrollIntoView();
    await sleep(50);
  }
  window.scrollTo(0, 0);
}

// ---------------------------------------------------------------------------
// Strategy 3 — Preload via new Image()
// Works in background tabs: the browser fetches the image even without a
// viewport. After the preload, we re-set the original element's src so it
// picks up the now-cached response.
// ---------------------------------------------------------------------------

function preloadImage(url) {
  return new Promise(resolve => {
    if (!url || !url.startsWith('http')) { resolve(false); return; }
    const img = new Image();
    img.onload = () => resolve(true);
    img.onerror = () => resolve(false);
    setTimeout(() => resolve(false), PRELOAD_TIMEOUT_MS);
    img.src = url;
  });
}

function refreshImg(img) {
  if (!isLoaded(img) && img.src) {
    const src = img.src;
    img.src = '';
    img.src = src;
  }
}

async function preloadUnloaded(maxImg) {
  const tasks = [];
  for (let i = 0; i <= maxImg; i++) {
    const img = document.getElementById('image-' + i);
    if (img && !isLoaded(img) && img.src && img.src.startsWith('http')) {
      tasks.push(preloadImage(img.src).then(ok => { if (ok) refreshImg(img); }));
    }
  }
  if (tasks.length > 0) {
    console.log('cs - Preloading', tasks.length, 'images...');
    await Promise.all(tasks);
  }
}

// ---------------------------------------------------------------------------
// Orchestrator — runs all strategies then polls for completion
// ---------------------------------------------------------------------------

async function loadAllImages(maxImg) {
  const total = maxImg + 1;
  const startTime = Date.now();
  let lastLoaded = 0;
  let stalledRounds = 0;

  // Run strategies in order
  forceLazyLoad(maxImg);
  await scrollThrough(maxImg);
  await preloadUnloaded(maxImg);

  // Poll until every image reports loaded, or we time out
  while (Date.now() - startTime < LOAD_TIMEOUT_MS) {
    const loaded = countLoaded(maxImg);
    console.log('cs -', loaded + '/' + total, 'loaded');
    if (loaded === total) return true;

    if (loaded === lastLoaded) {
      stalledRounds++;
      if (stalledRounds >= 3) {
        console.log('cs - Stalled, retrying strategies...');
        forceLazyLoad(maxImg);
        await preloadUnloaded(maxImg);
        stalledRounds = 0;
      }
    } else {
      stalledRounds = 0;
    }
    lastLoaded = loaded;

    await sleep(POLL_INTERVAL_MS);
  }

  const finalCount = countLoaded(maxImg);
  console.log('cs - Timeout.', finalCount + '/' + total, 'loaded.');
  return finalCount === total;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const maxImg = getMaxImg();
console.log('cs - Page loaded. Found', maxImg + 1, 'images.');

if (maxImg >= 0) {
  loadAllImages(maxImg).then(allLoaded => {
    const nextPage = getNextPage();
    console.log('cs - Done. All loaded:', allLoaded, '| Next:', nextPage);
    chrome.runtime.sendMessage({ pageDone: true, nextURL: nextPage });
  });
} else {
  console.log('cs - No images found, moving on.');
  chrome.runtime.sendMessage({ pageDone: true, nextURL: getNextPage() });
}
