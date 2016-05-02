title: Lucene - курс молодого бойца
category: Java
tags: Jetty, Lucene, Maven


[Lucene](http://lucene.apache.org/){:rel="nofollow"} - это библиотека для реализации высокоскоростного полнотекстового поиска с открытым исходным кодом, написанная полностью на **Java**. Вопреки некоторым ожиданиям и заблуждениям *Lucene* не является законченным приложением - это просто библиотека, которую можно (нужно) использовать для реализации поиска в приложениях, а каких именно -  *web*, *desktop* и т.д. не имеет значения. Проект активно развивается и поддерживается, кроме того, есть хорошие порты на другие языки программирования - а это уже о многом говорит в пользу проекта вцелом.

В этом цикле статей мы поэтапно рассмотрим основные возможности *Lucene* на примере реализации законченного **web-приложения** - системы поиска для реального и уже давно существующего сайта. Поскольку, как уже было упомянуто ранее, *Lucene* написана на *Java*, то наше приложение будет тоже написано на *Java* и реализовано в виде **Servlet**, хостится всё это добро будет на [Jetty](https://ru.wikipedia.org/wiki/Jetty){:rel="nofollow"}.

В проекте будет несколько подпроектов, поэтому предлагаю сразу воспользоваться мульти-модульностью [Maven](https://books.sonatype.com/mvnex-book/reference/multimodule.html){:rel="nofollow"}, где в корне намечается общая зависимость от Lucene. Начнём с сервера:

	:::bash
	~$ cd lucene-tutorial/
	~$ tree
	.
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

	7 directories, 5 files

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
	  </dependencies>
	  <modules>
	    <module>server</module>
	  </modules>
	</project>

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

Имеется готовый статический [сайт](http://www.turismy.com/){:rel="nofollow"}, для которого мы будем разрабатывать поиск в виде архива static.war. Мы возьмём некогда топовый в гугле сайт по ключевым словам *Семь Чудес Света*. Получить контент сайта можно с помощью *Linux*'овой утититы *wget*:

	:::bash
    wget -r http://www.turismy.com/

Динамический контент будет генерироваться сервлетом, который будет предоставлять возможность поиска по сайту, разрабатываться он будет поэтапно. Для **Servlet** явно указан маршрут - */search* в то время как статический контент в находится в корне сайта. Для начала реализуем очень простой сервлет, который отдаст какую-то элементарную информацию из *Lucene*:

*server/src/main/webapp/WEB-INF/web.xml*

	:::xml
	<?xml version="1.0" encoding="UTF-8"?>
	<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
		xmlns="http://java.sun.com/xml/ns/j2ee" 
		xmlns:web="http://xmlns.jcp.org/xml/ns/javaee" 
		xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee 
			http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd" 
		version="2.4">
	  <servlet>
	    <servlet-name>search</servlet-name>
	    <servlet-class>server.SearchServlet</servlet-class>
	  </servlet>
	  <servlet-mapping>
	    <servlet-name>search</servlet-name>
	    <url-pattern>/</url-pattern>
	  </servlet-mapping>
	</web-app>

*server/src/main/java/server/SearchServlet.java*

	:::java
	package server;

	import java.io.IOException;
	import java.io.PrintWriter;
	import java.util.Arrays;

	import javax.servlet.ServletException;
	import javax.servlet.http.HttpServlet;
	import javax.servlet.http.HttpServletRequest;
	import javax.servlet.http.HttpServletResponse;

	import org.apache.lucene.util.Version;

	public class SearchServlet extends HttpServlet {

	    @Override
	    public void doGet(final HttpServletRequest req, final HttpServletResponse res)
	            throws ServletException, IOException {
	        final PrintWriter out = res.getWriter();
	        final String luceneVersions = Arrays.toString(Version.class.getFields());

	        out.println("<HTML>");
	        out.println("<BODY>");
	        out.println(luceneVersions.replace(",", "<br />"));
	        out.println("</BODY>");
	        out.println("</HTML>");

	        out.close();
	    }
	}

###Сборка и первый запуск

	:::bash
	~$ apt install maven default-jdk
	~$ mvn -v
	Apache Maven 3.3.9
	Java version: 1.8.0_03-Ubuntu, vendor: Oracle Corporation
	~$ sudo netstat -tulpn | grep -q 8080 && echo 'port 8080 is busy !'
	~$ mvn clean -pl server/ jetty:run

![Linux Site]({attach}Linux_ff_site.png){:style="width:100%; border:1px solid #ddd;"}

![Linux Site Search]({attach}Linux_ff_site_slash_search.png){:style="width:100%; border:1px solid #ddd;"}

Теперь у нас в системе есть подопытный сайт **http://localhost:8080/** с которым мы и будем работать [далее]({filename}../2012-10-17-lucene-real-world---indexing/2012-10-17-lucene-real-world---indexing.md), где первым делом проиндексируем содержимое нашего сайта.

[Исходники]({attach}lucene-tutorial.zip)