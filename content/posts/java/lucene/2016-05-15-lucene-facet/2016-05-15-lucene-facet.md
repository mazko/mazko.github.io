title: Lucene - фасетный поиск
category: Java
tags: Lucene, maven, JSTL

После того, как пользователь получает первые результаты [поиска]({filename}../2012-10-29-lucene-real-world---syntax/2012-10-29-lucene-real-world---syntax.md) он наверняка захочет ещё дополнительно отфильтровывать результаты выдачи. Фасетный поиск на этапе [индексации]({filename}../2012-10-17-lucene-real-world---indexing/2012-10-17-lucene-real-world---indexing.md) сохраняет дополнительную информацию для вычисления всех возможный уточняющих вариантов последующей фильтрации поисковой выдачи, которые как бы *подсказывают* пользователю что можно ещё уточнить. Таким образом с помощью фасетной фильтрации каждый последующий запрос пользователя сужает выборку до тех пор пока цель поиска не будет достигнута.

В файле ```Top.json``` хранится ~15k дамп фильмов с кинопоиска на май 2016, на котором будем тестировать качество фасетного поиска. В дампе хранится оценка, название, id, актёры, режиссёры, композиторы, жанр, дата выхода, страна производитель, слоган и краткое описание для каждого фильма.

![screenshot]({attach}facet.gif){:style="width:100%; border:1px solid #ddd;"}

Структура мульти-модульного **maven** проекта, где в корневом ```pom.xml``` обозначена общая зависимость от Lucene, а также указана минимальная версия Java 1.8 и выше:

    :::bash
    ~$ tree
	.
	├── src
	│   ├── common
	│   │   ├── pom.xml
	│   │   └── src
	│   │       └── main
	│   │           └── java
	│   │               └── common
	│   │                   └── LuceneBinding.java
	│   ├── crawler
	│   │   ├── pom.xml
	│   │   └── src
	│   │       └── main
	│   │           ├── java
	│   │           │   └── crawler
	│   │           │       ├── App.java
	│   │           │       └── LuceneIndexer.java
	│   │           └── resources
	│   │               └── log4j.properties
	│   ├── pom.xml
	│   └── server
	│       ├── pom.xml
	│       └── src
	│           └── main
	│               ├── java
	│               │   └── server
	│               │       ├── DefaultSearchItem.java
	│               │       ├── FacetTakeResult.java
	│               │       ├── HighlightedSearchItem.java
	│               │       ├── LuceneSearcher.java
	│               │       ├── QueryHelper.java
	│               │       ├── SearchServlet.java
	│               │       └── takeble
	│               │           ├── ITakeble.java
	│               │           └── TakeResult.java
	│               └── webapp
	│                   ├── index.jsp
	│                   └── WEB-INF
	│                       ├── tags
	│                       │   ├── hi.tag
	│                       │   └── nav.tag
	│                       └── web.xml
	└── Top.json

	21 directories, 21 files

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
	    <dependency>
	      <groupId>org.apache.lucene</groupId>
	      <artifactId>lucene-facet</artifactId>
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

В подпроекте common объявлены общие константы используемые при поиске и индексации. Фасетный индекс состоит из трёх полей ```FACET_DIRECTOR```, ```FACET_DATE``` и ```FACET_CATEGORY```. Наиболее простой случай - режиссёр (director), поскольку для простоты предполагается что у одного фильма может быть он только один. Вместе с тем у одного фильма может быть уже несколько жанров, в этом случае ```setMultiValued```. Ну и самый интересный случай - древовидная фильтрация по дате - ```setHierarchical```:

*src/common/src/main/java/common/LuceneBinding.java*

	:::java
	package common;

	import java.nio.file.Path;
	import java.nio.file.Paths;

	import org.apache.lucene.analysis.Analyzer;
	import org.apache.lucene.analysis.standard.StandardAnalyzer;
	import org.apache.lucene.facet.FacetsConfig;

	/* This class is used both by Crawler and SearchServlet */

	public final class LuceneBinding {
		public static final Path SEARCH_INDEX_PATH = Paths.get(
			System.getProperty("user.home"), "lucene-tutorial-index", "search");
		public static final Path TAXO_INDEX_PATH = Paths.get(
			System.getProperty("user.home"), "lucene-tutorial-index", "taxo");

		public static final String FIELD_ID = "id";
		public static final String FIELD_TITLE = "title";
		public static final String FIELD_CONTENT = "content";
		public static final String FIELD_CATEGORY = "category";
		public static final String FIELD_DIRECTOR = "director";
		public static final String FIELD_RATE = "rate";

		public static final String FACET_DIRECTOR = "Director";
		public static final String FACET_DATE = "Release Date";
		public static final String FACET_CATEGORY = "Category";

		public static FacetsConfig getFacetsConfig() {
			final FacetsConfig config = new FacetsConfig();
			config.setHierarchical(LuceneBinding.FACET_DATE, true);
			config.setMultiValued(LuceneBinding.FACET_CATEGORY, true);
			return config;
		}

		public static Analyzer getAnalyzer() {
			return new StandardAnalyzer();
		}
	}

При индексации для фасетов создаётся параллельный индекс ```DirectoryTaxonomyWriter```. Ещё в поле рейтинга фильма ```FIELD_RATE``` дополнительно добавлена возможность сортировки результатов поиска:

*src/crawler/src/main/java/crawler/LuceneIndexer.java*

	:::java
	package crawler;

	import java.io.Closeable;
	import java.io.IOException;
	import java.text.SimpleDateFormat;
	import java.util.Date;

	import org.apache.log4j.Logger;
	import org.apache.lucene.document.Document;
	import org.apache.lucene.document.Field.Store;
	import org.apache.lucene.document.FloatDocValuesField;
	import org.apache.lucene.document.StringField;
	import org.apache.lucene.document.TextField;
	import org.apache.lucene.facet.FacetField;
	import org.apache.lucene.facet.taxonomy.directory.DirectoryTaxonomyWriter;
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

		private DirectoryTaxonomyWriter taxoWriter = null;

		@Override
		public void close() throws IOException {
			LuceneIndexer.logger.info(
					"Closing Index < " + LuceneBinding.SEARCH_INDEX_PATH + " > NumDocs: " + 
					this.indexWriter.numDocs());
			this.indexWriter.close();
			this.taxoWriter.close();
			LuceneIndexer.logger.info("Index closed OK!");
		}

		public void new_index() throws IOException {
			final Directory directory = FSDirectory.open(LuceneBinding.SEARCH_INDEX_PATH);
			final IndexWriterConfig iwConfig = new IndexWriterConfig(LuceneBinding.getAnalyzer());
			iwConfig.setOpenMode(OpenMode.CREATE);
			this.indexWriter = new IndexWriter(directory, iwConfig);
			this.taxoWriter = new DirectoryTaxonomyWriter(
				FSDirectory.open(LuceneBinding.TAXO_INDEX_PATH));
		}

		public void add(final int id, final String title, final String content, 
				final String director, final String[] cats,
				final Date date, final float rate) throws IOException {

			LuceneIndexer.logger.info("***** " + title + " *****");
			LuceneIndexer.logger.info(content);

			final Document doc = new Document();

			// A field that is indexed but not tokenized: the entire String value is
			// indexed as a single token
			doc.add(new StringField(LuceneBinding.FIELD_ID, new Integer(id).toString(), Store.YES));

			// A field that is indexed and tokenized, without term vectors.
			doc.add(new TextField(LuceneBinding.FIELD_TITLE, title, Store.YES));
			doc.add(new TextField(LuceneBinding.FIELD_CONTENT, content, Store.YES));

			// A field that is indexed but not tokenized
			doc.add(new StringField(LuceneBinding.FIELD_DIRECTOR, director, Store.YES));

			// Field that stores a per-document long value for scoring, sorting or
			// value retrieval
			doc.add(new FloatDocValuesField(LuceneBinding.FIELD_RATE, rate));
			doc.add(new StringField(LuceneBinding.FIELD_RATE, Float.toString(rate), Store.YES));

			// Facet
			doc.add(new FacetField(LuceneBinding.FACET_DIRECTOR, director));
			for (final String cat : cats) {
				doc.add(new FacetField(LuceneBinding.FACET_CATEGORY, cat));
				doc.add(new StringField(LuceneBinding.FIELD_CATEGORY, cat, Store.YES));
			}
			doc.add(new FacetField(LuceneBinding.FACET_DATE, new SimpleDateFormat("yyyy").format(date),
					new SimpleDateFormat("MM").format(date), new SimpleDateFormat("dd").format(date)));

			this.indexWriter.addDocument(LuceneBinding.getFacetsConfig().build(this.taxoWriter, doc));
		}
	}

При поиске обычный ```Query``` заворачивается в фасетный ```DrillDownQuery``` а непосредственно поиск осуществляется через ```DrillSideways```. Сортировка по рейтингу фильма:

*src/server/src/main/java/server/LuceneSearcher.java*

	:::java
	package server;

	import java.io.IOException;
	import java.util.AbstractMap.SimpleEntry;
	import java.util.ArrayList;
	import java.util.List;

	import org.apache.lucene.facet.DrillDownQuery;
	import org.apache.lucene.facet.DrillSideways;
	import org.apache.lucene.facet.DrillSideways.DrillSidewaysResult;
	import org.apache.lucene.facet.taxonomy.TaxonomyReader;
	import org.apache.lucene.facet.taxonomy.directory.DirectoryTaxonomyReader;
	import org.apache.lucene.index.CorruptIndexException;
	import org.apache.lucene.index.DirectoryReader;
	import org.apache.lucene.index.IndexReader;
	import org.apache.lucene.queryparser.classic.ParseException;
	import org.apache.lucene.search.IndexSearcher;
	import org.apache.lucene.search.Query;
	import org.apache.lucene.search.ScoreDoc;
	import org.apache.lucene.search.Sort;
	import org.apache.lucene.search.SortField;
	import org.apache.lucene.search.TopDocs;
	import org.apache.lucene.search.TopFieldCollector;
	import org.apache.lucene.search.highlight.InvalidTokenOffsetsException;
	import org.apache.lucene.store.Directory;
	import org.apache.lucene.store.FSDirectory;

	import common.LuceneBinding;
	import server.takeble.ITakeble;

	abstract class SearchAggregator<T> {
		protected Query query;
		protected IndexSearcher indexSearcher;

		abstract T aggregate(ScoreDoc sd) throws IOException, 
			CorruptIndexException, InvalidTokenOffsetsException;
	}

	class LuceneSearcher<T, A extends SearchAggregator<T>> implements ITakeble<T> {

		private final String story;
		private final List<SimpleEntry<String, String[]>> facets;
		private final Class<A> classA;

		/* IndexReader is thread safe - one instance for all requests */

		private static volatile IndexReader indexReader;

		private static volatile TaxonomyReader taxoReader;

		LuceneSearcher(final Class<A> classA, final String story, 
			final List<SimpleEntry<String, String[]>> facets)
				throws IOException {

			this.story = story;
			this.facets = facets;
			this.classA = classA;

			if (LuceneSearcher.indexReader == null) {
				synchronized (LuceneSearcher.class) {
					if (LuceneSearcher.indexReader == null) {
						final Directory dir = FSDirectory.open(LuceneBinding.SEARCH_INDEX_PATH);
						LuceneSearcher.indexReader = DirectoryReader.open(dir);
					}
				}
			}

			if (LuceneSearcher.taxoReader == null) {
				synchronized (LuceneSearcher.class) {
					if (LuceneSearcher.taxoReader == null) {
						LuceneSearcher.taxoReader = new DirectoryTaxonomyReader(
								FSDirectory.open(LuceneBinding.TAXO_INDEX_PATH));
					}
				}
			}
		}

		@Override
		public FacetTakeResult<T> Take(final int count, final int start) throws 
				ParseException, IOException, InstantiationException, 
				IllegalAccessException, InvalidTokenOffsetsException {

			final int nDocs = start + count;

			final DrillDownQuery query = new DrillDownQuery(LuceneBinding.getFacetsConfig(),
					QueryHelper.generate(this.story));

			this.facets.forEach((i) -> query.add(i.getKey(), i.getValue()));

			final IndexSearcher indexSearcher = new IndexSearcher(LuceneSearcher.indexReader);
			final SortField sortField = new SortField(
				LuceneBinding.FIELD_RATE, SortField.Type.FLOAT, true);
			final TopFieldCollector topCollector = TopFieldCollector.create(
				new Sort(sortField), Math.max(nDocs, 1), false, true, false);

			final DrillSideways facetDrill = new DrillSideways(indexSearcher, 
					LuceneBinding.getFacetsConfig(), LuceneSearcher.taxoReader);
			final DrillSidewaysResult drillResult = facetDrill.search(query, topCollector);

			final TopDocs topDocs = topCollector.topDocs();

			if (nDocs <= 0) {
				return new FacetTakeResult<T>(topDocs.totalHits, drillResult);
			}

			final ScoreDoc[] scoreDocs = topDocs.scoreDocs;
			final int length = scoreDocs.length - start;

			if (length <= 0) {
				return new FacetTakeResult<T>(topDocs.totalHits, drillResult);
			}

			final List<T> items = new ArrayList<T>(length);
			final A aggregator = this.classA.newInstance();
			aggregator.query = query;
			aggregator.indexSearcher = indexSearcher;

			for (int i = start; i < scoreDocs.length; i++) {
				items.add(i - start, aggregator.aggregate(scoreDocs[i]));
			}

			return new FacetTakeResult<T>(topDocs.totalHits, items, drillResult);
		}
	}

*src/server/src/main/java/server/FacetTakeResult.java*

	:::java
	package server;

	import java.io.IOException;
	import java.util.AbstractMap.SimpleEntry;
	import java.util.Arrays;
	import java.util.Collection;
	import java.util.Collections;
	import java.util.LinkedHashMap;
	import java.util.Map;

	import org.apache.lucene.facet.DrillSideways.DrillSidewaysResult;
	import org.apache.lucene.facet.FacetResult;
	import org.apache.lucene.facet.Facets;

	import common.LuceneBinding;
	import server.takeble.TakeResult;

	public final class FacetTakeResult<T> extends TakeResult<T> {

		private static final int TOP = 333;

		private final Map<String, Number> directors;

		private final Map<String, Number> categories;

		private final Map<String, SimpleEntry<Number, Map<String, Number>>> dates;

		public Map<String, Number> getDirectors() {
			return this.directors;
		}

		public Map<String, Number> getCategories() {
			return this.categories;
		}

		public Map<String, SimpleEntry<Number, Map<String, Number>>> getDates() {
			return this.dates;
		}

		private static FacetResult bugHelper(final Facets facets, final String... path) {
			try {
				return facets.getTopChildren(FacetTakeResult.TOP, LuceneBinding.FACET_DATE, path);
			} catch (final IOException e) {
				throw new RuntimeException(e);
			}
		}

		public FacetTakeResult(final int totalHits, final Collection<T> items, 
			final DrillSidewaysResult facetDrill) throws IOException {

			super(totalHits, items);

			if (totalHits > 0) {

				// Facets extraction: categories + date

				final Facets facets = facetDrill.facets;

				this.directors = Collections
						.unmodifiableMap(Arrays
								.stream(facets.getTopChildren(FacetTakeResult.TOP,
										LuceneBinding.FACET_DIRECTOR).labelValues)
								.sorted((e1, e2) -> Integer.compare(e2.value.intValue(), e1.value.intValue()))
								.collect(LinkedHashMap::new, (m, v) -> m.put(v.label, v.value), Map::putAll));

				this.categories = Collections
						.unmodifiableMap(Arrays
								.stream(facets.getTopChildren(FacetTakeResult.TOP,
										LuceneBinding.FACET_CATEGORY).labelValues)
								.sorted((e1, e2) -> Integer.compare(e2.value.intValue(), e1.value.intValue()))
								.collect(LinkedHashMap::new, (m, v) -> m.put(v.label, v.value), Map::putAll));

				this.dates = Collections.unmodifiableMap(
					Arrays.stream(FacetTakeResult.bugHelper(facets).labelValues)
						.sorted((y1, y2) -> Integer.compare(y2.value.intValue(), y1.value.intValue()))
						.collect(LinkedHashMap::new, (ymap, y) -> ymap.put(y.label, 
							new SimpleEntry<>(y.value, Collections.unmodifiableMap(Arrays
								.stream(FacetTakeResult.bugHelper(facets, y.label).labelValues)
								.sorted((m1, m2) -> Integer.compare(m2.value.intValue(), m1.value.intValue()))
								.collect(LinkedHashMap::new, (mmap, m) -> 
									mmap.put(m.label, m.value), Map::putAll)))),
							Map::putAll));
			} else {
				this.dates = null;
				this.directors = this.categories = null;
			}

		}

		public FacetTakeResult(final int totalHits, final DrillSidewaysResult facetDrill) throws IOException {
			this(totalHits, (Collection<T>) null, facetDrill);
		}
	}

*src/server/src/main/webapp/index.jsp*

	:::text
	<%@ page language="java" contentType="text/html; charset=UTF-8"
		pageEncoding="UTF-8"%>

	<%@ page import="server.SearchServlet"%>

	<%@ taglib tagdir="/WEB-INF/tags" prefix="tag"%>
	<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
	<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

	<c:set var="queryStr"
		value="${searchcontext[SearchServlet.QUERY_INPUT]}" />
	<c:set var="currentPageInt"
		value="${searchcontext[SearchServlet.CURRENT_PAGE]}" />
	<c:set var="perPageInt"
		value="${searchcontext[SearchServlet.RESULTS_PER_PAGE]}" />
	<c:set var="directedStr"
		value="${searchcontext[SearchServlet.DIRECTED]}" />
	<c:set var="categoryArr"
		value="${searchcontext[SearchServlet.CATEGORY]}" />
	<c:set var="dateStr" value="${searchcontext[SearchServlet.DATE]}" />

	<html>
	<head>
	<title>Lucene Facet Example</title>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	</head>
	<body>
		<form name="search" action="/" accept-charset="UTF-8">
			<p align="center">
				<input name="${SearchServlet.QUERY_INPUT}"
					value="<c:out value="${queryStr}"/>"
					style="text-align: center; width: 100%; font-size: 1.5em" />
			</p>
			<p style="display: flex; justify-content: center">
				<select title="Дерево: Год -> Месяц" name="${SearchServlet.DATE}">
					<option value="">-</option>
					<c:forEach items="${searchmodel.dates}" var="y">
						<option value="<c:out value="${y.key}"/>"
							${y.key == dateStr ? 'selected' : null}>
							<c:out value="${y.key} | ${y.value.key}" />
						</option>
						<c:forEach items="${y.value.value}" var="m">
							<c:set var="yyyymm"><c:out value="${y.key}-${m.key}" /></c:set>
							<option value="<c:out value="${yyyymm}"/>"
								${yyyymm == dateStr ? 'selected' : null}>
								<c:out value="-> ${m.key} | ${m.value}" />
							</option>
						</c:forEach>
					</c:forEach>
				</select> &nbsp; <select title="Режиссёр" name="${SearchServlet.DIRECTED}">
					<option value="">-</option>
					<c:forEach items="${searchmodel.directors}" var="entry">
						<option value="<c:out value="${entry.key}"/>"
							${entry.key == directedStr ? 'selected' : null}>
							<c:out value="${entry.value} | ${entry.key}" />
						</option>
					</c:forEach>
				</select> &nbsp; 
				<select title="Мульти: Жанр" multiple size="1"
					name="${SearchServlet.CATEGORY}">
					<option value="">-</option>
					<c:forEach items="${searchmodel.categories}" var="entry">
						<c:set var="isSelected" value="false" />
						<c:forEach var="cat" items="${categoryArr}">
							<c:if test="${cat == entry.key}">
								<c:set var="isSelected" value="true" />
							</c:if>
						</c:forEach>
						<option value="<c:out value="${entry.key}"/>"
							${isSelected ? 'selected' : null}>
							<c:out value="${entry.value} | ${entry.key}" />
						</option>
					</c:forEach>
				</select> &nbsp; <select title="Показывать"
					name="${SearchServlet.RESULTS_PER_PAGE}">
					<c:forTokens items="3,5,10,20,50" delims="," var="per">
						<option ${per == perPageInt ? 'selected' : null}>
							<c:out value="${per}" />
						</option>
					</c:forTokens>
				</select> &nbsp; <input type="submit" value="Поиск!" />
			</p>
		</form>

		<c:if test="${searchmodel != null}">
			<c:choose>
				<c:when test="${searchmodel.items != null}">
					<div style="float: right;">
						Page <b> ${currentPageInt} </b> from 
						<b>${Math.ceil((1.0 * searchmodel.totalHits) / perPageInt).intValue()}</b>
					</div>
					<c:if test="${currentPageInt > 1}">
						<tag:nav current="${currentPageInt - 1}" value="<" style=" float:left;" />
					</c:if>
					<c:if test="${searchmodel.totalHits > currentPageInt * perPageInt}">
						<tag:nav current="${currentPageInt + 1}" value=">" />
					</c:if>
					<div style="clear: both;">
						<c:forEach items="${searchmodel.items}" var="item">
							<hr />
							<p>
								<b>Совпадение: </b>${item.score} <b>Кинопоиск: </b> <a
									href="http://www.kinopoisk.ru/film/${item.id}/">${item.rate}</a> 
								<b>Режиссёр: </b>
								<c:out value="${item.director}" />
							</p>
							<p>
								<b>Жанр: </b>
								<c:out value="${fn:join(item.categories, ', ')}" />
							</p>
							<p>
								<b>Название: </b>
								<tag:hi value="${item.highlightedTitle}" />
							</p>
							<p>
								<b>Описание: </b>
								<tag:hi value="${item.highlightedContent}" />
							</p>
						</c:forEach>
					</div>
				</c:when>
				<c:otherwise>
					<p align="center">Ничего не найдено :(</p>
				</c:otherwise>
			</c:choose>
		</c:if>
		<p align="center">
			<a href="http://mazko.github.io/">http://mazko.github.io/</a>
		</p>
	</body>
	</html>

*src/server/src/main/webapp/WEB-INF/tags/hi.tag*

	:::text
	<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
	<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>

	<%@ attribute name="value" required="true" %>

	<c:set var="esc"><c:out value="${value}" /></c:set>

	<c:if test="${value != null}">
		${esc.replaceAll(
	          "\\[mazko\\.github\\.io\\](.*?)\\[/mazko\\.github\\.io\\]", 
	          "<b style=\"color:red;\">$1</b>")}
	</c:if>

*src/server/src/main/webapp/WEB-INF/tags/nav.tag*

	:::text
	<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

	<%@ attribute name="value" required="true"%>
	<%@ attribute name="style" required="false"%>
	<%@ attribute name="current" required="true"%>

	<%@ tag import="server.SearchServlet"%>

	<form name="search" action="/" accept-charset="UTF-8" style="${style}">
		<c:forEach items="${searchcontext}" var="entry">
			<c:if
				test="${entry.key != SearchServlet.CURRENT_PAGE && entry.key != SearchServlet.CATEGORY}">
				<input type="hidden" name="${entry.key}"
					value="<c:out value="${entry.value}"/>" />
			</c:if>
		</c:forEach>
		
		<c:forEach items="${searchcontext[SearchServlet.CATEGORY]}" var="item">
			<input type="hidden" name="${SearchServlet.CATEGORY}"
				value="<c:out value="${item}"/>" />
		</c:forEach>
		
		<input type="hidden" name="${SearchServlet.CURRENT_PAGE}"
			value="<c:out value="${current}"/>" /> 
		<input type="submit"
			value="<c:out value="${value}"/>" />
	</form>

Сборка и запуск:

	:::bash
	~$ cd src && mvn clean install && bash -c 'mvn -pl server/ jetty:run & sleep 10 && \
	    mvn -pl crawler/ exec:java -Dexec.mainClass="crawler.App" & \
	    trap "kill -TERM -$$" SIGINT ; wait'

<!-- <a href="{attach}download-kinopoisk.es6"></a> -->

[Исходники]({attach}lucene-tutorial.zip)
