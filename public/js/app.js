jQuery( function($){

  // X-Editable
  // http://vitalets.github.io/x-editable/index.html
  $('.editable').editable();
  $('.editable-date').editable({
    type: 'datetime',
    mode: 'inline',
    format: 'yyyy/mm/dd',
    datetimepicker: {
      minView: 'month',
      language: 'ja',
      todayBtn: 'linked',
      todayHighlight: 'true'
    }
  });
  $('.editable-datetime').editable({
    type: 'datetime',
    mode: 'inline',
    format: 'yyyy/mm/dd hh:ii',
    datetimepicker: {
      language: 'ja',
      todayBtn: 'linked',
      todayHighlight: 'true'
    }
  });
  $('.editable-lazy').each(function(){
    var target = $(this);
    var options = [];
    $.getJSON(target.attr('rel'), function(data){
      $.each(data, function(i, val){
        options.push({text: val[0], id: val[1]});
      });
    });
    target.editable({
      type: 'select2',
      select2: {
        dropdownAutoWidth: 'true'
      },
      source: options
    });
  });

  // live-checkbox
  $('.live-checkbox').on('change', function(){
    var url    = $(this).data('url');
    var pk     = $(this).data('pk');
    var name   = $(this).attr('name');
    var value  = $(this).attr('checked') ? 1 : 0;
    var jsondata   = {pk: pk, name: name, value: value};
    $.ajax({
      type: "POST",
      url: url,
      data: jsondata,
      datatype: 'json'
    });
  });

  // fixed Header
  // http://www.fixedheadertable.com/
  $('.fixed_table').fixedHeaderTable({
    height: 250
  });
//    $('.fixed_table').fixedHeaderTable('destroy');
//    $('.fixed_table').fixedHeaderTable('show');
  //
  $('a[data-toggle="tab"]').on('shown', function (e) {
//    e.target;
    var show_id = $(e.target).attr('href');
    $(show_id + ' .fixed_table').fixedHeaderTable('destroy');
    $(show_id + ' .fixed_table').fixedHeaderTable({
      height: 250
    });
  });

  // zipcode
  // https://github.com/kotarok/jQuery.zip2addr
  $('#id-zipcode').zip2addr('#id-address');

  // `class reload_form`
  $('.reload_form').on('change', function(){
    $(this.form).submit();
  });

  // `class auto-selection`
  // $('.auto-selection').on('active', function(){
  //   this.select();
  // });

  // form loading
  $('form').on('submit', function(){
    $(":submit", this).button('loading');
  });

  // X-Editableにより、bootstrap-datetimepickerを利用
  $('.datepicker').datetimepicker({
    format: 'yyyy/mm/dd',
    autoclose: 'true',
    minView: 'month',
    language: 'ja',
    todayBtn: 'linked',
    todayHighlight: 'true'
  });

  // chosen
  // http://harvesthq.github.com/chosen/
  // 日本語変換に対する挙動が今いち

  // select2
  // https://github.com/ivaynberg/select2
  $('.chosen').select2();

  // lazy-json
  $('.lazy-json').each(function(){
    var target = $(this);
    $.getJSON(target.attr('rel'), function(data){
      var options = [];
      $.each(data, function(i, val){
        options.push(new Option(val[0], val[1]));
      });
      target.append(options).select2();
    });
  });

  // auto_ruby
  // http://ogiyasu.com/auto_ruby.php
  $('.auto_ruby_from').each(function () {
    $(this).auto_ruby($('.auto_ruby_to'));
  });

  // timePicker
  // http://labs.perifer.se/timedatepicker/
  $('.timepicker').timePicker();

  // confirm for danger action
  $(".confirm").on('click', function(){
    var str = $(this).data('label');
    return confirm(str);
  });

  // for external link
  // 戻るリンクのために廃止
  // $("a[href^='http']").each(function() {
  //   $(this)
  //   // link target blank
  //   .attr('target', '_blank')
  // });
});

/* others

http://twitter.github.com/bootstrap/

http://code.google.com/p/ie6alert-js/

*/
