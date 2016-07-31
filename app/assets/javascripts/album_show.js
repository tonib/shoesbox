

var albumShowPage = {

  /** Page initialization */
  initialize: function() {

    // Songs table
    albumShowPage.songsTable = new ScrollableTable('songs' );
    albumShowPage.songsTable.load_parameters.artist_id = $('#artist_id').val();
    albumShowPage.songsTable.load_parameters.album_id = $('#album_id').val();

    // Table checks handler
    albumShowPage.tableChecks = new TableChecks(albumShowPage.songsTable);
    // Table operations
    albumShowPage.tableOps = new SongsTableOps(albumShowPage.songsTable,
      albumShowPage.tableChecks);
    // All songs selected by default:
    albumShowPage.tableChecks.selectAll();
  },

  /** Page finalization */
  finalize: function() {
    albumShowPage.songsTable.unbind();
    albumShowPage.songsTable = null;

    albumShowPage.tableChecks.unbind();
    albumShowPage.tableChecks = null;

    albumShowPage.tableOps.unbind();
    albumShowPage.tableOps = null;
  }

};
