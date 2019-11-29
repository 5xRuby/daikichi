if($('body').data("controller-path") === "backend/users"){
  document.addEventListener('turbolinks:load', function() {
    var prefix = 'input#user_assign_';
    var checkbox = $(prefix + 'leave_time');
    var inputField = $(prefix + 'date');
    checkbox.prop('checked', inputField.val() != '')
    inputField.prop('disabled', inputField.val() == '');
    checkbox.on('change', function(e) {
      if ($(this).is(':checked')) {
        inputField.prop('disabled', false);
      } else {
        inputField.prop('disabled', true);
        inputField.val('');
      }
    });
  })
}