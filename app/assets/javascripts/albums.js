
/** Albums index page. */
var albumsIndexPage = {

  initialize: function() {

    // Albums table
    albumsIndexPage.albumsTable =
      new ScrollableTable('albums' , $('#load_page_albums_path').val() );
    albumsIndexPage.tableChecks = new TableChecks(albumsIndexPage.albumsTable);
    albumsIndexPage.tableChecks.selectionAttribute = 'data-albumid';

    // Restore filter (cache crap)
    var textFilter = pageState.getUrlParameter('text_filter');
    $('#text_filter').val(textFilter);

    albumsIndexPage.albumsTable.load_parameters['text_filter'] = textFilter;

    albumsIndexPage.bindOpButtons( albumsIndexPage.tableChecks );

    // Autocomplete
    autocomplete( '#text_filter' , $('#suggest_path').val() , { hint: false } );

    // Submit events:
    $('#show_uncomplete, #search_button').click(function(e) {
      e.preventDefault();
      $('#filter').submit();
    });

    // Set affix for operations
    SongsTableOps.affixStickyOps();
  },

  bindOpButtons: function(tChecks) {
    // Add to queue
    $('#album_add_to_queue_btn').click(function(e) {
      e.preventDefault();
      var url = $('#add_to_queue_albums_path').val();
      $.post(url, tChecks.getOperationParameters() ,
        function(data) {}, 'script' );
    });

    // Download playlist
    $('#album_download_playlist_btn').click(function(e) {
      e.preventDefault();
      var url = $('#download_playlist_albums_path').val() + "?" +
        $.param( tChecks.getOperationParameters() );
      Turbolinks.visit( url );
    });

    // Download songs
    $('#album_download_songs_btn').click(function(e) {
      e.preventDefault();
      var url = $('#download_multiple_albums_path').val() + "?" +
        $.param( tChecks.getOperationParameters() );
      download_file( url , 'Downloading songs, this will take some time' );
    });

  },

  unbindOpButtons: function() {
    $('#album_add_to_queue_btn').unbind();
    $('#album_download_playlist_btn').unbind();
    $('#album_download_songs_btn').unbind();
  },

  finalize: function() {
    autocomplete_unbind( '#text_filter' );
    albumsIndexPage.albumsTable.unbind();
    albumsIndexPage.albumsTable = null;
    albumsIndexPage.tableChecks.unbind();
    albumsIndexPage.tableChecks = null;
    $('#show_uncomplete').unbind();
    albumsIndexPage.unbindOpButtons();
    SongsTableOps.unbindStickyOps();
  }

};
