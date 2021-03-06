
Gobe.embed = function(width, height){
    swfobject.embedSWF("/static/gobe.swf?d=" + Math.random(), Gobe.DIV, width, height, "9.0.0"
                , null, Gobe.flashVars, Gobe.params, {}
                , function(){ Gobe.swf = Gobe.get_movie(); });
};


jQuery(function(){
    var get = swfobject.getQueryParamValue;
    var height = get('h') || "500";
    var w = jQuery('#content').width();

    /* use jquery ui to style buttons */
    $("button").button();

    Gobe.params = {'bgcolor': '#FFFFFF'};
    Gobe.DIV = "content";



    // the value on the #hash overrides the other.
    // this block of code makes the links actually work.
    var anno_id = location.hash.substr(1).split(/!!/);
    if(anno_id[1]){
        Gobe.flashVars.annotations = "/annos/" + anno_id[1]
    }
    Gobe.embed(w, height);

    jQuery(window).hashchange( function(){
        var anno_id = location.hash.substr(1).split(/!!/); // remove #
        var title = anno_id[0]
        // add .gobe to get the right format to the flash movie.
        anno_id = anno_id[1]; // + ".gobe";


        jQuery.get('/annos/' + anno_id, function(anno_txt){
            if(jQuery.trim(anno_txt)){
                Gobe.swf.set_data(anno_txt);
                jQuery('#annotations').val(anno_txt);
                jQuery('#title').val(title);
            }
        });
    })

    var gs = jQuery('#gobe-style');
    gs.click(function(){
        var current_style = get_style();
        if(current_style != "/static/blue.css"){
            window.location = "?style=/static/blue.css" +  window.location.hash;
        }
        else {
            window.location = "?style=/static/gobe.css" + window.location.hash;
        }
    });

    jQuery('#submit').click(function(){
        var annos = jQuery('#annotations').val();
        //Gobe.swf.set_data(annos);
        var title = jQuery('#title').val();
        jQuery.post("/", {'annos': annos, 'title': title}, function(json){
            jQuery('#title').val(title);
            location.hash = '#' + title + "!!" + json.anno_id ;
        }, "json")
    });

    jQuery('.add-bar-hist').click(function(){
        var annos = jQuery('#bar-hist').val()
        jQuery.post("/", {"annos": annos}, function(json){
           var ja = jQuery('#annotations');
           var as = annos.split(/\n/);
           var plot_type = as[0].split(/,/).length > 1 ? "plot_hist" : "plot_line";
           var xmin, xmax;
           if (plot_type == "plot_line"){
               xmin = 0, xmax = annos.split(/\n/).length
           }
           else {
           // if it's a bar-plot, we can make a reasonable guess for xmin, xmax
           // based on the values in the data.
               var xmin = Number.MAX_VALUE, xmax = Number.MIN_VALUE;
               var i = 0, row;
               for(i=0; row=as[i++];){
                 if(row.substr(0) == "#"){ continue; }
                 var arow = row.split(",");
                 if (parseInt(arow[0]) < xmin){ xmin = parseInt(arow[0]); }
                 if (parseInt(arow[1]) > xmax){ xmax = parseInt(arow[1]); }
               }
               xmax += 5;
           }
           var new_line = [json.anno_id, "TRACK_ID",xmin, xmax, plot_type, 0, "/annos/" + json.anno_id].join(",");
           // add a row for the the newly uploaded hist data to the annos.
           ja.val(jQuery.trim(ja.val()) + "\n" + new_line);
           // click so the annos get updated.
           jQuery('#submit').click();
        }, "json")
    });

    jQuery('#clear').click(Gobe.clear);
    jQuery('#hide-labels').click(Gobe.hide_labels);
});

