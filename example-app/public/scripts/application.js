// /public/scripts/application.js
$( document ).ready( function () { 
  // Application JavaScript goes here

  $('form.delete').on('submit', function(event) {
    // ...
    var form = $(this)

    // /public/scripts/application.js
    if (confirm("Are you sure you'd like to delete this item?")) {
      var request = jQuery.ajax( { 
        // ...
      });

      request.done(function(body, statusText, jqXHR) {
        // Callback if the request is successful
      });

      request.fail(function(body, statusText, jqXHR) {
        // Callback if the request is unsuccessful
      });
    }
  });


});

// event.preventDefault();
// event.stopPropagation();