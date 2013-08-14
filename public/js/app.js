jQuery( function($){

  // global variables
  var DEBUG = 1;
  var notification_live_sec;
  var external_input_url;
  var check_url;
  var logger_url;
  var receiver_url;
  var jobs = {};
  var record_keys = false;
  var keys = [];
  var seconds = 1000;

  // keypress
  $(document).on('keypress', function(e){
    if (record_keys) {
      var key = e.charCode;
      if (key == 13) {
        var input = keys.join('');
        if (DEBUG) console.log(input);
        $.getJSON(external_input_url, {'input': input})
        .done(navigator_callback);
        keys = [];
        return;
      }
      keys.push(String.fromCharCode(key));
    }
    if (DEBUG) console.log(keys);
  });

  // show_notify
  var show_notify = function(obj){
    noty(obj);
  };

  // loading
  $(document).ajaxStart(function() {
    record_keys = false;
    $('#loading')
      .css("top", $(window).scrollTop() + "px")
      .css("left", $(window).scrollLeft() + "px")
      .show(0);
  }).ajaxComplete(function(){
    record_keys = true;
    $('#loading')
      .hide(0);
  }).ajaxError(function(){
    record_keys = true;
    show_notify({
      type: 'error',
      text: 'AJAX ERROR'
    });
  });

  var channels = {
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
    // TODO: exists media to warning_handler
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
    var audio_id = notify.find('.media-play').data('for');
    if (audio_id.length) {
      if (DEBUG) console.log('find media in notify : '+audio_id);
      show_notify({
        callback: {
          onShow: function(){ media_play(audio_id) }
        },
        text: notify.html()
      });
    }
    else {
      show_notify({ text:notify.html() });
    }
  };

  var warning_handler = function(str){
    if (DEBUG) console.log({'-- warning_handler':str});
    if (DEBUG) show_notify({
      type: 'warning',
      text: str
    });
    $.getJSON(logger_url, {type:'warn', msg:str});
  };

  var error_handler = function(str){
    if (DEBUG) console.log({'-- error_handler':str});
    if (DEBUG) show_notify({
      type: 'error',
      text: str
    });
    $.getJSON(logger_url, {type:'error', msg:str});
  };

  var navigator_callback = function(data, status){
    if (data.status == 'success') {
      var is_updated = false;
      $.each(data.body, function(i, obj){
        is_updated = true;
        if (obj.ChannelSwitch) {
          // ChannelSwitch
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
          // DetailDraw
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
          // NaviDraw
          if (DEBUG) console.log({'-- NaviDraw': obj.NaviDraw});
          $('.navi-step').removeClass(navigation_classes).hide(0);
          var finished = true;
          $.each(obj.NaviDraw.steps, function(i, step){
            if (finished) { finished = step.is_finished ? true : false }
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
          if (finished) {
            $('#finished').show(0);
          }
        }
        else if (obj.Play) {
          // Play
          // TODO: substep active check
          if (DEBUG) console.log({'-- Play': obj.Play});
          var id = obj.Play.id;
          var timer = setTimeout(media_play, obj.Play.delay * seconds, id);
          jobs[id] = timer;
          if (DEBUG) console.log('-- setTimeout for : '+id);
        }
        else if (obj.Notify) {
          // Notify
          if (DEBUG) console.log({'-- Notify': obj.Notify});
          var id = obj.Notify.id;
          var timer = setTimeout(notify_play, obj.Notify.delay * seconds, id);
          jobs[id] = timer;
          if (DEBUG) console.log('-- setTimeout for : '+id);
        }
        else if (obj.Cancel) {
          // Cancel
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
            var audio_id = audio.data('for');
            target.push(audio_id);
          }
          if (DEBUG) console.log({'-- cancel for': target});
          $.each(target, function(i, v){
            var job = jobs[v];
            if (typeof(job) == 'number') {
              clearTimeout(job);
              show_notify({
                type: 'success',
                text: 'timer for `' + v + '` is canceled'
              });
              delete jobs[v];
            }
            else if (typeof(job) == 'object') {
              job.pause();
              show_notify({
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
          if (DEBUG) console.log({'-- obj': obj});
          warning_handler('unknown response : ' + obj);
        }
      });
      // 更新音の再生
      if (is_updated) {
        media_play('update_sound');
      }
    }
    else {
      if (DEBUG) console.log({'-- data': data});
      error_handler(data.status);
    }
  };

  // play video/audio
  $('.media-play').on('click', function(e){
    e.preventDefault();
    var id = $(this).data('for');
    media_play(id);
    $.getJSON(check_url, {'media_play': id})
    .done(navigator_callback);
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
    external_input_url = $(this).data('external_input_url');
    check_url = $(this).data('check_url');
    logger_url = $(this).data('logger_url');
    receiver_url = $(this).data('receiver_url');
    var session_id = $(this).data('session_id');
    var ws = new WebSocket(receiver_url);
    ws.onmessage = function(e){
      if (DEBUG) console.log(e);
      if (RegExp(session_id).test(e.data)) {
        $.getJSON(external_input_url, {input: e.data})
          .done(navigator_callback);
      }
    };
    if (DEBUG) console.log(document.cookie);

    record_keys = true;

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
      timeout: notification_live_sec * seconds,
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
