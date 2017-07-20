(function() {
  function type_selector() {
    $selector = $(".type-selector");
    $selector.on('change', function(e){
      Turbolinks.visit("?" + $(this).attr('name') + "=" + $(this).val() );
    })
  }
  function autoHeight() {
    $wrap = $('#wrap');

    $wrap.css('min-height', 0);
    $wrap.css( 'min-height', $document.height() - $('#nav').height() - $('#footer').height() );
  }

  document.addEventListener("turbolinks:load", function() {
    $document = $(document);
    $window = $(window);

    type_selector();

    $document.ready(function(){
      autoHeight();
    });

    $window.resize(function(){
      autoHeight();
    });
  });
})();
