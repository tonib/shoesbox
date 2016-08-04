//= require jquery-ui

/**
  * Autocomplete a form field from the server
  * @param selector Field selector
  * @param source_url Source url for the autocomplete
*/
function autocomplete(selector, source_url)  {
  $(selector).autocomplete({

    source: source_url,

    select: function( event, ui ) {
      var $field = $(selector);
      // Set the input value
      $field.val( ui.item.value );
      // Submit the search form:
      var $form = $field.closest('form');
      if( $form.length > 0 )
        $form.submit();
    }
    
  });

}

/**
  * Unbind the autocomplete.
  * @param selector Field selector
*/
function autocomplete_unbind(selector) {
  $(selector).autocomplete('destroy');
}
