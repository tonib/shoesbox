
/**
  * Class to handle a songs filter
  * @param filter_id The filter table HTML id
*/
SongsFilter = function(filter_id, songs_table) {

  this.filter_id = filter_id;
  this.songs_table = songs_table;

  // Confirmed text to perform searchs
  this.confirmedText = '';

  // Restore filter from a possible cache:
  this.confirmedText = $(this.getTextFieldId()).val();
  this.songs_table.load_parameters = this.getFilterValues();

  var that = this;
  // The form submit
  $('#' + filter_id + '_filter').submit(function(e){
    e.preventDefault();
    that.search();
  });

  // The search button click
  $('#' + filter_id + '_search_button').click(function(e) {
    that.search();
  });

  // Autocomplete names
  autocomplete( '#' + filter_id + '_filter_text' , $('#suggest_path').val() , { hint: false } );

}

/** Get text field id. */
SongsFilter.prototype.getTextFieldId = function() {
  return '#' + this.filter_id + '_filter_text';
}

/** Perform a special search when the artist has changed. */
SongsFilter.prototype.getFilterValues = function() {

  var filter = {
    text: this.confirmedText
  };

  var play_list_id = $('#play_list_id').val();
  if( play_list_id )
    filter.play_list_id = parseInt(play_list_id);

  return filter;
}

/** Update the filter and table with data. */
SongsFilter.prototype.refreshWithData = function(data) {
  this.songs_table.appendNextPage(true, data.songs_page);
}

/** Perform a search with the current filter. */
SongsFilter.prototype.search = function() {
  this.confirmedText = $(this.getTextFieldId()).val();
  this.songs_table.load_parameters = this.getFilterValues();
  this.songs_table.refresh();
  // Remove the focus from the text field, to hide keyboard on phones
  $('#' + this.filter_id + '_search_button').focus();
}

SongsFilter.prototype.unbind = function() {
  if( this.filter_id == 'songs' )
    autocomplete_unbind( '#' + this.filter_id + '_filter_text' );
  $('#' + this.filter_id + '_filter').unbind();
  $('#' + this.filter_id + '_search_button').unbind();
}
