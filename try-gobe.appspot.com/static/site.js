jQuery(function(){
    var get = swfobject.getQueryParamValue;
    var height = get('h') || "500";
    var w = jQuery('#content').width();
    var params = {'bgcolor': '#FFFFFF'};
    Gobe.DIV = "content"

    swfobject.embedSWF("/static/gobe.swf?d=" + Math.random(), Gobe.DIV, w, height, "9.0.0"
                , null, flashVars, params, {}
                , function(){ Gobe.swf = Gobe.get_movie(); });

    jQuery('#submit').click(function(){
        var annos = jQuery('#annotations').val();
        Gobe.swf.set_data(annos);
        var title = jQuery('#title').val();
        jQuery.post("/", {'annos': annos, 'title': title}, function(r){
            console.log(r);
        })
    });
});
Gobe.onclick = function(args){
    console.log(args);
}
