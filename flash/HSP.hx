import flash.display.Sprite;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.geom.Point;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.external.ExternalInterface;
import Gobe;

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
class Annotation extends Sprite {
    public var ftype:String;
    public var is_hsp:Bool;
    public var id:String; // key for anntations hash.
    public var pxmin:Float;
    public var pxmax:Float;
    public var strand:Int;
    public var edges:Array<Int>;
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
        //#id,track_id,start,end,type,strand,name

        this.edges = new Array<Int>();
        this.id = l[0];
        this.track_id = l[1];
        this.bpmin = Std.parseInt(l[2]);
        this.bpmax = Std.parseInt(l[3]);
        this.ftype = l[4].toLowerCase();
        this.strand = l.length < 5 || l[5] == "+" ? 1 : -1;
        this.fname = l.length < 6 ? l[0] : l[6];
        this.is_hsp = this.ftype.substr(0, 3) == "hsp";
        this.addEventListener(MouseEvent.CLICK, onClick);
        // this only happens once its track is set.
        this.addEventListener(Event.ADDED_TO_STAGE, set_extents);

    }
    public inline function set_extents(e:Event){
        this.pxmin = track.rw2pix(this.bpmin);
        this.pxmax = track.rw2pix(this.bpmax);
        //trace(this.bpmin + "," + this.bpmax + "=>" + this.pxmin + "," + this.pxmax);
    }

    public function draw(){
        this.x = pxmin;
        var g = this.graphics;
        var is_hsptrack = is_hsp; //Std.is(subtrack, HSPTrack);
        this.y = -this.subtrack.track_height / 2;
        g.clear();
        this.h = style.feat_height * this.subtrack.track_height;
        g.lineStyle(style.line_width, is_hsptrack ? subtrack.fill_color : style.line_color);
        var tw = this.pxmax - this.pxmin;
        var alen = this.style.arrow_len * tw * this.strand;
        var xstart = this.strand == 1 ? 0 : tw;
        var xend = this.strand == 1 ? tw : 0;

        g.moveTo(xstart, h/2);
        //g.beginFill(is_hsptrack ? subtrack.fill_color : style.fill_color, style.fill_alpha);
        var c = is_hsptrack ? subtrack.fill_color : style.fill_color;


        var m = new flash.geom.Matrix();
        m.createGradientBox(tw, h/3, 290, 0, -h/6);
        g.beginGradientFill(flash.display.GradientType.LINEAR,
                         [Util.color_shift(c, -24), Util.color_shift(c, 24)],
                         [style.fill_alpha, style.fill_alpha],
                        [0x00, 0xFF], m);


        g.lineTo(xstart, -h/2);
        g.lineTo(xend - alen, -h/2);
        g.lineTo(xend, 0);
        g.lineTo(xend - alen, h/2);

        g.endFill();
    }
    public function onClick(e:MouseEvent){
        var te = this.edges;
        for(i in 0 ... te.length){
            Gobe.edges[te[i]].draw();
        }
        //trace([this.id, this.fname, (this.bpmax + this.bpmin)/ 2, e.stageX, this.track_id].join(","));
        if(! e.shiftKey){
            Gobe.js_onclick(this.id, this.fname, this.bpmin, this.bpmax, this.track_id);
        }
    }
}


class Style {
    public var ftype:String; // *LOWER*case feature type.
    public var fill_color:UInt;
    public var fill_alpha:Float;
    public var line_width:Float;
    public var line_color:UInt;
    public var arrow_len:Float;
    public var feat_height:Float; // in pct;
    public var zindex:Int;

    public function new(ftype:String, style_o:Dynamic){
        this.ftype = ftype.toLowerCase();
        this.fill_color = Util.color_string_to_uint(style_o.fill_color);
        this.fill_alpha = style_o.fill_alpha ?
                            Std.parseFloat(style_o.fill_alpha) : 1.0;
        this.line_width = style_o.line_width ?
                            Std.parseFloat(style_o.line_width) : 0.1;
        this.line_color = style_o.line_color ?
                            Util.color_string_to_uint(style_o.line_color) : 0x000000;
        this.feat_height = style_o.height ?
                            Std.parseFloat(style_o.height) : 0.5;
        this.arrow_len = style_o.arrow_len ?
                            Std.parseFloat(style_o.arrow_len) : 0.0;
        this.zindex = style_o.z ? Std.parseInt(style_o.z) : 5;
    }
    public function toString(){
        return "Style(" + this.ftype + "," + this.fill_color + "," + this.fill_alpha +")";
    }
}

class SubTrack extends Sprite {
    public var track:Track;
    public var fill_color:UInt;
    public var other:Track;
    public var track_height:Float;
    /// other is a pointer to the other track which shares
    /// pairs with this one.
    public function new(track:Track, other:Track, track_height:Float){
        super();
        this.track = track;
        this.other = other;
        this.track_height = track_height;
        this.draw();
        this.addEventListener(MouseEvent.CLICK, onClick);
        this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

    }
    public function clear(){
        var i = this.numChildren;
        while(i-- > 0){
            this.removeChildAt(i);
        }
    }
    public function onClick(e:MouseEvent){
        if(e.shiftKey){
            for(i in 0 ... this.numChildren){
                if (!Std.is(this.getChildAt(i), Annotation)) { continue; }
                var a = cast(this.getChildAt(i), Annotation);
                a.onClick(e);
            }
        }
        else if(e.ctrlKey){
            trace('ctrl');
        }
    }

    public function onMouseOut(e:MouseEvent){
        if(!e.ctrlKey){ return; }
        for(i in 0 ... this.numChildren){
            var a = cast(this.getChildAt(i), Annotation);
            for (ed in a.edges){
                Gobe.edges[ed].visible = false;
            }
        }
    }
    public function onMouseOver(e:MouseEvent){
        if (! e.ctrlKey ){ return; }
        trace('clicking');
        e.shiftKey = true;
        onClick(e);
    }

    public function draw(){
        var sw = flash.Lib.current.stage.stageWidth - 1;
        var off = 3;
        var g = this.graphics;
        g.lineStyle(0.5, 0.2);
        g.moveTo(off, 0);
        g.lineTo(sw - off, 0);
        g.lineStyle(0, 0.0, 0);
        if(this.track == this.other){
            g.beginFill(0, 0.1);
        }
        else { g.beginFill(0, 0); }
        g.moveTo(0, -this.track_height);
        g.lineTo(sw, -this.track_height);
        g.lineTo(sw, 0);
        g.lineTo(0, 0);
        g.endFill();

    }

}

class AnnoTrack extends SubTrack {
    public function new(track:Track, other:Track, track_height:Float){
        super(track, other, track_height);
    }
}

class HSPTrack extends SubTrack {
    public  var ttf:MTextField;

    public function new(track:Track, other:Track, track_height:Float){
        super(track, other, track_height);
        this.setUpTextField();
    }
    public function setUpTextField(){
        this.ttf = new MTextField();

        ttf.htmlText   = '<p>' + other.title + '</p>';
        ttf.multiline = true;

        ttf.border = false;
        ttf.borderColor      = 0xcccccc;
        //ttf.opaqueBackground = 0xf4f4f4;
        ttf.autoSize         = flash.text.TextFieldAutoSize.LEFT;
        this.addChildAt(ttf, this.numChildren);
        ttf.styleSheet.setStyle('p', {fontSize: Gobe.fontSize - 2, display: 'inline', fontColor: '0xcccccc',
                                    fontFamily: '_sans'});
        ttf.x      = flash.Lib.current.stage.stageWidth - ttf.width - 10;
        ttf.y      = -track_height; // - ttf.height;
    }
}

class Track extends Sprite {

    public  var title:String;
    public  var id:String;
    public  var i:Int; // index.
    public  var bpmin:Int;
    public  var bpmax:Int;
    public  var bpp:Float;
    public var track_height:Int;
    // key is id of other track.
    public var subtracks:Hash<SubTrack>;

    public  var mouse_down:Bool;
    public  var ttf:MTextField;

    public function new(id:String, title:String, bpmin:Int, bpmax:Int, track_height:Int){
        super();
        subtracks = new Hash<SubTrack>();
        this.id = id;
        this.title = title;
        this.track_height = track_height;
        this.bpmin = bpmin;
        this.bpmax = bpmax;
        this.mouse_down = false;
        this.setUpTextField();
        this.set_bpp();
        this.draw();
        //trace("bpmin-bpmax(rng):" + bpmin +"-" + bpmax + "(" + (bpmax - bpmin) + "), bpp:" + this.bpp);
    }
    public inline function set_bpp(){
        this.bpp = (bpmax - bpmin)/(1.0 * flash.Lib.current.stage.stageWidth);
    }
    public function clear(){
        this.graphics.clear();
        for(st in this.subtracks.iterator()){
            this.removeChild(st);
        }
        var i = this.numChildren;
        while(i-- > 0){
            this.removeChildAt(i);
        }
        this.subtracks = new Hash<SubTrack>();
    }
    public function draw(){
        var g = this.graphics;
        var mid = track_height/2;
        g.clear();
        var sw = flash.Lib.current.stage.stageWidth - 1;
        g.lineStyle(3.5, 0.6);
        // the border around this track.
        g.drawRoundRect(1, 1, sw - 2, track_height - 2, 22);

        // the dotted line in the middle.
        g.lineStyle(1, 0x444444, 0.9, false,
                    flash.display.LineScaleMode.NORMAL,
                    flash.display.CapsStyle.ROUND);
        var dash_w = 20;
        var gap_w = 10;
        g.moveTo(gap_w / 2, mid);
        var dx = dash_w;
        while(dx < sw + dash_w) {
            g.lineTo(dx, mid);
            dx += gap_w;
            g.moveTo(dx, mid);
            dx += dash_w;
        }
        this.draw_ruler();
    }
    public function draw_ruler(){
        var g = this.graphics;
        var mid = track_height/2;
        var sw = flash.Lib.current.stage.stageWidth - 1;
        var px_posns = [0, sw/2, sw];
        var bp_posns = [this.bpmin, Math.round((this.bpmin + this.bpmax)/2), this.bpmax];
        for(i in 0 ... 3){
            var t = new MTextField();
            t.htmlText = (bp_posns[i] + "");
            t.y = mid;
            t.x = px_posns[i];
            t.autoSize         = flash.text.TextFieldAutoSize.LEFT;
            t.opaqueBackground = 0xf2f2f2;
            addChild(t);
            if(i == 2){ t.x -= (t.width + 4); }
            if(i == 0){ t.x += 4; }
            t.y -= 0.60 * t.height;
        }
    }

    public inline function rw2pix(bp:Int){
        return (bp - this.bpmin) / this.bpp;
    }

    public function setUpTextField(){
        this.ttf = new MTextField();

        ttf.htmlText   = '<p>' + this.title + '</p>';
        ttf.y      = y + 3;
        ttf.x      = 5;
        ttf.multiline = true;

        ttf.border = true;
        ttf.borderColor      = 0xcccccc;
        ttf.opaqueBackground = 0xf4f4f4;
        ttf.autoSize         = flash.text.TextFieldAutoSize.LEFT;
        ttf.styleSheet.setStyle('p', {fontSize: Gobe.fontSize, display: 'inline',
                                    fontFamily: '_sans'});

        this.addChild(ttf);
        ttf.styleSheet.setStyle('p', {fontSize: Gobe.fontSize, display: 'inline',
                                    fontFamily: '_sans'});
    }
}
