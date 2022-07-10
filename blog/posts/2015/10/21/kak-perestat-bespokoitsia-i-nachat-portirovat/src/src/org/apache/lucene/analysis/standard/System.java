package org.apache.lucene.analysis.standard;

public final class System {
	public static void arraycopy(Object src, int srcPos, Object dest, int destPos, int length) {
		// :es6:
		// int[] elements_to_add = src.slice(srcPos, srcPos + length);
		// Array.prototype.splice.apply(dest, new int[] {destPos,
		// elements_to_add.length}.concat(elements_to_add));
		java.lang.System.arraycopy(src, srcPos, dest, destPos, length);
		// :end:
		// TODO: pure es6 but is not Java compilable is :(
		// dest.splice(destPos, elements_to_add.length, ...elements_to_add);
	}
}
