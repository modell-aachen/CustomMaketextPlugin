(function($) {
  $(document).ready(function() {
    bindRemove();
    bindRemoveLanguage();
    bindRestartApache();
    $('.addlanguage').bind('click', function(){
      $.blockUI();
    });
    $('.saveall').bind('click', function(){
      $data = {};
      $lastElem = $('.pobody tr:last input:first').attr('name');
      $lastElem = $lastElem.replace('_com','');
      $data['lastR'] = $lastElem;
      $('.pobody tr input').each(function(){
        $encoded = $('<div/>').text($(this).val()).html(); 
        $data[$(this).attr('name')] = $encoded;
      });
      $.blockUI();
      $.ajax({
        url: foswiki.getScriptUrl('rest')+"/CustomMaketextPlugin/save",
        data: $data,
        method: "POST",
        dataType: "html"
      }).done(function() {
        $.unblockUI();
      });
    });
    $('.addline').bind('click', function(){
      if($('.pobody').parent().find('thead th.header').length < 4){
        return false;
      }
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
        title: jsi18n.get('custommaketext', "Are you sure?"),
        text: jsi18n.get('custommaketext', "The line will be removed. After you save the translations you will not be able to recover deleted lines."),
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        confirmButtonText: jsi18n.get('custommaketext',"Yes, delete it!"),
        cancelButtonText: jsi18n.get('custommaketext',"Cancel"),
        closeOnConfirm: true
      },
      function(){
        $line.closest('tr').remove();
        swal(jsi18n.get('custommaketext',"Deleted!"), jsi18n.get('custommaketext',"The line was successfully deleted."), "success");
      });
    });
  }
  function bindRemoveLanguage(){
    $('.remove-lang').bind('click', function(){
      var $lang = $(this).attr('data-lang');
      swal({
         title: jsi18n.get('custommaketext', "Are you sure?"),
         text: jsi18n.get('custommaketext',"You will not be able to recover the translations!"),
         type: "warning",
         showCancelButton: true,
         confirmButtonColor: "#DD6B55",
         confirmButtonText: jsi18n.get('custommaketext',"Yes, delete it!"),
         cancelButtonText: jsi18n.get('custommaketext',"Cancel"),
         closeOnConfirm: true,
       },
       function(){
          $.blockUI();
          //get form
          $('#removeLangField').val($lang);
          $('#removeLangForm').submit();
      });
    });
  }
  function bindRestartApache(){
    $('.reloadhttpd').bind('click', function(){
      var $lang = $(this).attr('data-lang');
      swal({
         title: jsi18n.get('custommaketext', "Are you sure?"),
         text: jsi18n.get('custommaketext',"Some user's could get an Error-404."),
         type: "warning",
         showCancelButton: true,
         confirmButtonColor: "#DD6B55",
         confirmButtonText: jsi18n.get('custommaketext',"Yes, restart!"),
         cancelButtonText: jsi18n.get('custommaketext',"Cancel"),
         closeOnConfirm: true,
       },
       function(){
          $.blockUI();
          var status = 0;
          var prefs = foswiki.preferences;
          var url = [
            prefs.SCRIPTURL,
            '/restauth',
            prefs.SCRIPTSUFFIX,
            '/CustomMaketextPlugin/reloadhttpd'
          ].join('');

          $.ajax({
            url: url,
            success: function( response ) {
              status = response;
            },
            error: function( xhr, sts, err ) {
              status = 500;
            }
          }).done(function() {
            $.unblockUI();
            switch (status) {
              case "200": { swal(jsi18n.get('custommaketext',"Restart"), jsi18n.get('custommaketext',"Webserver successfully restarted. It could take a few minutes to see the changes."), "success"); break; }
              case "403": { swal(jsi18n.get('custommaketext',"Restart"), jsi18n.get('custommaketext',"You are not allowed to restart webserver."), "error"); break; }
              default: { swal(jsi18n.get('custommaketext',"Restart"), jsi18n.get('custommaketext',"Internal Server Error"), "error"); break; }
            }
          });
      });
    });
  }
})(jQuery);
