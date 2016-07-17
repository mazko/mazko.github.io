package org.apache.lucene.analysis.standard;

@SuppressWarnings("serial")
public class Exception extends java.lang.Exception {
	public Exception() {
		// :es6: remove extends java.lang.Exception
		// this.stack = (new Error()).stack;
		// :end:
	}
}
