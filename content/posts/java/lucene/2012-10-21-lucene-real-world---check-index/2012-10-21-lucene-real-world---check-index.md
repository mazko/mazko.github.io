title: Lucene - проверка индекса
category: Java
tags: Lucene


Данный пост будет очень короткий - на данном этапе имеется **Lucene** - [индекс](/java/2012/10/17/lucene-real-world---indexing), необходимо доработать `SearchServlet` таким образом, чтобы можно было получить и отобразить краткую информацию об индексе. Для проверки индекса в **Lucene** существует уже готовый к использованию специальный класс - `CheckIndex`, который мы и задействуем. Чтобы со временем исходный код сервлета `SearchServlet` не превратился в *макароны* по-флотски, максимально приблизимся к паттерну *модель-представление-контроллер* (**MVC**), где сервлет будет выполнять функцию *контроллера*, *модель* будет иметь формат простой строки, а *представление* будет реализовано в виде **jsp**-страницы.

*jLucene/server/webapps/search/src/nongreedy/SearchServlet.java*

    :::java
    package nongreedy; 
     
    import java.io.ByteArrayOutputStream; 
    import java.io.File; 
    import java.io.IOException; 
    import java.io.PrintStream; 
     
    import javax.servlet.ServletException; 
    import javax.servlet.http.HttpServlet; 
    import javax.servlet.http.HttpServletRequest; 
    import javax.servlet.http.HttpServletResponse; 
     
    import org.apache.lucene.index.CheckIndex; 
    import org.apache.lucene.store.Directory; 
    import org.apache.lucene.store.FSDirectory; 
     
    public class SearchServlet extends HttpServlet { 
     
        private final static String indexDir = 
            "../webapps/search/LuceneIndex"; 
     
        public void doGet(HttpServletRequest req, HttpServletResponse res) 
                throws ServletException, IOException { 
     
            Directory dir = FSDirectory.open(new File(indexDir)); 
            ByteArrayOutputStream byteArrayOutputStream = 
                new ByteArrayOutputStream(); 
            CheckIndex checkIndex = new CheckIndex(dir); 
            checkIndex.setInfoStream(
                new PrintStream(byteArrayOutputStream)); 
            checkIndex.checkIndex(); 
            byteArrayOutputStream.flush(); 
     
            req.setAttribute("checkindexmodel", 
                byteArrayOutputStream.toString()); 
            byteArrayOutputStream.close(); 
     
            getServletContext().getRequestDispatcher("/index.jsp") 
                    .forward(req, res); 
        } 
    }

*jLucene/server/webapps/search/app/index.jsp*

    :::jsp
    <% String model = request.getAttribute("checkindexmodel").toString(); %>

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
    %>

    <html>
        <head>
            <title>Lucene CheckIndex Example</title>
        </head>
        <body>
            <p>
                <%= escapeHTML(model.trim()).replace("\n", "<br />")%>
            </p>
            <p align="center">
                <a href="http://nongreedy.ru">http://nongreedy.ru</a>
            </p>
        </body>
    </html>

Результат выполнения должен быть таким:

![Win]({attach}win_chexkindex.png){:style="width:100%; border:1px solid #ddd;"}

![Linux]({attach}linux_checkindex.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-21-lucene-real-world---simple-search/2012-10-21-lucene-real-world---simple-search.md) реализуем простой поиск.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Simple_Crawler_Index){:rel="nofollow"}.
