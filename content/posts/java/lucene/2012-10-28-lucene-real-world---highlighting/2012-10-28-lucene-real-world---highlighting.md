title: Lucene - подсветка вхождений в результатах выдачи
category: Java
tags: Lucene, JSP, Maven, regex


Наш [поиск]({filename}../2012-10-27-lucene-real-world---language-analyzers/2012-10-27-lucene-real-world---language-analyzers.md) работает вроде бы неплохо, но выглядит как-то не очень аппетитно. Для улучшения визуального восприятия слово или фразу, по которой документ был найден, желательно выделить - например покрасить в другой цвет. Кроме того, текущий способ отображения результатов очень примитивен - не факт, что в начале текста вообще встречается искомая фраза - необходимо показать пользователю именно тот фрагмент текста, в котором *Lucene* её нашёл, тогда точно будет что подсвечивать. Подобный функционал в *Lucene* уже реализован в виде отдельного модуля `Highlighter`, причём скорость его работы зависит от наличия в индексе Term Vectors (задаётся на этапе создания индекса):

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
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-queryparser</artifactId>
          <version>6.0.0</version>
        </dependency>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-highlighter</artifactId>
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

*server/src/main/java/server/HighlightedSearchItem.java*

    :::java
    package server;

    import java.io.IOException;

    import org.apache.lucene.document.Document;
    import org.apache.lucene.index.CorruptIndexException;
    import org.apache.lucene.search.ScoreDoc;
    import org.apache.lucene.search.highlight.Highlighter;
    import org.apache.lucene.search.highlight.InvalidTokenOffsetsException;
    import org.apache.lucene.search.highlight.QueryScorer;
    import org.apache.lucene.search.highlight.SimpleHTMLFormatter;
    import org.apache.lucene.search.highlight.SimpleSpanFragmenter;

    import common.LuceneBinding;

    public class HighlightedSearchItem extends DefaultSearchItem {

        public final String highlightedTitle, highlightedContent;

        HighlightedSearchItem(final String title, final String content, final String uri, 
            final float score, final String highlightedTitle, final String highlightedContent) {
            super(title, content, uri, score);
            this.highlightedContent = highlightedContent;
            this.highlightedTitle = highlightedTitle;
        }
    }

    class HighlightedAgregator extends Aggregator<HighlightedSearchItem> {

        private Highlighter highlighter;

        private final String tryHighlight(final String text, final String[] fields)
                throws IOException, InvalidTokenOffsetsException {

            if (text == null) {
                return null;
            }

            if (this.highlighter == null) {
                final QueryScorer scorer = new QueryScorer(this.query);
                this.highlighter = new Highlighter(
                    new SimpleHTMLFormatter("[mazko.github.io]", "[/mazko.github.io]"),
                    scorer);
                this.highlighter.setTextFragmenter(new SimpleSpanFragmenter(scorer, 330));
            }

            for (final String field : fields) {
                final String highlighted = this.highlighter.getBestFragment(
                    LuceneBinding.getAnalyzer(), field, text);
                if (highlighted != null) {
                    return highlighted;
                }
            }

            return text;
        }

        @Override
        HighlightedSearchItem aggregate(final ScoreDoc sd)
                throws IOException, CorruptIndexException, InvalidTokenOffsetsException {

            final Document doc = this.indexSearcher.doc(sd.doc);
            final String title = doc.get(LuceneBinding.TITLE_FIELD);
            final String content = doc.get(LuceneBinding.CONTENT_FIELD);

            final String highlightedTitle = this.tryHighlight(title, 
                new String[] { 
                    LuceneBinding.RUS_TITLE_FIELD,
                    LuceneBinding.ENG_TITLE_FIELD, 
                    LuceneBinding.TITLE_FIELD });
            final String highlightedContent = this.tryHighlight(content, 
                new String[] { 
                    LuceneBinding.RUS_CONTENT_FIELD,
                    LuceneBinding.ENG_CONTENT_FIELD, 
                    LuceneBinding.CONTENT_FIELD });

            return new HighlightedSearchItem(title, content, 
                doc.get(LuceneBinding.URI_FIELD), sd.score, highlightedTitle, highlightedContent);
        }
    }

Используемый ранее класс `DefaultSearchItem` расширен полями, в каждом из которых будет храниться фрагмент текста, а подсвечиваемая фраза обернута в наборы символов *\[mazko.github.io\]* и *\[/mazko.github.io\]* - при необходимости их можно в любое время заменить, например, с помощью *нежадных* (non-greedy) регулярных выражений. Теперь необходимо сообщить об изменениях классу `LuceneSearcher`. Модель данных, передаваемая *jsp*-представлению, также претерпит небольших изменений: `TakeResult<DefaultSearchItem>` => `TakeResult<HighlightedSearchItem>`:

*server/src/main/java/server/SearchServlet.java*

    :::java
    package server;

    import java.io.IOException;

    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;

    import common.LuceneBinding;

    public class SearchServlet extends HttpServlet {

        public final static String QUERY_INPUT = "query";
        public final static String RESULTS_PER_PAGE = "resperpage";
        public final static String CURRENT_PAGE = "currentpage";

        @Override
        public void doGet(final HttpServletRequest req, final HttpServletResponse res)
                throws ServletException, IOException {

            final String query = req.getParameter(SearchServlet.QUERY_INPUT);
            final String itemsPerPage = req.getParameter(SearchServlet.RESULTS_PER_PAGE);
            final String currentPage = req.getParameter(SearchServlet.CURRENT_PAGE);

            if (query != null && !query.isEmpty()) {
                int currentPageInt = 1, itemsPerPageInt = 10;

                try {
                    currentPageInt = Integer.parseInt(currentPage);
                } catch (final NumberFormatException e) {
                }
                try {
                    itemsPerPageInt = Integer.parseInt(itemsPerPage);
                } catch (final NumberFormatException e) {
                }

                try {
                    req.setAttribute("searchmodel",
                            new LuceneSearcher<HighlightedSearchItem, HighlightedAgregator>(
                                HighlightedAgregator.class,
                                LuceneBinding.INDEX_PATH, query.trim())
                                    .Take(itemsPerPageInt, (currentPageInt - 1) * itemsPerPageInt));
                } catch (final Exception e) {
                    throw new ServletException(e);
                }
            }

            this.getServletContext().getRequestDispatcher("/index.jsp").forward(req, res);
        }
    }

*server/src/main/webapp/index.jsp*

    :::jsp
    <jsp:directive.page language="java"
        contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8" />

    <jsp:directive.page import="server.TakeResult" />
    <jsp:directive.page import="server.SearchServlet" />
    <jsp:directive.page import="server.HighlightedSearchItem" />

    <%!
        public String escapeHTML(String s) {
          if (s == null) return null;
          s = s.replaceAll("&", "&amp;");
          s = s.replaceAll("<", "&lt;");
          s = s.replaceAll(">", "&gt;");
          s = s.replaceAll("\"", "&quot;");
          s = s.replaceAll("'", "&apos;");
          return s;
        }

        public String highlight(String s) {
          if (s == null) return null;
          return  s.replaceAll(
              "\\[mazko\\.github\\.io\\](.*?)\\[/mazko\\.github\\.io\\]", 
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
                        <% if(qDefValue != null) { %>
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

            <% if(model != null && model.getItems() != null) { %>
                <p style="float:right;">
                     Page <b><%= cPage %></b> from <b>
                        <%= (int)Math.ceil(
                                ((float)model.totalHits) / rPerPage) 
                        %></b>
                </p>
            <% } %>

            <% if(model != null && model.getItems() != null) { %>
                <% if(cPage > 1) { %>
                    <form name="search" action="/search" 
                            accept-charset="UTF-8"
                            style="float:left;">
                        <% if(qDefValue != null) { %>
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
                        <% if(qDefValue != null) { %>
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
                <% if(model != null) { %>
                    <% if(model.getItems() != null) { %>
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
                <a href="http://mazko.github.io/">http://mazko.github.io/</a>
            </p>
        </body>
    </html>

Теперь результаты поиска выглядят повеселей:

    :::bash
    ~$ mvn clean install -pl server/ jetty:run

![Screenshot]({attach}linux_search_stem_hltr_sadov.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_sadov1.png){:style="width:100%; border:1px solid #ddd;"}

![Screenshot]({attach}linux_search_stem_hltr_tested.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-29-lucene-real-world---syntax/2012-10-29-lucene-real-world---syntax.md) рассмотрим синтаксис поисковых запросов в *Lucene*.

[Исходники]({attach}lucene-tutorial.zip)
