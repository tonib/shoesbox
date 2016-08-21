
/**
  * Class to handle operations over a songs table
  * @param table The ScrollableTable to handle
  * @param tableChecks The TableChecks to handle the table selection
*/
SongsTableOps = function(table, tableChecks) {

  this.table = table;
  this.tableChecks = tableChecks;

  // Set affix if the table ops are sticky
  SongsTableOps.affixStickyOps();

  // Add selected songs to the playlist
  var that = this;
  $('#add_to_queue_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select the songs to add");
      return;
    }

    // Do the call
    var url = $('#add_to_queue_songs_path').val();
    $.post(url, that.tableChecks.getOperationParameters(ids) ,
      function(data) {},
      'script'
    );
  });

  // Edit selected songs button
  $('#edit_songs_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select the songs to edit");
      return;
    }

    Turbolinks.visit( $('#edit_multiple_songs_path').val() + "?" +
      $.param( that.tableChecks.getOperationParameters(ids) )
    );

  });

  // Download multiple songs
  $('#download_songs_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select the songs to download");
      return;
    }

    var nSongs = that.tableChecks.getNSelectedSongs();
    if( nSongs > 500 ) {
      alert( 'The maximum number of songs to download is 500');
      return;
    }

    var url = $('#download_multiple_songs_path').val() + "?" +
      $.param( that.tableChecks.getOperationParameters(ids) );
    download_file( url , 'Downloading songs, this will take some time' );
  });

  // Download playlist
  $('#download_playlist_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select some song for the playlist");
      return;
    }

    var url = $('#download_playlist_songs_path').val() + "?" +
      $.param( that.tableChecks.getOperationParameters(ids) );
    download_file( url , 'Downloading play list');

  });

  // Delete songs
  $('#delete_songs_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select the songs to delete");
      return;
    }

    if( !confirm('Are you sure you want delete ' +
      ( ids == 'all' ? 'all selected' : ids.length ) + ' songs?') )
      return;

    var url = $('#delete_multiple_songs_path').val();
    $.post(url,
      that.tableChecks.getOperationParameters(ids) ,
      function(data) {},
      'script'
    );

  });

  // Download excel
  $('#download_excel_btn').click(function(e) {
    e.preventDefault();

    var ids = that.tableChecks.selectedRowsIds();
    if( ids.length == 0 ) {
      alert("Please, select the songs for the Excel");
      return;
    }

    Turbolinks.visit( $('#excel_songs_path').val() + "?format=csv&" +
      $.param( that.tableChecks.getOperationParameters(ids) )
    );

  });

}

/** Create the affix for sticky ops. Static method */
SongsTableOps.affixStickyOps = function() {
  $('.songs_ops_container.sticky_ops').affix({
      // how far to scroll down before link "slides" into view
      offset: { top:600 }
  });
}

/** Remove the affix for sticky ops. Static method */
SongsTableOps.unbindStickyOps = function() {
  $(window).off('.affix');
  $('.songs_ops_container.sticky_ops')
    .removeData('bs.affix').removeClass('affix affix-top affix-bottom');
}

/** Unbind operations events. */
SongsTableOps.prototype.unbind = function() {
  $('#add_to_queue_btn').unbind();
  $('#edit_songs_btn').unbind();
  $('#download_songs_btn').unbind();
  $('#delete_songs_btn').unbind();
  SongsTableOps.unbindStickyOps();
}
