title: Emscripten: портирование C/C++ на JavaScript (GNU sed | grep)
category: Admin
tags: Emscripten, Docker


[Emscripten](http://kripken.github.io/emscripten-site/docs/compiling/Building-Projects.html){:rel="nofollow"} это набор инструментов с открытым кодом для кросскомпиляции C/C++ проектов в JavaScript. Собственно сразу *online* демка портированных таким образом GNU *sed* и *grep*, а ниже можно оценить до чего же просто это делается. В поле ввода вводятся аргументы как при обычном вызове программ: ```--help``` и т.д. за исключением работы с файловой системой, т.к. браузер работает в песочнице.

[sed](http://sed.js.org/) | [grep](http://grep.js.org/)

<noscript><span style="color:red;">Включите JavaScript ! </span></noscript>
<script type="text/javascript" src="{attach}gnu_sed.js"></script>
<script type="text/javascript" src="{attach}gnu_grep.js"></script>

<script type="text/javascript">
(function() {

  var parseId, 
      sed_default_input = "-e 's/Fyodor \\(Dostoyevsky\\)/F. \\1/' -e 'n;d'",
      grep_default_input = "--text 'Dostoyevsky\\|Tolstoy'";

  function id(i) {
      return document.getElementById(i);
  }
  function parse(delay) {
      if (parseId) {
          window.clearTimeout(parseId);
      }

      parseId = window.setTimeout(function () {
        var input = id("text-input").value;
        var args = id("current-exec-args").value;
        var exec = id("current-exec").value;
        var output = window[exec](input, args);
        id("out-result").value = output.replace(/\n$/, "");
      }, delay || 555);
  }
  window.onload = function () {
      var update = function() { parse(); };
      id("text-input").onkeyup = update;
      id("current-exec").onchange = function() {
        id("current-exec-args").value = 
          id("current-exec").value === 'fn_gnu_sed'
            ? sed_default_input
            : grep_default_input;
        update(); 
      };
      id("current-exec-args").onkeyup = update;
      id("current-exec-args").value = sed_default_input;
      parse();
  };
})();
</script>

<!-- http://stackoverflow.com/q/5825861/ -->
<p style="display: flex;">
<select id="current-exec" style="margin-right:5px;">
    <option value="fn_gnu_sed">sed</option>
    <option value="fn_gnu_grep">grep</option>
</select>
<input id="current-exec-args" type="text" style="flex: 1;">
</p>

<div>
<!-- http://www.freeformatter.com/html-escape.html -->
<div style="width:49%; border:1px solid #ddd; float:left;">
  <textarea rows="10" id="text-input" autocomplete="off"
    style="width:97%; margin:auto; color: #AAFF00; background-color: #111111; border: none; overflow:auto; padding: 5px; display: block;">1  . In Search of Lost Time by Marcel Proust 
2  . Ulysses by James Joyce
3  . Don Quixote by Miguel de Cervantes
4  . Moby Dick by Herman Melville
5  . Hamlet by William Shakespeare
6  . War and Peace by Leo Tolstoy
7  . The Odyssey by Homer
8  . The Great Gatsby by F. Scott Fitzgerald
9  . The Divine Comedy by Dante Alighieri 
10 . Madame Bovary by Gustave Flaubert
11 . The Brothers Karamazov by Fyodor Dostoyevsky
12 . One Hundred Years of Solitude by Gabriel Garcia Marquez
13 . The Adventures of Huckleberry Finn by Mark Twain
14 . The Iliad by Homer
15 . Lolita by Vladimir Nabokov
16 . Anna Karenina by Leo Tolstoy
17 . Crime and Punishment by Fyodor Dostoyevsky
18 . Alice's Adventures in Wonderland by Lewis Carroll
19 . The Sound and the Fury by William Faulkner
20 . Pride and Prejudice by Jane Austen
21 . The Catcher in the Rye by J. D. Salinger
22 . Wuthering Heights by Emily Brontë
23 . Nineteen Eighty Four by George Orwell
24 . Heart of Darkness by Joseph Conrad
25 . To the Lighthouse by Virginia Woolf
26 . Absalom, Absalom! by William Faulkner
27 . Middlemarch by George Eliot
28 . The Trial by Franz Kafka
29 . One Thousand and One Nights by India/Iran/Iraq/Egypt
30 . The Stories of Anton Chekhov by Anton Chekhov
31 . The Red and the Black by Stendhal
32 . Gulliver's Travels by Jonathan Swift
33 . Catch-22 by Joseph Heller
34 . The Grapes of Wrath by John Steinbeck
35 . Invisible Man by Ralph Ellison
36 . The Stranger by Albert Camus
37 . Great Expectations by Charles Dickens
38 . The Aeneid by Virgil
39 . David Copperfield by Charles Dickens
40 . Mrs. Dalloway by Virginia Woolf
41 . Beloved by Toni Morrison
42 . The Canterbury Tales by Geoffrey Chaucer
43 . Collected Fiction by Jorge Luis Borges
44 . Leaves of Grass by Walt Whitman
45 . Candide by Voltaire
46 . Jane Eyre by Charlotte Brontë
47 . As I Lay Dying by William Faulkner
48 . The Sun Also Rises by Ernest Hemingway
49 . The Complete Stories of Franz Kafka by Franz Kafka
50 . Tristram Shandy by Laurence Sterne
51 . A Portrait of the Artist as a Young Man by James Joyce
52 . The Portrait of a Lady by Henry James
53 . Oedipus the King by Sophocles
54 . Les Misérables by Victor Hugo
55 . To Kill a Mockingbird by Harper Lee
56 . Paradise Lost by John Milton
57 . The Complete Tales and Poems of Edgar Allan Poe by Edgar Allan Poe
58 . Pale Fire by Vladimir Nabokov
59 . A Passage to India by E.M. Forster
60 . The Idiot by Fyodor Dostoyevsky
61 . The Scarlet Letter by Nathaniel Hawthorne
62 . Antigone by Sophocles
63 . Faust by Johann Wolfgang von Goethe
64 . The Magic Mountain by Thomas Mann
65 . Dead Souls by Nikolai Gogol
66 . The Metamorphosis by Franz Kafka
67 . Midnight's Children by Salman Rushdie
68 . Emma by Jane Austen
69 . For Whom the Bell Tolls by Ernest Hemingway
70 . Frankenstein by Mary Shelley
71 . Journey to the End of The Night by Louis-Ferdinand Céline
72 . Oresteia by Aeschylus
73 . The Old Man and the Sea by Ernest Hemingway
74 . Vanity Fair by William Makepeace Thackeray
75 . The Complete Stories of Flannery O'Connor by Flannery O'Connor
76 . Under the Volcano by Malcolm Lowry
77 . Gargantua and Pantagruel by Francois Rabelais
78 . Tom Jones by Henry Fielding
79 . Fairy Tales and Stories by Hans Christian Anderson
80 . Things Fall Apart by Chinua Achebe
81 . The Flowers of Evil by Charles Baudelaire
82 . Brave New World by Aldous Huxley
83 . The Tin Drum by Günter Grass
84 . The Good Soldier by Ford Madox Ford
85 . A Farewell to Arms by Ernest Hemingway
86 . The Possessed by Fyodor Dostoevsky
87 . Poems of Emily Dickinson by Emily Dickinson
88 . On the Road by Jack Kerouac
89 . The Master and Margarita by Mikhail Bulgakov
90 . The Castle by Franz Kafka
91 . Father Goriot by Honoré de Balzac
92 . Stories of Ernest Hemingway by Ernest Hemingway
93 . Robinson Crusoe by Daniel Defoe
94 . Collected Poems of W. B. Yeats by W. B. Yeats
95 . The Charterhouse of Parma by Stendhal
96 . The Tale of Genji by Murasaki Shikibu
97 . Oedipus at Colonus by Sophocles
98 . Fathers and Sons by Ivan Turgenev
99 . Metamorphoses by Ovid</textarea>
</div>
<div style="width:49%; border:1px solid #ddd; float:right;">
  <textarea rows="10" id="out-result" autocomplete="off"
    style="width:97%; margin:auto; color: #EE00AA; background-color: #111111; border: none; overflow:auto; padding: 5px; display: block;" readonly></textarea>
</div>
<div style="clear:both;"></div>
</div>

Собирается *Emscripten* из исходников довольно небыстро ~3 часа на ноуте core i3 4GB, посему проще прибегнуть к помощи готового образа для [docker](http://docs.docker.com/engine/installation/ubuntulinux/){:rel="nofollow"}:

*emcc-env/activate*

    :::bash
    for alias in 'emcc' 'emconfigure' 'emmake'; do
      alias $alias="sudo docker run -i -t --rm -v \$(pwd):/home/src 42ua/emsdk $alias"
    done
    unset alias

    PS1="(emsdk)$PS1"

Трюк с *activate* позволит абстрагироваться от деталей работы с *docker* и сконцентрироваться на кросскомпиляции:

    :::bash
    ~$ sudo docker pull 42ua/emsdk
    ~$ source emcc-env/activate
    (emsdk)~$ emcc -v
    emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 1.35.8
    clang version 3.8.0  (emscripten 1.35.8 : 1.35.8)
    Target: x86_64-unknown-linux-gnu
    Thread model: posix

Если повезёт, кросскомпиляция мало чем отличается от обычной сборки:

    :::bash
    ~$ curl -sL http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.gz  | tar xz && cd sed-4.2.2
    ~$ emconfigure ./configure --host=asmjs-local-emscripten
    ~$ emmake make
    ~$ emcc -o sed.node.js sed/*.o lib/libsed.a
    ~$ echo 'xof nworb kciuq ehT' | node sed.node.js \
        -e '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' \
        -e 's/$/!/'
    The quick brown fox!

Оптимизация возможна как на уровне LLVM так и JS включительно с Closure Compiler. Чего можно ожидать от оптимизации ?

    :::bash
    ~$ ls -sh sed.node.js
    1,9M sed.node.js
    ~$ emcc -O2 --memory-init-file 0 -o sed.js sed/*.o lib/libsed.a
    ~$ ls -sh sed.js
    620K sed.js

Наконец для удобства работы в брузере немного [шаманства](http://mozakai.blogspot.com/2012/03/howto-port-cc-library-to-javascript.html){:rel="nofollow"} и дело в шляпе:

*gnu_sed_template.js*

```js
var fn_parse_argc = require('shell-quote').parse;

module.exports = function(input_str, args_str) {

  var Module = {}, window = {};

  window.prompt = (function() {
    var input = input_str;
    return function() {
      var value = input;
      input = null;
      return value;
    };
  })();

  Module['thisProgram'] = 'sed';

  Module['arguments'] = fn_parse_argc(args_str);

  Module['return'] = '';

  Module['print'] = Module['printErr'] = function (text) {
      Module['return'] += text + '\n';
  };

  /* SED.RAW.JS */

  return Module['return'];
};
```

    :::bash
    ~$ sed '/\/\* SED.RAW.JS \*\// {
      r sed.js
      d
    }' < gnu_sed_template.js > gnu_sed.node.js
    ~$ browserify gnu_sed.node.js --standalone fn_gnu_sed > gnu_sed.js

Процедура с портирования [grep](http://ftp.gnu.org/gnu/grep/grep-2.22.tar.xz){:rel="nofollow"} мало чем отличается за исключением флага *--disable-threads* на этапе ```./configure```.