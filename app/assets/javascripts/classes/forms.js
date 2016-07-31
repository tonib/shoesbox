
/** Set a link href
  * @param $link jQuery link reference
  * @param url Url to set. If it's empty it will replaced by "#"
  */
function setLinkUrl($link, url) {
  if( !url )
    url = '#'
  $link.attr('href' , url );
}

// Common functions for all forms
$(document).on('page:change', function () {

  // Don't do it: Its a mess on phones
  // Focus the first form
  //$('input:visible:first').focus();

  // Style errors on the bootstrap way
  $('.field_with_errors').each(function(tag) {
    $(this).parent().addClass('has-error');
  });

  // Labels for URL fields
  $('a.link_label').each(function(index, link) {
    // Get the input id of the owner label
    var input_id = $(link).closest('label').attr('for');
    if(!input_id)
      return;

    // Set the target link with the field content
    var $input = $('#' + input_id);
    setLinkUrl( $(link) , $input.val() );
    $input.change(function(e) {
      setLinkUrl( $(link) , $(this).val() );
    });
  });

});
