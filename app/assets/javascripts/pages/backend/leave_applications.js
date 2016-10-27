document.addEventListener("turbolinks:load", function() {
  $('.employee-leaves-status-selector > .pending').on('click', function(){
    Turbolinks.visit("/backend/leave_applications/pending" );
  });

  $('.employee-leaves-status-selector > .approved').on('click', function(){
    Turbolinks.visit("/backend/leave_applications/approved" );
  });

  $('.employee-leaves-status-selector > .rejected').on('click', function(){
    Turbolinks.visit("/backend/leave_applications/rejected" );
  });

  $('.employee-leaves-status-selector > .canceled').on('click', function(){
    Turbolinks.visit("/backend/leave_applications/canceled" );
  });
});
