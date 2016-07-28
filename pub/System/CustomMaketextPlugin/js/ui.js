(function($) {
  $(document).ready(function() {
    bindRemove();
    bindRemoveLanguage();
    $('.addlanguage').bind('click', function(){
      $.blockUI();
    });
    $('.saveall').bind('click', function(){
      $.blockUI();
    });
    $('.addline').bind('click', function(){
      var $count = parseInt($('.pobody tr:last').attr('data-count'))+1;
      var $newElem = $('.pobody tr:last').clone();
      $newElem.removeAttr('style');
      $newElem.attr('data-count',$count);
      //if this is the first row
      $newElem.find('input[name="0_head_str"]').attr('name',$count+'_str');
      $newElem.find('input[type="text"]').each(function(){
        $name = $(this).attr('name').replace($count-1, $count);
        $(this).attr('name',$name);
        $(this).attr('value','');
      });
      $('.pobody').append($newElem);
      bindRemove();
    });
  });
  function bindRemove(){
    $('.remove-msgid').bind('click',function(){
      var $line = $(this);
      swal({
        title: "Are you sure?",
        text: "You will not be able to recover the translations!",
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        confirmButtonText: "Yes, delete it!",
        closeOnConfirm: false
      },
      function(){
        $line.closest('tr').remove();
        swal("Deleted!", "The line was successfully deleted", "success");
      });
    });
  }
  function bindRemoveLanguage(){
    $('.remove-lang').bind('click', function(){
      var $lang = $(this).attr('data-lang');
      swal({
         title: "Are you sure?",
         text: "You will not be able to recover the translations!",
         type: "warning",
         showCancelButton: true,
         confirmButtonColor: "#DD6B55",
         confirmButtonText: "Yes, delete it!",
         closeOnConfirm: false,
       },
       function(){
          $.blockUI();
          //get form
          $('#removeLangField').val($lang);
          $('#removeLangForm').submit();
      });
    });
  }
})(jQuery);
