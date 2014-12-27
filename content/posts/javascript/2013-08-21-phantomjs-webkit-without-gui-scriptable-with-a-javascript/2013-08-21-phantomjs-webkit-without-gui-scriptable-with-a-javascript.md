title: PhantomJS - полный фарш для браузера в консоли
category: JavaScript
tags: WebKit,PhantomJS


[WebKit](http://ru.wikipedia.org/wiki/WebKit){:rel="nofollow"} - свободный движок с открытым кодом для отображения веб-страниц, который лежит в основе таких популярных браузеров как *Chrome* и *Safari*. [PhantomJS](http://www.phantomjs.org/){:rel="nofollow"} также основан на *WebKit* и умеет делать всё то, что и обычный браузер, но:

- Нет *GUI* - действия программируются сценариями *JavaScript/CoffeeScript*, а результат можно при желании рендерить в PNG, GIF, JPEG, PDF

- Начиная с версии [PhantomJS 1.5](http://phantomjs.org/faq.html){:rel="nofollow"} не нужны [иксы](http://ru.wikipedia.org/wiki/X_Window_System){:rel="nofollow"}, что значительно упрощает разворачивание

###СБОРКА

*WebKit* использует [Qt](http://qt-project.org/){:rel="nofollow"}, для [сборки](http://phantomjs.org/build.html){:rel="nofollow"} из исходников возможно чего-то из перечисленного понадобится доустановить:

	:::bash
	~$ #apt-get install build-essential chrpath libssl-dev libfontconfig1-dev
	~$ wget https://phantomjs.googlecode.com/files/phantomjs-1.9.1-source.zip
	~$ unzip phantomjs-1.9.1-source.zip && cd phantomjs-1.9.1
	~$ #gdb bin/phantomjs
	~$ CFLAGS=-g CXXFLAGS=-g ./build.sh \
	   --qt-config '-webkit-debug' \
	   --qmake-args "QMAKE_CFLAGS=-g QMAKE_CXXFLAGS=-g"

Сборка может занимать ~30 минут.

###HELLO WORLD

Простой скрипт, который делает скриншот любого сайта:

*hello.js*

	:::javascript
	//create new webpage object
	var page = require('webpage').create();

	page.viewportSize = { width: 600, height: 600 };

	//load the page
	page.open('http://dou.ua/', function (status) {
	    if (status !== 'success') {
	        console.log('Unable to load the address: ' + status);
	        phantom.exit();
	    } else {
	        window.setTimeout(function () {
	            page.render('dou.png');
	            phantom.exit();
	        }, 200);
	    }
	});

Запуск:

	:::bash
	~$ bin/phantomjs hello.js

![FF screenshot]({attach}dou.png){:style="width:100%; border:1px solid #ddd;"}

###МОДУЛЬНОСТЬ

Наподобие с [Node](http://nodejs.org/){:rel="nofollow"} в *PhantomJS* поддерживается концепция модулей, а начиная с [PhantomJS 1.7](https://github.com/ariya/phantomjs/wiki/API-Reference){:rel="nofollow"} можно создавать пользовательские модули. Для примера напишем модуль, который задает таймаут на загрузку страницы:

*pageex.js*

	:::javascript
	function open(page, timeout, address, onload) {

	    timeout = timeout || 25000;

	    var page_load_timeout = window.setTimeout(function () {
	        page.stop();
	        onload('timeout');
	        page_load_timeout = false;
	    }, timeout);

	    page.open(address, function (status) {
	        clearTimeout(page_load_timeout);
	        if (page_load_timeout !== false) onload(status);
	    });
	}

	module.exports = {
	    open: open
	}

*hello.js*

	:::javascript
	var page = require('webpage').create(),
	    pageex = require('./pageex.js');

	page.viewportSize = { width: 600, height: 600 };

	pageex.open(page, 1000, 'http://dou.ua/', function (status) {
	    if (status !== 'success') {
	        console.log('Unable to load the address: ' + status);
	        phantom.exit();
	    } else {
	        window.setTimeout(function () {
	            page.render('dou.png');
	            phantom.exit();
	        }, 200);
	    }
	});

Если страница не прогрузиться за одну секунду, вывод в консоли будет ```Unable to load the address: timeout```.

###РАБОТА С DOM

В этой части мало отличий от обычного клиентского *JavaScrtipt*, плюс можно делать дополнительные инъекции в *DOM* готовых *\*js* файлов в том числе и локальных функцией ```injectJs```:

*dom.js*

	:::javascript
	var page = require('webpage').create();

	page.viewportSize = { width: 600, height: 600 };

	page.open('http://dou.ua/', function (status) {
	    if (status !== 'success') {
	        console.log('Unable to load the address: ' + status);
	        phantom.exit();
	    } else {
	        page.injectJs('jquery-1.10.1.min.js');
	        page.evaluate(function() {
	            $('ul.l-articles a.link:first').
	                css({color:'red'}).
	                text('Дайджест: PhantomJS');
	        });
	        window.setTimeout(function () {
	            page.render('dou_dom.png');
	            phantom.exit();
	        }, 200);
	    }
	});

Запуск:

	:::bash
	~$ #wget http://code.jquery.com/jquery-1.10.1.min.js
	~$ bin/phantomjs dom.js

![FF screenshot]({attach}dou_dom.png){:style="width:100%; border:1px solid #ddd;"}

Плюс полный контроль над файлами-ресурсов:

*resource.js*

	:::javascript
	var page = require('webpage').create(),
	    fs = require("fs");

	page.viewportSize = { width: 600, height: 600 };

	page.onResourceRequested = function(requestData, request) {
	    var spam = 'http://partner.googleadservices.com/',
	        photo = 'http://s.developers.org.ua/img/announces/',
	        data = btoa(fs.open('django.jpeg', 'rb').read()),
	        url = requestData['url'];

	    if(url.indexOf(spam) === 0 /* startsWith */)
	        request.abort();

	    if(url.indexOf(photo) === 0 /* startsWith */)
	        request.changeUrl('data:image/jpeg;base64,' + data);

	    console.log(url);
	}

	page.open('http://dou.ua/', function (status) {
	    if (status !== 'success') {
	        console.log('Unable to load the address: ' + status);
	        phantom.exit();
	    } else {
	        page.injectJs('jquery-1.10.1.min.js');
	        page.evaluate(function() {
	            $('ul.l-articles a.link:first').
	                css({color:'red'}).
	                text('Дайджест: PhantomJS');
	        });
	        window.setTimeout(function () {
	            page.render('dou_res.png');
	            phantom.exit();
	        }, 200);
	    }
	});

![FF screenshot]({attach}dou_res.png){:style="width:100%; border:1px solid #ddd;"}

###ВСТРОЕННЫЙ WEB SERVER

В *PhantomJS* также имеется встроенный веб-сервер [Mongoose](https://github.com/ariya/phantomjs/wiki/API-Reference-WebServer){:rel="nofollow"}:

*server.js*

	:::javascript
	var server  = require('webserver').create(),
	    fs      = require('fs'),
	    port    = require('system').env.PORT || 8080;

	var service = server.listen(port, function(request, response) {

	    if(request.method == 'POST' && request.post.url){
	 
	        var page = require('webpage').create();
	        page.viewportSize = { width: 600, height: 600 };

	        page.open(request.post.url, function (status) {
	            if (status !== 'success') {
	                console.log('Unable to load the address: ' + status);
	                page.close();
	            } else {
	                window.setTimeout(function () {
	                    page.render('out.png');
	                    page.close();
	                    var pngStream = fs.open('out.png', 'rb');
	                    var png = pngStream.read();
	                    pngStream.close();

	                    response.statusCode = 200;
	                    response.setHeader('Accept-Ranges', 'bytes');
	                    response.setHeader('Content-Length', png.length);
	                    response.setHeader('Content-Type', 'image/png');

	                    console.log(JSON.stringify(response.headers));

	                    response.setEncoding("binary");
	                    response.write(png);
	                    response.close();
	                }, 200);
	            }
	        });
	    } else {
	        response.statusCode = 200;
	        response.setHeader('Content-Type', 'text/html; charset=utf-8');
	        response.write(fs.read('index.html'));
	        response.close();
	    }
	});

	if(service) console.log("Started - http://localhost:" + server.port);

*index.html*

	:::html
	<!DOCTYPE html>
	<html>
	<head>
	    <title>PhantomJS server example</title>
	</head>
	<body>
	    <form method="post">
	        <input type="url" name="url" value="http://nongreedy.ru/">
	        <input type="submit" value="&raquo;">
	    </form>
	</body>
	</html>

Запуск:

	:::bash
	~$ bin/phantomjs server.js

Поскольку на [Heroku](https://www.heroku.com/){:rel="nofollow"} используется эфемерная файловая система, ```out.png``` между запросами сохраняться не будет, сам процесс неплохо изложен [тут](http://benjaminbenben.com/2013/07/28/phantomjs-webserver/){:rel="nofollow"}, пощупать можно [тут](http://a2pdf.herokuapp.com/){:rel="nofollow"}.
