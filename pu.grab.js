'use strict';

const btnReset = document.getElementById('btnReset');
const txtTodoList = document.getElementById('txtTodoList');
const btnTodoList = document.getElementById('btnTodoList');

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
