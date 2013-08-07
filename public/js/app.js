jQuery( function($){
  var channels = {
    'SCREEN': 'screen',
    'OVERVIEW': 'overview',
    'MATERIALS': 'materials',
    'GUIDE': 'guide'
  };

  var navigations = {
    'CURRENT': 'navi-current',
    'ABLE': 'navi-able',
    'DONE': 'navi-done',
    'NOT_YET': 'navi-not-yet',
    'OTHERS': 'navi-others'
  };
  var navigation_classes = $.map(navigations, function(value, key){ return value }).join(' ');

  var warning_handler = function(str){
    console.log(str);
  };

  var error_handler = function(str){
    // console.log(str);
    $.each(channels, function(i, id){
      // console.log(id);
      $('#' + id).delay(0).hide(0);
    });
    $('#screen')
      .html('<div class="alert alert-error">' + str +'</div>')
      .delay(0)
      .show(0);
  };

  var navigator_callback = function(data, status){
    console.log(data);
    if (data.status == 'success') {
      $.each(data.body, function(i, obj){
        // console.log(obj);
        if (obj.ChannelSwitch) {
          $.each(channels, function(i, id){
            // console.log(id);
            $('#' + id).hide();
          });
          $('#' + channels[obj.ChannelSwitch.channel]).show();
        }
        if (obj.DetailDraw) {
          // console.log(obj.DetailDraw);
          if ($('#' + obj.DetailDraw.id).length) {
            $('#detail').children('div').hide(0);
            $('#' + obj.DetailDraw.id).show(0);
          }
          else {
            warning_handler('missing DetailDraw id : ' + obj.DetailDraw.id);
          }
        }
        if (obj.NaviDraw) {
          // console.log(obj.NaviDraw);
          $('.navi-step').removeClass(navigation_classes).hide(0);
          $.each(obj.NaviDraw.steps, function(i, step){
            // console.log(step);
            if ($('#navi-' + step.id).length) {
                // step.is_finished;
              $('#navi-' + step.id)
                .addClass(navigations[step.visual])
                .show(0);
            }
            else {
              warning_handler('missing NaviDraw id : ' + step.id);
            }
          });
        }
        if (obj.Play) {
        }
        if (obj.Notify) {
          // console.log(obj.Notify);
          var notify = $('<p>');
          notify
            .attr('id', obj.Notify.id)
            .html(obj.Notify.id);
          $('#notify').append(notify)
            .hide(0)
            .delay(obj.Notify.delay * 1000)
            .show(0);
        }
        if (obj.Cancel) {
        }
      });
    }
    else {
      error_handler(data.status);
    }
  };

  $('.navigate').on('click', function(e){
    e.preventDefault();
    var url = $(this).attr('href');
    if ($(this).parent().hasClass('navi-current') && $(this).hasClass('substep')) {
      url = $(this).data('substep');
    }
    $.getJSON(url)
    .done(navigator_callback);
  });

  $('.navigator-run').each(function(){
    var url = $(this).attr('href');
    $.getJSON(url)
    .done(navigator_callback);
  });
});

/* others

http://twitter.github.com/bootstrap/

*/
