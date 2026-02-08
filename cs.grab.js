function getImgData() {
  let imgArray=[];
  //const pageUrl = window.location.href;
  //const saveToDir = /[^/]*\/[^/]*\/$/.exec(pageUrl)[0];
  for (let i=0; i<=maxImg; i++) {
    let myUrl = document.getElementById('image-' + i).src;
    //console.log('i:' + i + ' | myUrl:' + myUrl);
    imgArray.push([i, myUrl]);
  }
  //console.log(imgArray);
  return imgArray;
}

function getNextPage() {
  let pageUrlNext = '';
  const btnNext = document.getElementsByClassName('btn next_page')[0];
  if (btnNext != null) {pageUrlNext = btnNext.href;}
  console.log('cs - pageUrlNext:' + pageUrlNext);
  return pageUrlNext;
}

function getMaxImg() {
  let maxImg = -1;
  for (let i=0; i<500; i++) {
    let e = document.getElementById('image-' + i);
    if (e == null) {maxImg = i - 1; i = 500}
  }
  console.log('maxImg:' + maxImg);
  return maxImg;
}

function getWait(mySeconds, maxImg) {
  const coef=5;
  let myWait = coef*50;
  if (maxImg > 10)  {myWait=coef*25;}
  if (maxImg > 50)  {myWait=coef*10;}
  if (maxImg > 100) {myWait=coef*2.5;}
  mywait = mySeconds * 1000 / 7 / maxImg;
  return myWait;
}

function getTop(mySeconds, myWait, maxImg) {
  let myTop = Math.max(mySeconds * 1000 / myWait / maxImg, 2); myTop = Math.min(myTop, 8);
  return myTop;
}

function checkImgData(imgArray) {
  let myIndex=0, lastIndex=0;
  const regex = /\/([a-z-]{0,3}([0-9]+)[a-z-]{0,3})\.jpg/;
  for (imgData of imgArray) {
    if (imgData[1] == '') {
      console.log('MISSING - ' + imgData[0]);
    } else {
      try {myIndex=parseInt(imgData[1].match(regex)[2]);}
      catch (e) {console.log(imgData[1] + ' not set');}

      if ( myIndex == lastIndex + 1 ) {
        console.log(imgData[1] + ' good index');
      } else {
        console.log(imgData[1] + ' check index');
      }
      lastIndex=myIndex;
    }
  }
}

function moveToPage(pageURL) {
  chrome.runtime.sendMessage({URL: pageURL});
}


const mySeconds = 30, maxImg = getMaxImg();
const myWait = getWait(mySeconds, maxImg);
const myTop = getTop(mySeconds, myWait, maxImg);


let i=0, j=0;
let _autoScoot = setInterval(function() {
  console.log('img '+ i +'of' + maxImg + '\t|| iter ' + j + 'of' + myTop);
  if ( j < myTop ){
    let e = document.getElementById('image-' + i);
    if (e != null) {
      e.scrollIntoView();
      i++;
    } else {
      i=0; j++;
      window.scrollTo(0, 0);
      if (maxImg > -1) {
        document.getElementById('image-' + maxImg).scrollIntoView();
      }
    };
  } else {
    clearInterval(_autoScoot);
    checkImgData(getImgData());
    moveToPage(getNextPage());
  }
}, myWait);

chrome.runtime.onMessage.addListener(
  function(message, sender, sendResponse) {
    //
    if (message.bgStatus != null) {
      console.log('cs - message.bgStatus:' + message.bgStatus);
    }
  }
);
