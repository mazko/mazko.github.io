title: Lucene - курс молодого бойца
category: Java
tags: Jetty, Lucene, JSP


[Lucene](http://lucene.apache.org/){:rel="nofollow"} - это библиотека для реализации высокоскоростного полнотекстового поиска с открытым исходным кодом, написанная полностью на **Java**. Вопреки некоторым ожиданиям и заблуждениям *Lucene* не является законченным приложением - это просто библиотека, которую можно (нужно) использовать для реализации поиска в приложениях, а каких именно -  *web*, *desktop* и т.д. не имеет значения. Проект активно развивается и поддерживается, кроме того, есть хорошие порты на другие языки программирования - а это уже о многом говорит в пользу проекта вцелом.

В этом цикле статей мы поэтапно рассмотрим основные возможности *Lucene* на примере реализации законченного **web-приложения** - системы поиска для реального и уже давно существующего сайта. Поскольку, как уже было упомянуто ранее, *Lucene* написана на *Java*, то наше приложение будет тоже написано на *Java* и реализовано в виде **Servlet**. Существует немало  вариантов хостить подобные веб-приложения, например очень популярной связкой является сервер *Apache* + контейнер сервлетов *Tomcat*, однако описание процесса развёртывания явно выходит за рамки данного материала, поэтому в нашем примере будет использоваться немного нестандартное, но очень универсальное и удобное решение - [Jetty](http://www.mortbay.org/jetty/){:rel="nofollow"}. Представьте себе контейнер сервлетов + веб-сервер, полностью написанные на *Java*, которые не имеют внешних зависимостей, практически не нуждаются в процессе установки и настройки, запускаются как обычное приложение и выгружаются также. Разве такое вообще возможно ? Да ! Вот как будет выглядеть наше приложение, запускающее *Jetty*-сервер:

*jLucene/server/server/src/nongreedy/ServerApp.java*

	:::java
	package nongreedy; 
	 
	import org.eclipse.jetty.server.Server; 
	import org.eclipse.jetty.server.handler.ContextHandlerCollection; 
	import org.eclipse.jetty.server.handler.HandlerCollection; 
	import org.eclipse.jetty.webapp.WebAppContext; 
	 
	public class ServerApp { 
	    public static void main(String[] args) throws Exception { 
	 
	        Server server = new Server(8080); 
	 
	        HandlerCollection contexts = new ContextHandlerCollection(); 
	 
	        WebAppContext webappcontent = new WebAppContext(); 
	        webappcontent.setContextPath("/"); 
	        webappcontent.setWar("../webapps/content/content.war"); 
	        contexts.addHandler(webappcontent); 
	 
	        WebAppContext webappsearch = new WebAppContext(); 
	        webappsearch.setDescriptor(
	            "../webapps/search/app/WEB-INF/web.xml"); 
	        webappsearch.setResourceBase("../webapps/search/app"); 
	        webappsearch.setContextPath("/search"); 
	        webappsearch.setParentLoaderPriority(true); 
	        contexts.addHandler(webappsearch); 
	 
	        server.setHandler(contexts); 
	        server.start(); 
	        server.join(); 
	    } 
	}

Если порт **8080** в вашей системе занят, его можно поменять тут. В нашем случае на одном сервере хостятся два веб-приложения. Первое - это уже готовый [сайт](http://www.turismy.com/){:rel="nofollow"}, для которого мы будем разрабатывать поиск. Мы возьмём топовый на данный момент в гугле сайт по ключевым словам *Семь Чудес Света*. Получить контент сайта можно с помощью *Linux*'овой утититы *wget* (есть сборка и под Windows):

	:::bash
    wget -r http://www.turismy.com/

Второе веб-приложение - **Servlet**, который будет предоставлять возможность поиска по сайту, разрабатываться он будет поэтапно. Как видно по коду, он запускается несколько иначе. Во-первых, явно указан маршрут - */search*, во-вторых такая реализация имеет большую гибкость на этапе разработки и позволяет менять логику не перезагружая сам сервер.

Теперь реализуем очень простой сервлет, который отдаст какую-то элементарную информацию из *Lucene*:

*jLucene/server/webapps/search/app/WEB-INF/web.xml*

	:::xml
	<web-app xmlns="http://java.sun.com/xml/ns/j2ee" version="2.4" 
	         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	         xsi:schemaLocation="http:/java.sun.com/dtd/web-app_2_3.dtd"> 
	  <servlet> 
	    <servlet-name>hello</servlet-name> 
	    <servlet-class>nongreedy.SearchServlet</servlet-class> 
	  </servlet> 
	 
	  <servlet-mapping> 
	    <servlet-name>hello</servlet-name> 
	    <url-pattern>/</url-pattern> 
	  </servlet-mapping> 
	</web-app>

*jLucene/server/webapps/search/src/nongreedy/SearchServlet.java*

	:::java
	package nongreedy; 
	 
	import java.io.IOException; 
	import java.io.PrintWriter; 
	import java.util.Arrays; 
	 
	import javax.servlet.ServletException; 
	import javax.servlet.http.HttpServlet; 
	import javax.servlet.http.HttpServletRequest; 
	import javax.servlet.http.HttpServletResponse; 
	 
	import org.apache.lucene.util.Version; 
	 
	public class SearchServlet extends HttpServlet { 
	 
	    public void doGet(HttpServletRequest req, HttpServletResponse res) 
	            throws ServletException, IOException { 
	        PrintWriter out = res.getWriter(); 
	        String luceneVersions = 
	            Arrays.toString(Version.class.getFields()); 
	 
	        out.println("<HTML>"); 
	        out.println("<BODY>"); 
	        out.println(luceneVersions.replace(",", "<br />")); 
	        out.println("</BODY>"); 
	        out.println("</HTML>"); 
	 
	        out.close(); 
	    } 
	}

###Сборка и первый запуск

Единственное требование к системе, на на которой будет осуществляться сборка и запуск всех приложений, которые описываются в данном цикле статей - наличие *Java Development Kit* (**jdk**). Если говорить простым человеческим языком - при вызове из консоли / терминала команды `javac -version` ответ должен быть примерно таким `javac 1.6.0_23`. Дальше всю работу выполнят скрипты, описанные ниже. Предположительно их содержимое в следующих статьях меняться не будет.

*jLucene/server/build.bat*

	:::batch
	@if exist webapps\content\content.war goto compile 
	@cd webapps\content\src 
	@jar -cvf content.war . 
	@move content.war ..\ 
	@cd ..\..\..\ 
	 
	:compile 
	 
	@rd server\bin /Q /S 
	@md server\bin 
	 
	@set LIB=server/lib/*;server/lib/jetty/* 
	@set SRC=server/src/nongreedy/ServerApp.java 
	 
	@javac -cp %LIB% -d server/bin %SRC% 
	 
	@cd webapps\search 
	 
	@rd app\WEB-INF\classes /Q /S 
	@md app\WEB-INF\classes 
	 
	@set LIB=../../server/lib/jetty/servlet-api-3.0.jar;app/WEB-INF/lib/* 
	@set SRC=src/nongreedy/*.java 
	 
	@javac -cp %LIB% -d app/WEB-INF/classes %SRC% 
	 
	@pause

*jLucene/server/run.bat*

	:::batch
	@cd server 
	@set LIB=lib/*;lib/jetty/*;lib/jetty/jsp/* 
	 
	@java -cp bin;%LIB% ^
	-Dorg.apache.jasper.compiler.disablejsr199=true ^
	nongreedy.ServerApp 
	 
	@pause

![Windows Run]({attach}windows_build_run.png){:style="width:100%; border:1px solid #ddd;"}

![Windows Site]({attach}windows_ie_site.png){:style="width:100%; border:1px solid #ddd;"}

![Windows Site Search]({attach}windows_ie_site_slash_search.png){:style="width:100%; border:1px solid #ddd;"}

Как вы наверно догадались, это всё о *Windows*. Теперь *Linux* (openSUSE):

*jLucene/server/build.sh*

	:::bash
	#!/bin/bash

	# sudo zypper install java-1.6.0-openjdk-devel

	cd "`dirname "${0}"`"

	test -e "webapps/content/content.war";
	if [ $? -ne 0 ]
	then 
	    cd webapps/content/src
	    jar -cvf content.war .
	    mv content.war ../
	    cd ../../../
	fi

	rm -r -f server/bin
	mkdir server/bin

	# sources and link libraries

	SRC=server/src/nongreedy/ServerApp.java
	LIB=server/lib/*:server/lib/jetty/*

	# compile jetty server application

	javac -cp $LIB -d server/bin $SRC $*

	# compile servlet

	cd webapps/search

	rm -r -f app/WEB-INF/classes
	mkdir app/WEB-INF/classes

	SRC=src/nongreedy/*.java
	LIB=../../server/lib/jetty/servlet-api-3.0.jar:app/WEB-INF/lib/*

	javac -cp $LIB -d app/WEB-INF/classes $SRC $*

*jLucene/server/run.sh*

	:::bash
	#!/bin/bash

	cd "`dirname "${0}"`/server"

	# link libraries

	LIB=lib/*:lib/jetty/*:lib/jetty/jsp/*

	java -cp bin:$LIB \
	-Dorg.apache.jasper.compiler.disablejsr199=true \
	nongreedy.ServerApp

![Linux Run]({attach}Linux_build_run.png){:style="width:100%; border:1px solid #ddd;"}

![Linux Site]({attach}Linux_ff_site.png){:style="width:100%; border:1px solid #ddd;"}

![Linux Site Search]({attach}Linux_ff_site_slash_search.png){:style="width:100%; border:1px solid #ddd;"}

С этого момента интернет уже не нужен - в системе есть готовый сайт **http://localhost:8080/** с которым мы и будем работать далее. В [следующей]({filename}../2012-10-17-lucene-real-world---indexing/2012-10-17-lucene-real-world---indexing.md) статье мы проиндексируем содержимое нашего сайта.

Текущие исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/hello_world){:rel="nofollow"}.
