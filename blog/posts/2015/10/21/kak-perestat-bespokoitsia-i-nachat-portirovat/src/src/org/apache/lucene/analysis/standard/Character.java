package org.apache.lucene.analysis.standard;

public class Character {
	/**
	 * The minimum value of a
	 * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
	 * Unicode low-surrogate code unit</a> in the UTF-16 encoding, constant
	 * {@code '\u005CuDC00'}. A low-surrogate is also known as a
	 * <i>trailing-surrogate</i>.
	 *
	 * @since 1.5
	 */
	public static final char MIN_LOW_SURROGATE = 0xDC00;

	/**
	 * The maximum value of a
	 * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
	 * Unicode low-surrogate code unit</a> in the UTF-16 encoding, constant
	 * {@code '\u005CuDFFF'}. A low-surrogate is also known as a
	 * <i>trailing-surrogate</i>.
	 *
	 * @since 1.5
	 */
	public static final char MAX_LOW_SURROGATE = 0xDFFF;

	/**
	 * The minimum value of a
	 * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
	 * Unicode high-surrogate code unit</a> in the UTF-16 encoding, constant
	 * {@code '\u005CuD800'}. A high-surrogate is also known as a
	 * <i>leading-surrogate</i>.
	 *
	 * @since 1.5
	 */
	public static final char MIN_HIGH_SURROGATE = 0xD800;

	/**
	 * The maximum value of a
	 * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
	 * Unicode high-surrogate code unit</a> in the UTF-16 encoding, constant
	 * {@code '\u005CuDBFF'}. A high-surrogate is also known as a
	 * <i>leading-surrogate</i>.
	 *
	 * @since 1.5
	 */
	public static final char MAX_HIGH_SURROGATE = 0xDBFF;

	/**
	 * The minimum value of a
	 * <a href="http://www.unicode.org/glossary/#supplementary_code_point">
	 * Unicode supplementary code point</a>, constant {@code U+10000}.
	 *
	 * @since 1.5
	 */
	public static final int MIN_SUPPLEMENTARY_CODE_POINT = 0x010000;

	/**
	 * Determines if the given {@code char} value is a
	 * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
	 * Unicode high-surrogate code unit</a> (also known as <i>leading-surrogate
	 * code unit</i>).
	 *
	 * <p>
	 * Such values do not represent characters by themselves, but are used in
	 * the representation of <a href="#supplementary">supplementary
	 * characters</a> in the UTF-16 encoding.
	 *
	 * @param ch
	 *            the {@code char} value to be tested.
	 * @return {@code true} if the {@code char} value is between
	 *         {@link #MIN_HIGH_SURROGATE} and {@link #MAX_HIGH_SURROGATE}
	 *         inclusive; {@code false} otherwise.
	 * @see Character#isLowSurrogate(char)
	 * @see Character.UnicodeBlock#of(int)
	 * @since 1.5
	 */
	public static boolean isHighSurrogate(char ch) {
		// Help VM constant-fold; MAX_HIGH_SURROGATE + 1 == MIN_LOW_SURROGATE
		return ch >= MIN_HIGH_SURROGATE && ch < (MAX_HIGH_SURROGATE + 1);
	}

	/**
	 * Returns the code point at the given index of the {@code char} array,
	 * where only array elements with {@code index} less than {@code limit} can
	 * be used. If the {@code char} value at the given index in the {@code char}
	 * array is in the high-surrogate range, the following index is less than
	 * the {@code limit}, and the {@code char} value at the following index is
	 * in the low-surrogate range, then the supplementary code point
	 * corresponding to this surrogate pair is returned. Otherwise, the
	 * {@code char} value at the given index is returned.
	 *
	 * @param a
	 *            the {@code char} array
	 * @param index
	 *            the index to the {@code char} values (Unicode code units) in
	 *            the {@code char} array to be converted
	 * @param limit
	 *            the index after the last array element that can be used in the
	 *            {@code char} array
	 * @return the Unicode code point at the given index
	 * @exception NullPointerException
	 *                if {@code a} is null.
	 * @exception IndexOutOfBoundsException
	 *                if the {@code index} argument is negative or not less than
	 *                the {@code limit} argument, or if the {@code limit}
	 *                argument is negative or greater than the length of the
	 *                {@code char} array.
	 * @since 1.5
	 */
	public static int codePointAt(char[] a, int index, int limit) throws IndexOutOfBoundsException {
		if (index >= limit || limit < 0 || limit > a.length) {
			throw new IndexOutOfBoundsException();
		}
		return codePointAtImpl(a, index, limit);
	}

	/**
	 * Determines if the given {@code char} value is a
	 * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
	 * Unicode low-surrogate code unit</a> (also known as <i>trailing-surrogate
	 * code unit</i>).
	 *
	 * <p>
	 * Such values do not represent characters by themselves, but are used in
	 * the representation of <a href="#supplementary">supplementary
	 * characters</a> in the UTF-16 encoding.
	 *
	 * @param ch
	 *            the {@code char} value to be tested.
	 * @return {@code true} if the {@code char} value is between
	 *         {@link #MIN_LOW_SURROGATE} and {@link #MAX_LOW_SURROGATE}
	 *         inclusive; {@code false} otherwise.
	 * @see Character#isHighSurrogate(char)
	 * @since 1.5
	 */
	public static boolean isLowSurrogate(char ch) {
		return ch >= MIN_LOW_SURROGATE && ch < (MAX_LOW_SURROGATE + 1);
	}

	/**
	 * Converts the specified surrogate pair to its supplementary code point
	 * value. This method does not validate the specified surrogate pair. The
	 * caller must validate it using {@link #isSurrogatePair(char, char)
	 * isSurrogatePair} if necessary.
	 *
	 * @param high
	 *            the high-surrogate code unit
	 * @param low
	 *            the low-surrogate code unit
	 * @return the supplementary code point composed from the specified
	 *         surrogate pair.
	 * @since 1.5
	 */
	public static int toCodePoint(char high, char low) {
		// Optimized form of:
		// return ((high - MIN_HIGH_SURROGATE) << 10)
		// + (low - MIN_LOW_SURROGATE)
		// + MIN_SUPPLEMENTARY_CODE_POINT;
		return ((high << 10) + low) + (MIN_SUPPLEMENTARY_CODE_POINT - (MIN_HIGH_SURROGATE << 10) - MIN_LOW_SURROGATE);
	}

	// throws ArrayIndexOutofBoundsException if index out of bounds
	static int codePointAtImpl(char[] a, int index, int limit) {
		char c1 = a[index++];
		if (isHighSurrogate(c1)) {
			if (index < limit) {
				char c2 = a[index];
				if (isLowSurrogate(c2)) {
					return toCodePoint(c1, c2);
				}
			}
		}
		return c1;
	}

	/**
	 * Determines the number of {@code char} values needed to represent the
	 * specified character (Unicode code point). If the specified character is
	 * equal to or greater than 0x10000, then the method returns 2. Otherwise,
	 * the method returns 1.
	 *
	 * <p>
	 * This method doesn't validate the specified character to be a valid
	 * Unicode code point. The caller must validate the character value using
	 * {@link #isValidCodePoint(int) isValidCodePoint} if necessary.
	 *
	 * @param codePoint
	 *            the character (Unicode code point) to be tested.
	 * @return 2 if the character is a valid supplementary character; 1
	 *         otherwise.
	 * @see Character#isSupplementaryCodePoint(int)
	 * @since 1.5
	 */
	public static int charCount(int codePoint) {
		return codePoint >= MIN_SUPPLEMENTARY_CODE_POINT ? 2 : 1;
	}

	/**
	 * Returns the index within the given {@code char} subarray that is offset
	 * from the given {@code index} by {@code codePointOffset} code points. The
	 * {@code start} and {@code count} arguments specify a subarray of the
	 * {@code char} array. Unpaired surrogates within the text range given by
	 * {@code index} and {@code codePointOffset} count as one code point each.
	 *
	 * @param a
	 *            the {@code char} array
	 * @param start
	 *            the index of the first {@code char} of the subarray
	 * @param count
	 *            the length of the subarray in {@code char}s
	 * @param index
	 *            the index to be offset
	 * @param codePointOffset
	 *            the offset in code points
	 * @return the index within the subarray
	 * @exception NullPointerException
	 *                if {@code a} is null.
	 * @exception IndexOutOfBoundsException
	 *                if {@code start} or {@code count} is negative, or if
	 *                {@code start + count} is larger than the length of the
	 *                given array, or if {@code index} is less than
	 *                {@code start} or larger then {@code start + count}, or if
	 *                {@code codePointOffset} is positive and the text range
	 *                starting with {@code index} and ending with
	 *                {@code start + count - 1} has fewer than
	 *                {@code codePointOffset} code points, or if
	 *                {@code codePointOffset} is negative and the text range
	 *                starting with {@code start} and ending with
	 *                {@code index - 1} has fewer than the absolute value of
	 *                {@code codePointOffset} code points.
	 * @since 1.5
	 */
	public static int offsetByCodePoints(char[] a, int start, int count, int index, int codePointOffset)
			throws IndexOutOfBoundsException {
		if (count > a.length - start || start < 0 || count < 0 || index < start || index > start + count) {
			throw new IndexOutOfBoundsException();
		}
		return offsetByCodePointsImpl(a, start, count, index, codePointOffset);
	}

	static int offsetByCodePointsImpl(char[] a, int start, int count, int index, int codePointOffset)
			throws IndexOutOfBoundsException {
		int x = index;
		if (codePointOffset >= 0) {
			int limit = start + count;
			int i;
			for (i = 0; x < limit && i < codePointOffset; i++) {
				if (isHighSurrogate(a[x++]) && x < limit && isLowSurrogate(a[x])) {
					x++;
				}
			}
			if (i < codePointOffset) {
				throw new IndexOutOfBoundsException();
			}
		} else {
			int i;
			for (i = codePointOffset; x > start && i < 0; i++) {
				if (isLowSurrogate(a[--x]) && x > start && isHighSurrogate(a[x - 1])) {
					x--;
				}
			}
			if (i < 0) {
				throw new IndexOutOfBoundsException();
			}
		}
		return x;
	}
}
