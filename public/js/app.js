jQuery( function($){
  var channel = {
    'OVERVIEW': 'overview',
    'MATERIALS': 'materials',
    'GUIDE': 'guide'
  };

  var navigator_callback = function(data, status){
    console.log(data);
    if (data.status == 'success') {
      $.each(data.body, function(i, obj){
        console.log(obj);
        if (obj.ChannelSwitch) {
          $.each(channel, function(i, id){
            console.log(id);
            $('#' + id).hide();
          });
          $('#' + channel[obj.ChannelSwitch.channel]).show();
        }
      });
    }
  };

  $('.navigate').on('click', function(e){
    e.preventDefault();
    var url = $(this).attr('href');
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
