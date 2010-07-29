Gobe.embed = function(width, height){
    swfobject.embedSWF("/static/gobe.swf?d=" + Math.random(), Gobe.DIV, width, height, "9.0.0"
                , null, Gobe.flashVars, Gobe.params, {}
                , function(){ Gobe.swf = Gobe.get_movie(); });
};

jQuery(function(){
    var get = swfobject.getQueryParamValue;
    var height = get('h') || "500";
    var w = jQuery('#content').width();
    Gobe.params = {'bgcolor': '#FFFFFF'};
    Gobe.DIV = "content"

    Gobe.embed(w, height);


    jQuery(window).hashchange( function(){
        var anno_id = location.hash.substr(1).split(/!!/); // remove #
        var title = anno_id[0]
        anno_id = anno_id[1];


        jQuery.get('/annos/' + anno_id, function(anno_txt){
            if(jQuery.trim(anno_txt)){
                Gobe.swf.set_data(anno_txt);
                jQuery('#annotations').val(anno_txt);
                jQuery('#title').val(title);
            }
        });
    });


    jQuery('#submit').click(function(){
        var annos = jQuery('#annotations').val();
        //Gobe.swf.set_data(annos);
        var title = jQuery('#title').val();
        jQuery.post("/", {'annos': annos, 'title': title}, function(json){
            jQuery('#title').val(title);
            location.hash = '#' + title + "!!" + json.id ;
        }, "json")
    });
});
Gobe.onclick = function(args){
    console.log(args);
}
