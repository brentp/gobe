import HSP;
import Gobe;
import Plot;

class TInfo {
    public var bpmin:Int;
    public var bpmax:Int;
    public var id:String;
    public var name:String;
    public var order:Int;
    public function new(id:String, name:String, bpmin:Int, bpmax:Int, order:Int){
        this.bpmin = bpmin;
        this.bpmax = bpmax;
        this.id = id;
        this.name = name;
        this.order = order;
    }
}

class Util {
    public static var track_colors:Array<UInt> = [0xff9900, 0x330000, 0x99cc00, 0x009966, 0x9933cc, 0x3300ff, 0xffcc99];
    public static function add_edge_line(a:Annotation, b:Annotation, strength:Float):Null<Edge>{
        if (a == null || b == null){ return null; }

        var edge = new Edge(a, b, strength);
        var nedges = Gobe.edges.length;
        edge.a.edges.push(nedges);
        edge.b.edges.push(nedges);
        Gobe.edges.push(edge);
        flash.Lib.current.addChild(edge);
        return edge;
    }
    public static function set_hsp_colors(colors:Array<String>){
        var a = [];
        for(c in colors){ a.push(Util.color_string_to_uint(c)); }
        Util.track_colors = a;
    }

    //  public function new(id:String, title:String, bpmin:Int, bpmax:Int, track_height:Int){
    public static function add_tracks_from_annos(anno_lines:Array<Array<String>>):Array<Annotation>{
        // takes precedence if the limits are set explicitly.
        // keep track of which tracks have had their bounds set explicitly.
        var explicit_set = new Hash<Int>();
        var anarr = new Array<Annotation>();
        var lims = new Hash<TInfo>();
        var al:Array<String>;
        var nexplicit = 0;
        var ntracks = 0;
        for(al in anno_lines){
            var track_id = al[1];
            var a:Annotation;
            if (al[4] == "track"){ // explicitly specified track extents.
                var start = Std.parseInt(al[2]);
                var end  = Std.parseInt(al[3]);
                var info = new TInfo(al[0], al[1], start, end, nexplicit);
                nexplicit += 1;
                lims.set(info.id, info);
                explicit_set.set(info.id, nexplicit);
            }
            else if(al[4].substr(0, 4) == "plot"){
                var p:Plot;
                if(al[4].substr(5, 9) == "line"){
                    p = new PlotLine(al);
                }
                else if(al[4].substr(5, 9) == "hist"){
                    p = new PlotHist(al);
                }
                else {
                    continue;
                }
                Gobe.plots.set(p.track_id, p);
            }
            else {
                var a = new Annotation(al);
                anarr.push(a);
                if(explicit_set.exists(track_id)) { continue; }

                if (! lims.exists(track_id)){
                    var info = new TInfo(track_id, track_id, a.bpmin, a.bpmax, ntracks);
                    ntracks += 1;
                    lims.set(track_id, info);
                }
                else {
                    var lim = lims.get(track_id);
                    if(a.bpmin < lim.bpmin){lim.bpmin = a.bpmin; }
                    if(a.bpmax > lim.bpmax){lim.bpmax = a.bpmax; }
                }
            }
        }
        var arr:Array<TInfo> = Lambda.array(lims);
        arr.sort(function(a:TInfo, b:TInfo){ return a.order < b.order ? -1 : 1; });
        var ntracks = arr.length;
        var track_height = Std.int(flash.Lib.current.stage.stage.stageHeight / ntracks);
        var tracks = new Hash<Track>();
        var k = 0;
        for (t in arr){
            var rng = t.bpmax - t.bpmin;
            var start = t.bpmin;
            var end = t.bpmax;
            // extend the limits a bit. unless they were set explicitly.
            if(!explicit_set.exists(t.id)){
                start = Math.round(Math.max(1, Math.round(t.bpmin - rng * 0.05)));
                end = Math.round(t.bpmax + rng * 0.05);
            }
            var t = new Track(t.id, t.name, start, end, track_height);
            t.i = k;
            tracks.set(t.id, t);
            t.y = k * track_height;
            flash.Lib.current.addChildAt(t, 0);
            k += 1;
        }
        Gobe.tracks = tracks;
        for(a in anarr){ a.track = tracks.get(a.track_id); }
        return anarr;
    }

    public static function sorted_keys(keys:Iterator<String>):Array<String>{
        var skeys = new Array<String>();
        for(k in keys){ skeys.push(k); }
        skeys.sort(function(a:String, b:String){ return a < b ? 1: -1; });
        return skeys;
    }

    public static function next_track_color(aid:String, bid:String, colors:Hash<UInt>):UInt{
        // if the key exists, use it, otherwise, get the next color and add it to the hash.
        var color_key = aid < bid ? aid + "|" + bid : bid + "|" + aid;

        if(colors.exists(color_key)){
            return colors.get(color_key);
        }
        var l = 0; for(k in colors.keys()){ l += 1; }
        var track_color = Util.track_colors[l];
        colors.set(color_key, track_color);
        return track_color;
    }
    public static function color_string_to_uint(c:String):UInt{
        if(c == null){ return 0x000000; }
        c = '0x' + StringTools.replace(c, '#', '');
        return Std.parseInt(c);
    }

    public static inline function color_shift(c:UInt, cshift:Int):UInt {
        var r:UInt = ((c >> 16) & 0xff) + cshift;
        var g:UInt = ((c >> 8) & 0xff) + cshift;
        var b:UInt = (c & 0xff) + cshift;
        // *shrugh* please fix me!!

        if(r > 0xffff){ r = 0; }
        if(g > 0xffff){ g = 0; }
        if(b > 0xffff){ b = 0; }
        if(r > 255){ r = 255;}
        if(g > 255){ g = 255;}
        if(b > 255){ b = 255;}
        return r << 16 | g << 8 | b;

    }
}
