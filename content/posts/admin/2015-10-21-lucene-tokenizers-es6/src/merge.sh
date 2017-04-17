
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