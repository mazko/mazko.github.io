title: Lucene - процесс индексации
category: Java
tags: Lucene, JSoup, log4j


Среди множества документов, количество и размер которых могут быть очень большими,  необходимо отобрать только те из них, которые отвечают какому-либо условию - например содержат ту или иную фразу. Как решать подобную задачу ? Можно обойти последовательно все документы и проверить наличие искомой фразы в каждом из них. Но сколько времени и ресурсов может уйти на поиск фразы в документе размером скажем 1000000 слов и более ? Умножаем это число на количество документов... Предложенное решение слишком прямолинейно - пока мы будем что-то искать, пользователь может уже подзабыть что же именно он хотел и зачем это было надо.

Чтобы иметь возможность осуществлять поиск текста максимально быстро, предварительно необходимо его проиндексировать - преобразовать в какой-то другой формат, который позволит избежать вышеупомянутых проблем. В нашем случае источником информации является [сайт]({filename}../2012-10-15-lucene-real-world/2012-10-15-lucene-real-world.md), а документы это не что иное как его отдельные HTML-страницы. Для обхода всех страниц сайта нам понадобится простая программа-*паук* (*crawler*):

*jLucene/crawler/src/nongreedy/SimpleCrawler.java*

	:::java
	package nongreedy;

	import java.util.HashSet;
	import java.util.NavigableSet;
	import java.util.Set;
	import java.util.TreeSet;

	import org.apache.log4j.Logger;

	class SimpleCrawler {

	    public interface ICrawlEvents {
	        void onVisit(String url, String html, String seed);
	        boolean shouldVisit(String url, String seed);
	    }

	    private static final Logger logger = 
	        Logger.getLogger(SimpleCrawler.class.getName());

	    private ICrawlEvents events;
	    private NavigableSet<String> linksToCrawl;
	    private Set<String> linksCrawled;
	    private String seed;

	    public SimpleCrawler(String seed, ICrawlEvents events) {
	        this.events = events;
	        this.seed = seed;
	    };

	    public boolean hasLinksToCrawl() {
	        return !linksToCrawl.isEmpty();
	    }

	    public void run() {

	        linksCrawled = new HashSet<String>();
	        linksToCrawl = new TreeSet<String>();
	        linksToCrawl.add(seed);

	        while (hasLinksToCrawl()) {

	            String strURL = linksToCrawl.pollFirst();
	            linksCrawled.add(strURL);

	            try {
	                String html = HtmlHelper.download(strURL);

	                int linksAdded = 0;
	                for (String l : HtmlHelper.extractLinks(html, seed)) {
	                    if (events.shouldVisit(l, seed)
	                            && !linksCrawled.contains(l)
	                            && !linksToCrawl.contains(l)) {
	                        linksToCrawl.add(l);
	                        linksAdded++;
	                    }
	                }

	                logger.info(String.format("Fetched: [%s] %d new links",
	                        strURL, linksAdded));
	                events.onVisit(strURL, html, seed);
	            } catch (Exception ex) {
	                logger.error(String.format("Fetch error: [%s].",
	                        strURL), ex);
	            }
	        }
	    }
	}

Все ссылки хранятся в оперативной памяти - для маленьких и средних по величине сайтов такое решение вполне приемлемо. С внешним миром *crawler* общается посредством интерфейса `ICrawlEvents`, а с HTML работает через статический класс `HtmlHelper`. Последний активно использует прекрасную библиотеку для работы с *Html* в *Java* - [JSoup](http://jsoup.org/){:rel="nofollow"}, которая в совершенстве владеет языком *css-селекторов*. Также стоит обратить внимание на обязательное наличие временной задержки (*politeness*) между Http-запросами к сайту - большинство хостеров следят за количеством запросов с одного IP, поэтому при работе с реальным веб-сайтом необходимо соблюдать толерантность, если не хотите получить бан конечно.

*jLucene/crawler/src/nongreedy/HtmlHelper.java*

	:::java
	package nongreedy;

	import java.io.IOException;
	import java.util.Collection;
	import java.util.Collections;
	import java.util.HashSet;
	import java.util.Set;

	import org.jsoup.Jsoup;
	import org.jsoup.nodes.Document;
	import org.jsoup.nodes.Element;
	import org.jsoup.select.Elements;

	final class HtmlHelper {
	    public static Collection<String> extractLinks(
	        String html, String seed) {

	        Document document = Jsoup.parse(html, seed);
	        Set<String> linksSet = new HashSet<String>();
	        for (Element link : document.select("a[href]")) {
	            String strLink = 
	                link.attr("abs:href").trim().toLowerCase();
	            if (!strLink.isEmpty())
	                linksSet.add(strLink);
	        }

	        return Collections.unmodifiableCollection(linksSet);
	    }

	    public static String download(String link) throws IOException,
	            InterruptedException {

	        IOException ioe;
	        int retry = 5;

	        do {
	            try {

	                /* Crawling a real web site politeness > 5s */

	                Thread.sleep(1);
	                Document bDoc = Jsoup.connect(link)
	                        .userAgent("Mozilla")
	                        .timeout(30000).get();
	                return bDoc.html();
	            } catch (IOException ex) {
	                ioe = ex;
	            }
	        } while (--retry > 0);

	        throw ioe;
	    }

	    public static String extractTitle(String html) {
	        Document doc = Jsoup.parse(html);
	        Elements elements = doc.select("table table div table font");
	        if (null != elements && !elements.isEmpty())
	            return elements.first().text();
	        return null;
	    }

	    public static String extractContent(String html) {
	        Document doc = Jsoup.parse(html);
	        Elements elements = doc.select("table table div table div");
	        if (null != elements && !elements.isEmpty())
	            return elements.first().text();
	        return doc.select("table table div table").first().text();
	    }
	}

Теперь основная программа, которая будет запускать *crawler* и передавать необходимую информацию соответствующему классу `LuceneIndexer` для индексации:

*jLucene/crawler/src/nongreedy/Controller.java*

	:::java
	package nongreedy; 
	 
	import nongreedy.SimpleCrawler.ICrawlEvents; 
	 
	import org.apache.log4j.Logger; 
	import org.apache.log4j.PropertyConfigurator; 
	 
	public class Controller { 
	 
	    private static final Logger logger = 
	        Logger.getLogger(Controller.class.getName()); 
	 
	    private final static String indexDir = 
	        "../server/webapps/search/LuceneIndex"; 
	    private final static String crawlSeed = 
	        "http://localhost:8080"; 
	 
	    public static void main(String[] args) { 
	        try { 
	 
	            /* Setup: Logger, Ctrl + C */ 
	 
	            PropertyConfigurator.configure("pps/log4j.properties"); 
	            Runtime.getRuntime().addShutdownHook(new ShutdownHook()); 
	 
	            /* Start crawler and perform indexing */ 
	 
	            final LuceneIndexer luceneIndexer = 
	                new LuceneIndexer(indexDir);

	            new SimpleCrawler(crawlSeed, new ICrawlEvents() { 
	 
	                /* Proceed page - add to Lucene index */ 
	 
	                public void onVisit(String url, 
	                    String html, String seed) { 
	                    luceneIndexer.add(url, html); 
	                } 
	 
	                /* Skip any external links */ 
	 
	                public boolean shouldVisit(String url, String seed) { 
	                    return url.startsWith(seed); 
	                } 
	 
	            }).run(); 
	 
	        } catch (Exception ex) { 
	            logger.error("Unable to start !", ex); 
	        } 
	    } 
	 
	    /* Hook for Shutting down (include user Ctrl + C event) */ 
	 
	    private static class ShutdownHook extends Thread { 
	        public void run() { 
	            logger.info("Optimizing and close index."); 
	            LuceneIndexer.optimizeAndClose(); 
	            logger.info("Closed."); 
	        } 
	    } 
	}

Таким образом мы подошли, пожалуй, к ключевому моменту данной статьи - процессу создания индекса в *Lucene*. Главным классом тут является `IndexWriter` - которому необходимо знать директорию, где будут храниться файлы индекса. Опция `OpenMode.CREATE` указывает на необходимость удалять старый индекс, если тот на момент инициализации в указанной директории уже существует. Согласно [документации](http://lucene.apache.org/core/old_versioned_docs/versions/3_5_0/api/core/org/apache/lucene/index/IndexWriter.html){:rel="nofollow"}, `IndexWriter` потокобезопасный (completely thread safe), однако в нашем случае синхронизация введена для предупреждения попытки работы с `indexWriter`, который своё уже отработал, т.е. `indexWriter == null` - иначе в лог могут попасть не очень дружелюбные исключения типа `NullReferenceException` или `AlreadyClosedException`.

*jLucene/crawler/src/nongreedy/LuceneIndexer.java*

	:::java
	package nongreedy;

	import java.io.File;
	import java.io.IOException;

	import org.apache.log4j.Logger;
	import org.apache.lucene.document.Document;
	import org.apache.lucene.document.Field;
	import org.apache.lucene.document.Field.Index;
	import org.apache.lucene.document.Field.Store;
	import org.apache.lucene.document.Field.TermVector;
	import org.apache.lucene.index.IndexWriter;
	import org.apache.lucene.index.IndexWriterConfig;
	import org.apache.lucene.index.IndexWriterConfig.OpenMode;
	import org.apache.lucene.store.Directory;
	import org.apache.lucene.store.FSDirectory;

	class LuceneIndexer {
	    private static final Logger logger = 
	        Logger.getLogger(LuceneIndexer.class.getName());

	    /* IndexWriter is completely thread safe */

	    private static IndexWriter indexWriter;

	    public static void optimizeAndClose() {
	        try {
	            synchronized (LuceneIndexer.class) {
	                if (null != indexWriter) {
	                    indexWriter.close();
	                    indexWriter = null;
	                } else {
	                    throw new IOException("Index already closed");
	                }
	            }
	        } catch (IOException ex) {
	            logger.error(ex);
	        }
	    }

	    public LuceneIndexer(String indexDir) throws IOException {
	        Directory dir = FSDirectory.open(new File(indexDir));
	        IndexWriterConfig config = new IndexWriterConfig(
	                LuceneBinding.CURRENT_LUCENE_VERSION,
	                LuceneBinding.getAnalyzer());
	        config.setOpenMode(OpenMode.CREATE); // Rewrite old index
	        indexWriter = new IndexWriter(dir, config);
	    }

	    public void add(String url, String html) {

	        String title = HtmlHelper.extractTitle(html);
	        String content = HtmlHelper.extractContent(html);

	        logger.info("***** " + url + " *****");
	        if (null != title)
	            logger.info(title);
	        logger.info(content);

	        Document doc = new Document();

	        doc.add(new Field(LuceneBinding.URI_FIELD, 
	            url, Store.YES, Index.NO));
	        if (null != title)
	            doc.add(new Field(LuceneBinding.TITLE_FIELD, 
	                title, Store.YES, Index.ANALYZED, 
	                TermVector.WITH_POSITIONS_OFFSETS));
	        doc.add(new Field(LuceneBinding.CONTENT_FIELD, 
	            content, Store.YES, Index.ANALYZED, 
	            TermVector.WITH_POSITIONS_OFFSETS));

	        try {
	            synchronized (LuceneIndexer.class) {
	                if (null != indexWriter) {
	                    indexWriter.addDocument(doc);
	                }
	            }
	        } catch (IOException ex) {
	            logger.error(ex);
	        }
	    }
	}

Если внимательно посмотреть на содержимое каждой html-странички нашего сайта, то помимо <span style="text-decoration: line-through;">не</span>навязчивой рекламы и прочего мусора можно выделить две единицы более - менее полезной информации: *название* (title) публикации и её *содержимое* (content). Извлечь данную информацию из html нам поможет уже упомянутая выше библиотека *JSoup*, после чего можно добавлять `Document` с соответствующими полями в индекс *Lucene*.

*Lucene* может сохранять / извлекать следующие типы данных: `String`, `String[]`, `Byte[]` и `Byte[][]`, хотя поиск, конечно же, может осуществляться только по первым двум. В нашем случае первое поле - url, параметр `Store.YES` указывает на необходимость хранить в индексе оригинальное (неизменное) значение, а `Index.NO` на то, что поиск по этому полю осуществляться не будет, т.е. это поле несет дополнительную информацию о найденном документе, которую мы планируем использовать в будущем. Поля *title* и *content* индексируются одинаково - `Index.ANALYZED` указывает на то, что по данному полю будет осуществляться поиск а также просит *Lucene* задействовать механизмы анализа содержимого данного документа на этапе создания индекса (самый простой пример анализа - выделение слов из набора букв и пробелов между ними), параметр `TermVector.WITH_POSITIONS_OFFSET` позволяет сохранить дополнительную информацию о позициях тех или иных слов в теле документа - такой подход значительно ускоряет процесс подсветки найденных вхождений.

Класс `LuceneBinding` - это своеобразный мост между индексатором (*crawler*) и поиском (`SearchServlet`), он содержит общую информацию и используется совместно обоими приложениями:

*jLucene/server/webapps/search/src/nongreedy/LuceneBinding.java*

	:::java
	package nongreedy;

	import org.apache.lucene.analysis.Analyzer;
	import org.apache.lucene.analysis.standard.StandardAnalyzer;
	import org.apache.lucene.util.Version;

	/* This class is used both by Crawler and SearchServlet */

	public final class LuceneBinding {
	    public static final Version CURRENT_LUCENE_VERSION =
	        Version.LUCENE_35;

	    public static final String URI_FIELD = "uri";
	    public static final String TITLE_FIELD = "title";
	    public static final String CONTENT_FIELD = "content";

	    public static Analyzer getAnalyzer() {
	        return new StandardAnalyzer(CURRENT_LUCENE_VERSION);
	    }
	}

###Сборка и запуск

Перед запускам crawler должен быть запущен *Jetty* сервер с сайтом, который мы хотим проиндексировать. Чтобы корректно отображались русские буквы в консоли *Windows* необходимо обозначить правильную кодировку *Cp866* в файле *jLucene/crawler/pps/log4j.properties*

*jLucene/crawler/build.bat*

	:::batch
	@rd bin /Q /S 
	@md bin 
	 
	@set LIB=lib/*;../server/webapps/search/app/WEB-INF/lib/* 
	@set SRC=src/nongreedy/*.java ^
	../server/webapps/search/src/nongreedy/LuceneBinding.java 
	 
	@javac -cp .;%LIB% -d bin %SRC% 
	 
	@pause

*jLucene/crawler/run.bat*

	:::batch
	@set LIB=lib/*;../server/webapps/search/app/WEB-INF/lib/* 
	@java -cp bin;%LIB% nongreedy.Controller
	@pause

![Win Crawler Run]({attach}win_crawler_build_run_jog4j_Cp866.png){:style="width:100%; border:1px solid #ddd;"}

*jLucene/crawler/build.sh*

	:::bash
	#!/bin/bash

	cd "`dirname "${0}"`"

	rm -r -f bin
	mkdir bin

	SRC="src/nongreedy/*.java \
	../server/webapps/search/src/nongreedy/LuceneBinding.java"
	LIB=lib/*:../server/webapps/search/app/WEB-INF/lib/*

	javac -cp $LIB -d bin $SRC $*

*jLucene/crawler/run.sh*

	:::bash
	#!/bin/bash

	cd "`dirname "${0}"`"

	# link libraries

	LIB=lib/*:../server/webapps/search/app/WEB-INF/lib/*

	java -cp bin:$LIB nongreedy.Controller

![Linux Crawler Run]({attach}linux_crawler_build_run.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-21-lucene-real-world---check-index/2012-10-21-lucene-real-world---check-index.md) мы бегло заглянем в индекс, после чего реализуем простой поиск.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Simple_Crawler_Index){:rel="nofollow"}.
