package org.apache.lucene.analysis.standard;

import java.util.Random;

import org.junit.Ignore;

import junit.framework.TestCase;

@Ignore
class BaseTokenStreamTestCase extends TestCase {
	public static Random random() {
		return new Random();
	}

	static void checkOneTerm(Tokenizer ts, final String input, final String expected)
			throws IOException, IndexOutOfBoundsException {
		assertAnalyzesTo(ts, input, new String[] { expected });
	}

	static void assertTokenStreamContents(Tokenizer ts, String[] output) throws IOException, IndexOutOfBoundsException {
		assertAnalyzesTo(ts, null, output, null);
	}

	static void assertAnalyzesTo(Tokenizer ts, String input, String[] output)
			throws IOException, IndexOutOfBoundsException {
		assertAnalyzesTo(ts, input, output, null);
	}

	static void assertAnalyzesTo(Tokenizer ts, String input, String[] output, String[] types)
			throws IOException, IndexOutOfBoundsException {
		assertAnalyzesTo(ts, input, output, types, null, null);
	}

	static void assertAnalyzesTo(Tokenizer ts, String input, String[] output, int[] start, int[] end)
			throws IOException, IndexOutOfBoundsException {
		assertAnalyzesTo(ts, input, output, null, start, end);
	}

	static void assertAnalyzesTo(Tokenizer ts, String input, String[] output, String[] types, int[] start, int[] end)
			throws IOException, IndexOutOfBoundsException {
		TokenModel token = null;
		if (input != null) {
			ts.setReader(new StringReader(input));
		}
		for (int i = 0; (token = ts.incrementToken()) != null; i++) {
			if (output != null)
				assertEquals(token.text, output[i]);
			if (types != null)
				assertEquals(token.type, types[i]);
			if (start != null) {
				assertEquals(token.start, start[i]);
			}
			if (end != null) {
				assertEquals(token.start + token.text.length(), end[i]);
			}
		}
	}
}