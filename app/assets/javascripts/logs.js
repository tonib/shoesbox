
/** Log index page. */
var logsIndexPage = {

  initialize: function()
  {
    // Log table
    logsIndexPage.logsTable =
      new ScrollableTable('logs' , $('#load_page_logs_path').val() );
  },

  finalize: function() {
    logsIndexPage.logsTable.unbind();
    logsIndexPage.logsTable = null;
  }

};
