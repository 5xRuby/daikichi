document.addEventListener('turbolinks:load', function() {
  var datePicker = {
    $datePickers: $("*[data-input='datepicker']"),

    initDatePickers: function(elem) {
      $(elem).flatpickr({
        enableTime: false,
        dateFormat: $(elem).data('format')
      });
    },

    init: function() {
      var $this = this;
      $this.$datePickers.each(function() {
        $this.initDatePickers(this);
      });
    }
  };

  datePicker.init();
});
