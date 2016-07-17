import java.util.Arrays;

import org.apache.lucene.analysis.standard.IOException;
import org.apache.lucene.analysis.standard.IndexOutOfBoundsException;
import org.apache.lucene.analysis.standard.StringReader;
import org.apache.lucene.analysis.standard.TokenModel;
import org.apache.lucene.analysis.standard.Tokenizer;
import org.apache.lucene.analysis.standard.UAX29URLEmailTokenizer;

public class Test {
  /*

  lucene = require('./lucene-tokenizers')
  var ts = new lucene.UAX29URLEmailTokenizer();
  ts.setReader(new lucene.StringReader(
    "42 The quick brown fox <fox@mail.ru> jumps over the lazy dog < mailto:dog@gmail.com > "
  ));
  for (var token; (token = ts.incrementToken()) !== null;) {
    console.log([token.text, token.type]);
  }

  */
	public static void main(String[] args) throws IOException, IndexOutOfBoundsException {
		Tokenizer ts = new UAX29URLEmailTokenizer();
		ts.setReader(new StringReader(
				" a𩬅艱鍟䇹愯瀛훈민정음 42 The quick brown fox <fox@mail.ru> jumps over the lazy dog < dog@gmail.com > Copies an array from the specified source array, beginning at the specified position, to the specified position of the destination array. A subsequence of array components are copied from the source array referenced by src to the destination array referenced by dest. The number of components copied is equal to the length argument. The components at positions srcPos through srcPos+length-1 in the source array are copied into positions destPos through destPos+length-1, respectively, of the destination array. "
				));
		TokenModel token;
		while ((token = ts.incrementToken()) != null) {
			System.out.println(Arrays.asList(new String[] { token.text, token.type }));
		}
	}

}
