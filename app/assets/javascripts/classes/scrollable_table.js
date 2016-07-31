
/**
  * Class to handle a pageable by scroll table
  * @param table_id The table id
  * @param load_page_url Url to load new rows pages
*/
ScrollableTable = function(table_id, load_page_url) {

  this.table_id = table_id;
  this.load_page_url = load_page_url;

  // Already called to load more?
  this.load_more_called = false;

  // Last page index loaded. Check if we return from a cached page:
  this.last_page_index = 0;
  var $row_load_more = $('#' + this.table_id + ' tbody .load_more_class');
  if( $row_load_more.attr('aria-page-index') )
    this.last_page_index = parseInt( $row_load_more.attr('aria-page-index') );

  // Parameters to do the search
  this.load_parameters = {};

  // Callbacks to execute when a new page is loaded
  this.newPageCallbacks = [];

  // Callbacks to execute when a new page is added
  this.newPageAddedCallbacks = [];

  // Bind scroll event
  this.bindScrollEvent();

}

/** Bind event to load the next page */
ScrollableTable.prototype.bindScrollEvent = function() {
  var that = this;
  $('#' + this.table_id + ' .load_more_class').onScrollTo(function() {
    that.loadNextPage(false);
  });
}

/** True if all the table content has been loaded. */
ScrollableTable.prototype.isAllContentLoaded = function() {
  return $('#' + this.table_id + ' .load_more_class').length == 0;
}


/** Unbind events. */
ScrollableTable.prototype.unbind = function() {
  $('#' + this.table_id + ' .load_more_class').onScrollTo('unbind');
  this.newPageCallbacks = [];
  this.newPageAddedCallbacks = [];
}

/** Reload the table. */
ScrollableTable.prototype.refresh = function() {
  this.last_page_index = -1;
  this.loadNextPage(true);
}

/** Get the load page URL.
  * @return The request page url
  */
ScrollableTable.prototype.getRequestUrl = function() {
  this.load_parameters['page_index'] = this.last_page_index;
  return this.load_page_url + '?' + $.param(this.load_parameters);
}

/** Function to load the next table page. */
ScrollableTable.prototype.loadNextPage = function(clean_table) {
  if( !this.load_more_called ) {
    this.load_more_called = true;
    this.last_page_index += 1;
    var url = this.getRequestUrl();

    var that = this;
    $.get( url , function( html ) {
      that.appendNextPage(clean_table, html);
    } , 'html' );
  }
}

/** Function to load the next table page. */
ScrollableTable.prototype.appendNextPage = function(clean_table, html) {

  var $tbody = $('#' + this.table_id + ' tbody');
  if( clean_table )
    $tbody.empty();
  else
    $tbody.find('.load_more_class').remove();


  var newPageDom = $.parseHTML(html);

  // Call the callback for the new page
  for( var i=0; i<this.newPageCallbacks.length; i++)
    this.newPageCallbacks[i](newPageDom);

  // Append the new rows
  $tbody.append(newPageDom);

  // Call the callback for the new addition
  for( var i=0; i<this.newPageAddedCallbacks.length; i++)
    this.newPageAddedCallbacks[i]();

  this.load_more_called = false;

  // Rebind the scroll event
  this.bindScrollEvent();

}

/** Callback for new page loaded, before it is added. */
ScrollableTable.prototype.onNewPage = function(callback) {
  this.newPageCallbacks.push(callback);
}

/** Callback for new page, after it is added. */
ScrollableTable.prototype.onNewPageAdded = function(callback) {
  this.newPageAddedCallbacks.push(callback);
}

/** Get the number of rows on the table. */
ScrollableTable.prototype.getNRows = function() {
  return $('#' + this.table_id + ' tbody tr').length;
}
