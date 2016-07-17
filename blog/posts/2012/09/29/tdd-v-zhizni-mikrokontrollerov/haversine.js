var haversine_math = {
	toRad: function(v){
        	return v * Math.PI / 180;
	},
	toPrecisionFixed: function(v,precision) {
		if (isNaN(v)) return 'NaN';
        	var numb = v < 0 ? -v : v;  // can't take log of -ve number...
        	var sign = v < 0 ? '-' : '';
        	if (numb == 0) { 
              		n = '0.'; while (precision--) n += '0'; return n };  // can't take log of zero
              		var scale = Math.ceil(Math.log(numb)*Math.LOG10E);  // no of digits before decimal
              		var n = String(Math.round(numb * Math.pow(10, precision-scale)));
              		if (scale > 0) {  // add trailing zeros & insert decimal as required
                		l = scale - n.length;
              		while (l-- > 0) n = n + '0';
              		if (scale < n.length) n = n.slice(0,scale) + '.' + n.slice(scale);
            	} else {          // prefix decimal and leading zeros if required
            		while (scale++ < 0) n = '0' + n;
            		n = '0.' + n;
         	}
         	return sign + n;
      	},
	distanceTo: function(lat, lon, slat, slon, precision) {
	 	if (typeof precision == 'undefined') precision = 4;  
	 	var R = 6371;
	 	var lat1 = this.toRad(lat), lon1 = this.toRad(lon);
	 	var lat2 = this.toRad(slat), lon2 = this.toRad(slon);
	 	var dLat = lat2 - lat1;
	 	var dLon = lon2 - lon1;
	 	var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
		 	Math.cos(lat1) * Math.cos(lat2) * 
		 	Math.sin(dLon/2) * Math.sin(dLon/2);
	 	var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
	 	var d = R * c;
	 	return this.toPrecisionFixed(d,precision);
      	},
	print_haversine: function(){
		var lat1 = document.getElementById('haversine_lat1').value;
		var long1 = document.getElementById('haversine_long1').value;
		var lat2 = document.getElementById('haversine_lat2').value;
		var long2 = document.getElementById('haversine_long2').value;
		var distance = this.distanceTo(lat1, long1, lat2, long2);
         	document.getElementById("haversine_result").innerHTML = "Расстояние: <b>" + distance + "</b><em> km</em>";
      	}
}
