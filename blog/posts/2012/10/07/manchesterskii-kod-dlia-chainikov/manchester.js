function manchester_encode_and_print(){

	var bin = bin_encode();
	if (isNaN(bin)) return NaN;

	var res = "";
	for (var i = 0, l = bin.length; i < l; i++) {
		if (i && !(i % 8)) res += " ";
		res += bin.charAt(i) == '0' ? "10" : "01";
	}

        document.getElementById('manchester_result').innerHTML = '<b>' + res + '</b>'
      }
      function bin_encode(){
	var query = document.getElementById('manchester_query').value;
	var bin = parseInt(query).toString(2);
	if (isNaN(bin)) return NaN;

	/* Padding left */

	if (bin.length % 8) {
		var reqBytes = Math.ceil(bin.length / 8);
		for (var i = reqBytes * 8, l = bin.length; i > l; i--) 
			bin = '0' + bin;
	}

        return bin;
}
