(function() {

    function newAnalizer() {
      return new luceneTokenizers.UAX29URLEmailTokenizer();
    }

    QUnit.test( "Bounds", function( assert ) {
      checkBounds(newAnalizer());
    });

    QUnit.test( "LongEMAILatomText", function( assert ) {

      function getRandomInt(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
      }

      // EMAILatomText = [A-Za-z0-9!#$%&'*+-/=?\^_`{|}~]
      var emailAtomChars = "!#$%&'*+,-./" + 
        "0123456789=?ABCDEFGHIJKLMNOPQRSTUVWXYZ^_" + 
        "`abcdefghijklmnopqrstuvwxyz{|}~";
      var numChars = getRandomInt(22 * 1024, 333 * 1024);
      var buff = [];
      for( var i=0; i < numChars; i++ ){
        buff.push(
          emailAtomChars.charAt(
            Math.floor(Math.random() * emailAtomChars.length)
        ));
      }
      var text = buff.join('');
      var tokenCount = 0;
      var ts = newAnalizer();
      ts.setReader(new luceneTokenizers.StringReader(text));
      ts.reset();
      while (ts.incrementToken() != null) {
        tokenCount++;
      }
      ts.end();
      ts.close();
      assert.ok(tokenCount > 0);

      tokenCount = 0;
      ts.setMaxTokenLength(getRandomInt(200, 8192));
      ts.setReader(new luceneTokenizers.StringReader(text));
      ts.reset();
      while (ts.incrementToken() != null) {
        tokenCount++;
      }
      ts.end();
      ts.close();
      assert.ok(tokenCount > 0);
    });

    QUnit.test( "Armenian", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "Վիքիպեդիայի 13 միլիոն հոդվածները (4,600` հայերեն վիքիպեդիայում) գրվել են կամավորների կողմից ու համարյա բոլոր հոդվածները կարող է խմբագրել ցանկաց մարդ ով կարող է բացել Վիքիպեդիայի կայքը։",
          ["Վիքիպեդիայի", "13", "միլիոն", "հոդվածները", 
           "4,600", "հայերեն", "վիքիպեդիայում", "գրվել", 
           "են", "կամավորների", "կողմից", "ու", "համարյա", 
           "բոլոր", "հոդվածները", "կարող", "է",
           "խմբագրել", "ցանկաց", "մարդ", "ով", "կարող", "է", 
           "բացել", "Վիքիպեդիայի", "կայքը" ]);
    });

    QUnit.test( "Amharic", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "ዊኪፔድያ የባለ ብዙ ቋንቋ የተሟላ ትክክለኛና ነጻ መዝገበ ዕውቀት (ኢንሳይክሎፒዲያ) ነው። ማንኛውም",
          ["ዊኪፔድያ", "የባለ", "ብዙ", "ቋንቋ", "የተሟላ", "ትክክለኛና", "ነጻ", "መዝገበ", "ዕውቀት", "ኢንሳይክሎፒዲያ", "ነው",
            "ማንኛውም" ]);
    });

    QUnit.test( "Arabic", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
          "الفيلم الوثائقي الأول عن ويكيبيديا يسمى \"الحقيقة بالأرقام: قصة ويكيبيديا\" (بالإنجليزية: Truth in Numbers: The Wikipedia Story)، سيتم إطلاقه في 2008.",
          ["الفيلم", "الوثائقي", "الأول", "عن", "ويكيبيديا", "يسمى", "الحقيقة", "بالأرقام", "قصة",
            "ويكيبيديا", "بالإنجليزية", "Truth", "in", "Numbers", "The", "Wikipedia", "Story", "سيتم",
            "إطلاقه", "في", "2008" ]);
    });

    QUnit.test( "Aramaic", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "ܘܝܩܝܦܕܝܐ (ܐܢܓܠܝܐ: Wikipedia) ܗܘ ܐܝܢܣܩܠܘܦܕܝܐ ܚܐܪܬܐ ܕܐܢܛܪܢܛ ܒܠܫܢ̈ܐ ܣܓܝܐ̈ܐ܂ ܫܡܗ ܐܬܐ ܡܢ ܡ̈ܠܬܐ ܕ\"ܘܝܩܝ\" ܘ\"ܐܝܢܣܩܠܘܦܕܝܐ\"܀",
          [ "ܘܝܩܝܦܕܝܐ", "ܐܢܓܠܝܐ", "Wikipedia", "ܗܘ", "ܐܝܢܣܩܠܘܦܕܝܐ", "ܚܐܪܬܐ", "ܕܐܢܛܪܢܛ", "ܒܠܫܢ̈ܐ",
            "ܣܓܝܐ̈ܐ", "ܫܡܗ", "ܐܬܐ", "ܡܢ", "ܡ̈ܠܬܐ", "ܕ", "ܘܝܩܝ", "ܘ", "ܐܝܢܣܩܠܘܦܕܝܐ" ]);
    });

    QUnit.test( "Bengali", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "এই বিশ্বকোষ পরিচালনা করে উইকিমিডিয়া ফাউন্ডেশন (একটি অলাভজনক সংস্থা)। উইকিপিডিয়ার শুরু ১৫ জানুয়ারি, ২০০১ সালে। এখন পর্যন্ত ২০০টিরও বেশী ভাষায় উইকিপিডিয়া রয়েছে।",
          [ "এই", "বিশ্বকোষ", "পরিচালনা", "করে", "উইকিমিডিয়া", "ফাউন্ডেশন", "একটি", "অলাভজনক",
            "সংস্থা", "উইকিপিডিয়ার", "শুরু", "১৫", "জানুয়ারি", "২০০১", "সালে", "এখন", "পর্যন্ত",
            "২০০টিরও", "বেশী", "ভাষায়", "উইকিপিডিয়া", "রয়েছে" ]);
    });

    QUnit.test( "Farsi", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "ویکی پدیای انگلیسی در تاریخ ۲۵ دی ۱۳۷۹ به صورت مکملی برای دانشنامهٔ تخصصی نوپدیا نوشته شد.",
          [ "ویکی", "پدیای", "انگلیسی", "در", "تاریخ", "۲۵", "دی", "۱۳۷۹", "به", "صورت", "مکملی",
            "برای", "دانشنامهٔ", "تخصصی", "نوپدیا", "نوشته", "شد" ]);
    });

    QUnit.test( "Greek", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
        "Γράφεται σε συνεργασία από εθελοντές με το λογισμικό wiki, κάτι που σημαίνει ότι άρθρα μπορεί να προστεθούν ή να αλλάξουν από τον καθένα.",
          [ "Γράφεται", "σε", "συνεργασία", "από", "εθελοντές", "με", "το", "λογισμικό", "wiki",
            "κάτι", "που", "σημαίνει", "ότι", "άρθρα", "μπορεί", "να", "προστεθούν", "ή", "να", "αλλάξουν",
            "από", "τον", "καθένα" ]);
    });

    QUnit.test( "Thai", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
          "การที่ได้ต้องแสดงว่างานดี. แล้วเธอจะไปไหน? ๑๒๓๔",
          [ "การที่ได้ต้องแสดงว่างานดี", "แล้วเธอจะไปไหน", "๑๒๓๔" ]);
    });

    QUnit.test( "Lao", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
          "ສາທາລະນະລັດ ປະຊາທິປະໄຕ ປະຊາຊົນລາວ",
          [ "ສາທາລະນະລັດ", "ປະຊາທິປະໄຕ", "ປະຊາຊົນລາວ" ]);
    });

    QUnit.test( "Tibetan", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
          "སྣོན་མཛོད་དང་ལས་འདིས་བོད་ཡིག་མི་ཉམས་གོང་འཕེལ་དུ་གཏོང་བར་ཧ་ཅང་དགེ་མཚན་མཆིས་སོ། །",
          [ "སྣོན", "མཛོད", "དང", "ལས", "འདིས", "བོད", "ཡིག", "མི", "ཉམས", "གོང", "འཕེལ", "དུ",
            "གཏོང", "བར", "ཧ", "ཅང", "དགེ", "མཚན", "མཆིས", "སོ" ]);
    });

    /*
     * For chinese, tokenize as char (these can later form bigrams or whatever)
     */

    QUnit.test( "Chinese", function( assert ) {
      assertAnalyzesTo(newAnalizer(),
          "我是中国人。 １２３４ Ｔｅｓｔｓ ",
          [ "我", "是", "中", "国", "人", "１２３４", "Ｔｅｓｔｓ" ]);
    });

    QUnit.test( "LUCENE1545", function( assert ) {
      /*
       * Standard analyzer does not correctly tokenize combining character
       * U+0364 COMBINING LATIN SMALL LETTRE E. The word "moͤchte" is
       * incorrectly tokenized into "mo" "chte", the combining character is
       * lost. Expected result is only on token "moͤchte".
       */
      assertAnalyzesTo(newAnalizer(), "moͤchte", [ "moͤchte" ]);
    });

    /* Tests from StandardAnalyzer, just to show behavior is similar */

    QUnit.test( "AlphanumericSA", function( assert ) {
      // alphanumeric tokens
      assertAnalyzesTo(newAnalizer(), "B2B", [ "B2B" ]);
      assertAnalyzesTo(newAnalizer(), "2B", [ "2B" ]);
    });

    QUnit.test( "DelimitersSA", function( assert ) {
      // other delimiters: "-", "/", ","
      assertAnalyzesTo(newAnalizer(), "some-dashed-phrase", [ "some", "dashed", "phrase" ]);
      assertAnalyzesTo(newAnalizer(), "dogs,chase,cats", [ "dogs", "chase", "cats" ]);
      assertAnalyzesTo(newAnalizer(), "ac/dc", [ "ac", "dc" ]);
    });

    QUnit.test( "ApostrophesSA", function( assert ) {
      // internal apostrophes: O'Reilly, you're, O'Reilly's
      assertAnalyzesTo(newAnalizer(), "O'Reilly", [ "O'Reilly" ]);
      assertAnalyzesTo(newAnalizer(), "you're", [ "you're" ]);
      assertAnalyzesTo(newAnalizer(), "she's", [ "she's" ]);
      assertAnalyzesTo(newAnalizer(), "Jim's", [ "Jim's" ]);
      assertAnalyzesTo(newAnalizer(), "don't", [ "don't" ]);
      assertAnalyzesTo(newAnalizer(), "O'Reilly's", [ "O'Reilly's" ]);
    });

    QUnit.test( "NumericSA", function( assert ) {
      // floating point, serial, model numbers, ip addresses, etc.
      assertAnalyzesTo(newAnalizer(), "21.35", [ "21.35" ]);
      assertAnalyzesTo(newAnalizer(), "R2D2 C3PO", [ "R2D2", "C3PO" ]);
      assertAnalyzesTo(newAnalizer(), "216.239.63.104", [ "216.239.63.104" ]);
    });

    QUnit.test( "TextWithNumbersSA", function( assert ) {
      // numbers
      assertAnalyzesTo(newAnalizer(), 
        "David has 5000 bones", 
        [ "David", "has", "5000", "bones" ]);
    });

    QUnit.test( "VariousTextSA", function( assert ) {
      // various
      assertAnalyzesTo(newAnalizer(), 
        "C embedded developers wanted", 
        [ "C", "embedded", "developers", "wanted" ]);
      assertAnalyzesTo(newAnalizer(), 
        "foo bar FOO BAR", 
        [ "foo", "bar", "FOO", "BAR" ]);
      assertAnalyzesTo(newAnalizer(), 
        "foo      bar .  FOO <> BAR", 
        [ "foo", "bar", "FOO", "BAR" ]);
      assertAnalyzesTo(newAnalizer(), 
        "\"QUOTED\" word", 
        [ "QUOTED", "word" ]);
    });

    QUnit.test( "KoreanSA", function( assert ) {
      // Korean words
      assertAnalyzesTo(newAnalizer(), "안녕하세요 한글입니다", [ "안녕하세요", "한글입니다" ]);
    });

    QUnit.test( "Offsets", function( assert ) {
      assertAnalyzesTo(newAnalizer(), 
        "David has 5000 bones",
        [ "David", "has", "5000", "bones" ],
        null,
        [ 0, 6, 10, 15 ],
        [ 5, 9, 14, 20 ]);
    });

    QUnit.test( "Types", function( assert ) {
      assertAnalyzesTo(newAnalizer(), 
        "David has 5000 bones",
        [ "David", "has", "5000", "bones" ],
        [ "<ALPHANUM>", "<ALPHANUM>", "<NUM>", "<ALPHANUM>" ]);
    });

    QUnit.test( "MailtoSchemeEmails", function( assert ) {
      assertAnalyzesTo(newAnalizer(), 
        "mailto:test@example.org",
        [ "mailto", "test@example.org" ],
        [ "<ALPHANUM>", "<EMAIL>" ]);
      // TODO: Support full mailto: scheme URIs. See RFC 6068:
      // http://tools.ietf.org/html/rfc6068
      assertAnalyzesTo(newAnalizer(),
        "mailto:personA@example.com,personB@example.com?cc=personC@example.com"
            + "&subject=Subjectivity&body=Corpusivity%20or%20something%20like%20that",
        ["mailto", "personA@example.com",
          // TODO: recognize ',' address delimiter. Also, see
          // examples of ';' delimiter use at:
          // http://www.mailto.co.uk/
         ",personB@example.com", "?cc=personC@example.com", // TODO:
                                      // split
                                      // field
                                      // keys/values
         "subject", "Subjectivity", "body", "Corpusivity", 
         "20or", "20something", "20like", "20that"],        // TODO:
                                                            // Hex
                                                            // decoding
                                                            // +
                                                            // re-tokenization
        ["<ALPHANUM>", "<EMAIL>", "<EMAIL>", "<EMAIL>", 
         "<ALPHANUM>", "<ALPHANUM>", "<ALPHANUM>", "<ALPHANUM>", 
         "<ALPHANUM>", "<ALPHANUM>", "<ALPHANUM>", "<ALPHANUM>"]);
    });

    QUnit.test( "UnicodeWordBreaks", function( assert ) {
      WordBreakTestUnicode_6_3_0(newAnalizer());
    });

    QUnit.test( "Supplementary", function( assert ) {
      assertAnalyzesTo(newAnalizer(), 
        "𩬅艱鍟䇹愯瀛",
        [ "𩬅", "艱", "鍟", "䇹", "愯", "瀛" ],
        [ "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<IDEOGRAPHIC>" ]);
    });

    QUnit.test( "Korean", function( assert ) {
      assertAnalyzesTo(newAnalizer(), "훈민정음", [ "훈민정음" ], [ "<HANGUL>" ]);
    });

    QUnit.test( "Japanese", function( assert ) {
      assertAnalyzesTo(newAnalizer(), 
        "仮名遣い カタカナ", 
        [ "仮", "名", "遣", "い", "カタカナ" ], 
        [ "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<IDEOGRAPHIC>", "<HIRAGANA>", "<KATAKANA>" ]);
    });

    QUnit.test( "CombiningMarks", function( assert ) {
      checkOneTerm(newAnalizer(), "ざ", "ざ"); // hiragana
      checkOneTerm(newAnalizer(), "ザ", "ザ"); // katakana
      checkOneTerm(newAnalizer(), "壹゙", "壹゙"); // ideographic
      checkOneTerm(newAnalizer(), "아゙", "아゙"); // hangul
    });

    /**
     * Multiple consecutive chars in \p{Word_Break = MidLetter}, \p{Word_Break =
     * MidNumLet}, and/or \p{Word_Break = MidNum} should trigger a token split.
     */

    QUnit.test( "Mid", function( assert ) {
 
      // ':' is in \p{WB:MidLetter}, which should trigger a split unless there
      // is a Letter char on both sides
      assertAnalyzesTo(newAnalizer(), "A:B", ["A:B" ]);
      assertAnalyzesTo(newAnalizer(), "A::B", ["A", "B"]);

      // '.' is in \p{WB:MidNumLet}, which should trigger a split unless there
      // is a Letter or Numeric char on both sides
      assertAnalyzesTo(newAnalizer(), "1.2", [ "1.2" ]);
      assertAnalyzesTo(newAnalizer(), "A.B", [ "A.B" ]);
      assertAnalyzesTo(newAnalizer(), "1..2", [ "1", "2" ]);
      assertAnalyzesTo(newAnalizer(), "A..B", [ "A", "B" ]);

      // ',' is in \p{WB:MidNum}, which should trigger a split unless there is
      // a Numeric char on both sides
      assertAnalyzesTo(newAnalizer(), "1,2", [ "1,2" ]);
      assertAnalyzesTo(newAnalizer(), "1,,2", [ "1", "2" ]);

      // Mixed consecutive \p{WB:MidLetter} and \p{WB:MidNumLet} should
      // trigger a split
      assertAnalyzesTo(newAnalizer(), "A.:B", [ "A", "B" ]);
      assertAnalyzesTo(newAnalizer(), "A:.B", [ "A", "B" ]);

      // Mixed consecutive \p{WB:MidNum} and \p{WB:MidNumLet} should trigger a
      // split
      assertAnalyzesTo(newAnalizer(), "1,.2", [ "1", "2" ]);
      assertAnalyzesTo(newAnalizer(), "1.,2", [ "1", "2" ]);

      // '_' is in \p{WB:ExtendNumLet}

      assertAnalyzesTo(newAnalizer(), "A:B_A:B", [ "A:B_A:B" ]);
      assertAnalyzesTo(newAnalizer(), "A:B_A::B", [ "A:B_A", "B" ]);

      assertAnalyzesTo(newAnalizer(), "1.2_1.2", [ "1.2_1.2" ]);
      assertAnalyzesTo(newAnalizer(), "A.B_A.B", [ "A.B_A.B" ]);
      assertAnalyzesTo(newAnalizer(), "1.2_1..2", [ "1.2_1", "2" ]);
      assertAnalyzesTo(newAnalizer(), "A.B_A..B", [ "A.B_A", "B" ]);

      assertAnalyzesTo(newAnalizer(), "1,2_1,2", [ "1,2_1,2" ]);
      assertAnalyzesTo(newAnalizer(), "1,2_1,,2", [ "1,2_1", "2" ]);

      assertAnalyzesTo(newAnalizer(), "C_A.:B", [ "C_A", "B" ]);
      assertAnalyzesTo(newAnalizer(), "C_A:.B", [ "C_A", "B" ]);

      assertAnalyzesTo(newAnalizer(), "3_1,.2", [ "3_1", "2" ]);
      assertAnalyzesTo(newAnalizer(), "3_1.,2", [ "3_1", "2" ]);

    });
})();