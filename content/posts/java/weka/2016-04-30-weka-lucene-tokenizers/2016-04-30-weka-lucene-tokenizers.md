title: Как подружить Weka с Lucene (Tokenizer)
category: Java
tags: NLP, Weka, Lucene, Maven


В случае классификации [текстовой информации]({filename}../2016-04-26-weka-sentiment/2016-04-26-weka-sentiment.md) качество может зависеть не только от выбора алгоритма но и от способа преобразования текстовых данных к математический виду - в случае Weka этим занимается [StringToWordVector](http://weka.sourceforge.net/doc.dev/weka/filters/unsupervised/attribute/StringToWordVector.html){:rel="nofollow"} и одним из параметров у него задаётся тип [токенайзера](http://weka.sourceforge.net/doc.dev/weka/core/tokenizers/package-summary.html){:rel="nofollow"}. Задача токенайзера вроде как несложная - преобразовать строку текста в массив слов, но как нетрудно убедиться на картинке ниже если не полениться и задействовать более качественный [токенизатор]({filename}../../../admin/2015-10-21-lucene-tokenizers-es6/2015-10-21-lucene-tokenizers-es6.md), взятый например из [Lucene]({filename}../../lucene/2012-10-15-lucene-real-world/2012-10-15-lucene-real-world.md), итоговая точность определения категорий в Weka-классификаторе повышается:

![screenshot]({attach}weka-ui.gif){:style="width:100%; border:1px solid #ddd;"}

Итак [приступим](https://maven.apache.org/guides/getting-started/){:rel="nofollow"}:

    :::bash
    ~$ apt install maven
    ~$ mvn -B archetype:generate \
          -DarchetypeGroupId=org.apache.maven.archetypes \
          -DgroupId=weka.lucene \
          -DartifactId=weka-lucene
    ~$ cd weka-lucene/

Зависимости [Weka](http://mvnrepository.com/artifact/nz.ac.waikato.cms.weka/weka-stable){:rel="nofollow"}, [Lucene Analyzers](http://mvnrepository.com/artifact/org.apache.lucene/lucene-analyzers-common){:rel="nofollow"}:

*pom.xml*

    :::xml
    <project xmlns="http://maven.apache.org/POM/4.0.0" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
      <modelVersion>4.0.0</modelVersion>
      <groupId>weka.lucene</groupId>
      <artifactId>weka-lucene</artifactId>
      <packaging>jar</packaging>
      <version>1.0-SNAPSHOT</version>
      <name>weka-lucene</name>
      <url>http://maven.apache.org</url>
      <dependencies>
        <dependency>
          <groupId>junit</groupId>
          <artifactId>junit</artifactId>
          <version>4.12</version>
          <scope>test</scope>
        </dependency>
        <dependency>
          <groupId>org.apache.lucene</groupId>
          <artifactId>lucene-analyzers-common</artifactId>
          <version>6.0.0</version>
        </dependency>
        <dependency>
          <groupId>nz.ac.waikato.cms.weka</groupId>
          <artifactId>weka-stable</artifactId>
          <version>3.8.0</version>
        </dependency>
      </dependencies>
    </project>

Проверить актуальность зависимостей как всегда можно ```mvn versions:display-dependency-updates```.

    :::bash
    ~$ tree
    .
    ├── pom.xml
    └── src
        ├── main
        │   └── java
        │       └── weka
        │           └── core
        │               └── tokenizers
        │                   └── LuceneTokenizer.java
        └── test
            └── java
                └── weka
                    └── core
                        └── tokenizers
                            └── LuceneTokenizerTest.java

    11 directories, 3 files

*src/main/java/weka/core/tokenizers/LuceneTokenizer.java*

    :::java
    package weka.core.tokenizers;

    import java.lang.Math;
    import java.io.IOException;
    import java.io.StringReader;
    import java.util.Enumeration;
    import java.util.Vector;

    import org.apache.lucene.analysis.TokenStream;
    import org.apache.lucene.analysis.shingle.ShingleFilter;
    import org.apache.lucene.analysis.standard.UAX29URLEmailTokenizer;
    import org.apache.lucene.analysis.tokenattributes.CharTermAttribute;

    import weka.core.Option;
    import weka.core.RevisionUtils;
    import weka.core.Utils;

    public class LuceneTokenizer extends Tokenizer {

        private transient TokenStream m_stream;

        /** the maximum number of N */
        private int m_NMax = 3;

        /** the minimum number of N */
        private int m_NMin = 1;

        /**
         * Returns the revision string.
         * 
         * @return the revision
         */
        @Override
        public String getRevision() {
            return RevisionUtils.extract("$Revision: 1.0 $");
        }

        /**
         * Returns a string describing the tokenizer
         * 
         * @return a description suitable for displaying in the
         *         explorer/experimenter gui
         */
        @Override
        public String globalInfo() {
            return "Tokenizer based on Apache Lucene UAX29URLEmailTokenizer & ShingleFilter.";
        }

        /**
         * Returns true if there's more elements available
         * 
         * @return true if there are more elements available
         */
        @Override
        public boolean hasMoreElements() {
            try {
                if (m_stream.incrementToken()) {
                    return true;
                } else {
                    m_stream.end();
                    m_stream.close();
                    return false;
                }
            } catch (final IOException e) {
                throw new RuntimeException(e);
            }
        }

        /**
         * Returns N-grams and also (N-1)-grams and .... and 1-grams.
         * 
         * @return the next element
         */
        @Override
        public String nextElement() {
            final CharSequence o = m_stream.getAttribute(CharTermAttribute.class);
            return o.toString();
        }

        /**
         * Sets the string to tokenize.
         * 
         * @param s
         *            the string to tokenize
         */
        @Override
        public void tokenize(final String s) {
            final UAX29URLEmailTokenizer t = new UAX29URLEmailTokenizer();
            t.setReader(new StringReader(s));
            if (m_NMax > 1) {
                final ShingleFilter f = new ShingleFilter(t, m_NMax);
                if (m_NMin > 1) {
                    f.setMinShingleSize(m_NMin);
                    f.setOutputUnigrams(false);
                }
                m_stream = f;
            } else {
                m_stream = t;
            }

            try {
                m_stream.reset();
            } catch (final IOException e) {
                throw new RuntimeException(e);
            }
        }

        /**
         * Returns an enumeration of all the available options..
         * 
         * @return an enumeration of all available options.
         */

        @Override
        public Enumeration<Option> listOptions() {
            final Vector<Option> result = new Vector<Option>();
            @SuppressWarnings("unchecked")
            final Enumeration<Option> enm = super.listOptions();

            while (enm.hasMoreElements()) {
                result.addElement(enm.nextElement());
            }

            result.addElement(
                new Option("\tThe max size of the Ngram (default = 3).", "max", 1, "-max <int>"));

            result.addElement(
                new Option("\tThe min size of the Ngram (default = 1).", "min", 1, "-min <int>"));

            return result.elements();
        }

        /**
         * Gets the current option settings for the OptionHandler.
         * 
         * @return the list of current option settings as an array of strings
         */
        @Override
        public String[] getOptions() {
            Vector<String> result;
            String[] options;
            int i;

            result = new Vector<String>();

            options = super.getOptions();
            for (i = 0; i < options.length; i++) {
                result.add(options[i]);
            }

            result.add("-max");
            result.add("" + getNGramMaxSize());

            result.add("-min");
            result.add("" + getNGramMinSize());

            return result.toArray(new String[result.size()]);
        }

        /**
         * Parses a given list of options.
         * 
         * @param options
         *            the list of options as an array of strings
         * @throws Exception
         *             if an option is not supported
         */
        @Override
        public void setOptions(final String[] options) throws Exception {
            String value;

            super.setOptions(options);

            value = Utils.getOption("max", options);
            if (value.length() != 0) {
                setNGramMaxSize(Integer.parseInt(value));
            } else {
                setNGramMaxSize(3);
            }

            value = Utils.getOption("min", options);
            if (value.length() != 0) {
                setNGramMinSize(Integer.parseInt(value));
            } else {
                setNGramMinSize(1);
            }
        }

        /**
         * Gets the max N of the NGram.
         * 
         * @return the size (N) of the NGram.
         */
        public int getNGramMaxSize() {
            return m_NMax;
        }

        /**
         * Sets the max size of the Ngram.
         * 
         * @param value
         *            the size of the NGram.
         */
        public void setNGramMaxSize(final int value) {
            m_NMax = Math.max(1, value);
        }

        /**
         * Returns the tip text for this property.
         * 
         * @return tip text for this property suitable for displaying in the
         *         explorer/experimenter gui
         */
        public String NGramMaxSizeTipText() {
            return "The max N of the NGram.";
        }

        /**
         * Sets the min size of the Ngram.
         * 
         * @param value
         *            the size of the NGram.
         */
        public void setNGramMinSize(final int value) {
            m_NMin = Math.max(1, value);
        }

        /**
         * Gets the min N of the NGram.
         * 
         * @return the size (N) of the NGram.
         */
        public int getNGramMinSize() {
            return m_NMin;
        }

        /**
         * Returns the tip text for this property.
         * 
         * @return tip text for this property suitable for displaying in the
         *         explorer/experimenter gui
         */
        public String NGramMinSizeTipText() {
            return "The min N of the NGram.";
        }

        /**
         * Runs the tokenizer with the given options and strings to tokenize. The
         * tokens are printed to stdout.
         * 
         * @param args
         *            the commandline options and strings to tokenize
         */
        public static void main(final String[] args) {
            runTokenizer(new LuceneTokenizer(), args);
        }
    }

*src/test/java/weka/core/tokenizers/LuceneTokenizerTest.java*

    :::java
    package weka.core.tokenizers;

    import org.junit.Assert;
    import org.junit.Test;


    public class LuceneTokenizerTest {

        /** Creates a default LuceneTokenizer */
        final Tokenizer m_Tokenizer = new LuceneTokenizer();

        /**
         * tests the number of generated tokens
         * 
         * @throws Exception
         */
        @Test
        public void testNumberOfGeneratedTokens() throws Exception {

            final String s = "HOWEVER, the egg only got larger and larger, and more and more human";
            String[] result;

            // only 1-grams

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "1", s });
            Assert.assertEquals("number of tokens differ (1)", 13, result.length);

            // only 2-grams

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "2", "-max", "2", s });
            Assert.assertEquals("number of tokens differ (2)", 12, result.length);

            // 1 to 3-grams

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "3", s });
            Assert.assertEquals("number of tokens differ (3)", 36, result.length);

            // 1 to 5-grams

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "5", s });
            Assert.assertEquals("number of tokens differ (4)", 55, result.length);
        }

        /**
         * tests the number of generated tokens
         * 
         * @throws Exception
         */
        @Test
        public void testNumberOfGeneratedTokensCannotSplit() throws Exception {

            // 1 to 3-grams, but sentence only has 2 grams

            final String s = "cannot split";
            String[] result;

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "3", s });
            Assert.assertEquals("number of tokens differ", 3, result.length);
        }

        /**
         * tests the number of generated tokens
         * 
         * @throws Exception
         */
        @Test
        public void testNumberOfGeneratedBlank() throws Exception {
            String s;
            String[] result;

            s = " ";
            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "3", s });
            Assert.assertEquals("number of tokens differ", 0, result.length);

            s = "!-/";
            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "3", s });
            Assert.assertEquals("number of tokens differ", 0, result.length);
        }

        /**
         * tests the content of generated tokens
         * 
         * @throws Exception
         */
        @Test
        public void testContentOfGeneratedTokens() throws Exception {
            final String s = "The quick brown fox jumps over the lazy dog@dog.com";
            String[] result;

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "1", "-max", "3", s });
            Assert.assertArrayEquals("dismatch", new String[] {
                "The", "The quick", "The quick brown",
                "quick", "quick brown", "quick brown fox",
                "brown", "brown fox", "brown fox jumps",
                "fox", "fox jumps", "fox jumps over",
                "jumps", "jumps over", "jumps over the",
                "over", "over the", "over the lazy",
                "the", "the lazy", "the lazy dog@dog.com",
                "lazy", "lazy dog@dog.com", "dog@dog.com"
            }, result);

            result = Tokenizer.tokenize(m_Tokenizer, new String[] { "-min", "2", "-max", "4", s });
            Assert.assertArrayEquals("dismatch", new String[] {
                "The quick", "The quick brown", "The quick brown fox",
                "quick brown", "quick brown fox", "quick brown fox jumps",
                "brown fox", "brown fox jumps", "brown fox jumps over",
                "fox jumps", "fox jumps over", "fox jumps over the",
                "jumps over", "jumps over the", "jumps over the lazy",
                "over the", "over the lazy", "over the lazy dog@dog.com",
                "the lazy", "the lazy dog@dog.com", "lazy dog@dog.com"
            }, result);
        }

    }

Проверка, [исходники]({attach}weka-lucene.zip):

    :::bash
    ~$ mvn clean test
       Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
    ~$ mvn clean install exec:java -Dexec.mainClass="weka.gui.GUIChooser"
