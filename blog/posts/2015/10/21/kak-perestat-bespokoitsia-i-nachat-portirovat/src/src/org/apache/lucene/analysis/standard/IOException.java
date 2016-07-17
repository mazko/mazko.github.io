package org.apache.lucene.analysis.standard;

@SuppressWarnings("serial")
public class IOException extends Exception {
	public final String msg;

	public IOException(String msg) {
		super();
		this.msg = msg;
	}
}
