title: Анализ тональности текста с помощью Weka
category: Java
tags: NLP, Weka, REPL


Имеется [заданный]({attach}kino1k.tar.gz) набор документов для которых уже заранее известна тональность: **good**, **neutral**, **bad**. Для [нового](http://ole.in.ua/) документа необходимо определить какая у него тональность из трёх указанных.
Идеального решения тут не существует ну хотябы потому, что понятие хороший/плохой/злой часто субъективно :) Но всё-же можно попробовать взять среднюю температуру по больнице [задействовав](https://habrahabr.ru/post/149605/){:rel="nofollow"} т.н. Машинное Обучение (ML). Причём в нашем случае это будет Машинное Обучение с учителем т.к. набор обучающих данных имеется изначально.

Очевидно главный показатель работы классификатора - точность. Поскольку в ML обычно требуется много экспериментировать с различными параметрами, то наряду с множеством *open-source* проектов наличие какого-никакого UI не может не радовать и у [Weka](http://www.cs.waikato.ac.nz/ml/weka/){:rel="nofollow"} UI есть.

![screenshot]({attach}weka-ui.gif){:style="width:100%; border:1px solid #ddd;"}

Подробней процесс классификации в Weka расписан [тут](http://jmgomezhidalgo.blogspot.com/2013/01/text-mining-in-weka-chaining-filters.html){:rel="nofollow"}. Теперь то же самое, что на картинке, но уже в терминале и без UI (фильтры Weka выглядят жутковато, но их необязательно набивать ручками - можно скопировать из UI что и сделано в конце анимации):

    :::sh
    ~$ P1=http://mazko.github.io/blog/posts/2016/04/26/ \
       P2=analiz-tonalnosti-teksta-s-pomoshchiu-weka/kino1k.tar.gz \
       sh -c 'curl -sL "${P1}${P2}" | tar xz'

    ~$ alias javam='java -Xmx2g -cp ./weka-3-8-0/*:.'

    ~$ javam weka.core.converters.TextDirectoryLoader \
       -dir kino1k > /tmp/weka-output$$.arff

    # note loaded text attributes attributes and their order
    # we shall use this order later in Java application
    ~$ head -n4 /tmp/weka-output$$.arff

    # optionally switch to sh because bash requires additional escape
    # of ! symbol which is used in NGramTokenizer delimiters
    ~$ javam weka.classifiers.meta.FilteredClassifier \
        -F "weka.filters.MultiFilter \
            -F \"weka.filters.unsupervised.attribute.StringToWordVector \
                -R first-last -W 4444 -prune-rate -1.0 -N 0 \
                -stemmer weka.core.stemmers.NullStemmer \
                -stopwords-handler weka.core.stopwords.Null \
                -M 1 -tokenizer \\\"weka.core.tokenizers.NGramTokenizer -max 3 -min 1 \\\"\" \
            -F \"weka.filters.supervised.attribute.AttributeSelection \
                -E \\\"weka.attributeSelection.InfoGainAttributeEval \\\" \
                -S \\\"weka.attributeSelection.Ranker -T 0.0 -N -1\\\"\"" \
        -W weka.classifiers.bayes.NaiveBayesMultinomial \
        -t /tmp/weka-output$$.arff \
        -d ./sentiment-naive-bayes-multinomial.1.3.ig.model -x 3


Дополнительно классификатор сериализуется в файл ```sentiment-naive-bayes-multinomial.1.3.ig.model``` что позволит его использовать с пользой для дела:

*Classy.java*

    :::java
    import java.util.ArrayList;
    import java.util.stream.IntStream;

    import weka.classifiers.meta.FilteredClassifier;
    import weka.core.Attribute;
    import weka.core.DenseInstance;
    import weka.core.Instance;
    import weka.core.Instances;
    import weka.core.SerializationHelper;

    public class Classy {
        public class ClassyResult {
            public final double score;
            public final String clazz;

            public ClassyResult(final String clazz, final double score) {
                this.score = score;
                this.clazz = clazz;
            }

            public String toString() {
                return this.clazz + " -> " + this.score;
            }
        }

        /** The actual classifier. */
        private final FilteredClassifier m_classifier;

        /** The actual classifier algorithm */
        private final String m_algorithm;

        public Classy(final String model) throws Exception {
            m_classifier = (FilteredClassifier) SerializationHelper.read(model);
            m_algorithm = m_classifier.getClassifier().getClass().getSimpleName();
        }

        /**
         * Method that converts a text message into an instance.
         * 
         * @param text
         *            the message content to convert
         * @param data
         *            the header information
         * @return the generated Instance
         */
        private Instances makeInstance(final String text) {

            // Create vector of attributes.
            final ArrayList<Attribute> fvWekaAttributes = new ArrayList<Attribute>(2);

            // Add attribute for holding messages.
            final Attribute attrText = new Attribute("text", (ArrayList<String>) null);
            fvWekaAttributes.add(attrText);

            // Add class attribute.
            // Order is important: head -n4 /tmp/weka-output$$.arff
            // ...
            // @attribute @@class@@ {neutral,bad,good}
            final ArrayList<String> fvClassVal = new ArrayList<String>(3);
            fvClassVal.add("neutral");
            fvClassVal.add("bad");
            fvClassVal.add("good");
            final Attribute attrClass = new Attribute("@@class@@", fvClassVal);
            fvWekaAttributes.add(attrClass);

            // Create dataset with initial capacity of 0, and set index of class.
            final Instances instances = new Instances("Rel", fvWekaAttributes, 0);
            instances.setClassIndex(instances.numAttributes() - 1);

            // Create and add the instance
            final Instance instance = new DenseInstance(2);
            instance.setValue(attrText, text);
            instances.add(instance);

            // DEBUG: if something goes wrong 
            // or to understand better what we've just
            // done you can always compare output:
            // head -n4 /tmp/weka-output$$.arff
            // @relation _any_name_is_valid
            // @attribute text string
            // @attribute @@class@@ {neutral,bad,good}
            // with generated instance:
            // System.out.println(instances);
            // @relation Rel
            // @attribute text string
            // @attribute @@class@@ {neutral,bad,good}
            // @data
            // ...

            return instances;
        }

        public ClassyResult[] assignClass(final String message) throws Exception {

            // Make message into instance.
            final Instances instances = makeInstance(message);

            // Get index of predicted class value.
            final Instance in = instances.instance(0);

            // Get the predicted probabilities
            final double[] ps = m_classifier.distributionForInstance(in);

            return IntStream.range(0, ps.length)
                .mapToObj(i -> new ClassyResult(in.classAttribute().value(i), ps[i]))
                .toArray(ClassyResult[]::new);
        }

        public String getAlgorithm() {
            return m_algorithm;
        }

    }

*App.java*

    ::java
    import java.util.Arrays;
    import java.util.Scanner;

    public class App { 
        public static void main(final String[] args) throws Exception {
            System.out.println("Loading model...");
            final Classy instance = new Classy("./sentiment-naive-bayes-multinomial.1.3.ig.model");
            System.out.println("Model loaded");
            System.out.println("Model trained algorithm: " + instance.getAlgorithm());
            System.out.println("Now print text to analyze!");
            try(final Scanner scan = new Scanner(System.in)) {
                while (true) {
                    System.out.print("> ");
                    if (!scan.hasNextLine()) break;
                    final String line = scan.nextLine();
                    final Classy.ClassyResult[] result = instance.assignClass(line);
                    System.out.println(Arrays.toString(result));
                }
            }

        } 
    }

REPL:

    :::bash
    ~$ javac App.java Classy.java -cp ./weka-3-8-0/*:.
    ~$ java -cp ./weka-3-8-0/*:. App
    Loading model...
    Model loaded
    Model trained algorithm: NaiveBayesMultinomial
    Now print text to analyze!
    > жизнь прекрасна
    [neutral -> 0.32679098745501506, bad -> 0.23459195142944572, good -> 0.4386170611155391]
    > всё плохо
    [neutral -> 0.31243645980279694, bad -> 0.4502602266214787, good -> 0.2373033135757244]

В продолжение темы добавление функциональности Weka на примере [Lucene токенизаторов]({filename}../2016-04-30-weka-lucene-tokenizers/2016-04-30-weka-lucene-tokenizers.md).