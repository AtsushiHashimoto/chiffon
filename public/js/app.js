jQuery( function($){

  // global variables
  var notification_live_sec;
  var jobs = {};
  var DEBUG = 1;

  // loading
  $(document).ajaxStart(function() {
    $('#loading')
      .css("top", $(window).scrollTop() + "px")
      .css("left", $(window).scrollLeft() + "px")
      .show(0);
  }).ajaxComplete(function(){
    $('#loading')
      .hide(0);
  }).ajaxError(function(){
    noty({
      type: 'error',
      text: 'AJAX ERROR'
    });
  });

  var channels = {
    'SCREEN': 'screen',
    'OVERVIEW': 'overview',
    'MATERIALS': 'materials',
    'GUIDE': 'guide'
  };

  var navigations = {
    'CURRENT': 'navi-current',
    'ABLE': 'navi-able',
    'OTHERS': 'navi-others'
  };
  var navigation_classes = $.map(navigations, function(value, key){ return value }).join(' ');

  var media_play = function(id){
    if (DEBUG) console.log('-- media_play id : '+id);
    var media = $('#' + id);
    if (!media.length) {
      warning_handler('missing recipe for media_play : ' + id);
    }
    media = document.getElementById(id);
    if (!media) {
      warning_handler('missing media id : '+id);
    }
    jobs[id] = media;
    media.play();
  };

  var notify_play = function(id){
    console.log('-- notify_play id : '+id);
    var notify = $('#' + id);
    if (!notify.length) {
      warning_handler('missing recipe for notify_play : ' + id);
    }
    var audio_id = notify.find('.media-play').attr('rel');
    if (audio_id.length) {
      if (DEBUG) console.log('find media in notify : '+audio_id);
      noty({
        callback: {
          onShow: function(){ media_play(audio_id) }
        },
        text: notify.html()
      });
    }
    else {
      noty({ text:notify.html() });
    }
  };

  var warning_handler = function(str){
    console.log('-- warning_handler str : '+str);
    noty({
      type: 'warning',
      text: str
    });
  };

  var error_handler = function(str){
    console.log('-- error_handler str : '+str);
    noty({
      type: 'error',
      text: str
    });
  };

  var navigator_callback = function(data, status){
    if (data.status == 'success') {
      $.each(data.body, function(i, obj){
        if (obj.ChannelSwitch) {
          if (DEBUG) console.log({'-- ChannelSwitch': obj.ChannelSwitch});
          $.each(channels, function(i, id){
            $('#' + id).hide(0);
          });
          var pane = $('#' + channels[obj.ChannelSwitch.channel]);
          if (!pane) {
            warning_handler('unknown channel : '+obj.ChannelSwitch.channel);
          }
          pane.show(0);
        }
        else if (obj.DetailDraw) {
          if (DEBUG) console.log({'-- DetailDraw': obj.DetailDraw});
          var id = obj.DetailDraw.id;
          var pane = $('#' + id);
          if (pane.length) {
            $('#detail').children('div').hide(0);
            pane.show(0);
          }
          else {
            warning_handler('missing recipe for DetailDraw : ' + id);
          }
        }
        else if (obj.NaviDraw) {
          if (DEBUG) console.log({'-- NaviDraw': obj.NaviDraw});
          $('.navi-step').removeClass(navigation_classes).hide(0);
          $.each(obj.NaviDraw.steps, function(i, step){
            if ($('#navi-' + step.id).length) {
              $('#check-' + step.id).attr('checked', step.is_finished ? true : false);
              $('#navi-' + step.id)
                .addClass(navigations[step.visual])
                .show(0);
            }
            else {
              warning_handler('missing recipe for NaviDraw : ' + step.id);
            }
          });
        }
        else if (obj.Play) {
          if (DEBUG) console.log({'-- Play': obj.Play});
          var id = obj.Play.id;
          var timer = setTimeout(media_play, obj.Play.delay * 1000, id);
          jobs[id] = timer;
          if (DEBUG) console.log('-- setTimeout for : '+id);
        }
        else if (obj.Notify) {
          if (DEBUG) console.log({'-- Notify': obj.Notify});
          var id = obj.Notify.id;
          var timer = setTimeout(notify_play, obj.Notify.delay * 1000, id);
          jobs[id] = timer;
          if (DEBUG) console.log('-- setTimeout for : '+id);
        }
        else if (obj.Cancel) {
          if (DEBUG) console.log({'-- Cancel': obj.Cancel});
          var id = obj.Cancel.id;
          var target = [];
          var cancel = $('#'+id);
          if (!cancel.length) {
            warning_handler('missing recipe for Cancel : ' + id);
          }
          target.push(id);
          var audio = cancel.find('.media-play');
          if (audio.length) {
            var audio_id = audio.attr('rel');
            target.push(audio_id);
          }
          if (DEBUG) console.log({'-- cancel for': target});
          $.each(target, function(i, v){
            var job = jobs[v];
            if (typeof(job) == 'number') {
              clearTimeout(job);
              noty({
                type: 'success',
                text: 'timer for `' + v + '` is canceled'
              });
              delete jobs[v];
            }
            else if (typeof(job) == 'object') {
              job.pause();
              noty({
                type: 'success',
                text: 'video/audio for `' + v + '` is paused'
              });
              delete jobs[v];
            }
            else {
              if (DEBUG) console.log({'-- jobname': job});
              warning_handler('not exist or not support in jobs : '+v);
            }
          });
          if (DEBUG) console.log({'-- stack jobs': jobs});
        }
        else {
          if (DEBUG) console.log({'-- Cancel': obj.Cancel});
          warning_handler('unknown response : ' + obj);
        }
      });
    }
    else {
      if (DEBUG) console.log({'-- data': data});
      error_handler(data.status);
    }
  };

  // play video/audio
  $('.media-play').on('click', function(e){
    e.preventDefault();
    var id = $(this).attr('rel');
    media_play(id);
  });

  // start ajax
  $('.check').on('click', function(e){
    var url = $(this).data('url');
    $.getJSON(url)
    .done(navigator_callback);
  });

  // start ajax
  $('.navigate').on('click', function(e){
    e.preventDefault();
    var url = $(this).attr('href');
    $.getJSON(url)
    .done(navigator_callback);
  });

  // init
  $('.navigator-run').each(function(){
    var url = $(this).attr('href');
    notification_live_sec = $(this).data('notification_live_sec');
    $.getJSON(url)
    .done(navigator_callback);
    $.noty.defaults = {
      layout: 'bottom',
      theme: 'defaultTheme',
      type: 'alert',
      text: '',
      dismissQueue: true,
      template: '<div class="noty_message"><span class="noty_text"></span><div class="noty_close"></div></div>',
      animation: {
          open: {height: 'toggle'},
          close: {height: 'toggle'},
          easing: 'swing',
          speed: 400
      },
      timeout: notification_live_sec * 1000,
      force: false,
      modal: false,
      maxVisible: 5,
      closeWith: ['click'],
      callback: {
          onShow: function() {},
          afterShow: function() {},
          onClose: function() {},
          afterClose: function() {}
      },
      buttons: false // an array of buttons
    };
  });
});

/* libraries

http://twitter.github.com/bootstrap/

http://needim.github.io/noty/

*/
