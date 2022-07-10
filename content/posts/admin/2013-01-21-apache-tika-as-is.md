title: Автоматический определь языка в Apache Tika
category: Admin
tags: NLP, Tika


[Apache Tika](http://tika.apache.org/){:rel="nofollow"} - это кроссплатформенный набор инструментов, написанный на ```Java``` для предварительной обработки и анализа текстовой информации - выделения мета-данных, извлечения текста из разнообразных форматов файлов, автоматического определения языка текста и т.д. Умеет эта штука делать много всего интересного, но мы сконцентрируемся на процессе генерации [N-gram](http://en.wikipedia.org/wiki/N-gram){:rel="nofollow"}-файлов для интересующих языков, не поддерживаемых Tika из коробки, чтобы с их помощью можно было автоматически определять языки для текстов.
Для начала было бы неплохо скачать и попробовать запустить само приложение [tika-app-1.2.jar](http://www.apache.org/dyn/closer.cgi/tika/tika-app-1.2.jar){:rel="nofollow"} ~ 27 МБ. Как и любое другое ```Java``` приложение [Tika](http://tika.apache.org/){:rel="nofollow"} можно запустить универсальным способом ```java -jar tika-app-1.2.jar --help```, хотя в *Linux* можно ещё проще:

	:::bash
	~$ java -version
	~$ chmod +x tika-app-1.2.jar
	~$ ./tika-app-1.2.jar --help

Если на машине стоит ```Java```, после выполнения следует ожидать перечисление списка поддерживаемых команд. Предположим мы хотим посмотреть список поддерживаемых форматов входных файлов:

	:::bash
	~$ ./tika-app-1.2.jar --list-supported-types

В результате будет выведен форматированный список, в котором выводится приблизительно такое содержимое, только намного больше:

	:::text
	application/pdf
	  alias:     application/x-pdf
	  supertype: application/octet-stream
	  parser:    org.apache.tika.parser.DefaultParser
	application/msword
	  alias:     application/vnd.ms-word
	  supertype: application/x-tika-msoffice
	  parser:    org.apache.tika.parser.DefaultParser

Давайте уберём все строчки, которые начинаются с пробела, а затем посчитаем сколько их осталось:

	:::bash
	~$ ./tika-app-1.2.jar --list-supported-types | sed '/^ /d'
	~$ ./tika-app-1.2.jar --list-supported-types | sed '/^ /d' | wc -l

Таким образом [Tika](http://tika.apache.org/){:rel="nofollow"} версия 1.2 из коробки поддерживает 1372 различных формата. 

В текущей версии [Tika](http://tika.apache.org/){:rel="nofollow"} поддерживается ~27 языков среди которых например точно нет турецкого - поставим себе задачу это поправить. Для выделения [N-gram](http://en.wikipedia.org/wiki/N-gram){:rel="nofollow"} нам понадобится связный текст - чем больше тем лучше, и уверенность в том что мы заранее знаем язык этого текста. Для экспериментов вот нашелся в Гугле довольно большой [ipa.pdf](http://www.ittihad.com.tr/ipa.pdf){:rel="nofollow"} файл на турецком языке. Предлагаю проверить с помощью [Tika](http://tika.apache.org/){:rel="nofollow"} действительно ли формат соответствует указанному расширению:

	:::bash
	~$ ./tika-app-1.2.jar -d ipa.pdf

Вывод: ```application/pdf```. Ради интереса попросим вывести более подробно метаинформацию из файла:

	:::bash
	~$ ./tika-app-1.2.jar -m ipa.pdf 
	ERROR - Error: Could not parse predefined CMAP file for 'Adobe-Ide-UCS2'
	Content-Length: 9055059
	Content-Type: application/pdf
	Creation-Date: 2008-01-26T23:40:04Z
	created: Sun Jan 27 01:40:04 EET 2008
	date: 2008-01-26T23:40:04Z
	dcterms:created: 2008-01-26T23:40:04Z
	meta:creation-date: 2008-01-26T23:40:04Z
	producer: PDF Creator Plus 4.0 - http://www.peernet.com
	resourceName: ipa.pdf
	xmp:CreatorTool: PDF Creator Plus 4.0 - http://www.peernet.com
	xmpTPg:NPages: 2351

Ошибка ```Adobe-Ide-UCS2``` связана скорее всего не с [Tika](http://tika.apache.org/){:rel="nofollow"}, а с [pdfbox](http://pdfbox.apache.org/){:rel="nofollow"} - но в любом случае мы увидели что хотели, поэтому далее предлагаю эту ошибку просто игнорировать. Теперь извлечем из нашего *pdf* полезный текст:

	:::bash
	~$ ./tika-app-1.2.jar -t ipa.pdf > trout
	~$ ./tika-app-1.2.jar -T ipa.pdf > trout
	~$ file -bi trout

Вывод последней команды: ```text/plain; charset=utf-8```. В случае ```-T``` текст будет немного *плотнее* за счёт удаления лишних пробелов, отступов и т.д. В результате размер файла с полезным текстом ~5,6 МБ в сравнении с 9 МБ оригинального *pdf*. Ну и наконец попробуем автоматически определить язык документа:

	:::bash
	~$ ./tika-app-1.2.jar -l ipa.pdf 

Вывод: ```et```. Тут удивляться нечему - для корректного определения турецкого языка в [Tika](http://tika.apache.org/){:rel="nofollow"} должен быть список [N-gram](http://en.wikipedia.org/wiki/N-gram){:rel="nofollow"}, характерный для этого языка. Сгенерировать небходимый файл можно на основе имеющегося текста, где в следующей команде *tr* - это идентификатор турецкого языка в формате [ISO 639-2](http://www.loc.gov/standards/iso639-2/php/code_list.php){:rel="nofollow"}.

	:::bash
	~$ ./tika-app-1.2.jar --create-profile=tr -eUTF-8 trout

В результате появится файл *tr.ngp*. [Tika](http://tika.apache.org/){:rel="nofollow"} считывает список *.ngp* профайлов из специального файла ```tika.language.properties```. Этот файл скрывается в недрах [tika-app-1.2.jar](http://www.apache.org/dyn/closer.cgi/tika/tika-app-1.2.jar){:rel="nofollow"}, но его можно подменить - создать копию ```tika.language.override.properties``` и сообщить об этом через ```java classpath```. После чего в ```tika.language.override.properties``` необходимо расширить ключ ```languages ``` турецким языком (через запятую) и добавить новый ключ ```name.tr``` со значением *Turkish*. Пробуем:

	:::bash
	~$ mkdir -p org/apache/tika/language
	~$ cp tr.ngp org/apache/tika/language
	#cp tika.language.override.properties org/apache/tika/language
	#tika.language.override.properties languages << tr
	#tika.language.override.properties name.tr=Turkish
	~$ java -cp .:tika-app-1.2.jar org.apache.tika.cli.TikaCLI -l \
	http://tr.wikipedia.org/wiki/Linus_Benedict_Torvalds

Вывод: ```tr```. Ура ! Мы с Вами только что обучили [Tika](http://tika.apache.org/){:rel="nofollow"} новому языку ! Теперь ещё одна дача - преобразовать *tr.ngp* в [javascript](http://mazko.github.io/jsli/){:rel="nofollow"}:

	:::bash
	LNG=`basename $1 .ngp`
	SUM=0
	for COUNT in $(sed '/^#/d;s/^\S\+\s\+\([0-9]\+\)$/\1/' $LNG.ngp)
	do
	SUM=`expr $SUM + $COUNT`;
	done

	echo "(function() {" > $LNG.js
	echo "var ngrams = {" >> $LNG.js
	perl -CSD -p -e 's{([^\t\n\x20-\x7E])}{sprintf "\\u%04x", ord $1}eg' \
	-f $LNG.ngp | sed '/^#/d;s/^\(\S\+\)\s\+\([0-9]\+\)$/"\1":\2,/' >> $LNG.js
	sed -i '$s/,$//' $LNG.js
	echo "};" >> $LNG.js
	echo "LanguageIdentifier.addProfile('$LNG', ngrams, $SUM);" >> $LNG.js
	echo "}());" >> $LNG.js

Сохраним как ```ngp2js```, затем ```chmod +x ngp2js``` и запускаем: ```./ngp2js tr.ngp```. В результате будет сгенерирован ```tr.js``` размером ~13 КБ.
Если очень коротко резюмировать - для генерации качественных [N-gram](http://en.wikipedia.org/wiki/N-gram){:rel="nofollow"} файлов нужно много хорошего связного текста заранее известного языка. Сам процесс создания *.ngp* профайлов очень прост и требует минимум усилий.
