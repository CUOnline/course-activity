$(document).ready(function() {
  $('.category').click(function(e) {
    $(this).next().toggle('fade');
    var icon = $(this).find('span').first();
    icon.toggleClass('glyphicon-chevron-down');
    icon.toggleClass('glyphicon-chevron-up');
  });

  $('.item').click(function(e) {
    $(this).next('tr').toggle('fade');
    var icon = $(this).find('span').first();
    icon.toggleClass('glyphicon-triangle-top');
    icon.toggleClass('glyphicon-triangle-bottom');
  });
});
