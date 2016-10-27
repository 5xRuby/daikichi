document.addEventListener("turbolinks:load", function() {
  $document = $(document);
  $window = $(window);

  function autoHeight() {
    $wrap = $('#wrap');

    $wrap.css('min-height', 0);
    $wrap.css( 'min-height', $document.height() - $('#nav').height() - $('#footer').height() );
  }

  $document.ready(function(){
    autoHeight();
  });

  $window.resize(function(){
    autoHeight();
  });
});
