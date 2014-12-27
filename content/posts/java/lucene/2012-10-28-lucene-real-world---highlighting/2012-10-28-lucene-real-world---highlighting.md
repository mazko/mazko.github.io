title: Lucene - подсветка вхождений в результатах выдачи
category: Java
tags: Lucene


Наш [поиск]({filename}../2012-10-27-lucene-real-world---language-analyzers/2012-10-27-lucene-real-world---language-analyzers.md) работает вроде бы неплохо, но выглядит как-то не очень аппетитно. Для улучшения визуального восприятия слово или фразу, по которой документ был найден, желательно выделить - например покрасить в другой цвет. Кроме того, текущий способ отображения результатов очень примитивен - не факт, что в начале текста вообще встречается искомая фраза - необходимо показать пользователю именно тот фрагмент текста, в котором *Lucene* её нашёл, тогда точно будет что подсвечивать. Подобные вещи в *Lucene* уже умеет делать готовый класс - `Highlighter`, а поскольку на этапе индексации для полей, задействованных в поиске, мы не забыли указать параметр `TermVector.WITH_POSITIONS_OFFSETS`, процесс подсветки будет происходить максимально быстро:

*jLucene/server/webapps/search/src/nongreedy/HighlightedSearchItem.java*

    :::java
    package nongreedy;

    import java.io.IOException;

    import org.apache.lucene.document.Document;
    import org.apache.lucene.index.CorruptIndexException;
    import org.apache.lucene.search.ScoreDoc;
    import org.apache.lucene.search.highlight.Highlighter;
    import org.apache.lucene.search.highlight.InvalidTokenOffsetsException;
    import org.apache.lucene.search.highlight.QueryScorer;
    import org.apache.lucene.search.highlight.SimpleHTMLFormatter;
    import org.apache.lucene.search.highlight.SimpleSpanFragmenter;

    public class HighlightedSearchItem extends DefaultSearchItem {

        public final String highlightedTitle, highlightedContent;

        HighlightedSearchItem(String title, String content, String uri,
                float score, String highlightedTitle, 
                String highlightedContent) {
            super(title, content, uri, score);
            this.highlightedContent = highlightedContent;
            this.highlightedTitle = highlightedTitle;
        }
    }

    class HighlightedAgregator extends Aggregator<HighlightedSearchItem> {

        private Highlighter highlighter;

        private final String tryHighlight(String text, String[] fields)
                throws IOException, InvalidTokenOffsetsException {

            if (null == text)
                return null;

            if (null == highlighter) {
                final QueryScorer scorer = new QueryScorer(query);
                highlighter = new Highlighter(new SimpleHTMLFormatter(
                        "[nongreedy.ru]", "[/nongreedy.ru]"), scorer);
                highlighter.setTextFragmenter(
                    new SimpleSpanFragmenter(scorer, 330));
            }

            for (final String field : fields) {
                final String highlighted = highlighter.getBestFragment(
                        LuceneBinding.getAnalyzer(), field, text);
                if (null != highlighted)
                    return highlighted;
            }

            return text;
        }

        @Override
        HighlightedSearchItem aggregate(ScoreDoc sd) throws IOException,
                CorruptIndexException, InvalidTokenOffsetsException {

            final Document doc = indexSearcher.doc(sd.doc);
            final String title = doc.get(LuceneBinding.TITLE_FIELD);
            final String content = doc.get(LuceneBinding.CONTENT_FIELD);

            final String highlightedTitle = tryHighlight(title, 
                    new String[] {
                        LuceneBinding.RUS_TITLE_FIELD, 
                        LuceneBinding.ENG_TITLE_FIELD,
                        LuceneBinding.TITLE_FIELD });
            final String highlightedContent = tryHighlight(content, 
                    new String[] {
                        LuceneBinding.RUS_CONTENT_FIELD, 
                        LuceneBinding.ENG_CONTENT_FIELD,
                        LuceneBinding.CONTENT_FIELD });

            return new HighlightedSearchItem(title, content,
                    doc.get(LuceneBinding.URI_FIELD), sd.score, 
                    highlightedTitle, highlightedContent);
        }
    }

Используемый ранее класс `DefaultSearchItem` расширен полями, в каждом из которых будет храниться фрагмент текста, а подсвечиваемая фраза обернута в наборы символов *\[nongreedy.ru\]* и *\[/nongreedy.ru\]* - при необходимости их можно в любое время заменить, например, с помощью *нежадных* (non greedy) регулярных выражений. Теперь необходимо сообщить об изменениях классу `LuceneSearcher`. Модель данных, передаваемая *jsp*-представлению, также претерпит небольших изменений: `TakeResult<DefaultSearchItem>` => `TakeResult<HighlightedSearchItem>`:

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
     
                try { 
                    req.setAttribute( 
                            "searchmodel", 
                            new LuceneSearcher<HighlightedSearchItem, 
                                HighlightedAgregator>( 
                                    HighlightedAgregator.class, 
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
    <jsp:directive.page import="nongreedy.HighlightedSearchItem" />

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
        
        public String highlight(String s) {
            if (null == s) return null;
            return  s.replaceAll(
                "\\[nongreedy.ru\\](.*?)\\[/nongreedy.ru\\]", 
                "<b style=\"color:red;\">$1</b>");
        }
    %>

    <% 
        final TakeResult<HighlightedSearchItem> model = 
            (TakeResult<HighlightedSearchItem>)request
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
            <title>Lucene Highlighter Example</title>
            <meta http-equiv="Content-Type" 
                  content="text/html; charset=UTF-8">
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
                            <% for(HighlightedSearchItem item : 
                                   model.getItems()) { %>
                                <hr/>
                                <p><b>Score: </b><%= item.score %></p>
                                <p><b>Url: </b><a href="<%= item.uri %>">
                                    <%= item.uri %></a>
                                </p>
                                <p><b>Title: </b>
                                    <%= highlight(
                                            escapeHTML(
                                                item.highlightedTitle)) %>
                                </p>
                                <p><b>Content: </b>
                                    <%= highlight(
                                            escapeHTML(
                                                item.highlightedContent)) %>
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

Теперь результаты поиска выглядят повеселей:

![Screenshot]({attach}linux_search_stem_hltr_sadov.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_sadov1.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_test.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_tests.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_testing.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}win_search_stem_hltr_sad.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}win_search_stem_hltr_sad1.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}win_search_stem_hltr_test.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}win_search_stem_hltr_tested.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}win_search_stem_hltr_tested1.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-29-lucene-real-world---syntax/2012-10-29-lucene-real-world---syntax.md) рассмотрим синтаксис поисковых запросов в *Lucene*.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Lucene_Stem_Hltr){:rel="nofollow"}.
