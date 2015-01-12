console.log(document.location.href);
console.log('hello');

var cookies = {}

function initCookies() {
    var ca = document.cookie.split(';');
    for(var i=0; i<ca.length; i++) {
        name = ca[i].replace(/=.*/, "");
        name = name.replace(/^ +/, "");
        val = ca[i].replace(/^[^=]*=/, "")
      //console.log(name + " => " + val);
        cookies[name] = val;
    }
}

function initSettings() {

}

loc = document.location.href + "";
loc = loc.replace(/[.].*/, "");
loc = loc.replace(/.*\//, "");

var hide_html = "<a>[Hide it]</a>";
var show_html = "<a>[Show it]</a> (hidden)";

var FLAG_should_be_hidden = true;
var FLAG_should_be_shown  = false;

function setBlock(elem, should_be_hidden) {
    elem.style.width="100%"
    elem.style.display="inline-block"
    if (should_be_hidden) {
        elem.style.backgroundColor="#ffc0c0"
        elem.innerHTML = show_html;
        elem.close = 0;
    } else {
        elem.style.backgroundColor="#c8c8c8"
        elem.innerHTML = hide_html;
        elem.close = 1;
    }
}

function initElements() {

    var key = "CL_HIDE_ACTIVE"
    if (localStorage[key] == undefined || localStorage[key] == 'no') {
        var active = false;
    } else {
        var active = true;
    }
    active = true;

    var elements = document.getElementsByClassName("row");
    if (elements != null) {
        for (var i = elements.length-1 ; i>=0; i--) {
            var ID = elements[i].getAttribute("data-pid");
            if (ID != null && ID != "") {
                ID = loc + "_" + ID;
              //console.log(ID);
                var hider = document.createElement("span");
                hider.id = "hider"
                if (localStorage[ID] == undefined || localStorage[ID] == "show") {
                    setBlock(hider, FLAG_should_be_shown);
                    showit = 1;
                } else {
                    setBlock(hider, FLAG_should_be_hidden);
                    showit = 0;
                }
                if (!active || showit) {
                    hider.addEventListener("click", toggleMe.bind(null, ID));
                    elements[i].insertBefore(hider, elements[i].childNodes[0]);
                } else {
                    elements[i].parentNode.removeChild(elements[i]);
                }
            }
            //var x = elements[i].getElementsByClassName("i");
            //if (x != null && x.length >= 1) {
            //    console.log(x);
            //}
        }
    }
}

//initCookies();
initSettings();
initElements();


function setCookie(cname, cvalue, exdays) {
    var d = new Date();
    d.setTime(d.getTime() + (exdays*24*60*60*1000));
    var expires = "expires=" + d.toUTCString();
    document.cookie = cname + "=" + cvalue + "; " + expires + "; path=/";
}

function toggleMe(ID) {
    console.log(ID);
    var elements = document.getElementsByClassName("row");
    if (elements != null) {
        for (var i=0; i<elements.length; i++) {
            console.log(i);
            var node = elements[i];
            var id = node.getAttribute("data-pid");
            if (id != null && id != "") {
                id = loc + "_" + id;
                //console.log(id);
                if (id == ID) {
                    var childNodes = node.childNodes;
                    for (var i=0; i<childNodes.length; i++) {
                        if (childNodes[i].id == "hider") {
                            var hider = childNodes[i];
                            if (hider.close == 1) {
                                setBlock(hider, FLAG_should_be_hidden);
                                var d = new Date();
                                localStorage[ID] = d.toUTCString();
                            } else {
                                setBlock(hider, FLAG_should_be_shown);
                                localStorage.removeItem(ID);
                            }
                        }
                    }
                    return
                }
            }
        }
    }
}

navigator.webkitPersistentStorage.requestQuota(1024*1024*10, 
  function(grantedBytes) {
      console.log(grantedBytes);
  }, function(e){
      console.log('Error', e);
  })

