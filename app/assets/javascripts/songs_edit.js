
var songEditPage = {

  bindSongEditCheck: function(check_id, field_id) {

    $('#' + check_id).click(function() {

      var readonly = !$(this).prop('checked');
      $('#' + field_id).attr('readonly', readonly );

      // Enable / disable autocomplete:
      if ( field_id == 'artist' || field_id == 'album')
        songEditPage.autocomplete( field_id , !readonly );
    });

    var readonly = !$('#' + check_id).prop('checked');
    $('#' + field_id).attr('readonly', readonly);

  },

  autocomplete: function(field_id, enable) {
    if( enable )
      autocomplete( '#' + field_id , $('#suggest_' + field_id + 's_path').val() );
    else
      autocomplete_unbind( '#' + field_id );
  },

  preg_quote: function( str ) {
    // http://kevin.vanzonneveld.net
    // +   original by: booeyOH
    // +   improved by: Ates Goral (http://magnetiq.com)
    // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +   bugfixed by: Onno Marsman
    // *     example 1: preg_quote("$40");
    // *     returns 1: '\$40'
    // *     example 2: preg_quote("*RRRING* Hello?");
    // *     returns 2: '\*RRRING\* Hello\?'
    // *     example 3: preg_quote("\\.+*?[^]$(){}=!<>|:");
    // *     returns 3: '\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:'

    return (str+'').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
  },

  remove_text_entry: function(name, entry) {
    return name
      .replace( songEditPage.preg_quote(entry + ' -') , '' , 'gi' )
      .replace( songEditPage.preg_quote(entry + '-') , '' , 'gi' )
      .replace( songEditPage.preg_quote(entry) , '' , 'gi' )
      .trim();
  },

  assign_fields: function(e) {
    e.preventDefault();

    var initialNumberRegex = /^(\d+).*/

    var artist_name = $('#artist').val();
    var album_name = $('#album').val();

    // Get the songs paths info
    var songs_info = $('#songs_table label').map(function() {

      // Try to get songs info from paths
      var song_info = {};

      // Get the file name without extension
      var path = $(this).text().trim();
      path = path.replace(/\\/g, '/');
      song_info.name = path.substring( path.lastIndexOf('/')+1, path.lastIndexOf('.') );

      // Remove underscores
      song_info.name = song_info.name.replace( /_/g , ' ' );
      song_info.name = song_info.name.trim();

      // Remove the artist and album names
      song_info.name = songEditPage.remove_text_entry( song_info.name , artist_name );
      song_info.name = songEditPage.remove_text_entry( song_info.name , album_name );

      // Try to get the track number:
      var matches = initialNumberRegex.exec(song_info.name);
      song_info.track = 0;
      if( matches != null && matches.length > 1 )
      {
        song_info.track = parseInt( matches[1] );
        song_info.name = song_info.name.substring( matches[1].length );
        song_info.name = song_info.name.trim();
        var c = song_info.name.charAt(0);
        if( c == '.' || c == '-' ) {
          song_info.name = song_info.name.substring( 1 );
          song_info.name = song_info.name.trim();
        }

      }

      // Capitalize
      song_info.name = song_info.name.charAt(0).toUpperCase() + song_info.name.slice(1);

      return song_info;
    }).get();

    // Assign numbers
    $('#songs_table input[type=number]').each(function(index) {
      var text = $(this).val();
      if( text == "0" || text == "" )
        $(this).val( songs_info[index].track );
    });

    // Assign songs names
    $('#songs_table input[type=text]').each(function(index) {
      $(this).val( songs_info[index].name );
    });

    //alert(songs_paths[0].name + ' ' + songs_paths[0].track);

    return false;
  },

  /** Page initialization */
  initialize: function() {
    songEditPage.bindSongEditCheck('update_artist' , 'artist');
    songEditPage.bindSongEditCheck('update_album' , 'album');
    songEditPage.bindSongEditCheck('update_genre' , 'genre');

    songEditPage.autocomplete( 'artist' , true );
    songEditPage.autocomplete( 'album' , true );
    $('#assign_fields').click(this.assign_fields);
  },

  finalize: function() {
    $('#update_artist').unbind();
    $('#update_album').unbind();
    $('#update_genre').unbind();
    $('#assign_fields').unbind();

    autocomplete_unbind( '#artist' );
    autocomplete_unbind( '#album' );
  }

};
