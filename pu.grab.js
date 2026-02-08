'use strict';

const btnReset = document.getElementById('btnReset');
const txtTodoList = document.getElementById('txtTodoList');
const btnTodoList = document.getElementById('btnTodoList');
const txtSaveFolder = document.getElementById('txtSaveFolder');

// Load saved folder on popup open
chrome.storage.local.get({ saveFolder: 'webtoons' }, (result) => {
  txtSaveFolder.value = result.saveFolder;
});

// Persist folder setting on change
txtSaveFolder.addEventListener('input', () => {
  const folder = txtSaveFolder.value.trim();
  chrome.storage.local.set({ saveFolder: folder });
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
