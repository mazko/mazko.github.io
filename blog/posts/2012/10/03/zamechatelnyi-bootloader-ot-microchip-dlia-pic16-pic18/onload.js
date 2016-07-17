$(function() {

  	var css = [
	  '#slider_bootloder_shots {',
	    'margin:0 auto; width: 780px; height:423px; overflow : hidden;',
	  '}',
	  '#slider_bootloder_shots ul {',
	    'margin:0; padding:0; list-style:none;',
	  '}',
	  '#slider_bootloder_shots li {',
	    'width:780px; overflow:hidden; height:423px; padding: 0; margin:0;',
	  '}',

	  '/* Slider numeric controls */',

	  'ol#bootloader_controls {',
	    'margin:0; padding:1.5em 0 .3em 0; height:28px; text-align: center; list-style:none;',
	  '}',
	  'ol#bootloader_controls li {',
	    'display: inline; margin:0 10px 0 0; padding:0; height:28px; line-height:28px;',
	  '}',
	  'ol#bootloader_controls li a {',
	    'height:28px; line-height:28px; border:1px solid #ccc; background:#DAF3F8; color:#555; padding:0 10px; text-decoration:none;',
	  '}',
	  'ol#bootloader_controls li.current a {',
	    'background:#5DC9E1; color:#fff;',
	  '}',
	  'ol#bootloader_controls li a:focus {',
	    'outline:none;',
	  '}'
    ].join('\n');

	$('head').append(
		$('<style/>').attr('type', 'text/css').html(css)
	);

    /* Init */

    $("#slider_bootloder_shots").easySlider({
        numeric: true,
        numericId: 'bootloader_controls'
    });

});
