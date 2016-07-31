
/** Artists edition page. */
var artistEditPage = {

  setImageSearchUrl: function(name_selector) {
    $('#search_img_lnk').attr('href' ,
      'http://www.google.com/search?tbm=isch&q=' + $(name_selector).val() );
  },

  bindWikiLinks: function() {
    // Set the wikipedia link when a dropdown item is clicked
    $('.wikisearch_lnk').click(function(e) {
      e.preventDefault();
      $('#artist_wikilink').val( $(this).attr('href') );
      // Fire wikipedia field changed event
      $('#artist_wikilink').change();
    });
  },

  initialize: function() {

    // Last suggestion searched on wikipedia.
    artistEditPage.lastWikiSearched = '';

    // Wikipedia dropdown
    $('.dropdown-toggle').dropdown();

    // Store the original busy icon html
    if( !artistEditPage.wikiSearchAjax )
      artistEditPage.wikiSearchAjax = $('#wikisearch_menu').html();

    // Wikipedia dropdown displayed
    $('#wikisearch_drop').on('show.bs.dropdown', function () {

      // Check if the artist name has changed.
      if( $('#artist_name').val() == artistEditPage.lastWikiSearched )
        return;
      artistEditPage.lastWikiSearched = $('#artist_name').val();

      // Show the ajax busy:
      $('#wikisearch_menu').html(artistEditPage.wikiSearchAjax);

      // Ask the server for suggestions:
      var url = $('#search_wikipedia_artists_path').val() + '?artist_name=' +
        artistEditPage.lastWikiSearched;
      $.get( url , function( html ) {
          // Update the wikipedia menu
          $('#wikisearch_menu').html(html);
          artistEditPage.bindWikiLinks();
        });
    });

    // Get wikipedia image url button clicked
    $('#wikipedia_img_btn').click(function(e) {
      var url = $('#get_wikipedia_image_artists_path').val() +
        '?wikipedia_url=' + $('#artist_wikilink').val();
      $.getScript(url);
      e.preventDefault();
    });

    // Update the image when the URL has changed
    artistEditPage.bindImageChange('#artist_name');

  },

  bindImageChange: function(name_selector) {

    // Bind image URL changed event
    var originalImage = $('#img_container').html();
    $('#new_image_url').change(function(e) {
      var value = $(this).val();
      if( !value )
        $('#img_container').html( originalImage );
      else
        $('#img_container').html('<a href="' + value + '"><img src="' + value +
          '" alt="Image" style="max-height: 100px; max-width: 100px" />' +
          '</a>');
    });

    // Link to search artist images (name changed event)
    artistEditPage.setImageSearchUrl(name_selector);
    $(name_selector).change(function(e) {
      artistEditPage.setImageSearchUrl(name_selector);
    });

  },

  unbindImageChange: function(name_selector) {
    $('#new_image_url').unbind();
    $(name_selector).unbind();
  },

  finalize: function() {
    $('#wikisearch_drop').unbind();
    $('.wikisearch_lnk').unbind();
    artistEditPage.unbindImageChange('#artist_name');
  }

};
