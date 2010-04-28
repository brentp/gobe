import HSP;
import Gobe;

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
        c = StringTools.replace(c, '#', '0x');
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
