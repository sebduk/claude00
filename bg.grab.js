/*
*** Background ***
******************

Receive URLs from cs (next chapter) or pu (todo list)
Add URLs to stack
Process stack
  Reset after processing full stack

Receive toggle from cs on processing next in stack or not and adding new urls or not (in case of given list of non consecutive)

  Receive toggle from cs on processing next in stack similtaneously or successively (do later)
*/

let urlStack = [] /* urlStack.push(new-URL) to add at the end, urlStack[0] for top of the pile, urlStack.shift() to remove top and shift all others */
let addToNextTab = true;

function top_of_the_pile_and_scoot() {
  logItAll('top_of_the_pile_and_scoot in');
  if (urlStack.length > 0) {
    console.log('bg - Open tab:' + urlStack[0]);
    console.log(new Date().toString());
    chrome.tabs.create({
      url: urlStack[0]
    });
    urlStack.shift();
  }
  logItAll('top_of_the_pile_and_scoot out');
}

function loadUrlList(urlList) {
  logItAll('loadUrlList in');
  let lines = urlList.split('\n');
  (lines[0] == 'off') ? topline=1000 : topline=50;
  for (let i=0; i<lines.length && i<topline; i++) {
    addToUrlList(lines[i]);
  }
  logItAll('loadUrlList out');
}

function addToUrlList(myUrl) {
  //logItAll('addToUrlList in');
  if (myUrl.substring(0, 4) == 'http') {urlStack.push(myUrl);}
  //logItAll('addToUrlList out');
}

function logItAll(where) {
  console.log('bg - ' + where);
  console.log('addToNextTab:' + addToNextTab + ' || urlStack count:' + urlStack.length);
  console.log('   urlStack:' + urlStack);
  //console.log(new Date().toString());
  console.log(' ');
}

chrome.runtime.onMessage.addListener(
  function(message, sender, sendResponse) {
    logItAll('message listener in');

    // Stop/Go add to list from the Popup (pu.grab.js) either from Stop Button or the Todo List
    if (message.addToNextTab != null) {
      console.log('bg - message.addToNextTab:' + message.addToNextTab);
      if (message.addToNextTab == "stop") {
        addToNextTab = false;
      } else {
        addToNextTab = true;
      }
      urlStack.length = 0;
    }

    // Next URL coming from Content-Script (cs.grab.js)
    // Every time a page is done a message is sent to prompt a next page if relevant
    if (message.URL != null) {
      console.log('bg - message.URL:' + message.URL);
      if (addToNextTab) {addToUrlList(message.URL);}
      top_of_the_pile_and_scoot();
    }

    // URL list from the Popup (pu.grab.js)
    if (message.urlList != null) {
      console.log('bg - message.urlList:' + message.urlList);
      loadUrlList(message.urlList);
      top_of_the_pile_and_scoot();
    }
    logItAll('message listener out');
  }
);
