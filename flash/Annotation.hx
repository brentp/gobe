import flash.display.Sprite;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.geom.Point;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.external.ExternalInterface;
import Gobe;
import Track;
import Glyph;

class Edge extends Sprite {
    public var a:Annotation;
    public var b:Annotation;
    public var strength:Float;
    public var i:Int;
    public var drawn:Bool;
    public function new(a:Annotation, b:Annotation, s:Float){
        super();
        this.a = a; this.b = b; this.strength = s;
        this.drawn = false;
        this.addEventListener(MouseEvent.CLICK, onClick);
        this.visible = false;
    }
    public function draw(?force:Bool=false){
        if(this.drawn){
            this.visible = true;
            return;
        }
        var g = this.graphics;
        g.clear();
        var aa = this.a;
        var bb = this.b;
        if(aa.y > bb.y){
            aa = this.b;
            bb = this.a;
        }
        else {

        }
        // TODO use visible.
        if (this.drawn){
            // probably force because they want to draw every edge. but this is
            // already drawn, so leave it.
            this.drawn = force;
            return;
        }
        var ul = aa.localToGlobal(new flash.geom.Point(0, 0));
        var ur = aa.localToGlobal(new flash.geom.Point(aa.pxmax - aa.pxmin, 0));

        var ll = bb.localToGlobal(new flash.geom.Point(0, 0));
        var lr = bb.localToGlobal(new flash.geom.Point(bb.pxmax - bb.pxmin, 0));
        // alternating linestyle is to draw only lines on the y, not along the x
        g.lineStyle(0.0, 0.0);
        g.beginFill(aa.subtrack.fill_color, 0.3);
        g.moveTo(ul.x, ul.y);
        g.lineTo(ur.x, ur.y);
        g.lineStyle(0, aa.subtrack.fill_color);
        g.lineTo(lr.x, lr.y);
        g.lineStyle(0, 0.0);
        g.lineTo(ll.x, ll.y);
        g.lineStyle(0, aa.subtrack.fill_color);
        g.lineTo(ul.x, ul.y);
        g.endFill();
        this.drawn = true;
        this.visible = true;
    }
    public function onClick(e:MouseEvent){
        this.visible = false;
    }
}

// this is the base class for drawable annotations.
class BaseAnnotation extends Sprite {
    public var ftype:String;
    public var is_hsp:Bool;
    public var id:String; // key for anntations hash.
    public var pxmin:Float;
    public var pxmax:Float;
    public var strand:Int; // -1, 0, or 1
    public var bpmin:Int;
    public var bpmax:Int;
    public var style:Style;
    public var track:Track;
    public var subtrack:SubTrack;
    public var track_id:String;
    public var h:Float;
    public var fname:String;

    public function new(l:Array<String>){
        super();
        //#id,track_id,start,end,type,strand,name, [color]

        this.id = l[0];
        this.track_id = l[1];
        this.bpmin = Std.parseInt(l[2]);
        this.bpmax = Std.parseInt(l[3]);
        this.ftype = l[4].toLowerCase();
        this.strand = l[5] == '-' ? -1 : (l[5] == '+' ? 1 : 0);
        this.fname = l.length < 6 ? l[0] : l[6];
        this.addEventListener(Event.ADDED_TO_STAGE, added);
    }
    public function draw(){}
    public inline function set_extents(){
        this.pxmin = track.rw2pix(this.bpmin);
        this.pxmax = track.rw2pix(this.bpmax);
    }
    public function added(e:Event){
        this.set_extents();
        this.draw();
    }
}

class Annotation extends BaseAnnotation {
    public var edges:Array<Int>;
    public var color:UInt;
    // empty_color is just a sentinel to show the color
    // hasn't been set since a uint can't be undefined.
    public static var empty_color:UInt = 0x000001;

    public function new(l:Array<String>){
        super(l);
        this.color = Annotation.empty_color;
        this.edges = new Array<Int>();
        this.is_hsp = this.ftype.substr(0, 3) == "hsp";
        this.addEventListener(MouseEvent.CLICK, onClick);
        // this only happens once its track is set.

        if (l.length > 7){
            //trace('setting color');
            this.color = Util.color_string_to_uint(l[7]);
        }
    }

    public override function draw(){
        this.x = pxmin;
        this.y = -this.subtrack.track_height / 2;
        trace(this + "," + this.y);
        this.h = style.feat_height * this.subtrack.track_height;
        Glyph.draw(this);
    }
    public function onClick(e:MouseEvent){
        var te = this.edges;
        for(i in 0 ... te.length){
            Gobe.edges[te[i]].draw();
        }
        //trace([this.id, this.fname, (this.bpmax + this.bpmin)/ 2, e.stageX, this.track_id].join(","));
        if(! e.shiftKey){
            Gobe.js_onclick(this.id, this.fname, this.ftype, this.bpmin, this.bpmax, this.track_id);
        }
    }
}


class Style {
    public var ftype:String; // *LOWER*case feature type.
    public var glyph:String; // arrow, box, diamond, ...
    public var fill_color:UInt;
    public var fill_alpha:Float;
    public var line_width:Float;
    public var line_color:UInt;
    public var arrow_len:Float;
    public var feat_height:Float; // in pct;
    public var zindex:Int;

    public function new(ftype:String, style_o:Dynamic){
        this.ftype = ftype.toLowerCase();
        this.glyph = style_o.glyph ? style_o.glyph: "generic";
        this.fill_color = Util.color_string_to_uint(style_o.fill_color);
        this.fill_alpha = style_o.fill_alpha ?
                            Std.parseFloat(style_o.fill_alpha) : 1.0;
        this.line_width = style_o.line_width ?
                            Std.parseFloat(style_o.line_width) : 0.1;
        this.line_color = style_o.line_color ?
                            Util.color_string_to_uint(style_o.line_color) : 0xffffff;
        this.feat_height = style_o.height ?
                            Std.parseFloat(style_o.height) : 0.5;
        this.arrow_len = style_o.arrow_len ?
                            Std.parseFloat(style_o.arrow_len) : 0.0;
        this.zindex = style_o.z ? Std.parseInt(style_o.z) : 5;
        //trace(this.toString());
    }
    public function toString(){
        return "Style(" + this.ftype + "," + this.glyph + "," + this.fill_color + "," + this.fill_alpha +")";
    }
}
