
var artistShowPage = {

  /** Page initialization */
  initialize: function() {

    // Songs table
    artistShowPage.songsTable = new ScrollableTable('songs' );
    artistShowPage.songsTable.load_parameters.artistid = $('#artist_id').val();
    artistShowPage.songsChecks = new TableChecks(artistShowPage.songsTable);
    artistShowPage.songsOps = new SongsTableOps(artistShowPage.songsTable,
      artistShowPage.songsChecks);
    artistShowPage.songsChecks.selectAll();

    // Albums table
    if( $('#albums').length ) {
      artistShowPage.albumsTable = new ScrollableTable( 'albums' );
      artistShowPage.albumsTable.load_parameters.artistid = $('#artist_id').val();
      artistShowPage.albumsTable.load_parameters.show_uncomplete = true;
      artistShowPage.albumsChecks = new TableChecks(artistShowPage.albumsTable);
      artistShowPage.albumsChecks.selectionAttribute = 'data-albumid';
      artistShowPage.albumsChecks.selectAll();
      albumsIndexPage.bindOpButtons( artistShowPage.albumsChecks );
    }

  },

  /** Page finalization */
  finalize: function() {
    artistShowPage.songsTable.unbind();
    artistShowPage.songsTable = null;
    artistShowPage.songsChecks.unbind();
    artistShowPage.songsChecks = null;
    artistShowPage.songsOps.unbind();
    artistShowPage.songsOps = null;

    if( $('#albums').length ) {
      artistShowPage.albumsTable.unbind();
      artistShowPage.albumsTable = null;
      artistShowPage.albumsChecks.unbind();
      artistShowPage.albumsChecks = null;
      albumsIndexPage.unbindOpButtons();
    }

  }

};
