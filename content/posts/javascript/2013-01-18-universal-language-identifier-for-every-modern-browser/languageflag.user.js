// ==UserScript==

// @name		Language Flag
// @description		Language identification button, with styling.
// @namespace		http://nongreedy.ru/
// @version		0.1
// @include		*
// @copyright		2013+, Oleg Mazko
// @icon		http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/UA.png

// @require  http://mazko.github.com/jsli/lib/LanguageIdentifier.js
// @require  http://mazko.github.com/jsli/lib/Lng/be.js
// @require  http://mazko.github.com/jsli/lib/Lng/ca.js
// @require  http://mazko.github.com/jsli/lib/Lng/da.js
// @require  http://mazko.github.com/jsli/lib/Lng/de.js
// @require  http://mazko.github.com/jsli/lib/Lng/el.js
// @require  http://mazko.github.com/jsli/lib/Lng/en.js
// @require  http://mazko.github.com/jsli/lib/Lng/eo.js
// @require  http://mazko.github.com/jsli/lib/Lng/es.js
// @require  http://mazko.github.com/jsli/lib/Lng/et.js
// @require  http://mazko.github.com/jsli/lib/Lng/fi.js
// @require  http://mazko.github.com/jsli/lib/Lng/fr.js
// @require  http://mazko.github.com/jsli/lib/Lng/gl.js
// @require  http://mazko.github.com/jsli/lib/Lng/hu.js
// @require  http://mazko.github.com/jsli/lib/Lng/is.js
// @require  http://mazko.github.com/jsli/lib/Lng/it.js
// @require  http://mazko.github.com/jsli/lib/Lng/lt.js
// @require  http://mazko.github.com/jsli/lib/Lng/nl.js
// @require  http://mazko.github.com/jsli/lib/Lng/no.js
// @require  http://mazko.github.com/jsli/lib/Lng/pl.js
// @require  http://mazko.github.com/jsli/lib/Lng/pt.js
// @require  http://mazko.github.com/jsli/lib/Lng/ro.js
// @require  http://mazko.github.com/jsli/lib/Lng/ru.js
// @require  http://mazko.github.com/jsli/lib/Lng/sk.js
// @require  http://mazko.github.com/jsli/lib/Lng/sl.js
// @require  http://mazko.github.com/jsli/lib/Lng/sv.js
// @require  http://mazko.github.com/jsli/lib/Lng/th.js
// @require  http://mazko.github.com/jsli/lib/Lng/uk.js
// @require  http://mazko.github.com/jsli/lib/Lng/tr.js
// @resource be http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/BY.png
// @resource ca http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/AD.png
// @resource da http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/DK.png
// @resource de http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/DE.png
// @resource el http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/GR.png
// @resource en http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/GB.png
// @resource eo http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/mars.png
// @resource es http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/ES.png
// @resource et http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/EE.png
// @resource fi http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/FI.png
// @resource fr http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/FR.png
// @resource gl http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/mars.png
// @resource hu http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/HU.png
// @resource is http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/IS.png
// @resource it http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/IT.png
// @resource lt http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/LT.png
// @resource nl http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/NL.png
// @resource no http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/NO.png
// @resource pl http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/PL.png
// @resource pt http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/PT.png
// @resource ro http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/RO.png
// @resource ru http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/RU.png
// @resource sk http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/SK.png
// @resource sl http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/SI.png
// @resource sv http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/SE.png
// @resource th http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/TH.png
// @resource uk http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/UA.png
// @resource tr http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/TR.png

// @resource unknown http://nongreedy.ru/downloads/2013-01-18-universal-language-identifier-for-every-modern-browser/flags/64/mars.png

// ==/UserScript==

function getBodyText() {
    var doc = window.document, body = doc.body, selection, range, bodyText;
    if (body.createTextRange) {
        return body.createTextRange().text;
    } 
    if (window.getSelection) {
        selection = window.getSelection();
        range = doc.createRange();
        range.selectNodeContents(body);
        selection.addRange(range);
        bodyText = selection.toString();
        selection.removeAllRanges();
        return bodyText;
    }
}

if (document.body) {
    var zNode = document.createElement ('a');
    zNode.innerHTML = '^ Язык';
    zNode.setAttribute ('id', 'nongreedy-jsli');
    zNode.setAttribute ('href', '#');
    document.body.appendChild (zNode);
    
    //--- click handler.
    document.getElementById("nongreedy-jsli").addEventListener ("click", function (zEvent) {
        var text = window.getSelection().toString();
        if (!text) text = getBodyText();
        var lng = LanguageIdentifier.identify(text).language;
        zNode.innerHTML = "";
        zNode.setAttribute ('title', 'ISO 639: ' + lng);
        zNode.setAttribute ('style', 'background-image: url(' + GM_getResourceURL(lng) + ')!important; background-repeat: no-repeat!important;background-position: 50% 50%!important;vertical-align: middle!important;line-height: 0!important;width: 64px!important;height:64px!important;border:none!important;background-color:transparent!important;');
        
        zEvent.preventDefault();
    });
    
    //--- double click handler.
    document.getElementById("nongreedy-jsli").addEventListener ("dblclick", function (zEvent) {
        GM_openInTab("http://nongreedy.ru/");
        
        zEvent.preventDefault();
    });
    
    //--- Style our newly added elements using CSS.
    GM_addStyle ("\
#nongreedy-jsli {\
z-index: 99999!important;\
display: block;\
border: 1px solid rgb(204, 204, 204)!important;\
background: none repeat scroll 0% 0% rgb(247, 247, 247)!important;\
text-align: center!important;\
position: fixed!important;\
bottom: 10px!important;\
right: 10px!important;\
cursor: pointer!important;\
color: rgb(51, 51, 51)!important;\
font-family: verdana!important;\
font-size: 11px!important;\
padding: 5px!important;\
text-decoration:none!important;\
opacity:0.4!important;\
filter:alpha(opacity=40)!important; /* For IE8 and earlier */\
transition: opacity .25s ease-in-out!important;\
-moz-transition: opacity .25s ease-in-out!important;\
-webkit-transition: opacity .25s ease-in-out!important;\
}\
#nongreedy-jsli:hover {\
opacity:1.0!important;\
filter:alpha(opacity=100)!important; /* For IE8 and earlier */\
}\
");
}

