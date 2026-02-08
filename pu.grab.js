'use strict';

const btnReset = document.getElementById('btnReset');
const txtTodoList = document.getElementById('txtTodoList');
const btnTodoList = document.getElementById('btnTodoList');
const txtSaveFolder = document.getElementById('txtSaveFolder');
const chkAutoClose = document.getElementById('chkAutoClose');

// Load saved settings on popup open
chrome.storage.local.get({ saveFolder: 'webtoons', autoCloseTabs: false }, (result) => {
  txtSaveFolder.value = result.saveFolder;
  chkAutoClose.checked = result.autoCloseTabs;
});

// Persist folder setting on change
txtSaveFolder.addEventListener('input', () => {
  const folder = txtSaveFolder.value.trim();
  chrome.storage.local.set({ saveFolder: folder });
});

// Persist auto-close setting on change
chkAutoClose.addEventListener('change', () => {
  chrome.storage.local.set({ autoCloseTabs: chkAutoClose.checked });
});

btnReset.addEventListener('click', () => {
  console.log('pu - Reset');
  chrome.runtime.sendMessage({ addToNextTab: 'go' });
});

btnTodoList.addEventListener('click', () => {
  const text = txtTodoList.value.trim();
  if (!text || text === 'Nothing in your list.') {
    txtTodoList.value = 'Nothing in your list.';
    return;
  }
  console.log('pu - Sending list to background');
  chrome.runtime.sendMessage({ addToNextTab: 'stop', urlList: text });
});
