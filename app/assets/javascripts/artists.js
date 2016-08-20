
//= require artist_edit
//= require artist_show

/** Artists index page. */
var artistsIndexPage = {

  initialize: function() {
    // Songs table
    artistsIndexPage.artistsTable =
      new ScrollableTable('artists' , $('#load_page_artists_path').val() );
    artistsIndexPage.tableChecks = new TableChecks(artistsIndexPage.artistsTable);
    artistsIndexPage.tableChecks.selectionAttribute = 'data-artistid';

    // Restore filter (cache crap)
    var textFilter = pageState.getUrlParameter('text_filter');
    $('#text_filter').val(textFilter);
    var order = pageState.getUrlParameter('order');
    if(order)
      $('#order').val(order);

    artistsIndexPage.artistsTable.load_parameters['text_filter'] = textFilter;
    artistsIndexPage.artistsTable.load_parameters['order'] = order;

    var submit_function = function(e) {
      e.preventDefault();
      $('#filter').submit();
    };

    // Set affix for operations
    SongsTableOps.affixStickyOps();

    // Submit button:
    $('#search_button').click(submit_function);
    // Order:
    $('#order').change(submit_function);

    // Add to queue
    var that = this;
    $('#add_to_queue_btn').click(function(e) {
      e.preventDefault();
      var url = $('#add_to_queue_artists_path').val();
      $.post(url, that.tableChecks.getOperationParameters() ,
        function(data) {}, 'script' );
    });

    // Download playlist
    $('#download_playlist_btn').click(function(e) {
      e.preventDefault();
      Turbolinks.visit( $('#download_playlist_artists_path').val() + "?" +
        $.param( that.tableChecks.getOperationParameters() )
      );
    });

    // Download songs
    $('#download_songs_btn').click(function(e) {
      e.preventDefault();

      var url = $('#download_multiple_artists_path').val() + "?" +
        $.param( that.tableChecks.getOperationParameters() );
      download_file( url , 'Downloading songs, this will take some time' );
    });

    // Autocomplete artist name
    autocomplete( '#text_filter' , $('#suggest_artists_path').val() , { hint: false } );

  },

  finalize: function() {
    artistsIndexPage.artistsTable.unbind();
    artistsIndexPage.artistsTable = null;
    artistsIndexPage.tableChecks.unbind();
    artistsIndexPage.tableChecks = null;
    $('#search_button').unbind();
    autocomplete_unbind( '#text_filter' );
    $('#add_to_queue_btn').unbind();
    $('#download_playlist_btn').unbind();
    SongsTableOps.unbindStickyOps();
  }

};
