package org.apache.lucene.analysis.standard;

public final class TokenModel {
	public final String text, type;
	public final long start, positionIncrement;

	public TokenModel(String text, String type, long start, long posInc) {
		this.text = text;
		this.type = type;
		this.start = start;
		this.positionIncrement = posInc;
	}
}
