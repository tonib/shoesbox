
/** The page state */
var pageState = {

  /** Current page. */
  currentPage: null,

  /** Initialize the page specific javascript.
    * As turbolinks loads ALL javascript together, we need to initialize like this.
    * @param pageFunctions.initialize Function to initialize the page. It can be null.
    * @param pageFunctions.finalize Function to finalize the page. It can be null.
    */
  setPage: function(page) {
    // Call the finalize:
    // this.initialize = pageFunctions.initialize ? pageFunctions.initialize : null;
    // this.finalize = pageFunctions.finalize ? pageFunctions.finalize : null;
    pageState.currentPage = page;
  },

  /** Return the current page javascript state. It can be null. */
  getPage: function() { return pageState.currentPage; },

  /** Get the current page id. It can be null */
  getPageId: function(pageId) {
    if( !pageState.currentPage )
      return null;
    return pageState.currentPage.pageId;
  },

  /** Page change event */
  pageChange: function(restoreFromCache) {

    // Initialize the page
    if( pageState.currentPage && pageState.currentPage.initialize ) {
      pageState.currentPage.initialize(restoreFromCache);
    }

    // Initialize the small player
    smallPlayer.initialize(restoreFromCache);

    if( !restoreFromCache )
      // Initialize the go to top affix
      pageState.pageAffix();

  },

  /** New page is going to be loaded event */
  pageBeforeUnload: function() {
    // Call the current page finalize
    if( pageState.currentPage && pageState.currentPage.finalize ) {
      pageState.currentPage.finalize();
    }
    // Finalize small player
    smallPlayer.finalize();
    // Clean page:
    pageState.currentPage = null;
    // Unbind scroll to top
    $('#top_link').unbind();
  },

  pageAffix: function() {
    // Affix (go back to top)
    $('#top_link').click(function(e) {
      e.preventDefault();
      window.scrollTo(0,0);
    });
  },

  getUrlParameter: function (sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split('&'),
      sParameterName,
      i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split('=');

      if (sParameterName[0] === sParam) {
        var value = sParameterName[1];
        if( value === undefined )
          return true;
        else
          return decodeURIComponent(sParameterName[1]).replace(/\+/g, ' ');
      }
    }
  }

};

// New page loaded
$(document).on('page:change', function() {
  console.log('page:change');
  pageState.pageChange(false);
});

// New page is going to be loaded
$(document).on('page:before-unload', function(e) {
  console.log('page:before-unload');
  pageState.pageBeforeUnload();
});

// Page restored from the cache
$(document).on('page:restore', function(e) {
  console.log('page:restore');

  // The restore from cache does not eval javascript. Do it manually:
  $('body script').each(function() {
    eval( $(this).text() );
  });
  
  // Remove iframes: They are added when a download is started
  $('body iframe').remove();

  pageState.pageChange(true);
});

/* Unload event: Stop playing streaming. If not, when the page is closed
  the 'ended' audio event will be fired, and the player will try to load
  the next song, and that song IS STORED ON PERMANENT COOKIES AS THE CURRENT
  PLAY (WRONG!) */
$(window).on('beforeunload', function(){
  streamingPlayer.stop();
});

// Feedback ajax calls:
$(document)
  .bind("ajax:beforeSend", function() {
    // Chrome on Android does not allow auto play. Play will work ONLY
    // if play is called a first time from an gesture event. So, here is the
    // crap:
    streamingPlayer.enablePlay();
  })
  .bind('ajaxSend', function(){
    $('#busy_img').show();
  } )
  .bind('ajaxComplete', function(){ $('#busy_img').hide(); } );

  // Send get forms with the attribute "data-turboform" through turbolinks
  $(document).on("submit", "form[data-turboform]", function(e) {
    Turbolinks.visit(this.action+(this.action.indexOf('?') == -1 ? '?' : '&')+$(this).serialize());
    return false;
  });

// Define console.log on Internet Explorer
if(!window.console) {console={}; console.log = function(){};}

// Disable turbolinks pages cache (troublesome)
//Turbolinks.pagesCached(0);
