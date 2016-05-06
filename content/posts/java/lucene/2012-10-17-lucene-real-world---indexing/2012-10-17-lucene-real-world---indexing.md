title: Lucene - процесс индексации
category: Java
tags: Lucene, JSoup, Maven


Среди множества документов, количество и размер которых могут быть очень большими,  необходимо отобрать только те из них, которые отвечают какому-либо условию - например содержат ту или иную фразу. Как решать подобную задачу ? Можно обойти последовательно все документы и проверить наличие искомой фразы в каждом из них. Но сколько времени и ресурсов может уйти на поиск фразы в документе размером скажем 1000000 слов и более ? Умножаем это число на количество документов... Предложенное решение слишком прямолинейно - пока мы будем что-то искать, пользователь может уже подзабыть что же именно он хотел и зачем это было надо.

Чтобы иметь возможность осуществлять поиск текста максимально быстро, предварительно необходимо его проиндексировать - преобразовать в какой-то другой [формат](https://en.wikipedia.org/wiki/Inverted_index){:rel="nofollow"}, который позволит избежать вышеупомянутых проблем. В нашем случае источником информации является [сайт]({filename}../2012-10-15-lucene-real-world/2012-10-15-lucene-real-world.md), а документы это не что иное как текстовое содержимое его отдельных HTML-страниц. Для обхода всех страниц сайта нам понадобится *crawler*. Это будет ещё один подпроект в мультимодульном Maven проекте наряду с Server. Ещё у них будет общая зависимость Common для совместно используемых констант:

    :::bash
    ~$ cd lucene-tutorial/
    ~$ tree
    .
    ├── common
    │   ├── pom.xml
    │   └── src
    │       └── main
    │           └── java
    │               └── common
    │                   └── LuceneBinding.java
    ├── crawler
    │   ├── pom.xml
    │   └── src
    │       └── main
    │           ├── java
    │           │   └── crawler
    │           │       ├── App.java
    │           │       ├── HtmlHelper.java
    │           │       ├── LuceneIndexer.java
    │           │       └── SimpleCrawler.java
    │           └── resources
    │               └── log4j.properties
    ├── pom.xml
    └── server
        ├── pom.xml
        ├── src
        │   └── main
        │       ├── java
        │       │   └── server
        │       │       └── SearchServlet.java
        │       └── webapp
        │           └── WEB-INF
        │               └── web.xml
        └── static.war

    18 directories, 13 files

*pom.xml*

	:::xml
	<project xmlns="http://maven.apache.org/POM/4.0.0" 
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
	  <modelVersion>4.0.0</modelVersion>
	  <groupId>tutorial.lucene</groupId>
	  <artifactId>parent</artifactId>
	  <packaging>pom</packaging>
	  <version>1.0</version>
	  <dependencies>
	    <dependency>
	      <groupId>org.apache.lucene</groupId>
	      <artifactId>lucene-core</artifactId>
	      <version>6.0.0</version>
	    </dependency>
	    <dependency>
	      <groupId>org.apache.lucene</groupId>
	      <artifactId>lucene-analyzers-common</artifactId>
	      <version>6.0.0</version>
	    </dependency>
	  </dependencies>
	  <modules>
	    <module>server</module>
	    <module>crawler</module>
	    <module>common</module>
	  </modules>
	  <build>
	    <plugins>
	      <plugin>
	        <groupId>org.apache.maven.plugins</groupId>
	        <artifactId>maven-compiler-plugin</artifactId>
	        <version>3.5.1</version>
	        <configuration>
	          <source>1.8</source>
	          <target>1.8</target>
	        </configuration>
	      </plugin>
	    </plugins>
	  </build>
	</project>

*crawler/pom.xml*

	:::xml
	<project xmlns="http://maven.apache.org/POM/4.0.0" 
	         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
	                             http://maven.apache.org/maven-v4_0_0.xsd">
	  <modelVersion>4.0.0</modelVersion>
	  <parent>
	    <groupId>tutorial.lucene</groupId>
	    <artifactId>parent</artifactId>
	    <version>1.0</version>
	  </parent>
	  <artifactId>crawler</artifactId>
	  <packaging>jar</packaging>
	  <name>Lucene Tutorial Crawler</name>
	  <dependencies>
	    <dependency>
	      <groupId>log4j</groupId>
	      <artifactId>log4j</artifactId>
	      <version>1.2.17</version>
	    </dependency>
	    <dependency>
	      <groupId>org.jsoup</groupId>
	      <artifactId>jsoup</artifactId>
	      <version>1.9.1</version>
	    </dependency>
	    <dependency>
	      <groupId>tutorial.lucene</groupId>
	      <artifactId>common</artifactId>
	      <version>1.0</version>
	    </dependency>
	  </dependencies>
	</project>

*common/pom.xml*

	:::xml
	<project xmlns="http://maven.apache.org/POM/4.0.0" 
	         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
	                             http://maven.apache.org/maven-v4_0_0.xsd">
	  <modelVersion>4.0.0</modelVersion>
	  <parent>
	    <groupId>tutorial.lucene</groupId>
	    <artifactId>parent</artifactId>
	    <version>1.0</version>
	  </parent>
	  <artifactId>common</artifactId>
	  <packaging>jar</packaging>
	  <name>Crawler and Server Shared Constants</name>
	</project>

*crawler/src/main/java/crawler/SimpleCrawler.java*

    :::java
    package crawler;

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

        private static final Logger logger = Logger.getLogger(SimpleCrawler.class.getName());

        private final ICrawlEvents events;
        private NavigableSet<String> linksToCrawl;
        private Set<String> linksCrawled;
        private final String seed;

        public SimpleCrawler(final String seed, final ICrawlEvents events) {
            this.events = events;
            this.seed = seed;
        };

        public boolean hasLinksToCrawl() {
            return !this.linksToCrawl.isEmpty();
        }

        public void run() {

            this.linksCrawled = new HashSet<String>();
            this.linksToCrawl = new TreeSet<String>();
            this.linksToCrawl.add(this.seed);

            while (this.hasLinksToCrawl()) {

                final String strURL = this.linksToCrawl.pollFirst();
                this.linksCrawled.add(strURL);

                try {
                    final String html = HtmlHelper.download(strURL);

                    int linksAdded = 0;
                    for (final String l : HtmlHelper.extractLinks(html, this.seed)) {
                        if (this.events.shouldVisit(l, this.seed) && !this.linksCrawled.contains(l)
                                && !this.linksToCrawl.contains(l)) {
                            this.linksToCrawl.add(l);
                            linksAdded++;
                        }
                    }

                    SimpleCrawler.logger.info(
                        String.format("Fetched: [%s] %d new links", strURL, linksAdded));
                    this.events.onVisit(strURL, html, this.seed);
                } catch (final Exception ex) {
                    SimpleCrawler.logger.error(String.format("Fetch error: [%s].", strURL), ex);
                }
            }
        }
    }

Все ссылки хранятся в оперативной памяти - для маленьких и средних по величине сайтов такое решение вполне приемлемо. С внешним миром *crawler* общается посредством интерфейса `ICrawlEvents`, а с HTML работает через статический класс `HtmlHelper`. Последний активно использует прекрасную библиотеку для работы с *Html* в *Java* - [JSoup](http://jsoup.org/){:rel="nofollow"}, которая работает в стиле JQuery посредством *css-селекторов*. Также стоит обратить внимание на **обязательное** наличие временной задержки (*politeness*) между Http-запросами к сайту - большинство хостеров следят за количеством запросов с одного IP, поэтому при работе с реальным веб-сайтом за пределами localhost необходимо соблюдать толерантность, если не хотите получить бан конечно.

*crawler/src/main/java/crawler/HtmlHelper.java*

    :::java
    package crawler;

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
        public static Collection<String> extractLinks(final String html, final String seed) {

            final Document document = Jsoup.parse(html, seed);
            final Set<String> linksSet = new HashSet<String>();
            for (final Element link : document.select("a[href]")) {
                final String strLink = link.attr("abs:href").trim().toLowerCase();
                if (!strLink.isEmpty()) {
                    linksSet.add(strLink);
                }
            }

            return Collections.unmodifiableCollection(linksSet);
        }

        public static String download(final String link) throws IOException, InterruptedException {

            IOException ioe;
            int retry = 5;

            do {
                try {

                    /* Crawling a real web site politeness > 5s */

                    Thread.sleep(1);
                    final Document bDoc = Jsoup.connect(link).userAgent("Mozilla").timeout(30000).get();
                    return bDoc.html();
                } catch (final IOException ex) {
                    ioe = ex;
                }
            } while (--retry > 0);

            throw ioe;
        }

        public static String extractTitle(final String html) {
            final Document doc = Jsoup.parse(html);
            final Elements elements = doc.select("table table div table font");
            if (elements != null && !elements.isEmpty()) {
                return elements.first().text();
            }
            return null;
        }

        public static String extractContent(final String html) {
            final Document doc = Jsoup.parse(html);
            final Elements elements = doc.select("table table div table div");
            if (elements != null && !elements.isEmpty()) {
                return elements.first().text();
            }
            return doc.select("table table div table").first().text();
        }
    }

Теперь точка входа, которая будет запускать *crawler* и передавать необходимую информацию соответствующему классу `LuceneIndexer` для индексации:

*crawler/src/main/java/crawler/App.java*

    :::java
    package crawler;

    import org.apache.log4j.Logger;

    public class App {

        private static final Logger logger = Logger.getLogger(App.class.getName());

        private final static String crawlSeed = "http://localhost:8080";

        public static void main(final String[] args) {
            try (final LuceneIndexer luceneIndexer = new LuceneIndexer()) {

                luceneIndexer.new_index();

                /* Start crawler and perform indexing */

                new SimpleCrawler(App.crawlSeed, new SimpleCrawler.ICrawlEvents() {

                    /* Proceed page - add to Lucene index */

                    @Override
                    public void onVisit(final String url, final String html, final String seed) {
                        luceneIndexer.add(url, html);
                    }

                    /* Skip any external links */

                    @Override
                    public boolean shouldVisit(final String url, final String seed) {
                        return url.startsWith(seed);
                    }

                }).run();

            } catch (final Exception ex) {
                App.logger.error("Unable to start !", ex);
            }
        }
    }

Таким образом мы подошли, пожалуй, к ключевому моменту данной статьи - процессу создания индекса в *Lucene*. Главным классом тут является `IndexWriter` - которому необходимо знать директорию, где будут храниться файлы индекса. Опция `OpenMode.CREATE` указывает на необходимость удалять старый индекс, если тот на момент инициализации в указанной директории уже существует. Согласно [документации](https://lucene.apache.org/core/6_0_0/core/org/apache/lucene/index/IndexWriter.html){:rel="nofollow"}, `IndexWriter` потокобезопасный:

*crawler/src/main/java/crawler/LuceneIndexer.java*

    :::java
    package crawler;

    import java.io.Closeable;
    import java.io.IOException;

    import org.apache.log4j.Logger;
    import org.apache.lucene.document.Document;
    import org.apache.lucene.document.Field;
    import org.apache.lucene.document.FieldType;
    import org.apache.lucene.index.IndexOptions;
    import org.apache.lucene.index.IndexWriter;
    import org.apache.lucene.index.IndexWriterConfig;
    import org.apache.lucene.index.IndexWriterConfig.OpenMode;
    import org.apache.lucene.store.Directory;
    import org.apache.lucene.store.FSDirectory;

    import common.LuceneBinding;

    class LuceneIndexer implements Closeable {
        private static final Logger logger = Logger.getLogger(LuceneIndexer.class.getName());

        /* IndexWriter is completely thread safe */

        private IndexWriter indexWriter = null;

        @Override
        public void close() throws IOException {
            if (this.indexWriter != null) {
                LuceneIndexer.logger.info("Closing Index < " + 
                        LuceneBinding.INDEX_PATH + " > NumDocs: " + this.indexWriter.numDocs());
                this.indexWriter.close();
                this.indexWriter = null;
                LuceneIndexer.logger.info("Index Closed OK!");
            } else {
                throw new IOException("Index already closed");
            }
        }

        public void new_index() throws IOException {
            final Directory directory = FSDirectory.open(LuceneBinding.INDEX_PATH);
            final IndexWriterConfig iwConfig = new IndexWriterConfig(LuceneBinding.getAnalyzer());
            iwConfig.setOpenMode(OpenMode.CREATE);
            this.indexWriter = new IndexWriter(directory, iwConfig);
        }

        public void add(final String url, final String html) {

            final String title = HtmlHelper.extractTitle(html);
            final String content = HtmlHelper.extractContent(html);

            LuceneIndexer.logger.info("***** " + url + " *****");
            if (title != null) {
                LuceneIndexer.logger.info(title);
            }
            LuceneIndexer.logger.info(content);

            final Document doc = new Document();

            final FieldType urlType = new FieldType();
            urlType.setIndexOptions(IndexOptions.DOCS);
            urlType.setStored(true);
            urlType.setTokenized(false);
            urlType.setStoreTermVectorOffsets(false);
            urlType.setStoreTermVectorPayloads(false);
            urlType.setStoreTermVectorPositions(false);
            urlType.setStoreTermVectors(false);
            doc.add(new Field(LuceneBinding.URI_FIELD, url, urlType));

            final FieldType tokType = new FieldType();
            tokType.setIndexOptions(IndexOptions.DOCS_AND_FREQS_AND_POSITIONS_AND_OFFSETS);
            tokType.setStored(true);
            tokType.setTokenized(true);
            tokType.setStoreTermVectorOffsets(true);
            tokType.setStoreTermVectorPayloads(true);
            tokType.setStoreTermVectorPositions(true);
            tokType.setStoreTermVectors(true);
            if (title != null) {
                doc.add(new Field(LuceneBinding.TITLE_FIELD, title, tokType));
            }
            doc.add(new Field(LuceneBinding.CONTENT_FIELD, content, tokType));

            try {
                if (this.indexWriter != null) {
                    this.indexWriter.addDocument(doc);
                }
            } catch (final IOException ex) {
                LuceneIndexer.logger.error(ex);
            }
        }
    }

Если внимательно посмотреть на содержимое каждой html-странички нашего сайта, то помимо <span style="text-decoration: line-through;">не</span>навязчивой рекламы и прочего мусора можно выделить две единицы более - менее полезной информации: *название* (title) публикации и её *содержимое* (content). Извлечь данную информацию из html нам поможет уже упомянутая выше библиотека *JSoup*, после чего можно добавлять `Document` с соответствующими полями в индекс *Lucene*.

*Lucene* может сохранять / извлекать [различные типы данных](https://lucene.apache.org/core/6_0_0/core/org/apache/lucene/document/Field.html){:rel="nofollow"}. В нашем случае все данные текстовые, первое поле - url, параметр `setStored(true)` указывает на необходимость хранить в индексе оригинальное (неизменное) значение, а остальный `false` на то, что поиск по этому полю осуществляться не будет, т.е. это поле несет дополнительную информацию о найденном документе, которую мы планируем использовать в будущем. Поля *title* и *content* индексируются одинаково - `setTokenized(true)` указывает на то, что по данному полю будет осуществляться поиск а также просит *Lucene* задействовать механизмы анализа содержимого данного документа на этапе создания индекса (самый простой пример анализа - выделение слов из набора букв и пробелов между ними), параметр `setStoreTermVector(true)` позволяет сохранить дополнительную информацию о позициях тех или иных слов в теле документа - такой подход значительно ускоряет процесс подсветки найденных вхождений.

Класс `LuceneBinding` - это своеобразный мост между индексатором (*crawler*) и поиском (`SearchServlet`), он содержит общую информацию и используется совместно обоими приложениями:

*common/src/main/java/common/LuceneBinding.java*

    :::java
    package common;

    import java.nio.file.Path;
    import java.nio.file.Paths;

    import org.apache.lucene.analysis.Analyzer;
    import org.apache.lucene.analysis.standard.StandardAnalyzer;

    /* This class is used both by Crawler and SearchServlet */

    public final class LuceneBinding {
        public static final Path INDEX_PATH = Paths.get(
            System.getProperty("user.home"), "lucene-tutorial-index");
        public static final String URI_FIELD = "uri";
        public static final String TITLE_FIELD = "title";
        public static final String CONTENT_FIELD = "content";

        public static Analyzer getAnalyzer() {
            return new StandardAnalyzer();
        }
    }

###Сборка и запуск

Перед запускам crawler должен быть запущен *Jetty* сервер с сайтом, который мы хотим проиндексировать. Чтобы корректно отображались русские буквы в консоли *Windows* может понадобиться обозначить правильную кодировку *Cp866* в файле *crawler/src/main/resources/log4j.properties*

    :::bash
    ~$ mvn clean install && bash -c 'mvn -pl server/ jetty:run & sleep 10 && \
        mvn -pl crawler/ exec:java -Dexec.mainClass="crawler.App" & \
        trap "kill -TERM -$$" SIGINT ; wait'
    ...
    INFO [crawler.App.main()] Closing Index < /home/oleg/lucene-tutorial-index > NumDocs: 53
    INFO [crawler.App.main()] Index Closed OK!
    Ctrl+C

[Далее]({filename}../2012-10-21-lucene-real-world---check-index/2012-10-21-lucene-real-world---check-index.md) мы бегло заглянем в индекс, после чего реализуем простой поиск.

[Исходники]({attach}lucene-tutorial.zip)
