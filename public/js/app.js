jQuery( function($){

  // global variables
  var DEBUG = 1;
  var notification_live_sec;
  var external_input_url;
  var check_url;
  var play_control_url;
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
        $.getJSON(external_input_url, {input: input})
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

  // チャンネルの定義テーブル
  var channels = {
    'OVERVIEW': 'overview',
    'MATERIALS': 'materials',
    'GUIDE': 'guide'
  };

  // メニューの表示切り替えテーブル
  var navigations = {
    'CURRENT': 'navi-current',
    'ABLE': 'navi-able',
    'OTHERS': 'navi-others'
  };

  // メニュー初期化用クラス名
  var navigation_classes = $.map(navigations, function(value, key){ return value }).join(' ');

  // 音声・動画のDOM要素を取得
  var get_media = function(id){
    // var media = $('#' + id); // こっちだとコントロールができない
    var media = document.getElementById(id);
    if (!media) {
      warning_handler('missing media id : '+id);
      return;
    }
    return media;
  }

  // フルスクリーンイベント
  $(document).on('webkitfullscreenchange', function(e){
    // 残念ながら取得できない（フルスクリーン時でもfalse）
    // if (DEBUG) console.log({fullscreen: document.webkitFullScreen ? true : false});
    if (DEBUG) console.log({fullscreenstate: $(':-webkit-full-screen').length ? true : false});
    var value = $(':-webkit-full-screen').length ? 'ON' : 'OFF';
    if (DEBUG) console.log(e);
    $.getJSON(play_control_url, {pk: e.srcElement.id, operation: 'FULL_SCREEN', value: value})
      .done(navigator_callback);
  });

  // フルスクリーンにする
  var request_full_screen = function(id){
    var media = get_media(id);
    if (!media) return;
    if (!$(':-webkit-full-screen').length) {
      // 大きく表示されない（CSSで可能？）
      // $(media).parent('.step').get(0).webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT);
      media.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT);
    } else {
      document.webkitCancelFullScreen();
    }
  }

  // 音声・動画を再生する
  var media_play = function(id, force){
    if (DEBUG) console.log('-- media_play id : '+id);
    var media = get_media(id);
    if (!media) return;
    jobs[id] = media;
    var step = $(media).parent('.step');
    if (DEBUG) console.log(step);
    var showOrHide = step.is(':visible');
    if (DEBUG) console.log(showOrHide);
    if (force || showOrHide) {
      if (DEBUG) console.log('play!');
      media.play();
    }
    else {
      warning_handler('step/substep is not active for media id : ' + id);
    }
  };

  // お知らせを表示する
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
          onShow: function(){ media_play(audio_id, true) }
        },
        text: notify.html()
      });
    }
    else {
      show_notify({ text:notify.html() });
    }
  };

  // 警告を表示し，サーバーへログを送信する
  var warning_handler = function(str){
    if (DEBUG) console.log({'-- warning_handler':str});
    if (DEBUG) show_notify({
      type: 'warning',
      text: str
    });
    $.getJSON(logger_url, {type:'warn', msg:str});
  };

  // エラーを表示し，サーバーへログを送信する
  var error_handler = function(str){
    if (DEBUG) console.log({'-- error_handler':str});
    if (DEBUG) show_notify({
      type: 'error',
      text: str
    });
    $.getJSON(logger_url, {type:'error', msg:str});
  };

  // Navigator呼び出し後のコールバック関数
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
              warning_handler('missing in jobs : '+v);
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
        var id = 'update_sound';
        if ($('#' + id).length) {
          media_play('update_sound', true);
        }
      }
    }
    else {
      if (DEBUG) console.log({'-- data': data});
      error_handler(data.status);
    }
  };

  // 音量を上げるボタン
  $('.louder').on('click', function(e){
    e.preventDefault();
    var id = $(this).data('for');
    var media = get_media(id);
    if (!media) return;
    media.volume += 0.1;
  });

  // 音量を下げるボタン
  $('.softer').on('click', function(e){
    e.preventDefault();
    var id = $(this).data('for');
    var media = get_media(id);
    if (!media) return;
    media.volume -= 0.1;
  });

  // フルスクリーンにするボタン
  $('.full-screen').on('click', function(e){
    e.preventDefault();
    var id = $(this).data('for');
    request_full_screen(id);
  });

  // 音量変更，ミュート判定
  var mute_status;
  var volume_timer;
  var volume_change = function(data){
    $.getJSON(play_control_url, {id: data.id, operation: 'VOLUME', value: data.v})
      .done(navigator_callback);
    clearTimeout(volume_timer);
    volume_timer = '';
  }

  // 再生場所変更判定
  var seeked_timer;
  var time_change = function(data){
    $.getJSON(play_control_url, {id: data.id, operation: 'JUMP', value: data.v})
      .done(navigator_callback);
    clearTimeout(seeked_timer);
    seeked_timer = '';
  }

  // 音声・動画を再生するボタン
  $('.media-play').each(function(){
    var id = $(this).data('for');
    var media = get_media(id);
    if (!media) return;
    if (DEBUG) console.log(media);
    $(media).on('ended', function(e){
      if (DEBUG) console.log(e.type);
      $.getJSON(play_control_url, {pk: id, operation: 'TO_THE_END'})
        .done(navigator_callback);
    });
    $(media).on('play', function(e){
      if (DEBUG) console.log(e.type);
      $.getJSON(play_control_url, {pk: id, operation: 'PLAY'})
        .done(navigator_callback);
    });
    $(media).on('pause', function(e){
      if (DEBUG) console.log(e);
      $.getJSON(play_control_url, {pk: id, operation: 'PAUSE'})
        .done(navigator_callback);
    });
    $(media).on('seeked', function(e){
      if (DEBUG) console.log(e.type);
      if (seeked_timer) {
        clearTimeout(seeked_timer);
      }
      seeked_timer = setTimeout(time_change, 1000, {id:id, v:media.currentTime});
    });
    $(media).on('volumechange', function(e){
      if (DEBUG) console.log(e.type);
      if (DEBUG) console.log(media.volume);
      if (DEBUG) console.log(media.muted);
      if (mute_status != media.muted) {
        mute_status = media.muted;
        var value = mute_status ? 'ON' : 'OFF';
        $.getJSON(play_control_url, {id: id, operation: 'MUTE', value: value})
          .done(navigator_callback);
      }
      else {
        if (volume_timer) {
          clearTimeout(volume_timer);
        }
        volume_timer = setTimeout(volume_change, 1000, {id:id, v:media.volume});
      }
    });
  })
  .on('click', function(e){
    e.preventDefault();
    var id = $(this).data('for');
    var media = get_media(id);
    if (!media) return;
    mute_status = media.muted;
    media_play(id);
  });

  // 済ボタン
  $('.check').on('click', function(e){
    var url = $(this).data('url');
    $.getJSON(url)
    .done(navigator_callback);
  });

  // ナビボタン
  $('.navigate').on('click', function(e){
    e.preventDefault();
    var url = $(this).attr('href');
    $.getJSON(url)
    .done(navigator_callback);
  });

  // 初期設定および動作
  $('.navigator-run').each(function(){
    var url = $(this).attr('href');
    notification_live_sec = $(this).data('notification_live_sec');
    external_input_url = $(this).data('external_input_url');
    check_url = $(this).data('check_url');
    play_control_url = $(this).data('play_control_url');
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
