package org.apache.lucene.analysis.standard;

public final class StringReader implements Reader {

	private String str;
	private int length;
	private int next = 0;

	/**
	 * Creates a new string reader.
	 *
	 * @param s
	 *            String providing the character stream.
	 */
	public StringReader(String s) {
		super();
		this.str = s;
		this.length = s.length();
	}

	/**
	 * Check to make sure that the stream has not been closed
	 * 
	 * @throws IOException
	 */
	private void ensureOpen() throws IOException {
		if (str == null)
			throw new IOException("Stream closed");
	}

	/**
	 * Reads characters into a portion of an array.
	 *
	 * @param cbuf
	 *            Destination buffer
	 * @param off
	 *            Offset at which to start writing characters
	 * @param len
	 *            Maximum number of characters to read
	 *
	 * @return The number of characters read, or -1 if the end of the stream has
	 *         been reached
	 *
	 * @exception IOException
	 *                If an I/O error occurs
	 * @throws IndexOutOfBoundsException
	 */
	public int read(char cbuf[], int off, int len) throws IOException, IndexOutOfBoundsException {
		ensureOpen();
		if ((off < 0) || (off > cbuf.length) || (len < 0) || ((off + len) > cbuf.length) || ((off + len) < 0)) {
			throw new IndexOutOfBoundsException();
		} else if (len == 0) {
			return 0;
		}
		if (next >= length)
			return -1;
		int n = Math.min(length - next, len);
		// :es6:
		// for (int nT = n; nT-- > 0; ) {
		// cbuf[off + nT] = str.charCodeAt(next + nT);
		// }
		str.getChars(next, next + n, cbuf, off);
		// :end:
		next += n;
		return n;
	}

	/**
	 * Closes the stream and releases any system resources associated with it.
	 * Once the stream has been closed, further read(), ready(), mark(), or
	 * reset() invocations will throw an IOException. Closing a previously
	 * closed stream has no effect.
	 */
	public void close() {
		str = null;
	}
}
