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
        /*
        g.lineStyle(0.5, 0.2);
        g.moveTo(off, 0);
        g.lineTo(sw - off, 0);
        */
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
    public var ttf:MTextField;
    public var track:Track;
    public function new(track:Track){
        super();
        this.track = track;
        this.draw();
        this.setUpTitleTextField();
    }

    public function setUpTitleTextField(){
        this.ttf = new MTextField();

        ttf.htmlText   = '<p>' + track.title + '</p>';
        ttf.y      = y + 4;
        ttf.x      = 80;
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


    public function draw() {
        this.draw_ruler();
        var g = this.graphics;
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
        g.lineStyle(1, 0);
        g.moveTo(Track.border_thickness/2, Gobe.info_track_height - Track.border_thickness / 2);
        g.lineTo(flash.Lib.current.stage.stageWidth, Gobe.info_track_height - Track.border_thickness / 2);
    }

    public function draw_ruler(){
        var g = this.graphics;
        var ymid = Track.border_thickness;// + Gobe.info_track_height/2;
        var sw = flash.Lib.current.stage.stageWidth;
        var px_posns = [Track.border_thickness / 2, sw/2, sw - Track.border_thickness];

        var tw = track.bpmax - track.bpmin;
        var bp_posns = [0, Math.round(tw/2), tw];

        var precision = Math.round (Math.log(bp_posns[1] - bp_posns[0]) / 2.30258509) + 1;
        for(i in 0 ... 3){
            var t = new MTextField();
            t.htmlText = (Util.human_readable(bp_posns[i], precision));
            t.y = ymid;
            t.x = px_posns[i];
            t.autoSize         = flash.text.TextFieldAutoSize.LEFT;
            t.opaqueBackground = 0xf2f2f2;
            addChild(t);
            if(i == 2){ t.x -= (t.width + Track.border_thickness); }
            if(i == 0){ t.x += Track.border_thickness; }
            //t.y -= 0.60 * t.height;
        }
    }
}

class AnnoTrack extends SubTrack {
    public var plus:AnnoSubTrack;
    public var minus:AnnoSubTrack;
    public var both:AnnoSubTrack;

    public function new(track:Track, track_height:Float){
        super(track, track, track_height);
        plus  = new AnnoSubTrack(track, track, track_height / 2);
        minus = new AnnoSubTrack(track, track, track_height / 2);
        both = new AnnoSubTrack(track, track, track_height);
        addChild(plus);
        addChild(minus);
        addChild(both);
        both.y = minus.y = track_height / 2;
        //minus.x = 19;
        track.subtracks.set('+', plus);
        track.subtracks.set('-', minus);
        track.subtracks.set('0', both);
        track.addChildAt(this, 0);

    }
    public override function draw(){
        var sw = flash.Lib.current.stage.stageWidth - 1;
        var off = 3;
        var g = this.graphics;
        g.lineStyle(0, 0.0, 0);
        g.beginFill(0, 0.1); // TODO: allow setting track background via css or csv.
        g.moveTo(0, -this.track_height/2);
        g.lineTo(sw, -this.track_height/2);
        g.lineTo(sw, this.track_height/2);
        g.lineTo(0, this.track_height/2);
        g.endFill();

        var mid = 0;
        // the dotted line in the middle.
        g.lineStyle(1, 0x444444, 0.9, false,
                    flash.display.LineScaleMode.NORMAL,
                    flash.display.CapsStyle.ROUND);
        var dash_w = 4;
        var gap_w = 2;
        g.moveTo(gap_w / 2, mid);
        var dx = dash_w;
        while(dx < sw + dash_w) {
            g.lineTo(dx, mid);
            dx += gap_w;
            g.moveTo(dx, mid);
            dx += dash_w;
        }
    }

}

class AnnoSubTrack extends SubTrack {
    public function new(track:Track, other:Track, track_height:Float){
        super(track, other, track_height);
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
    public var info_track:InfoTrack;
    // key is id of other track.
    public var subtracks:Hash<SubTrack>;

    public static var border_thickness:Float = 3.5;
    public static var border_color = 0x333333;

    public  var mouse_down:Bool;
    //public  var ttf:MTextField;

    public function new(id:String, title:String, bpmin:Int, bpmax:Int, track_height:Int){
        super();
        subtracks = new Hash<SubTrack>();
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
