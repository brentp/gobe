var Gobe = {
    'onmouseover': function(id, name, bpx, px, track_id){
    },
    'onclick': function(id, name, bpx, px, track_id){
        console.log(id, name, bpx, px, track_id);
    },
    'warn': function(msg){
        console.error("Flash msg:" + msg);
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
