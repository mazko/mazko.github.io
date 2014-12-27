title: Lucene - постраничный поиск
category: Java
tags: Lucene


С [индексом]({filename}../2012-10-21-lucene-real-world---check-index/2012-10-21-lucene-real-world---check-index.md) в **Lucene**, кажется, разобрались - на очереди поиск. Давайте немножко подумаем. Предположим, поиском будет заниматься класс `LuceneSearcher`, а результатом поиска должен быть класс `TakeResult`, в котором будет достаточно информации для реализации постраничной выдачи. Что может измениться в будущем ? На данном этапе мы можем предположить, что единицей поиска будет класс в котором будут два поля - *content* и *title*. А если изменится сайт или нам понадобиться какая-то дополнительная информация в результатах выдачи ? Процесс создания и наполнения класса - единицы поиска лучше вынести за пределы `LuceneSearcher`, для этой цели можно задействовать механизм *шаблонов* (*generic*):

*jLucene/server/webapps/search/src/nongreedy/TakeResult.java*

    :::java
    package nongreedy;

    import java.io.IOException;
    import java.util.Collection;
    import java.util.Collections;

    import org.apache.lucene.queryParser.ParseException;

    public final class TakeResult<T> {
        public final int totalHits;
        private final Collection<T> items;

        protected TakeResult(int totalHits, Collection<T> items) {
            this.totalHits = totalHits;
            this.items = items;
        }

        public Collection<T> getItems() {
            if (null != items)
                return Collections.unmodifiableCollection(items);
            return null;
        }

        interface ITakeble<T> {
            TakeResult<T> Take(int count, int start) 
                    throws InstantiationException, IOException, 
                           IllegalAccessException, ParseException;
        }
    }

*jLucene/server/webapps/search/src/nongreedy/LuceneSearcher.java*

    :::java
    package nongreedy;

    import java.io.File;
    import java.io.IOException;
    import java.util.ArrayList;

    import nongreedy.TakeResult.ITakeble;

    import org.apache.lucene.index.CorruptIndexException;
    import org.apache.lucene.index.IndexReader;
    import org.apache.lucene.queryParser.ParseException;
    import org.apache.lucene.search.IndexSearcher;
    import org.apache.lucene.search.Query;
    import org.apache.lucene.search.ScoreDoc;
    import org.apache.lucene.search.TopDocs;
    import org.apache.lucene.search.TopScoreDocCollector;
    import org.apache.lucene.store.Directory;
    import org.apache.lucene.store.FSDirectory;

    abstract class Aggregator<T> {
        protected Query query;
        protected IndexSearcher indexSearcher;

        abstract T aggregate(ScoreDoc sd) 
            throws IOException, CorruptIndexException;
    }

    class LuceneSearcher<T, A extends Aggregator<T>> 
        implements ITakeble<T> {

        private final String story;
        private final Class<A> classA;
        private final boolean docsScoredInOrder;

        /* IndexReader is thread safe - one instance for all requests */

        private static volatile IndexReader indexReader;

        LuceneSearcher(Class<A> classA, String indexDir, String story)
                throws IOException {

            /* unlimited search time, unordered results */

            this(classA, indexDir, story, false);
        }

        LuceneSearcher(Class<A> classA, String indexDir, String story,
                boolean docsScoredInOrder) throws IOException {

            this.story = story;
            this.classA = classA;
            this.docsScoredInOrder = docsScoredInOrder;

            if (null == indexReader) {
                synchronized (LuceneSearcher.class) {
                    if (null == indexReader) {
                        Directory dir = FSDirectory.open(
                            new File(indexDir));
                        indexReader = IndexReader.open(dir);
                    }
                }
            }
        }

        @Override
        public TakeResult<T> Take(int count, int start)
                throws InstantiationException, IllegalAccessException,
                ParseException, IOException {

            int nDocs = start + count;

            Query query = QueryHelper.generate(story);
            IndexSearcher indexSearcher = new IndexSearcher(indexReader);
            TopScoreDocCollector collector = TopScoreDocCollector.create(
                    Math.max(nDocs, 1), docsScoredInOrder);
            indexSearcher.search(query, collector);
            TopDocs topDocs = collector.topDocs();

            if (nDocs <= 0)
                return new TakeResult<T>(topDocs.totalHits, null);

            ScoreDoc[] scoreDocs = topDocs.scoreDocs;
            int length = scoreDocs.length - start;

            if (length <= 0)
                return new TakeResult<T>(topDocs.totalHits, null);

            ArrayList<T> items = new ArrayList<T>(length);
            A aggregator = classA.newInstance();
            aggregator.query = query;
            aggregator.indexSearcher = indexSearcher;

            for (int i = start; i < scoreDocs.length; i++)
                items.add(i - start, aggregator.aggregate(scoreDocs[i]));

            return new TakeResult<T>(topDocs.totalHits, items);
        }
    }

Процесс создания нового экземпляра класса `IndexReader`, в зависимости от размера текущего индекса, может быть очень затратным с точки зрения ресурсов системы - CPU и ОЗУ. Поэтому в документации настоятельно рекомендуется создать в программе ОДИН экземпляр данного класса и использовать его совместно между всеми потоками приложения по мере необходимости - `IndexReader` изначально проектировался как [потокобезопасный](http://lucene.apache.org/core/old_versioned_docs/versions/3_5_0/api/core/org/apache/lucene/index/IndexReader.html){:rel="nofollow"} (thread safe). С учётом вышесказанного в нашем случае (см. *LuceneSearcher.java*) `IndexReader` может существовать только в одном экземпляре, используется *ленивая инициализация* по принципу double checked locking ([блокировка с двойной проверкой](http://ru.wikipedia.org/wiki/Double_checked_locking){:rel="nofollow"}), в связи с чем поле `indexReader` объявлено как `volatile`. Если содержимое индекса измениться извне (что вполне возможно в реальных условиях), `IndexReader` необходимо обновить - для этой цели целесообразней не создавать новый экземпляр, а лучше использовать специальный метод `IndexReader.reopen()`. В противном случае, если не обновить экземпляр `IndexReader`, новые данные, добавленные в индекс, в результаты поисковой выдачи не попадут.

Когда пользователь вводит какое-либо слово / фразу в качестве поискового запроса, это просто строка, чтобы с ней мог рабртать *Lucene* её необходимо преобразовать / распарсить в экземпляр класса `Query` . Почему именно так будет понятно, когда будет описан синтаксис запросов для *Lucene*. В нашем случае используется `MultiFieldQueryParser`, который позволяет осуществлять поиск одновременно(параллельно) по нескольким заданным полям в индексе:

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
                    LuceneBinding.CURRENT_LUCENE_VERSION,
                    new String[] { LuceneBinding.TITLE_FIELD,
                            LuceneBinding.CONTENT_FIELD },
                    LuceneBinding.getAnalyzer());

            /* Operator OR is used by default */

            parser.setDefaultOperator(QueryParser.Operator.AND);

            return parser.parse(QueryParser.escape(story));
        }
    }

Теперь можно реализовать простой класс, который содержит информацию о найденном документе. Помимо известных нам *title*, *content* и *uri* появляется новая сущность - *score*. Это числовой показатель соответвия найденного документа тому запросу, который использовался *Lucene* для его поиска - **релевантность**.

*jLucene/server/webapps/search/src/nongreedy/DefaultSearchItem.java*

    :::java
    package nongreedy;

    import java.io.IOException;

    import org.apache.lucene.document.Document;
    import org.apache.lucene.index.CorruptIndexException;
    import org.apache.lucene.search.ScoreDoc;

    public class DefaultSearchItem {
        public final String title, content, uri;
        public final float score;

        DefaultSearchItem(String title, 
            String content, String uri, float score) {

            this.uri = uri;
            this.title = title;
            this.content = content;
            this.score = score;
        }
    }

    class DefaultAgregator extends Aggregator<DefaultSearchItem> {

        @Override
        DefaultSearchItem aggregate(ScoreDoc sd) throws IOException,
                CorruptIndexException {
            Document doc = indexSearcher.doc(sd.doc);

            return new DefaultSearchItem(
                    doc.get(LuceneBinding.TITLE_FIELD),
                    doc.get(LuceneBinding.CONTENT_FIELD),
                    doc.get(LuceneBinding.URI_FIELD), sd.score);
        }

    }

На данном этапе уже имеются все необходимые механизмы для реализии процесса поиска с постраничной выдачей результатов. В качестве передаваемой *jsp*-представлению *модели* данных будет выступать экземпляр класса `TakeResult<DefaultSearchItem>`:

*jLucene/server/webapps/search/src/nongreedy/SearchServlet.java*

    :::java
    package nongreedy; 
     
    import java.io.IOException; 
     
    import javax.servlet.ServletException; 
    import javax.servlet.http.HttpServlet; 
    import javax.servlet.http.HttpServletRequest; 
    import javax.servlet.http.HttpServletResponse; 
     
    public class SearchServlet extends HttpServlet { 
     
        private final static String indexDir = 
            "../webapps/search/LuceneIndex"; 
        public final static String QUERY_INPUT = "query"; 
        public final static String RESULTS_PER_PAGE = "resperpage"; 
        public final static String CURRENT_PAGE = "currentpage"; 
     
        public void doGet(HttpServletRequest req, HttpServletResponse res) 
                throws ServletException, IOException { 
     
            final String query = req.getParameter(QUERY_INPUT); 
            final String itemsPerPage = req.getParameter(RESULTS_PER_PAGE); 
            final String currentPage = req.getParameter(CURRENT_PAGE); 
     
            if (null != query && !query.isEmpty()) { 
                int currentPageInt = 1, itemsPerPageInt = 10; 
     
                try { 
                    currentPageInt = Integer.parseInt(currentPage); 
                } catch (NumberFormatException e) { 
                } 
                try { 
                    itemsPerPageInt = Integer.parseInt(itemsPerPage); 
                } catch (NumberFormatException e) { 
                } 

                /* Простите, не влазит красиво */ 

                try { 
                    req.setAttribute( 
                        "searchmodel", 
                        new LuceneSearcher<DefaultSearchItem, 
                                DefaultAgregator>(
                                    DefaultAgregator.class, 
                                    indexDir, 
                                    query.trim())
                                       .Take(
                                           itemsPerPageInt, 
                                           (currentPageInt - 1) 
                                               * itemsPerPageInt)); 
                } catch (Exception e) { 
                    throw new ServletException(e); 
                } 
            } 
     
            getServletContext().getRequestDispatcher("/index.jsp") 
                    .forward(req, res); 
        } 
    }

*jLucene/server/webapps/search/app/index.jsp*

    :::jsp
    <jsp:directive.page language="java"
        contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8" />

    <jsp:directive.page import="nongreedy.TakeResult" />
    <jsp:directive.page import="nongreedy.SearchServlet" />
    <jsp:directive.page import="nongreedy.DefaultSearchItem" />

    <%!
        public String escapeHTML(String s) {
            if (null == s) return null;
              s = s.replaceAll("&", "&amp;");
              s = s.replaceAll("<", "&lt;");
              s = s.replaceAll(">", "&gt;");
              s = s.replaceAll("\"", "&quot;");
              s = s.replaceAll("'", "&apos;");
              return s;
        }
        
        public String ellipsize(String s, int max) {
              if (s.length() > max) {
                  final String end = " ...";
                  s = s.substring(0, max - end.length()).trim() + end;
              }
              return s;
        }
    %>

    <% 
        final TakeResult<DefaultSearchItem> model = 
            (TakeResult<DefaultSearchItem>)request
                .getAttribute("searchmodel");
            
        final String qDefValue = escapeHTML(request
            .getParameter(SearchServlet.QUERY_INPUT));
        final int rPerPage = request.getParameter(
            SearchServlet.RESULTS_PER_PAGE) == null ? 5 : 
                Integer.parseInt(request
                    .getParameter(SearchServlet.RESULTS_PER_PAGE));
        final int cPage = request.getParameter(
            SearchServlet.CURRENT_PAGE) == null ? 1 : 
                Integer.parseInt(request
                    .getParameter(SearchServlet.CURRENT_PAGE));
    %>

    <html>
        <head>
            <title>Lucene Search Example</title>
            <meta http-equiv="Content-Type" 
                content="text/html; charset=UTF-8" />
        </head>
        <body>
        
            <form name="search" action="/search" accept-charset="UTF-8">
                <p align="center">
                    <input name="<%= SearchServlet.QUERY_INPUT %>"
                        <% if(null != qDefValue) { %>
                            value="<%= qDefValue %>"
                        <% } %>
                        size="55" style="text-align:center;"/>
                </p>
                <p align="center">
                    <input name="<%= SearchServlet.RESULTS_PER_PAGE %>" 
                        size="5" value="<%= rPerPage %>"
                        style="text-align:center;" />
                    &nbsp;Results Per Page&nbsp;
                    <input type="submit" value="Search!"/>
                </p>
            </form>
            
            <% if(null != model && null != model.getItems()) { %>
                <p style="float:right;">
                    Page <b><%= cPage %></b> from <b>
                        <%= (int)Math.ceil(
                                ((float)model.totalHits) / rPerPage) 
                        %></b>
                </p>
            <% } %>
            
            <% if(null != model && null != model.getItems()) { %>
                <% if(cPage > 1) { %>
                    <form name="search" action="/search" 
                            accept-charset="UTF-8" 
                            style="float:left;">
                        <% if(null != qDefValue) { %>
                            <input type="hidden" 
                                name="<%= SearchServlet.QUERY_INPUT %>"
                                value="<%= qDefValue %>" />
                        <% } %>
                        <input type="hidden" 
                            name="<%= SearchServlet.RESULTS_PER_PAGE %>" 
                            value="<%= rPerPage %>" />
                        <input type="hidden" 
                            name= "<%= SearchServlet.CURRENT_PAGE %>" 
                            value="<%= cPage - 1 %>"/>
                        <input type="submit" 
                            value="<%= escapeHTML("<") %>"/>
                    </form>
                <% } %>

                <% if(model.totalHits > cPage * rPerPage) { %>
                    <form name="search" action="/search" 
                            accept-charset="UTF-8" >
                        <% if(null != qDefValue) { %>
                            <input type="hidden" 
                                name="<%= SearchServlet.QUERY_INPUT %>"
                                value="<%= qDefValue %>" />
                        <% } %>
                        <input type="hidden" 
                            name="<%= SearchServlet.RESULTS_PER_PAGE %>" 
                            value="<%= rPerPage %>" />
                        <input type="hidden" 
                            name= "<%= SearchServlet.CURRENT_PAGE %>" 
                            value="<%= cPage + 1 %>"/>
                        <input type="submit" 
                            value="<%= escapeHTML(">") %>"/>
                    </form>
                <% } %>
            <% } %>

            <p align="center" style="clear:both;">
                <% if(null != model) { %>
                    <% if(null != model.getItems()) { %>
                        <p>
                            <% for(DefaultSearchItem item : 
                                    model.getItems()) { %>
                                <hr/>
                                <p><b>Score: </b><%= item.score %></p>
                                <p><b>Url: </b>
                                    <a href="<%= item.uri %>">
                                        <%= item.uri %>
                                    </a>
                                </p>
                                <p><b>Title: </b>
                                    <%= escapeHTML(item.title) %>
                                </p>
                                <p><b>Content: </b>
                                    <%= escapeHTML(
                                            ellipsize(item.content, 330)) 
                                    %>
                                </p>
                            <% } %>
                        </p>
                    <% } else { %>
                        I'm sorry I couldn't find what you were looking for.
                    <% } %>
                <% } %>
            </p>
            <p align="center">
                <a href="http://nongreedy.ru">http://nongreedy.ru</a>
            </p>
        </body>
    </html>

Результат выполнения должен быть таким:

![Screen1]({attach}linux_search_veka.png){:style="width:100%; border:1px solid #ddd;"}

![Screen2]({attach}linux_search_7_chudes.png){:style="width:100%; border:1px solid #ddd;"}

![Screen3]({attach}win_search_veka.png){:style="width:100%; border:1px solid #ddd;"}

![Screen4]({attach}win_search_7_chudes.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-27-lucene-real-world---language-analyzers/2012-10-27-lucene-real-world---language-analyzers.md) рассмотрим языковые возможности *Lucene*, особенно интересно посмотреть на русский анализатор - `RussianAnalyzer`.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Lucene_Searcher){:rel="nofollow"}.
