title: Lucene - синтаксис запросов
category: Java
tags: Lucene


Как уже упоминалось [ранее]({filename}../2012-10-21-lucene-real-world---simple-search/2012-10-21-lucene-real-world---simple-search.md), между строкой запроса, которую вводит пользователь для осуществления поиска и  методом, реализующим непосредственно сам поиск в *Lucene*, имеется промежуточный класс - `Query`. Этот класс можно создавать программно - причём можно создавать даже очень сложный  `Query`, используя комбинацию из нескольких из них, тем самым достигая наилучших результатов поиска. Однако последнее не всегда целесообразно делать вручную - в *Lucene* уже имеется определённый синтаксис запросов, который позволяет распарсить вводимую пользователем строку и тем самым автоматически создать сложный `Query`. До этого момента мы не использовали данный механизм, принудительно экранируя все запросы методом `QueryParser.escape`:

*jLucene/server/webapps/search/src/nongreedy/QueryHelper.java*

    :::java
    package nongreedy;

    import org.apache.lucene.queryParser.MultiFieldQueryParser;
    import org.apache.lucene.queryParser.ParseException;
    import org.apache.lucene.queryParser.QueryParser;
    import org.apache.lucene.search.MultiTermQuery;
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

            /* Here are some changes for SYNTAX DEMO */

            parser.setAllowLeadingWildcard(true);
            parser.setMultiTermRewriteMethod(
                MultiTermQuery.SCORING_BOOLEAN_QUERY_REWRITE);

            return parser.parse(story);
        }
    }

К сожалению используемый нами ранее класс `Highlighter` для подсветки найденных результатов не умеет работать с некоторыми сложными типами `Query`, поэтому их необходимо преобразовать в более простые - вызвать на этапе парсинга `setMultiTermRewriteMethod`, а в процессе подсветки выполнить `Query.rewrite`:

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

                /*
                 * A query must be rewritten in its most primitive 
                 * form for Query-TermScorer to be happy. For example, 
                 * wildcard, fuzzy, prefix, and range queries rewrite 
                 * themselves to a BooleanQuery of all the matching
                 * terms. Call Query. rewrite(IndexReader), which
                 * translates the query into primitive form, to 
                 * rewrite a query prior to passing the Query to 
                 * QueryTermScorer (unless you’re sure
                 * the query is already a primitive one).
                 */

                final QueryScorer scorer = new QueryScorer(
                        query.rewrite(indexSearcher.getIndexReader()));
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
                    doc.get(LuceneBinding.URI_FIELD), 
                    sd.score, highlightedTitle, highlightedContent);
        }
    }

Теперь можно откинуться на спинку кресла и насладиться результатами, хотя... В нашем случае итоговую картину сильно смазывают языковые анализаторы - `RussianAnalyzer` и `EnglishAnalyzer`, поэтому предлагаю не полениться и вернуться на время освоения текущего материала к использованию в процессе поиска только одного анализатора - `StandardAnalyzer`. Так будет лучше видно, в чем именно соль того или иного запроса:

*jLucene/server/webapps/search/src/nongreedy/QueryHelper.java*

    :::java
    package nongreedy;

    import org.apache.lucene.queryParser.MultiFieldQueryParser;
    import org.apache.lucene.queryParser.ParseException;
    import org.apache.lucene.queryParser.QueryParser;
    import org.apache.lucene.search.MultiTermQuery;
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

            /* Here are some changes for SYNTAX DEMO */

            parser.setAllowLeadingWildcard(true);
            parser.setMultiTermRewriteMethod(
                MultiTermQuery.SCORING_BOOLEAN_QUERY_REWRITE);

            return parser.parse(story);
        }
    }

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

                /*
                 * A query must be rewritten in its most primitive 
                 * form for Query-TermScorer to be happy. For example, 
                 * wildcard, fuzzy, prefix, and range queries rewrite 
                 * themselves to a BooleanQuery of all the matching
                 * terms. Call Query. rewrite(IndexReader), which
                 * translates the query into primitive form, to 
                 * rewrite a query prior to passing the Query to 
                 * QueryTermScorer (unless you’re sure
                 * the query is already a primitive one).
                 */

                final QueryScorer scorer = new QueryScorer(
                        query.rewrite(indexSearcher.getIndexReader()));
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
                    new String[] { LuceneBinding.TITLE_FIELD });
            final String highlightedContent = tryHighlight(content,
                    new String[] { LuceneBinding.CONTENT_FIELD });

            return new HighlightedSearchItem(title, content,
                    doc.get(LuceneBinding.URI_FIELD), 
                    sd.score, highlightedTitle, highlightedContent);
        }
    }

###Синтаксис

Семейство *WildcardQuery*: **бо?** - вместо '?' может быть ОДИН любой символ; **бо*** любое количество **0..n** любых символов после 'бо'

![screenshot]({attach}prefix1.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}prefix2.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}prefix3.png){:style="width:100%; border:1px solid #ddd;"}

*FuzzyQuery* - ищутся похожие слова:

![screenshot]({attach}fuzzy.png){:style="width:100%; border:1px solid #ddd;"}

Поиск по конкретным полям в индексе:

![screenshot]({attach}field.png){:style="width:100%; border:1px solid #ddd;"}

Булевые запросы:

![screenshot]({attach}content_boolean.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}field_boolean_not.png){:style="width:100%; border:1px solid #ddd;"}

*PhraseQuery* - поиск фразы. С помощью '~' можно задать максимальное расстояние между словами фразы.

![screenshot]({attach}phrase.png){:style="width:100%; border:1px solid #ddd;"}

![screenshot]({attach}phrase_fuzzy.png){:style="width:100%; border:1px solid #ddd;"}

Исходники на [github](https://github.com/mazko/Lucene-Jetty-Lessons/tree/master/Lucene_Query_Syntax){:rel="nofollow"}.
