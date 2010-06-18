import Annotation;
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
    public static var track_colors:Array<UInt> = [0xff9900, 0x330000, 0x99cc00, 0x009966, 0x9933cc, 0x3300ff, 0xffcc99, 0xcccccc, 0x3333dd];

    public static function add_edge_line(a:Annotation, b:Annotation, strength:Float):Null<Edge>{
        // add an edge between a an b.
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

    private static function updateEdgeTracks(a:Annotation, b:Annotation, strength:Float, edge_tracks:Hash<Hash<Int>>){
            // used in addAnnotation to add annos to edge_tracks which
           // keeps track of unique track pairs.
            var edge = Util.add_edge_line(a, b, strength);
            if (edge == null){ return; }

            // so here we tabulate all the unique track pairs...
            var aid = edge.a.track_id;
            var bid = edge.b.track_id;

            // for each edge, need to see the annos.tracks it's associated with...
            if(! edge_tracks.exists(aid)) { edge_tracks.set(aid, new Hash<Int>()); }
            if(! edge_tracks.exists(bid)) { edge_tracks.set(bid, new Hash<Int>()); }
            edge_tracks.get(bid).set(aid, 1);
            edge_tracks.get(aid).set(bid, 1);
    }

    public static function add_tracks_from_annos(anno_lines:Array<Array<String>>, edge_tracks:Hash<Hash<Int>>):Array<Annotation>{
        // takes precedence if the limits are set explicitly.
        // account for which tracks have had their bounds set explicitly.
        var explicit_set = new Hash<Int>();
        var anarr = new Array<Annotation>();
        var lims = new Hash<TInfo>();
        var al:Array<String>;
        var nexplicit = 0;
        var ntracks = 0;
        var hsps = new Array<Annotation>();
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
                // if a plot is specified, its limits are used as the explicit extents.
                if(! explicit_set.exists(al[1])){
                    var info = new TInfo(al[1], al[1], p.bpmin, p.bpmax, nexplicit);
                    lims.set(info.id, info);
                    nexplicit += 1;
                    explicit_set.set(info.id, nexplicit);
                }
                Gobe.plots.set(p.track_id, p);
                ntracks += set_track_info(p, lims, explicit_set);
            }
            else {
                var a = new Annotation(al);
                anarr.push(a);
                ntracks += set_track_info(a, lims, explicit_set);
                Gobe.set_anno_style(a);
                // handle hsp stuff.
                if(a.is_hsp){
                    hsps.push(a);
                    if(hsps.length % 2 == 0){
                        Util.updateEdgeTracks(hsps[0], hsps[1], 1.0, edge_tracks);
                        hsps = [];
                    }
                }
                else if (hsps.length != 0) {
                    Gobe.js_warn("non-consecutive hsps");
                }
            }
        }
        var arr:Array<TInfo> = Lambda.array(lims);

        // count the number of subtracks. used in calcing track heights.
        var subtracks_by_track = new Hash<Int>();
        var nsubtracks = 0;
        for(parent_track_id in edge_tracks.keys()){
            // multiply by 2 to account for plus and minus
            var nt = 2 * Lambda.count(edge_tracks.get(parent_track_id));
            subtracks_by_track.set(parent_track_id, nt);
            nsubtracks += nt;
        }
        /* using sympy/sage:
        H = var('H')     // total movie height
        nst = var('nst') // number of subtracks.
        th = var('th')   // track height
        strat = var('strat') // ratio of subtrack height to track height
        nt = var('nt')   // number of tracks
        eqn = H == nst * (strat * th) + nt * th
        eqn.solve(th)

        [th == H/(nst*strat + nt)]
        */

        var H = flash.Lib.current.stage.stage.stageHeight;
        ntracks = arr.length;
        // this is the height of an anno_track. it's the total height minus the space for the info tracks.
        var th = Std.int((H - ntracks * Gobe.info_track_height) / (nsubtracks * Gobe.sub_track_height_ratio + ntracks));
        var sth = (Gobe.sub_track_height_ratio * th);
        //trace("total:" + H + " th:" + th + " sth:" + sth);
        arr.sort(function(a:TInfo, b:TInfo){ return a.order < b.order ? -1 : 1; });
        Gobe.anno_track_height = Std.int(th);
        Gobe.sub_track_height = Std.int(sth);

        var tracks = new Hash<Track>();
        var k = 0;
        var h = 0;
        for (t in arr){
            var rng = t.bpmax - t.bpmin;
            var start = t.bpmin;
            var end = t.bpmax;
            // extend the limits a bit. unless they were set explicitly.
            if(!explicit_set.exists(t.id)){
                start = Math.round(Math.max(1, Math.round(t.bpmin - rng * 0.05)));
                end = Math.round(t.bpmax + rng * 0.05);
            }
            // the track_height accounts for the anno track and the number of subtracks.
            var track_height = Std.int(th + sth * subtracks_by_track.get(t.id) + Gobe.info_track_height);
            //trace(t.id + ":" + track_height);
            var t = new Track(t.id, t.name, start, end, track_height);
            t.i = k;
            tracks.set(t.id, t);
            t.y = h;
            h += track_height;
            flash.Lib.current.addChildAt(t, 0);
            k += 1;
        }
        Gobe.tracks = tracks;
        for(a in anarr){ a.track = tracks.get(a.track_id); }
        return anarr;
    }

    public static function set_track_info(a:BaseAnnotation, lims:Hash<TInfo>, explicit_set:Hash<Int>):Int{
        var ntracks = 0;
        if(explicit_set.exists(a.track_id)) { return 0; }

        if (! lims.exists(a.track_id)){
            var info = new TInfo(a.track_id, a.track_id, a.bpmin, a.bpmax, ntracks);
            ntracks = 1;
            lims.set(a.track_id, info);
        }
        else {
            var lim = lims.get(a.track_id);
            if(a.bpmin < lim.bpmin){lim.bpmin = a.bpmin; }
            if(a.bpmax > lim.bpmax){lim.bpmax = a.bpmax; }
        }
        return ntracks;
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

    public static function human_readable(n:UInt):String {
        // to hide in-significant digits, we check if can shorten Kb or Mb
        var sn = Std.string(n);
        if (StringTools.endsWith(sn, "000000")) return sn.substr(0, sn.length-6) + "M";
        if (StringTools.endsWith(sn, "000")) return sn.substr(0, sn.length-3) + "K";
        return sn;
    }
    
    public static function autoscale(bp_len:UInt):Int {
        // used by the ruler graphics to determine an array of tick locs in bp
        // the algorithm used here attempts to make the array close to 'optimal' size
        var optimal_ticks:Int = 20;
        var stride:Int = 1;

        // scale `bp_len` to range [0, 100]
        var slen = Std.string(bp_len);
        var tlen = slen.charAt(0);
        if (slen.length > 1) {
            tlen += slen.charAt(1);
        }
        var precision = slen.length - 2; // how many zeros we need to pad?
        var bp_len_scaled = Std.parseInt(tlen);
        
        // stride length 1, 2, 5 -- pick the stride with the number of ticks close to optimal 
        var best_stride = 1;
        var best_tick_diff = optimal_ticks * 1.;
        for (stride in [1, 2, 5]) {
            var tick_diff = Math.abs(bp_len_scaled / stride - optimal_ticks);
            if (tick_diff < best_tick_diff) {
                best_stride = stride;
                best_tick_diff = tick_diff;
            }
        }

        while (precision > 0) {
            best_stride*=10;
            precision-=1;
        }

        return best_stride;
    }

}
