DcmgrGUI.prototype.sshKeyPairPanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/keypairs/list/',page),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "name":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "name" : "-",
      "create_at" : "-",
      "update_at":''
    }
  }
  
  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_ssh_keypairs',
    template_id:'#sshKeyPairsListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  c_list.setDetailTemplate({
    template_id:'#sshKeypairsDetailTemplate',
    detail_path:'/keypairs/show/'
  });
    
  c_list.element.bind('dcmgrGUI.contentChange', function(event,params){
    var ssh_key_pair = params.data.ssh_key_pair;
    c_pagenate.changeTotal(ssh_key_pair.owner_total);
    c_list.setData(ssh_key_pair.results);
    c_list.singleCheckList(c_list.detail_template);
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  bt_refresh.element.bind('dcmgrGUI.refresh', function(){
    
    //Update list element
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/keypairs/list/', c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_list.page, c_list.maxrow)
    c_list.element.trigger('dcmgrGUI.updateList', {request:list_request})
    
    $.each(c_list.checked_list, function(check_id,obj){
      //All remove detail element
      $($('#detail').find('#'+check_id)).remove();
      
      //All reload detail element
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/keypairs/show/', check_id)
      },true);
    });
  });
  
  c_pagenate.element.bind('dcmgrGUI.updatePagenate', function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var bt_create_ssh_keypair = new DcmgrGUI.Dialog({
    target:'.create_ssh_keypair',
    width:400,
    height:200,
    title:'Create SSH Key Pair',
    path:'/create_ssh_keypair',
    callback: function(){
      var html = '<iframe src="javascript:false" name="hiddenIframe" style="display:none"></iframe>';
      $(this).find('#create_ssh_keypair_dialog').append(html);
    },
    button:{
     "Create": function() { 
       var name = $(this).find('#ssh_keypair_name').val();
       var download_once = $(this).find('#ssh_keypair_download_once').attr('checked');

       if(!name){
         $('#ssh_keypair_name').focus();
         return false;
       }
       
       if(!name.match(/[a-z0-9_]+/)){
         $('#ssh_keypair_name').focus();
         return false;
       }
       
       var iframe = $(this).find('iframe:first').contents();
       var html = '<form id="prk_download" action="/keypairs/create_ssh_keypair" method="get">'
                  +'<input type="hidden" name="name" value="'+name+ '">'
                  +'<input type="hidden" name="download_once" value="'+download_once+ '">'
                  +'</form>'

       iframe.find('body').append(html);
       iframe.find("#prk_download").submit();
       bt_refresh.element.trigger('dcmgrGUI.refresh');
       $(this).dialog("close");
      }
    }
  });
  
  bt_create_ssh_keypair.target.bind('click', function(){
    bt_create_ssh_keypair.open();
  });
  
  var bt_delete_ssh_keypair = new DcmgrGUI.Dialog({
    target: '.delete_ssh_keypair',
    width: 400,
    height: 200,
    title: 'Delete SSH Keypair',
    path: '/delete_ssh_keypair',
    button:{
     "Yes, Delete": function() { 
       var ssh_keypair_id = $(this).find('#ssh_keypair_id').val();
       $.ajax({
          "type": "DELETE",
          "async": true,
          "url": '/keypairs/'+ ssh_keypair_id +'.json',
          "dataType": "json",
          success: function(json, status){
            bt_refresh.element.trigger('dcmgrGUI.refresh');
          }
       });
       $(this).dialog("close");
      }
    }
  });
  
  bt_delete_ssh_keypair.target.bind('click', function() {
    var id = c_list.currentChecked();
    if( id ){
      bt_delete_ssh_keypair.open({"ids":[id]});
    }
    return false;
  });
  

  c_list.setData(null);
  c_list.update(list_request,true);
}