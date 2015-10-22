title: Как перестать беспокоиться и начать портировать
category: JavaScript
tags: NLP, Lucene, ES6


Пример портирования **Java** => **JavaScript** на примере токенизаторов из [Lucene]({filename}../../java/lucene/2012-10-15-lucene-real-world/2012-10-15-lucene-real-world.md). [Исходники](https://github.com/mazko/mazko.github.io/tree/src/content/posts/javascript/2015-10-21-lucene-tokenizers-es6/src).

##TL;DR

Процесс можно условно разделить на несколько этапов:

- Зависимости от внешних библиотек дожны быть представленны в виде исходников, а незадействованный код по возможности удалён т.к. размер таки имеет значение и чем меньше весит портированный скрипт тем он быстрее отработает в браузере

- Точно так же системные классы среды исполнения *Java*, например *Character.java*, необходимо переопределить скопировав в проект 

- На этом этапе логика должна быть полностью рабочей, если у портируемого проекта имеются юнит-тесты - прогнать их. Если что-то не работает сейчас, вряд-ли заработает после трансляции :)

- Собственно сама [трансляция](http://mazko.github.io/ESJava/) добытых *Java* исходников в [ES6](https://babeljs.io/docs/learn-es2015/){:rel="nofollow"}

- Точечная адаптация - например реализовать логику метода *System.arraycopy*, который переопределили ранее, но уже для *JavaScript*


<noscript><span style="color:red;">Включите JavaScript ! </span></noscript>
<script type="text/javascript" src="{attach}src/out/lucene-tokenizers.babel.js"></script>

<script type="text/javascript">
(function() {
  var parseId;

  function id(i) {
      return document.getElementById(i);
  }
  function parse(delay) {
      if (parseId) {
          window.clearTimeout(parseId);
      }

      parseId = window.setTimeout(function () {
        var ts = new luceneTokenizers[id("tokenizer-class").value];
        ts.setReader(
          new luceneTokenizers.StringReader(
            id("text-to-tokenize").value)
        );
        var res = [];
        for (var token, i=0; (token = ts.incrementToken()) !== null; i++) {
          res.push(token);
        }
        id("tokenize-result").value = JSON.stringify(res, null, 2);
      }, delay || 1984);
  }
  window.onload = function () {
      var update = function() { parse(); };
      id("text-to-tokenize").onkeyup = update;
      id("tokenizer-class").onchange = update;
      parse();
  };
})();
</script>

<select id="tokenizer-class">
    <option value="StandardTokenizer">Standard</option>
    <option value="UAX29URLEmailTokenizer">UAX29URLEmail</option>
</select>

<div>
<!-- http://www.freeformatter.com/html-escape.html -->
<div style="width:49%; border:1px solid #ddd; float:left;">
  <textarea rows="10" id="text-to-tokenize" autocomplete="off"
    style="width:97%; margin:auto; color: #AAFF00; background-color: #111111; border: none; overflow:auto; padding: 5px; display: block;">The quick brown fox &lt;fox@mail.ru&gt; jumps over the 42 lazy dogs &lt; mailto:dog@gmail.com &gt; !? More at -> http://www.google.com/ &#9749;
  </textarea>
</div>
<div style="width:49%; border:1px solid #ddd; float:right;">
  <textarea rows="10" id="tokenize-result" autocomplete="off"
    style="width:97%; margin:auto; color: #EE00AA; background-color: #111111; border: none; overflow:auto; padding: 5px; display: block;" readonly></textarea>
</div>
<div style="clear:both;"></div>
</div>


Как видно на демке и несложно догадаться по названию токенайзер [UAX29URLEmailTokenizer](https://lucene.apache.org/core/5_3_1/analyzers-common/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizer.html){:rel="nofollow"} чуть более православный по вебу. Оба *StandardTokenizer* и *UAX29URLEmailTokenizer* вполне себе дружат с юникодом.

Теперь чуть подробней о процессе портирования.

##ESJava

Итоговая структура папок Java проекта (Eclipse):


    :::bash
    ~$ tree
    .
    ├── src
    │   ├── org
    │   │   └── apache
    │   │       └── lucene
    │   │           └── analysis
    │   │               ├── standard
    │   │               │   ├── Character.java
    │   │               │   ├── Exception.java
    │   │               │   ├── IndexOutOfBoundsException.java
    │   │               │   ├── IOException.java
    │   │               │   ├── Reader.java
    │   │               │   ├── StandardAnalyzer.java
    │   │               │   ├── StandardTokenizerImpl.java
    │   │               │   ├── StandardTokenizer.java
    │   │               │   ├── StringReader.java
    │   │               │   ├── System.java
    │   │               │   ├── Tokenizer.java
    │   │               │   ├── TokenModel.java
    │   │               │   ├── UAX29URLEmailTokenizerImpl.java
    │   │               │   └── UAX29URLEmailTokenizer.java
    │   │               └── tokenattributes
    │   │                   └── CharTermAttribute.java
    │   └── Test.java
    └── tests
        └── org
            └── apache
                └── lucene
                    └── analysis
                        └── standard
                            ├── BaseTokenStreamTestCase.java
                            ├── Slow.java
                            ├── TestStandardAnalyzer.java
                            ├── TestUAX29URLEmailTokenizer.java
                            ├── TestUtil.java
                            └── WordBreakTestUnicode_6_3_0.java

    13 directories, 22 files

Для удобства работы с исходниками среды выполнения Java:

    :::bash
    ~$ apt-get install openjdk-7-source

И так выглядит один из переопределённых в проекте системных файлов:

*src/org/apache/lucene/analysis/standardSystem.java*

    :::java
    public final class System {
      public static void arraycopy(Object src, int srcPos, Object dest, int destPos, int length) {
        // :es6:
        // int[] elements_to_add = src.slice(srcPos, srcPos + length);
        // Array.prototype.splice.apply(dest, new int[] {destPos,
        // elements_to_add.length}.concat(elements_to_add));
        java.lang.System.arraycopy(src, srcPos, dest, destPos, length);
        // :end:
      }
    }

В *ES6* есть хорошая инструкция ```import```, но поведение немного отличается от аналогичной в Java - файлы из одного пространства тоже необходимо импортировать явно. Но лень. Проще закинуть все классы в один файл:

*merge.sh*

    :::bash
    # find -name '*.java' | grep './src/org/apache/lucene/analysis/'
    cat \
    ./src/org/apache/lucene/analysis/standard/Exception.java \
    ./src/org/apache/lucene/analysis/standard/IOException.java \
    ./src/org/apache/lucene/analysis/standard/IndexOutOfBoundsException.java \
    ./src/org/apache/lucene/analysis/standard/Reader.java \
    ./src/org/apache/lucene/analysis/standard/StringReader.java \
    ./src/org/apache/lucene/analysis/standard/Character.java \
    ./src/org/apache/lucene/analysis/tokenattributes/CharTermAttribute.java \
    ./src/org/apache/lucene/analysis/standard/TokenModel.java \
    ./src/org/apache/lucene/analysis/standard/Tokenizer.java \
    ./src/org/apache/lucene/analysis/standard/System.java \
    ./src/org/apache/lucene/analysis/standard/StandardAnalyzer.java \
    ./src/org/apache/lucene/analysis/standard/StandardTokenizerImpl.java \
    ./src/org/apache/lucene/analysis/standard/StandardTokenizer.java \
    ./src/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizerImpl.java \
    ./src/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizer.java \
    | sed '/^package\s/d' | sed '/^import\s/d' \
    > lucene-tokenizers.java

И просмотреть список точечных адаптаций для JavaScript:

    :::bash
    ~$ awk '/\:es6\:/,/\:end\:/' lucene-tokenizers.java

Трансляция:

    :::bash
    ~$ npm install -g esjava
    ~$ node --stack-size=10000 `which esjava` lucene-tokenizers.java > out/lucene-tokenizers.es6

Осталось указать на *export* классы *StringReader*, *StandardTokenizer*, *UAX29URLEmailTokenizer* и добавить поддержку старых JavaScript движков:

*out/js.sh*

    :::bash
    ES6FILE='lucene-tokenizers.es6'

    for cls in 'StringReader' 'StandardTokenizer' 'UAX29URLEmailTokenizer'; do
      sed -i "s/^class\s\+${cls}\s\+/export class ${cls} /" ${ES6FILE}
    done

    sed 's/\\u/\\\\u/g' "$ES6FILE" |                     \
    node --stack-size=10000                              \
    "`which babel`"                                      \
    --compact=false                                      \
    --modules umdStrict --module-id luceneTokenizers |   \
    sed 's/\\\\u/\\u/g' > lucene-tokenizers.babel.js

Скрипт на выходе *lucene-tokenizers.babel.js* крутится в демке.

Юнит тесты: [StandardTokenizer]({attach}src/out/tests/TestStandardTokenizer.html), [UAX29URLEmailTokenizer]({attach}src/out/tests/TestTestUAX29URLEmailTokenizer.html)

<!-- Pelican Attach hack -->

<!-- find . -type f -not -path '*/\.*' | xargs -I{} -n1 echo -e '<a href="\x7Battach\x7Dsrc/{}"></a>' | xclip -selection clipboard -->

<!-- <a href="{attach}src/./lucene-tokenizers.java"></a>
<a href="{attach}src/./src/Test.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/IndexOutOfBoundsException.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/StandardTokenizer.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/StringReader.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/StandardTokenizerImpl.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizer.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/Reader.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/StandardAnalyzer.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/TokenModel.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/Character.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/Tokenizer.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/System.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/Exception.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/IOException.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizerImpl.java"></a>
<a href="{attach}src/./src/org/apache/lucene/analysis/tokenattributes/CharTermAttribute.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/BaseTokenStreamTestCase.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/TestUtil.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/TestUAX29URLEmailTokenizer.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/TestStandardAnalyzer.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/WordBreakTestUnicode_6_3_0.java"></a>
<a href="{attach}src/./tests/org/apache/lucene/analysis/standard/Slow.java"></a>
<a href="{attach}src/./notes"></a>
<a href="{attach}src/./out/lucene-tokenizers.babel.js"></a>
<a href="{attach}src/./out/js.sh"></a>
<a href="{attach}src/./out/tests/qunit/qunit-1.19.0.js"></a>
<a href="{attach}src/./out/tests/qunit/qunit-1.19.0.css"></a>
<a href="{attach}src/./out/tests/BaseTokenStreamTestCase.js"></a>
<a href="{attach}src/./out/tests/TestStandardTokenizer.html"></a>
<a href="{attach}src/./out/tests/TestTestUAX29URLEmailTokenizer.html"></a>
<a href="{attach}src/./out/tests/WordBreakTestUnicode_6_3_0.js"></a>
<a href="{attach}src/./out/lucene-tokenizers.es6"></a>
<a href="{attach}src/./merge.sh"></a>
 -->