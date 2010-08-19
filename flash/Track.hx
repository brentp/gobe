import flash.display.Sprite;
import flash.events.MouseEvent;
import Gobe;

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

    public override function toString(){
        var s = "SubTrack(" + this.track.title;
        if(this.track != this.other){
            s += ", " + this.other.title;
        }
        return s + ")";
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

        g.lineStyle(0, 0, 0.0);
        g.beginFill(0, 0); // TODO: allow setting track background via css or csv.
        g.moveTo(0, -this.track_height);
        g.lineTo(sw, -this.track_height);
        g.lineTo(sw, 0);
        g.lineTo(0, 0);
        g.endFill();
    }

}

class InfoTrack extends Sprite {
    public var track:Track;
    public function new(track:Track){
        super();
        this.track = track;
        this.draw();
    }

    public function draw() {
        this.draw_ruler();
        var g = this.graphics;
        var height = Options.info_track_height;
        var border = Track.border_thickness / 2;
        /*
        g.moveTo(0, 0);
        g.beginFill(0, 0.1); 
        var sw = flash.Lib.current.stage.stageWidth;
        g.lineTo(sw, 0);
        g.lineTo(sw, Gobe.info_track_height);
        g.lineTo(0, Gobe.info_track_height);
        g.lineTo(0, 0);
        g.endFill();
        */
        g.lineStyle(border, 0);
        g.moveTo(border, height - border);
        g.lineTo(flash.Lib.current.stage.stageWidth, height - border);
    }

    public function draw_ruler(){
        var g = this.graphics;
        var ymid = Track.border_thickness;

        var height = Options.info_track_height / 2;
        var border = Track.border_thickness / 2;
        var sw = flash.Lib.current.stage.stageWidth;
        var tw = track.bpmax - track.bpmin;
        var baseline_lw = 2;
        var major_tick_lw = 2;
        var minor_tick_lw = 1;

        // baseline
        g.lineStyle(baseline_lw, 0x0000ff, .2);
        g.moveTo(border, height - border);
        g.lineTo(flash.Lib.current.stage.stageWidth, height - border);

        var stride = Util.autoscale(tw);
        // major ticks
        var xpos = stride;
        var xpos_px:Float;
        while (xpos < tw) {
            xpos_px = border + xpos * (sw - 2*border) / tw; 
            g.lineStyle(major_tick_lw, 0x0000ff);
            g.moveTo(xpos_px, .4*height);
            g.lineTo(xpos_px, 1.4*height);
            // tick labels
            var t = new MTextField();
            t.htmlText = (Util.human_readable(xpos));
            t.y = ymid;
            t.x = xpos_px;
            t.autoSize = flash.text.TextFieldAutoSize.LEFT;
            addChild(t);

            xpos += stride;
        }

        // minor ticks
    }
}

class AnnoTrack extends SubTrack {
    public var plus:AnnoSubTrack;
    public var minus:AnnoSubTrack;
    public var both:AnnoSubTrack;
    public var ttf:MTextField;
    public var subanno_id:String;

    public function new(track:Track, track_height:Float, subanno_id:String=""){
        super(track, track, track_height);
        track.anno_track = this;
        this.subanno_id = subanno_id;
        plus  = new AnnoSubTrack(track, track_height / 2);
        minus = new AnnoSubTrack(track, track_height / 2);
        both = new AnnoSubTrack(track,  track_height);
        addChild(both);
        addChild(plus);
        addChild(minus);
        both.y = minus.y = track_height / 2;
        //minus.x = 19;
        track.subtracks.set(subanno_id + '+', plus);
        track.subtracks.set(subanno_id + '-', minus);
        track.subtracks.set(subanno_id + '0', both);
        track.addChildAt(this, 0);
        if (subanno_id == ""){
            this.setUpTitleTextField();
        }
    }

    public function setUpTitleTextField(){
        this.ttf = new MTextField();

        ttf.y      = -both.y;
        ttf.x      = 6;

        ttf.border = true;
        ttf.borderColor      = 0xcccccc;
        ttf.opaqueBackground = 0xf4f4f4;
        ttf.autoSize         = flash.text.TextFieldAutoSize.LEFT;
        ttf.styleSheet.setStyle('p', {fontSize: Gobe.fontSize, display: 'inline',
                                    fontFamily: 'Arial,serif,sans-serif'});
        ttf.htmlText   = '<p>' + track.title + '</p>';

        this.addChild(ttf);
    }

    public override function draw(){
        var sw = flash.Lib.current.stage.stageWidth - Track.border_thickness - 1;
        var off = 3;
        var g = this.graphics;
        // the lines around the sub-anno tracks.
        g.lineStyle(0.9, 0xffffff, 1);
        g.beginFill(Options.anno_track_background_color); // TODO: allow setting track background via css or csv.
        g.moveTo(Track.border_thickness, -this.track_height/2);
        g.lineTo(sw, -this.track_height/2);
        g.lineTo(sw, this.track_height/2);
        g.lineTo(Track.border_thickness, this.track_height/2);
        g.endFill();

        var mid = 0;
        // the dotted line in the middle.
        g.lineStyle(1, 0x444444, 0.9, false,
                    flash.display.LineScaleMode.NORMAL,
                    flash.display.CapsStyle.ROUND);
        var dash_w:Float = 4;
        var gap_w:Float = 3.5;
        g.moveTo(gap_w / 2, mid);
        var dx = dash_w;
        while(dx < sw + dash_w) {
            g.lineTo(dx, mid);
            dx += gap_w;
            g.moveTo(dx, mid);
            dx += dash_w;
        }
    }
    public override function onClick(e:MouseEvent){
        /* since events dont get propagated to the both subtrack, here we
        do it manually, checking if each feature in the both subtrack contains
        the click.
        */
        super.onClick(e);
        var n:Int = both.numChildren;
        var i:Int;
        for(i in 0 ... n){
            var a_sprite = both.getChildAt(i);
            if(a_sprite.hitTestPoint(e.stageX, e.stageY)){
                cast(a_sprite, Annotation).onClick(e);
            }
        }
    }

}

class AnnoSubTrack extends SubTrack {
    public function new(track:Track, track_height:Float){
        super(track, track, track_height);
    }
}

class HSPTrack extends SubTrack {
    public var ttf:MTextField;
    public function new(track:Track, other:Track, track_height:Float){
        super(track, other, track_height);
        this.setUpTextField();
    }
    public function setUpTextField(){
        this.ttf = new MTextField();

        ttf.multiline = true;

        ttf.border = false;
        ttf.borderColor      = 0xcccccc;
        //ttf.opaqueBackground = 0xf4f4f4;
        ttf.autoSize         = flash.text.TextFieldAutoSize.LEFT;
        this.addChildAt(ttf, this.numChildren);
        ttf.styleSheet.setStyle('p', {fontSize: Gobe.fontSize - 1, display: 'inline', fontColor: '0xcccccc',
                                    fontFamily: 'arial,sans-serif'});
        ttf.y      = -track_height; // - ttf.height;
        ttf.htmlText   = '<p>' + other.title + '</p>';
        ttf.x      = flash.Lib.current.stage.stageWidth - ttf.width - 10;
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
    public var info_track:InfoTrack;
    public var anno_track:AnnoTrack;
    public var extra_anno_tracks:Array<AnnoTrack>;
    public var extra_anno_track_ids:Array<String>;
    // key is id of other track.
    public var subtracks:Hash<SubTrack>;

    public static var border_thickness:Float = 3.5;
    public static var border_color = 0x333333;

    public  var mouse_down:Bool;
    //public  var ttf:MTextField;
    public override function toString(){
        return "Track(" + this.id + ", " + this.title + ")";
    }

    public function new(id:String, title:String, bpmin:Int, bpmax:Int, track_height:Int){
        super();
        subtracks = new Hash<SubTrack>();
        extra_anno_tracks = new Array<AnnoTrack>();
        extra_anno_track_ids = new Array<String>();
        this.id = id;
        this.title = title;
        this.track_height = track_height;
        this.bpmin = bpmin;
        this.bpmax = bpmax;
        this.mouse_down = false;
        this.set_bpp();
        this.add_info_track();
        this.draw();
        //trace("bpmin-bpmax(rng):" + bpmin +"-" + bpmax + "(" + (bpmax - bpmin) + "), bpp:" + this.bpp);
    }
    public inline function set_bpp(){
        this.bpp = (bpmax - bpmin)/(flash.Lib.current.stage.stageWidth - Track.border_thickness);
    }

    private function add_info_track(){
        this.info_track = new InfoTrack(this);
        this.addChild(info_track);
        info_track.y = Track.border_thickness / 2;
    }

    public function clear(){
        this.graphics.clear();
        for(st in this.subtracks.iterator()){
            if(Type.getClass(st) == AnnoSubTrack){ continue; }
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
        var sw = flash.Lib.current.stage.stageWidth;
        g.lineStyle(Track.border_thickness, Track.border_color);
        // the border around this track.
        g.drawRoundRect(Track.border_thickness/2, Track.border_thickness/2, sw - Track.border_thickness, track_height, 22);
    }

    public inline function rw2pix(bp:Int){
        return ((bp - this.bpmin) / this.bpp) + Track.border_thickness;
    }

}
