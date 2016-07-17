package org.apache.lucene.analysis.standard;

import java.util.Random;

public class TestUtil {
	/** start and end are BOTH inclusive */
	public static int nextInt(Random r, int start, int end) {
		return r.nextInt((end - start) + 1) + start;
	}
}
