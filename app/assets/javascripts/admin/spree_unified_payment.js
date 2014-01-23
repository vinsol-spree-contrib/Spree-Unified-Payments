$(document).ready(function() {
  click_on_overlay = function(pop_up_div) {
    $('div.ui-widget-overlay').on('click', function(){
      $('div.ui-widget-overlay').remove();
      pop_up_div.dialog("close");
    });
  }

  ModalPopUp = function(pop_up_div) {
    var self = {
      init: function() {
        pop_up_div.dialog({ 
          autoOpen: false,
          modal: true,
          width:700,
          closeText: "X",
          dialogClass:"quick_view_container",
          close: function(event, ui) {
            pop_up_div.remove();
            $('#easy_zoom').remove();
          }
        });
      },
      show: function() {
        pop_up_div.dialog("open");
        click_on_overlay(pop_up_div);
      } 
    }
    self.init();
    return self;
  }  
  
  $('#reveal_xml').click(function() {
    ct_id = $(this).attr('data-ct-id');
    var quick_view = new ModalPopUp($("<div></div>").attr('id', 'quick_view_popup').html($("#xml_response_" + ct_id).clone()));
    $('#quick_view_popup .xml_response').removeClass('hidden');
    quick_view.show();
  })
});
