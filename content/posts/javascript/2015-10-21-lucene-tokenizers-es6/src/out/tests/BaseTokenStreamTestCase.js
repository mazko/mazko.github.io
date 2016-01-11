function makeStrOfChrs(chr, num) {
  var arr = new Array(num);
  for (var i = 0; i < num; i++) {
    arr[i] = chr;
  }
  return arr.join('');
}

function assertTokenStreamContents(ts, texts, types, starts, ends) {
  var i = 0;
  for (var token; (token = ts.incrementToken()) !== null; i++) {
    if (texts) {
      QUnit.equal(token.text, texts[i]);
    }
    if (types) {
      QUnit.equal(token.type, types[i]);
    }
    if (starts) {
      QUnit.equal(token.start, starts[i]);
    }
    if (ends) {
      QUnit.equal(token.start + token.text.length, ends[i]);
    }
  }
  if (texts) {
    QUnit.equal(i, texts.length);
  }
  if (types) {
    QUnit.equal(i, types.length);
  }
  if (starts) {
    QUnit.equal(i, starts.length);
  }
  if (ends) {
    QUnit.equal(i, ends.length);
  }
}

function assertAnalyzesTo(ts, input, output, types, start, end) {
  if (input != null) {
    ts.setReader(new luceneTokenizers.StringReader(input));
  }
  assertTokenStreamContents(ts, output, types, start, end);
}

function checkOneTerm(ts, input, expected) {
  assertAnalyzesTo(ts, input, [expected]);
}

function checkBounds(tokenizer) {
  var StringReader = luceneTokenizers.StringReader;
  tokenizer.setReader(new StringReader(''));
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader(' '));
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader(makeStrOfChrs(' ', 10000)));
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader('a'));
  QUnit.equal(tokenizer.incrementToken().text, 'a');
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader(' a'));
  QUnit.equal(tokenizer.incrementToken().text, 'a');
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader('a '));
  QUnit.equal(tokenizer.incrementToken().text, 'a');
  QUnit.equal(tokenizer.incrementToken(), null);
  tokenizer.setReader(new StringReader(' a '));
  QUnit.equal(tokenizer.incrementToken().text, 'a');
  QUnit.equal(tokenizer.incrementToken(), null);
  var biga = ' ' + makeStrOfChrs('a', 10000);
  tokenizer.setReader(new StringReader(biga));
  QUnit.equal(tokenizer.incrementToken().text, biga.substring(1, 256));
  var a = makeStrOfChrs('a', 255), b = makeStrOfChrs('b', 255);
  tokenizer.setReader(new StringReader(a + b));
  QUnit.equal(tokenizer.incrementToken().text, a);
  QUnit.equal(tokenizer.incrementToken().text, b);
  QUnit.equal(tokenizer.incrementToken(), null);
}