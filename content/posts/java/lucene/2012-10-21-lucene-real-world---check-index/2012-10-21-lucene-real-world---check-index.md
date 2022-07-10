title: Lucene - проверка индекса
category: Java
tags: Lucene, jsp, Maven


Данный пост будет очень короткий - на данном этапе имеется **Lucene** - [индекс]({filename}../2012-10-17-lucene-real-world---indexing/2012-10-17-lucene-real-world---indexing.md), необходимо доработать `SearchServlet` таким образом, чтобы можно было получить и отобразить краткую информацию об индексе. Для проверки индекса в **Lucene** существует уже готовый к использованию специальный класс - `CheckIndex`, который мы и задействуем. Чтобы со временем исходный код сервлета `SearchServlet` не превратился в *макароны* по-флотски, максимально приблизимся к паттерну *модель-представление-контроллер* (**MVC**), где сервлет будет выполнять функцию *контроллера*, *модель* будет иметь формат простой строки, а *представление* будет реализовано в виде **jsp**-страницы.

*server/pom.xml*

    :::xml
    <project xmlns="http://maven.apache.org/POM/4.0.0" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <parent>
        <groupId>tutorial.lucene</groupId>
        <artifactId>parent</artifactId>
        <version>1.0</version>
      </parent>
      <artifactId>server</artifactId>
      <packaging>war</packaging>
      <name>Lucene Tutorial Server</name>
      <dependencies>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>servlet-api</artifactId>
            <version>2.4</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
          <groupId>tutorial.lucene</groupId>
          <artifactId>common</artifactId>
          <version>1.0</version>
        </dependency>
      </dependencies>
      <build>
        <plugins>
          <plugin>
            <groupId>org.eclipse.jetty</groupId>
            <artifactId>jetty-maven-plugin</artifactId>
            <version>9.3.8.v20160314</version>
            <configuration>
              <webApp>
                <contextPath>/search</contextPath>
              </webApp>
              <contextHandlers>
                <contextHandler implementation="org.eclipse.jetty.maven.plugin.JettyWebAppContext">
                  <war>${project.basedir}/static.war</war> -->
                  <contextPath>/</contextPath>
                </contextHandler>
              </contextHandlers> 
            </configuration>
          </plugin>
        </plugins>
      </build>
    </project>

*server/src/main/java/server/SearchServlet.java*

    :::java
    package server;

    import java.io.ByteArrayOutputStream;
    import java.io.IOException;
    import java.io.OutputStream;
    import java.io.PrintStream;

    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;

    import org.apache.lucene.index.CheckIndex;
    import org.apache.lucene.store.Directory;
    import org.apache.lucene.store.FSDirectory;

    public class SearchServlet extends HttpServlet {

        @Override
        public void doGet(final HttpServletRequest req, final HttpServletResponse res)
                throws ServletException, IOException {
            try (final OutputStream byteArrayOutputStream = new ByteArrayOutputStream()) {
                final Directory dir = FSDirectory.open(common.LuceneBinding.INDEX_PATH);
                try (final CheckIndex checkIndex = new CheckIndex(dir)) {
                    checkIndex.setInfoStream(new PrintStream(byteArrayOutputStream));
                    checkIndex.checkIndex();
                    byteArrayOutputStream.flush();
                    req.setAttribute("checkindexmodel", byteArrayOutputStream.toString());
                }
            }

            this.getServletContext().getRequestDispatcher("/index.jsp").forward(req, res);
        }
    }

*server/src/main/webapp/index.jsp*

    :::jsp
    <% String model = request.getAttribute("checkindexmodel").toString(); %>

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
                <a href="http://mazko.github.io/">http://mazko.github.io/</a>
            </p>
        </body>
    </html>

Результат выполнения должен быть таким:

    :::bash
    ~$ mvn clean install -pl server/ jetty:run

![Linux]({attach}linux_checkindex.png){:style="width:100%; border:1px solid #ddd;"}

[Далее]({filename}../2012-10-21-lucene-real-world---simple-search/2012-10-21-lucene-real-world---simple-search.md) реализуем простой поиск.

[Исходники]({attach}lucene-tutorial.zip)
