package org.apache.lucene.analysis.standard;

public interface Reader {
	public void close() throws IOException;

	public int read(char[] arg0, int arg1, int arg2) throws IOException, IndexOutOfBoundsException;
}
