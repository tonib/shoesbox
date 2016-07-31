
/** Trigger an event when scroll shows a tag.
  * http://stackoverflow.com/questions/21561480/trigger-event-when-user-scroll-to-specific-element-with-jquery
  * @param callback A function to bind the scroll event, or 'unbind' to unbind
  *   the event.
  */
$.fn.onScrollTo = function(callback) {

  var currentCallback = $('body').data('scrollCallback');
  if( currentCallback )
    $(window).unbind('scroll', currentCallback);

  if( callback === 'unbind')
    return;

  var $that = this;
  if($that.length == 0)
    return;

  var newCallback = function() {
    var hT = $that.offset().top,
      hH = $that.outerHeight(),
      wH = $(window).height(),
      wS = $(this).scrollTop();
    //console.log((hT-wH) , wS);
    if (wS > (hT+hH-wH))
      callback();
  };

  $(window).scroll(newCallback);
  $('body').data('scrollCallback', newCallback);
  
  return this;
}
