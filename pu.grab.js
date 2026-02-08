function resetAll() {
  console.log('pu - resetAll');
  addToNextTab = true;
  chrome.runtime.sendMessage({addToNextTab: 'go', URL: ''});
  //set_color();
}

function doTodoList() {
  if (txtTodoList.value != '' && txtTodoList.value != 'Nothing in your list.') {
    console.log('pu - Send list to background.');
    console.log(txtTodoList.value);
    addToNextTab = false;
    chrome.runtime.sendMessage({addToNextTab: 'stop', urlList: txtTodoList.value});
  } else {
    console.log('pu - Nothing in your list.');
    txtTodoList.value = 'Nothing in your list.';
  }
  //set_color();
}

const btnReset = document.getElementById('btnReset');
const txtTodoList = document.getElementById('txtTodoList');
const btnTodoList = document.getElementById('btnTodoList');

let goToNextTab = null, addToNextTab = null, i = 0;

btnReset.addEventListener('click', e=> {resetAll()});
btnTodoList.addEventListener('click', e=> {doTodoList()});
