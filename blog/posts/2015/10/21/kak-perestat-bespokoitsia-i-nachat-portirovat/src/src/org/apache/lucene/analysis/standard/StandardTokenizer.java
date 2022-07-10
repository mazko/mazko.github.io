/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.lucene.analysis.standard;

import org.apache.lucene.analysis.tokenattributes.CharTermAttribute;

/**
 * A grammar-based tokenizer constructed with JFlex.
 * <p>
 * This class implements the Word Break rules from the Unicode Text Segmentation
 * algorithm, as specified in <a href="http://unicode.org/reports/tr29/">Unicode
 * Standard Annex #29</a>.
 * <p>
 * Many applications have specific tokenizer needs. If this tokenizer does not
 * suit your application, please consider copying this source code directory to
 * your project and maintaining your own grammar-based tokenizer.
 */

public class StandardTokenizer implements Tokenizer {
	/** A private instance of the JFlex-constructed scanner */
	private StandardTokenizerImpl scanner;
	// TODO: how can we remove these old types?!
	public static final int ALPHANUM = 0;
	/** @deprecated (3.1) */
	@Deprecated
	public static final int APOSTROPHE = 1;
	/** @deprecated (3.1) */
	@Deprecated
	public static final int ACRONYM = 2;
	/** @deprecated (3.1) */
	@Deprecated
	public static final int COMPANY = 3;
	public static final int EMAIL = 4;
	/** @deprecated (3.1) */
	@Deprecated
	public static final int HOST = 5;
	public static final int NUM = 6;
	/** @deprecated (3.1) */
	@Deprecated
	public static final int CJ = 7;

	/** @deprecated (3.1) */
	@Deprecated
	public static final int ACRONYM_DEP = 8;

	public static final int SOUTHEAST_ASIAN = 9;
	public static final int IDEOGRAPHIC = 10;
	public static final int HIRAGANA = 11;
	public static final int KATAKANA = 12;
	public static final int HANGUL = 13;

	/** String token types that correspond to token type int constants */
	public static final String[] TOKEN_TYPES = new String[] { "<ALPHANUM>", "<APOSTROPHE>", "<ACRONYM>", "<COMPANY>",
			"<EMAIL>", "<HOST>", "<NUM>", "<CJ>", "<ACRONYM_DEP>", "<SOUTHEAST_ASIAN>", "<IDEOGRAPHIC>", "<HIRAGANA>",
			"<KATAKANA>", "<HANGUL>" };

	public static final int MAX_TOKEN_LENGTH_LIMIT = 1024 * 1024;

	private int skippedPositions;

	private int maxTokenLength = StandardAnalyzer.DEFAULT_MAX_TOKEN_LENGTH;

	public final TokenModel incrementToken() throws IOException, IndexOutOfBoundsException {
		skippedPositions = 0;
		CharTermAttribute termAtt = new CharTermAttribute();
		while (true) {
			int tokenType = scanner.getNextToken();

			if (tokenType == StandardTokenizerImpl.YYEOF) {
				return null;
			}

			if (scanner.yylength() <= maxTokenLength) {
				scanner.getText(termAtt);
				return new TokenModel(termAtt.toString(), TOKEN_TYPES[tokenType], scanner.yychar(),
						skippedPositions + 1);
			} else
				// When we skip a too-long term, we still increment the
				// position increment
				skippedPositions++;
		}
	}

	/**
	 * Set maximum allowed token length. If a token is seen that exceeds this
	 * length then it is discarded. This setting only takes effect the next time
	 * tokenStream or tokenStream is called.
	 */
	public void setMaxTokenLength(int length) {
		maxTokenLength = length;
	}

	/**
	 * @see #setMaxTokenLength
	 */
	public int getMaxTokenLength() {
		return maxTokenLength;
	}

	@Override
	public void setReader(Reader reader) {
		scanner = new StandardTokenizerImpl(reader);
	}

	@Override
	public void reset() {
		// TODO Auto-generated method stub

	}

	@Override
	public void end() {
		// TODO Auto-generated method stub

	}

	@Override
	public void close() {
		// TODO Auto-generated method stub

	}
}
