title: Lucene - автозаполнение ввода пользователя
category: Java
tags: Lucene, maven, AJAX

Используя подсказки в процессе ввода [поискового]({filename}../2016-05-15-lucene-facet/2016-05-15-lucene-facet.md) запроса можно быстрее искать нужную информацию. Поисковые подсказки - это схожие с вашим запросом термины. Они появляются на экране по мере того, как вы вводите в строку поиска запрос. Для данного процесса критически важна скорость реакции на ввод пользователя, поэтому на серверной части ускорить процесс поможет специально заточенный индекс / модель данных, а на стороне клиента неплохо бы использовать [AJAX](https://ru.wikipedia.org/wiki/AJAX){:rel="nofollow"} дабы не перезагружать каждый раз HTML-страницу целиком при изменении поискового запроса. На картинке показан результат работы алгоритма [AnalyzingSuggester](https://lucene.apache.org/core/6_0_0/suggest/org/apache/lucene/search/suggest/analyzing/AnalyzingSuggester.html){:rel="nofollow"}, который можно запустить скачав исходники в конце текущего материала.

![screenshot]({attach}suggest.gif){:style="width:100%; border:1px solid #ddd;"}

Первым делом нужно добавить в мульти-модульный **maven** проект новую зависимость ```lucene-suggest```:

*src/pom.xml*

    :::xml
    <project xmlns="http://maven.apache.org/POM/4.0.0" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <groupId>tutorial.lucene</groupId>
      <artifactId>parent</artifactId>
      <packaging>pom</packaging>
      <version>1.0</version>
      <properties>
      <lucene.version>6.0.0</lucene.version>
      </properties>
      <dependencies>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-core</artifactId>
          <version>${lucene.version}</version>
        </dependency>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-analyzers-common</artifactId>
          <version>${lucene.version}</version>
        </dependency>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-facet</artifactId>
          <version>${lucene.version}</version>
        </dependency>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-suggest</artifactId>
          <version>${lucene.version}</version>
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

С помощью методов ```store``` / ```load``` в классе [AnalyzingSuggester](https://lucene.apache.org/core/6_0_0/suggest/org/apache/lucene/search/suggest/analyzing/AnalyzingSuggester.html){:rel="nofollow"} можно сохранить / восстанавливать модель данных автодополнения в файл для последующего быстрого старта. Поскольку эта логика используется как при индексации так и при поиске, она вынесена в их общий модуль ```LuceneBinding```. С помощью метода ```weight()``` задаётся приоритет для фраз автодополнения - в данном случае наиболее короткие фразы будут первыми в списке:

*src/common/src/main/java/common/LuceneBinding.java*

    :::java
    package common;

    import java.io.IOException;
    import java.io.InputStream;
    import java.io.OutputStream;
    import java.nio.file.Files;
    import java.nio.file.Path;
    import java.nio.file.Paths;
    import java.util.Set;

    import org.apache.lucene.analysis.Analyzer;
    import org.apache.lucene.analysis.standard.StandardAnalyzer;
    import org.apache.lucene.facet.FacetsConfig;
    import org.apache.lucene.search.spell.Dictionary;
    import org.apache.lucene.search.suggest.InputIterator;
    import org.apache.lucene.search.suggest.analyzing.AnalyzingSuggester;
    import org.apache.lucene.store.FSDirectory;
    import org.apache.lucene.util.BytesRef;

    /* This class is used both by Crawler and SearchServlet */

    public final class LuceneBinding {
      private static final Path ROOT = Paths.get(System.getProperty("user.home"), "lucene-tutorial-index");
      public static final Path SEARCH_INDEX_PATH = LuceneBinding.ROOT.resolve("search");
      public static final Path TAXO_INDEX_PATH = LuceneBinding.ROOT.resolve("taxo");
      public static final Path SUGGEST_INDEX_PATH = LuceneBinding.ROOT.resolve("suggest");

      public static final String FIELD_ID = "id";
      public static final String FIELD_TITLE = "title";
      public static final String FIELD_CONTENT = "content";
      public static final String FIELD_CATEGORY = "category";
      public static final String FIELD_DIRECTOR = "director";
      public static final String FIELD_RATE = "rate";

      public static final String FACET_DIRECTOR = "Director";
      public static final String FACET_DATE = "Release Date";
      public static final String FACET_CATEGORY = "Category";

      public static final int SUGGEST_MAX_SHINGLES = 5;

      public static FacetsConfig getFacetsConfig() {
        final FacetsConfig config = new FacetsConfig();
        config.setHierarchical(LuceneBinding.FACET_DATE, true);
        config.setMultiValued(LuceneBinding.FACET_CATEGORY, true);
        return config;
      }

      public static Analyzer getAnalyzer() {
        return new StandardAnalyzer();
      }

      public static final class Suggester extends AnalyzingSuggester {
        private static final Path ser = LuceneBinding.SUGGEST_INDEX_PATH.resolve("serialized");

        private Suggester() throws IOException {
          super(FSDirectory.open(LuceneBinding.SUGGEST_INDEX_PATH.resolve("tmp")), 
            "", LuceneBinding.getAnalyzer());
        }

        public static void store(final Dictionary input) throws IOException {
          final Suggester suggester = new Suggester();
          suggester.build(new InputIterator() {
            final InputIterator i = input.getEntryIterator();
            private BytesRef c;
            final int MAX_TOKEN_LENGTH = LuceneBinding.SUGGEST_MAX_SHINGLES
                * (1 + StandardAnalyzer.DEFAULT_MAX_TOKEN_LENGTH);

            @Override
            public BytesRef next() throws IOException {
              this.c = this.i.next();
              return this.c;
            }

            @Override
            public long weight() {
              // short phrases more important
              return this.MAX_TOKEN_LENGTH - this.c.length;
            }

            @Override
            public BytesRef payload() {
              return this.i.payload();
            }

            @Override
            public boolean hasPayloads() {
              return this.i.hasPayloads();
            }

            @Override
            public Set<BytesRef> contexts() {
              return this.i.contexts();
            }

            @Override
            public boolean hasContexts() {
              return this.i.hasContexts();
            }
          });

          try (final OutputStream os = Files.newOutputStream(Suggester.ser)) {
            suggester.store(os);
          }
        }

        public static Suggester load() throws IOException {
          final Suggester suggester = new Suggester();
          try (final InputStream is = Files.newInputStream(Suggester.ser)) {
            suggester.load(is);
          }
          return suggester;
        }
      }
    }

Индекс для автодополнения будет строится по двум полям ```suggestIndexer.add(title, description)```. Комбинации слов достигаются с помощью [ShingleAnalyzerWrapper](https://lucene.apache.org/core/6_0_0/analyzers-common/org/apache/lucene/analysis/shingle/ShingleAnalyzerWrapper.html){:rel="nofollow"}:  

*src/crawler/src/main/java/crawler/SugestIndexer.java*

    :::java
    package crawler;

    import java.io.Closeable;
    import java.io.IOException;
    import java.nio.file.Path;

    import org.apache.lucene.analysis.shingle.ShingleAnalyzerWrapper;
    import org.apache.lucene.document.Document;
    import org.apache.lucene.document.Field.Store;
    import org.apache.lucene.document.TextField;
    import org.apache.lucene.index.DirectoryReader;
    import org.apache.lucene.index.IndexReader;
    import org.apache.lucene.index.IndexWriter;
    import org.apache.lucene.index.IndexWriterConfig;
    import org.apache.lucene.index.IndexWriterConfig.OpenMode;
    import org.apache.lucene.search.spell.LuceneDictionary;
    import org.apache.lucene.store.FSDirectory;

    import common.LuceneBinding;
    import common.LuceneBinding.Suggester;

    public class SugestIndexer implements Closeable {

      private final IndexWriter writer;
      public static final String FIELD_SUGGEST = "SUGGEST";
      private static final Path SHINGLES_INDEX_PATH = LuceneBinding.SUGGEST_INDEX_PATH.resolve("shingles");

      public SugestIndexer() throws IOException {
        final IndexWriterConfig iwConfig = new IndexWriterConfig(
            new ShingleAnalyzerWrapper(LuceneBinding.getAnalyzer(), LuceneBinding.SUGGEST_MAX_SHINGLES));
        iwConfig.setOpenMode(OpenMode.CREATE);
        this.writer = new IndexWriter(FSDirectory.open(SugestIndexer.SHINGLES_INDEX_PATH), iwConfig);
      }

      public void add(final String... items) throws IOException {
        final Document doc = new Document();
        for (final String item : items) {
          doc.add(new TextField(SugestIndexer.FIELD_SUGGEST, item, Store.NO));
        }
        this.writer.addDocument(doc);
      }

      @Override
      public void close() throws IOException {
        this.writer.close();
        try (final IndexReader reader = DirectoryReader.open(this.writer.getDirectory())) {
          Suggester.store(new LuceneDictionary(reader, SugestIndexer.FIELD_SUGGEST));
        }
        // TODO: we can remove SHINGLES_INDEX_PATH directory now
      }
    }

Сервлет отдаёт все варианты автодополнений в JSON-формате ```http://localhost:8080/api/suggest?q=космос```:

*src/server/src/main/java/server/SuggestServlet.java*

    :::java
    package server;

    import java.io.IOException;
    import java.util.AbstractMap.SimpleEntry;
    import java.util.ArrayList;
    import java.util.Collection;
    import java.util.HashMap;
    import java.util.Map;
    import java.util.stream.Collectors;
    import java.util.stream.Stream;

    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;

    import org.json.JSONArray;

    import common.LuceneBinding.Suggester;

    public class SuggestServlet extends HttpServlet {

      private static volatile Suggester suggester;
      private static int MAX_SUGGESTS = 22;

      @Override
      public void doGet(final HttpServletRequest req, final HttpServletResponse res)
          throws ServletException, IOException {

        if (SuggestServlet.suggester == null) {
          synchronized (SuggestServlet.class) {
            if (SuggestServlet.suggester == null) {
              SuggestServlet.suggester = Suggester.load();
            }
          }
        }

        final String query = req.getParameter("q");
        final Collection<?> lookupResultList = SuggestServlet.suggester
            .lookup(query, false, SuggestServlet.MAX_SUGGESTS).stream()
            .sorted((e1, e2) -> Long.compare(e2.value, e1.value))
            .map(v -> Stream
                .of(new SimpleEntry<>("key", v.key), new SimpleEntry<>("hi", v.highlightKey),
                    new SimpleEntry<>("val", v.value))
                .collect(HashMap::new, (m, e) -> m.put(e.getKey(), e.getValue()), Map::putAll))
            .collect(Collectors.toCollection(ArrayList::new));

        final JSONArray json = new JSONArray(lookupResultList);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(json.toString());
      }
    }

Сборка и запуск:

	:::bash
	~$ cd src
	~$ mvn clean install
	~$ mvn -pl crawler/ exec:java -Dexec.mainClass="crawler.App"
	~$ mvn -pl server/ jetty:run


[Исходники]({attach}lucene-tutorial.zip)
