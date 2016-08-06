
/** Start a file download, with UI
  * @param url The URL to download
  * @param message The message to show on the toast
  */
function download_file(url, message) {

    toastr.info( message );

    // We will use an iframe for the download, to do not stop the current streaming
    var $iframe = $("<iframe/>").attr({
        src: url,
        style: "visibility:hidden;display:none"
    });

    // Start the download
    $iframe.appendTo(document.body);
}
