title: Lucene - языковые анализаторы
category: Java
tags: Lucene, Stemming


Как Вам [поиск]({filename}../2012-10-21-lucene-real-world---simple-search/2012-10-21-lucene-real-world---simple-search.md) ? Мы вводим в качестве запроса слово **сад** и получаем **0** (НОЛЬ) результатов, в то время как это же слово в другом падеже - **сады** - даёт целых **6** (ШЕСТЬ) ! Всё дело в том, что в процессе индексации / поиска использовался стандартный анализатор текста - `StandardAnalyzer`, который ничего не знает об особенностях того или иного языка. Какие вообще существуют алгоритмы для *программного* выделения основы слова ? Очень распространёнными, и, что немаловажно в контексте процесса индексации - быстрыми, являются алгоритмы [стемминга](http://ru.wikipedia.org/wiki/%D0%A1%D1%82%D0%B5%D0%BC%D0%BC%D0%B8%D0%BD%D0%B3){:rel="nofollow"}, среди которых, наиболее популярными и часто используемыми являются [Стеммеры Портера](http://ru.wikipedia.org/wiki/%D0%A1%D1%82%D0%B5%D0%BC%D0%BC%D0%B5%D1%80_%D0%9F%D0%BE%D1%80%D1%82%D0%B5%D1%80%D0%B0){:rel="nofollow"} - впервые опубликованные ещё в далёком 1980 году. Введите ОДНО слово, выберите язык и нажмите кнопку "**Стеммер!**":

<script type="text/javascript" src="{attach}stem.js"> </script>
<script type="text/javascript" src="{attach}Snowball.min.js"> </script>

<p>
<input maxlength="33" size="33" id="jssnowball_input" value="нежадный" style="text-align: left; padding:.3em;" type="text"/>
<select id="jssnowball_language" style="padding:.2em;"><option value="russian">Русский</option><option value="danish">danish</option><option value="dutch">dutch</option><option value="finnish">finnish</option><option value="french">french</option><option value="german">german</option><option value="hungarian">hungarian</option><option value="italian">italian</option><option value="norwegian">norwegian</option><option value="portuguese">portuguese</option><option value="english">english</option><option value="spanish">spanish</option><option value="swedish">swedish</option><option value="romanian">romanian</option><option value="turkish">turkish</option></select>
<button style="padding:.2em;" type="button" onclick="jssnowball_print();"><noscript><span style="color:red;">Включите JavaScript ! </span></noscript>Стеммер!</button>
</p>
<p id="jssnowball_result">
</p>

Хорошая новость - в *Lucene* уже есть готовые анализаторы для многих распространённых языков, в том числе и для русского, которые можно взять из коробки. Вопрос тут несколько в иной плоскости - как организовать поиск, задействовав одновременно несколько из них - для русскоязычных сайтов было бы неплохо предусмотреть и Английский (`EnglishAnalyzer`) и Русский (`RussianAnalyzer`). Можно попробовать автоматически определять язык текста и задействовать соответствующий анализатор, однако у такого решения есть подводный камень. Всё дело в том, что точность определения языка очень сильно зависит от объёма текста - чем он меньше, тем больше вероятность ошибки и это особенно актуально для процесса поиска, когда пользователь вводит всего несколько слов в строку запроса. Очевидно, что алгоритм с использованием автоматического определения языка необходимо дорабатывать.

В данном примере будет представлено альтернативное решение, реализованное исключительно средствами *Lucene*. В структуре индекса добавятся дополнительные соответствующие конкретному языку поля. Для каждого поля в *Lucene* можно задать свой анализатор, используя класс `PerFieldAnalyzerWrapper`:

*jLucene/server/webapps/search/src/nongreedy/LuceneBinding.java*

    :::java
    package nongreedy;

    import java.util.HashMap;
    import java.util.Map;

    import org.apache.lucene.analysis.Analyzer;
    import org.apache.lucene.analysis.PerFieldAnalyzerWrapper;
    import org.apache.lucene.analysis.en.EnglishAnalyzer;
    import org.apache.lucene.analysis.ru.RussianAnalyzer;
    import org.apache.lucene.analysis.standard.StandardAnalyzer;
    import org.apache.lucene.util.Version;

    /* This class is used both by Crawler and SearchServlet */

    public final class LuceneBinding {
    	public static final Version CURRENT_LUCENE_VERSION = 
                Version.LUCENE_35;

    	public static final String URI_FIELD = "uri";
    	public static final String TITLE_FIELD = "title";
    	public static final String CONTENT_FIELD = "content";

    	/* Russian */

    	public static final String RUS_TITLE_FIELD = "rustitle";
    	public static final String RUS_CONTENT_FIELD = "ruscontent";

    	/* English */

    	public static final String ENG_TITLE_FIELD = "engtitle";
    	public static final String ENG_CONTENT_FIELD = "engcontent";

    	public static Analyzer getAnalyzer() {

    		Map<String, Analyzer> analyzers = 
                        new HashMap<String, Analyzer>();
    		analyzers.put(RUS_TITLE_FIELD, new RussianAnalyzer(
    				CURRENT_LUCENE_VERSION));
    		analyzers.put(RUS_CONTENT_FIELD, new RussianAnalyzer(
    				CURRENT_LUCENE_VERSION));
    		analyzers.put(ENG_TITLE_FIELD, new EnglishAnalyzer(
    				CURRENT_LUCENE_VERSION));
    		analyzers.put(ENG_CONTENT_FIELD, new EnglishAnalyzer(
    				CURRENT_LUCENE_VERSION));

    		return new PerFieldAnalyzerWrapper(new StandardAnalyzer(
    				CURRENT_LUCENE_VERSION), analyzers);
    	}
    }

Данные поля необходимо добавить в индекс - можно с параметром `Store.NO`, поскольку в нашем случае у документа `Document` уже имеются соответствующие поля, хранящие оригинальные значения (созданные с параметром `Store.YES`) - зачем дублировать информацию и тем самым раздувать размеры индекса.

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

            /* Russian use Store.NO - we already have original value */

            if (null != title)
                doc.add(new Field(LuceneBinding.RUS_TITLE_FIELD, 
                        title, Store.NO, Index.ANALYZED, 
                        TermVector.WITH_POSITIONS_OFFSETS));
            doc.add(new Field(LuceneBinding.RUS_CONTENT_FIELD, 
                    content, Store.NO, Index.ANALYZED, 
                    TermVector.WITH_POSITIONS_OFFSETS));

            /* English use Store.NO */

            if (null != title)
                doc.add(new Field(LuceneBinding.ENG_TITLE_FIELD, 
                        title, Store.NO, Index.ANALYZED, 
                        TermVector.WITH_POSITIONS_OFFSETS));
            doc.add(new Field(LuceneBinding.ENG_CONTENT_FIELD, 
                    content, Store.NO, Index.ANALYZED, 
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

Для поиска по нескольким полям одновременно используем уже известный `MultiFieldQueryParser`, просто расширив перечень интересующих нас полей:

*jLucene/server/webapps/search/src/nongreedy/QueryHelper.java*

    :::java
    package nongreedy;

    import org.apache.lucene.queryParser.MultiFieldQueryParser;
    import org.apache.lucene.queryParser.ParseException;
    import org.apache.lucene.queryParser.QueryParser;
    import org.apache.lucene.search.Query;

    final class QueryHelper {
        static Query generate(String story) throws ParseException {
            QueryParser parser = new MultiFieldQueryParser(
                    LuceneBinding.CURRENT_LUCENE_VERSION, new String[] {
                            LuceneBinding.TITLE_FIELD, 
                            LuceneBinding.CONTENT_FIELD,
                            /* Russian */
                            LuceneBinding.RUS_TITLE_FIELD,
                            LuceneBinding.RUS_CONTENT_FIELD,
                            /* English */
                            LuceneBinding.ENG_TITLE_FIELD,
                            LuceneBinding.ENG_CONTENT_FIELD },
                    LuceneBinding.getAnalyzer());

            /* Operator OR is used by default */

            parser.setDefaultOperator(QueryParser.Operator.AND);

            return parser.parse(QueryParser.escape(story));
        }
    }

После переидексации сайта результаты поисковой выдачи выглядят уже намного лучше:

![screenshot]({attach}linux_search_stem_sad.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}linux_search_stem_sad1.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}linux_search_stem_test.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}linux_search_stem_tests.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}win_search_stem_sad.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}win_search_stem_sad1.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}win_search_stem_test.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}win_search_stem_tests.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-28-lucene-real-world---highlighting/2012-10-28-lucene-real-world---highlighting.md) реализуем подсветку найденных вхождений.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Lucene_Stemmers){:rel="nofollow"}.
