var Gobe = {
    'onmouseover': function(id, name, bpstart, bpend, track_id){
    },
    'onclick': function(args){
        console.log(args);
        var text = "<b>Type:</b>" + args[2] + "<br />";
        text += "<b>Start:</b>" + args[3] + "<br />";
        text += "<b>Stop:</b>" + args[4] + "<br />";
        jQuery('#dialog').html(text).dialog({title: args[1]});
    },
    'warn': function(msg){
        console.log("Flash msg:" + msg);
    },

    'redraw': function(){
        Gobe.swf.redraw();
    },

    'set_hsp_colors': function(){
        var colors = [];
        if (arguments.length > 0 && arguments[0] instanceof Array){
            colors = arguments[0];
        }
        else {
            for(var i=0; i<arguments.length; i++){ colors.push(arguments[i]); }
        }
        if(colors) Gobe.swf.set_hsp_colors(colors);
    },

    DIV: 'flashcontent',
    'get_movie': function () {
          if (swfobject.ua.ie) {
              return window[Gobe.DIV];
          } else {
              return document[Gobe.DIV];
          }
    },
    'clear': function(){
        // dont change this!
        Gobe.swf.clear_wedges();
    },
    'set_linewidth': function(linewidth){
        // dont change this. could check for 0 <= lw <= ?
        Gobe.swf.set_linewidth(linewidth);
    }
};
