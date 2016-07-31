
//= require classes/scroll_listener
//= require songs_filter
//= require classes/scrollable_table
//= require toastr
//= require classes/songs_table_ops

var songsIndexPage = {

  // Songs filter
  songsFilter: null,

  // Songs table
  songsTable: null,

  // Table checks
  tableChecks: null,

  // Table operations
  tableOps: null,

  /** Page initialization */
  initialize: function() {

    // Songs table
    songsIndexPage.songsTable = new ScrollableTable('songs' , $('#load_page_path').val() );

    // Initialize the filter:
    songsIndexPage.songsFilter = new SongsFilter('songs', songsIndexPage.songsTable );

    // Table checks handler
    songsIndexPage.tableChecks = new TableChecks(songsIndexPage.songsTable);

    // Table operations
    songsIndexPage.tableOps = new SongsTableOps(songsIndexPage.songsTable,
      songsIndexPage.tableChecks);

  },

  /** Page finalization */
  finalize: function() {
    songsIndexPage.songsTable.unbind();
    songsIndexPage.songsTable = null;

    songsIndexPage.songsFilter.unbind();
    songsIndexPage.songsFilter = null;

    songsIndexPage.tableChecks.unbind();
    songsIndexPage.tableChecks = null;

    songsIndexPage.tableOps.unbind();
    songsIndexPage.tableOps = null;
  }

};
