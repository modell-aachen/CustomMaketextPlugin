(function($) {
  $(document).ready(function() {
    bindRemove();
    bindRemoveLanguage();
    bindRestartApache();

    // configure the table sorter
    // initial sort: second column (en), asc
    $.tablesorter.defaults.sortList = [[1, 0]];
    // defines how data is extracted from the td elements
    $.tablesorter.defaults.textExtraction = function(node) {
      return node.childNodes[0].value;
    };

    $('.addlanguage').bind('click', function(){
      $.blockUI();
      $('table.tablesorter').trigger('update');
    });

    $('.saveall').bind('click', function(){
      // check if user entered at least a msgid in each row
      // and if each entry in column en is unique
      var missingMsgid = false;
      var $msgidInputs = $('.pobody tr:visible input[name$="_str"]');
      var msgidsArray = [];
      $msgidInputs.each(function() {
        var $value = $(this).attr('value');
        missingMsgid = missingMsgid || ($value ? false : true);
        msgidsArray.push($value);
      });
      if(missingMsgid) {
        swal(jsi18n.get('custommaketext',"Error"), jsi18n.get('custommaketext',"Please provide a value for \'en\' in each row."), "error");
        return;
      }
      if(hasDuplicates(msgidsArray)) {
        swal(jsi18n.get('custommaketext',"Error"), jsi18n.get('custommaketext',"Please enter unique values in column \'en\'."), "error");
        return;
      }

      // collect data to send from inputs
      $data = {};
      var $dataCounts = $('.pobody tr').map(function() {
        return $(this).attr('data-count');
      });
      var $lastElem = Math.max.apply(null, $dataCounts);
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
      }).error(function(){
        $.unblockUI();
        swal(jsi18n.get('custommaketext',"Error"), jsi18n.get('custommaketext',"You are not allowed."), "error");
      });
    });

    $('.addline').bind('click', function(){
      // if no language was added yet the user should not be able to add new lines
      if($('.pobody').parent().find('thead th.header').length < 4){
        return false;
      }
      var $dataCounts = $('.pobody tr').map(function() {
        return $(this).attr('data-count');
      });
      var $count = Math.max.apply(null, $dataCounts) + 1;
      var $newElem = $('.pobody tr:last').clone();
      $newElem.removeAttr('style');
      $newElem.attr('data-count',$count);
      // if this is the first row
      $newElem.find('input[name="0_head_str"]').attr('name',$count+'_str');
      $newElem.find('input[type="text"]').each(function(){
        $name = $(this).attr('name').replace(/\d+/, $count);
        $(this).attr('name',$name);
        $(this).attr('value','');
      });
      $('.pobody').append($newElem);
      // bind event listener to newly created text input fields 
      $newElem.find('input').bind('blur', function() {
        $('table.tablesorter').trigger('update');
      });
      $('table.tablesorter').trigger('update');
      bindRemove();
    });

    // bind update of table sorter cache to the 'focus lost' event of the inputs 
    $('.pobody input:visible[type="text"]').bind('blur', function() {
      $('table.tablesorter').trigger('update');
    });

  });

  // helper function
  function hasDuplicates(array) {
    var valuesSoFar = [];
    for (var i = 0; i < array.length; ++i) {
        if (valuesSoFar.indexOf(array[i]) !== -1) return true;
        valuesSoFar.push(array[i]);
    }
    return false;
  }

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
        $('table.tablesorter').trigger('update');
        // swal(jsi18n.get('custommaketext',"Deleted!"), jsi18n.get('custommaketext',"The line was successfully deleted."), "success");
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
          $('table.tablesorter').trigger('update');
      });
    });
  }

  function bindRestartApache(){
    $('.reloadhttpd').bind('click', function(){
      var $lang = $(this).attr('data-lang');
      swal({
         title: jsi18n.get('custommaketext', "Are you sure?"),
         text: jsi18n.get('custommaketext',"Some users could get an Error-404."),
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
