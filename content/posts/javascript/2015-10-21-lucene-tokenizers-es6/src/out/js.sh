ES6FILE='lucene-tokenizers.es6'

for cls in 'StringReader' 'StandardTokenizer' 'UAX29URLEmailTokenizer'; do
  sed -i "s/^class\s\+${cls}\s\+/export class ${cls} /" ${ES6FILE}
done 

# traceur --out traceur/lucene-tokenizers.traceour.js "$ES6FILE"

# Why Babel break unicode ? Fails on [\uD800-\uFFFF] chars. Hot fix: 

sed 's/\\u/\\\\u/g' "$ES6FILE" |                     \
~/iojs-v3.3.1-linux-x64/bin/node --stack-size=10000  \
"`which babel`"                                      \
--compact=false                                      \
--modules umdStrict --module-id luceneTokenizers |   \
sed 's/\\\\u/\\u/g' > lucene-tokenizers.babel.js