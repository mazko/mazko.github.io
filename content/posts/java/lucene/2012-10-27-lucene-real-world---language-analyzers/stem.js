function jssnowball_print(){
    var Stem = function(lng, word) {
        var testStemmer = new Snowball(lng);
        return function(word) {
            testStemmer.setCurrent(word);
            testStemmer.stem();
            return testStemmer.getCurrent();
        }
    };

    var lng = document.getElementById("jssnowball_language").value; 
    var word = document.getElementById("jssnowball_input").value;

    document.getElementById("jssnowball_result").innerHTML = "<b>" + new Stem(lng)(word) + "</b>";
}
