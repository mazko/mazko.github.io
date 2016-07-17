package org.apache.lucene.analysis.standard;

public interface Tokenizer {
	TokenModel incrementToken() throws IOException, IndexOutOfBoundsException;

	void setReader(Reader reader);

	void reset();

	void end();

	void close();
}
