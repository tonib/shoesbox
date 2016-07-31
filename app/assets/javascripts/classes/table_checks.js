
/** Handler for selectionable tables.
  */
TableChecks = function(scrollableTable) {

  this.scrollableTable = scrollableTable;
  this.lastCheckClicked = null;
  this.selectionAttribute = 'data-songid';

  var that = this;

  // If there are sticky table operations, add the selection badge there, to
  // show it on the affix
  var $stickyOps = $('.songs_ops_container.sticky_ops');
  if( $stickyOps.length > 0 ) {

    if( $stickyOps.find( '.sticky_selection' ).length == 0 ) {
      // Add it only if it does not exists
      $stickyOps.prepend(
        '<span class="sticky_selection selection_column">' +
          //'<span style="min-width:35px" class="badge">0</span><br/>' +
          '<input type="checkbox" class="select_all" id="sticky_select_all">' +
        '</span>'
        );
    }

  }

  // Select all checkbox clicked
  this.getCheckAllSelector().click(function(e) {
    that.getCheckAllSelector().prop('checked', $(this).prop('checked'));
    that.onSelectAllCheckClicked();
  });

  // If some check is unchecked, uncheck the select all:
  this.bindTable( $('#' + scrollableTable.table_id) );

  // Handle new pages addition
  scrollableTable.onNewPage(function(pageDom) {
    that.bindTable( $(pageDom) );
    if( that.getCheckAllSelector().prop('checked') )
      $(pageDom).find('.selection').prop('checked' , true);
  });
  scrollableTable.onNewPageAdded(function() {
    that.onSelectionChanged();
  });

  // Initial status
  this.onSelectionChanged();

  // Add a badge with the selection count, if it does not exist
  if( $('#' + this.scrollableTable.table_id + ' thead .badge').length == 0 )
    this.getCheckAllSelector().before('<span class="badge" style="min-width:35px">0</span><br/>');

}

TableChecks.prototype.getCheckAllSelector = function() {
  return $('#' + this.scrollableTable.table_id + ' .select_all, #sticky_select_all');
}

TableChecks.prototype.selectAll = function() {
  this.getCheckAllSelector().prop('checked' , true);
  this.onSelectAllCheckClicked();
}

TableChecks.prototype.onSelectAllCheckClicked = function() {
  $('#' + this.scrollableTable.table_id).find('.selection')
    .prop('checked' , this.getCheckAllSelector()[0].checked);
  this.onSelectionChanged();
}

TableChecks.prototype.onSelectionClicked = function($check, e) {

  if(!$check.prop('checked'))
    // If some check is unchecked, uncheck the select all:
    this.getCheckAllSelector().prop('checked',false);
  else {
    // If all rows are checked, check the select all
    if( $('#' + this.scrollableTable.table_id + ' tbody input:not(:checked)')
      .length == 0 )
      this.getCheckAllSelector().prop('checked',true);
  }

  // Check multirow selections
  if(e.shiftKey && this.lastCheckClicked && $check != this.lastCheckClicked) {
    var $checks = $check.closest('tbody').find('.selection');
    var idxCurrent = $checks.index($check);
    var idxLast = $checks.index(this.lastCheckClicked);
    var increment = idxCurrent > idxLast ? -1 : 1;
    for( var i = idxCurrent + increment; i != idxLast; i += increment ) {
      $($checks[i]).prop('checked' , this.lastCheckClicked.prop('checked'));
    }
    // Clean selection
    window.getSelection().removeAllRanges();
  }

  this.lastCheckClicked = $check;

  this.onSelectionChanged();
}

TableChecks.prototype.bindTable = function($table) {
  var that = this;

  // Selection changes event:
  $table.find('.selection').click(function(e) {
    that.onSelectionClicked($(this), e);
  });

  // When the row is clicked toggle its selection
  // The filter / find combinations is needed when a new page is loaded
  // the tr are roots and both work different
  // See http://danielnouri.org/notes/2011/03/14/a-jquery-find-that-also-finds-the-root-element/
  $table.filter('tr')
  .add($table.find('tr'))
  .click(function(e) {
    if( e.target && e.target.tagName && e.target.tagName.toLowerCase() == 'td' ) {
      e.preventDefault();
      var $check = $(this).find('.selection').first();
      $check.prop('checked' , !$check.prop('checked'));
      that.onSelectionClicked($check, e);
    }
  });
}

TableChecks.prototype.isAllSelected = function() {
  return $('#' + this.scrollableTable.table_id + ' .select_all').prop('checked');
}

/**
  * Get selected rows ids
  * @param id_type The type of id to get. If it's null, this.selectionAttribute
  * will be used as selection type
  * @returns If all songs are selected, it returns "all". Otherwise it returns
  * an array with integers with the songs ids, without duplicates.
  */
TableChecks.prototype.selectedRowsIds = function(id_type) {

  if( id_type == null )
    id_type = this.selectionAttribute;

  // Check if all is selected
  if( this.isAllSelected() )
     return 'all';

  // Get selected ids
  var selected_songs_ids = [];
  $('#' + this.scrollableTable.table_id + ' tbody input:checked').each(function() {
    var song_id = parseInt( $(this).attr(id_type) );
    selected_songs_ids.push(song_id);
  });

  // Remove duplicates
  selected_songs_ids = $.grep(selected_songs_ids, function(v, k){
      return $.inArray(v ,selected_songs_ids) === k;
  });

  return selected_songs_ids;
}

/** Get the number of selected rows. */
TableChecks.prototype.getNSelectedSongs = function() {

  if( this.isAllSelected() )
    return this.scrollableTable.getNRows();
  else
    return $('#' + this.scrollableTable.table_id + ' tbody input:checked')
      .length;
}

TableChecks.prototype.getSelectionFieldName = function() {
  // 'data-XXXXX'
  return this.selectionAttribute.substring(5);
}

TableChecks.prototype.getOperationParameters = function(ids , selectionName ) {

  if( selectionName == null )
    selectionName = this.getSelectionFieldName();
  if( ids == null )
    ids = this.selectedRowsIds();

  var params = {};
  params[ selectionName ] = ids;
  params[ 'filter' ] = this.scrollableTable.load_parameters;
  return params;
}

/** Callback for selection changes. */
TableChecks.prototype.onSelectionChanged = function() {

  // Enable / disable selection operations
  var $tableOps = $('#songs_ops_container');
  if( $tableOps.length == 0 )
    $tableOps = $('#' + this.scrollableTable.table_id ).prev();

  if( $tableOps.hasClass('songs_ops_container') ) {
    var $selector = $tableOps.find( "a" ).not('.alwaysenabled');
    if( this.getNSelectedSongs() == 0 )
      $selector.addClass('disabled');
    else
      $selector.removeClass('disabled');
  }

  // Update selection count:
  var count;
  if( !this.scrollableTable.isAllContentLoaded() &&  this.isAllSelected() )
    count = 'All';
  else
    count = this.getNSelectedSongs();
  $('#' + this.scrollableTable.table_id + ' thead .badge, .sticky_selection .badge').text(count);

}

TableChecks.prototype.unbind = function() {
  $('#' + this.scrollableTable.table_id + ' .select_all').unbind();
  $('#' + this.scrollableTable.table_id + ' .selection').unbind();
  $('#' + this.scrollableTable.table_id + ' tr').unbind();
  $('#sticky_select_all').unbind();
  this.lastCheckClicked = null;
}
