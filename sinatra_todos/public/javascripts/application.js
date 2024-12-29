$(function(){
  // Confirm delete for to-dos and lists
  $('form.delete').on('click', function(event){
    // Prevent default HTML behavior (form being submitted) from occurring 
    event.preventDefault();
    // Stop the event from propagating (cut the chain of events)
    event.stopPropagation();

    if (confirm("Are you sure? This cannot be undone.")) {
      // Submit manually only if condition is met
      $(this).submit();
    }
  })
});