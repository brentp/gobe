import flash.external.ExternalInterface;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Loader;
import flash.display.StageScaleMode;
import flash.display.StageAlign;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.system.LoaderContext;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.StyleSheet;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.events.IOErrorEvent;
import Util;
import HSP;


class Gobe extends Sprite {

    public static var fontSize:Int = 12;

    public static  var ctx = new LoaderContext(true);

    private var track:String;
    public var cnss:Array<Int>;
    public var stage_height:Int;
    public var stage_width:Float;

    public var wedge_alpha:Float;

    public var drag_sprite:DragSprite;

    public var panel:Sprite; // holds the lines.
    public var feature_stylesheet:StyleSheet; // how to draw stuff..

    private var _all:Bool;
    public var tracks:Hash<Track>;
    public var annotations:Hash<Annotation>;
    public var styles:Hash<Style>; // {'CDS': CDSINFO }
    public static var edges = new Array<Edge>();

    public var annotations_url:String;
    public var edges_url:String;
    public var tracks_url:String;

    public function clearPanelGraphics(e:MouseEvent){
        while(panel.numChildren != 0){ panel.removeChildAt(0); }
    }
    public static function js_onclick(fid:String, fname:String, px:Float, x:Float, track_id:String){
        ExternalInterface.call('Gobe.onclick', fid, fname, px, x, track_id);
    }
    public static function js_warn(warning:String){
        ExternalInterface.call('Gobe.warn', warning);
    }
    public static function js_onmouseover(fid:String, fname:String, px:Float, x:Float, track_id:String){
        ExternalInterface.call('Gobe.onmouseover', fid, fname, px, x, track_id);
    }

    public static function main(){
        haxe.Firebug.redirectTraces();
        var stage = flash.Lib.current.stage;
        stage.align     = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.addChild( new Gobe());
    }
    private function add_callbacks(){
        ExternalInterface.addCallback("clear_wedges", clear_wedges);
    }

    public function clear_wedges(){
        for(w in edges){ w.visible = false; }
    }
    public function onMouseWheel(e:MouseEvent){
        var change = e.delta > 0 ? 1 : - 1;
        this.wedge_alpha += (change / 10.0);
        if(this.wedge_alpha > 1){ this.wedge_alpha = 1.0; }
        if(this.wedge_alpha < 0.1){ this.wedge_alpha = 0.1; }
    }
    public function onMouseMove(e:MouseEvent){
        var x = e.localX;
        var tid = this.tracks.keys().next();
        var t = tracks.get(tid);
        trace(x);
    }


    public function new(){
        super();
        var p = flash.Lib.current.loaderInfo.parameters;

        this.drag_sprite = new DragSprite();
        this.wedge_alpha = 0.3;
        this.annotations_url = p.annotations;
        this.edges_url = p.edges;
        this.tracks_url = p.tracks;

        panel = new Sprite(); 
        addChild(panel);
        addChild(this.drag_sprite);
        this.add_callbacks();
        var i:Int;

        // the event only gets called when mousing over an HSP.
        addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

        // this one the event gets called anywhere.
        flash.Lib.current.stage.focus = flash.Lib.current.stage.stage;
        //flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyPress);
        this.stage_width = flash.Lib.current.stage.stage.stageWidth;
        this.stage_height = flash.Lib.current.stage.stage.stageHeight;
        geturl(p.style, styleReturn);


    }
    public function styleReturn(e:Event) {
        feature_stylesheet = new StyleSheet();
        feature_stylesheet.parseCSS(e.target.data);
        styles = new Hash<Style>();
        for(ftype in feature_stylesheet.styleNames){
            ftype = ftype.toLowerCase();
            var st = feature_stylesheet.getStyle(ftype);
            styles.set(ftype, new Style(ftype, st));
        }
        this.geturl(this.tracks_url, trackReturn); //
    }

    public function onKeyPress(e:KeyboardEvent){
        if(e.keyCode == 38 || e.keyCode == 40){ // up
            if(e.keyCode == 38 && Gobe.fontSize > 25){ return; }
            if(e.keyCode == 40 && Gobe.fontSize < 8){ return; }
            Gobe.fontSize += (e.keyCode == 38 ? 1 : - 1);
            for(k in tracks.keys()){
                tracks.get(k).ttf.styleSheet.setStyle('p', {fontSize:Gobe.fontSize});
            }
        }
    }
    public function geturl(url:String, handler:Event -> Void){
        trace("getting:" + url);
        var ul = new URLLoader();
        ul.load(new URLRequest(url));
        ul.addEventListener(Event.COMPLETE, handler);
        ul.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event){
Gobe.js_warn("failed to get:" + url + "\n" + e); });
    }

    public function edgeReturn(e:Event){
        var lines:Array<String> = StringTools.ltrim(e.target.data).split("\n");
        // for each track, keep track of the other tracks it maps to.
        var edge_tracks = new Hash<Hash<Int>>();
        for(line in lines){
            if(line.charAt(0) == "#" || line.length == 0) { continue; }
            var edge = Util.add_edge_line(line, annotations);
            if (edge == null){ continue; }

            // so here we tabulate all the unique track pairs...
            var aid = edge.a.track.id;
            var bid = edge.b.track.id;

            // for each edge, need to see the annos.tracks it's associated with...
            if(! edge_tracks.exists(aid)) { edge_tracks.set(aid, new Hash<Int>()); }
            if(! edge_tracks.exists(bid)) { edge_tracks.set(bid, new Hash<Int>()); }
            edge_tracks.get(bid).set(aid, 1);
            edge_tracks.get(aid).set(bid, 1);
        }
        initializeSubTracks(edge_tracks);
        addAnnotations();
    }
    private function initializeSubTracks(edge_tracks:Hash<Hash<Int>>){
        // so here, it knows all the annotations and edges, so we figure out
        // the subtracks it needs to show the relationships.
        var atrack_ids:Array<String> = Util.sorted_keys(edge_tracks.keys());
        var colors = new Hash<UInt>();
        for(aid in atrack_ids){
            var btrack_ids = Util.sorted_keys(edge_tracks.get(aid).keys());
            var ntracks = btrack_ids.length;
            var atrack = tracks.get(aid);

            var i = 1;
            // the height used per HSP row.
            var sub_height = 0.95 * atrack.track_height / (2 * (ntracks + 1));
            var remaining = atrack.track_height - (sub_height * 2 * ntracks);
            //trace(sub_height + ", " +  remaining + ", " + remaining / 2);
            for(bid in btrack_ids){
                var color_key = aid < bid ? aid + "|" + bid : bid + "|" + aid;
                var track_color = Util.next_track_color(aid, bid, colors);
                var btrack = tracks.get(bid);
                for(strand in ['+', '-']){

                    var sub = new HSPTrack(atrack, btrack, sub_height);
                    //sub.fill_color = Util.track_colors[btrack.i];
                    sub.fill_color = track_color;
                    atrack.subtracks.set(strand + bid, sub);
                    atrack.addChildAt(sub, 0);
                    if (strand == '+'){
                        // start from top, goes to middle
                        sub.y = i * sub_height;
                    }
                    else {
                        // start from bottom, goes to middle
                        sub.y = atrack.track_height - (ntracks - i) * sub_height;
                    }
                    sub.draw();
                }
                i += 1;
            }
            // now initialize the tracks for +/- annotations.
            i -= 1;
            var plus  = new AnnoTrack(atrack, atrack, remaining/2);
            var minus = new AnnoTrack(atrack, atrack, remaining/2);
            plus.y = i * sub_height + remaining / 2;
            minus.y = plus.y + remaining/ 2;
            //minus.y = atrack.track_height - (ntracks - i) * sub_height - remaining/2;
            //trace(plus.y);
            atrack.subtracks.set('+', plus);
            atrack.subtracks.set('-', minus);
            atrack.addChildAt(plus, 0);
            atrack.addChildAt(minus, 0);
        }
    }
    private function addAnnotations(){
        var arr = new Array<Annotation>();
        var a:Annotation;
        for(a in annotations.iterator()){ arr.push(a); }
        arr.sort(function(a:Annotation, b:Annotation):Int {
            return a.style.zindex < b.style.zindex ? -1 : 1;
        });
        for(a in arr){
            if(a.ftype != "hsp"){
                var sub = a.track.subtracks.get(a.strand == 1 ? '+' : '-');
                a.subtrack = sub;
                sub.addChild(a);
            }
            else {
                // loop over the pairs and add to appropriate subtrack based on the id of other.
                for(edge_id in a.edges){
                    var edge = edges[edge_id];
                    var other:Annotation = edge.a == a ? edge.b : edge.a;
                    var strand = other.strand == 1 ? '+' : '-';
                    var sub = a.track.subtracks.get(strand + other.track.id);
                    a.subtrack = sub;
                    sub.addChild(a);
                }
            }
            a.draw();
        }
    }

    public function annotationReturn(e:Event){
        annotations = new Hash<Annotation>();
        var anno_lines:Array<String> = StringTools.ltrim(e.target.data).split("\n");
        for(line in anno_lines){
            if(line.charAt(0) == "#" || line.length == 0){ continue;}
            var a = new Annotation(line, tracks);
            a.style = styles.get(a.ftype);
            if(annotations.exists(a.id)) {
                Gobe.js_warn(a.id + " is not a unique annotation id. overwriting");
            }
            annotations.set(a.id, a);
        }
        geturl(this.edges_url, edgeReturn);

    }

    public function trackReturn(e:Event){
        // called by style return.
        this.geturl(this.annotations_url, annotationReturn);
        tracks = new Hash<Track>();
        var lines:Array<String> = e.target.data.split("\n");
        var ntracks = 0;
        for(line in lines){ if (line.charAt(0) != "#" && line.length != 0){ ntracks += 1; }}
        var track_height = Std.int(this.stage_height / ntracks);
        var k = 0;
        for(line in lines){
            if(line.charAt(0) == "#" || line.length == 0){ continue; }
            var t = new Track(line, track_height);
            t.i = k;
            tracks.set(t.id, t);
            t.y = k * track_height;
            flash.Lib.current.addChildAt(t, 0);
            k += 1;
        }
    }

}

class MTextField extends TextField {
    public function new(){
        super();
        this.styleSheet = new StyleSheet();
    }
}

// this makes the gray selection triangle.
class DragSprite extends Sprite {
    public var startx:Float;
    public var starty:Float;
    public function new(){
        super();
    }
    public function do_draw(eX:Float, eY:Float){
        this.graphics.clear();
        this.graphics.lineStyle(1, 0xcccccc);
        var xmin = Math.min(this.startx, eX);
        var xmax = Math.max(this.startx, eX);
        var ymin = Math.min(this.starty, eY);
        var ymax = Math.max(this.starty, eY);

        this.graphics.beginFill(0xcccccc, 0.2);
        this.graphics.drawRect(xmin, ymin, xmax - xmin, ymax - ymin);
        this.graphics.endFill();
    }
}


class GEvent extends Event {
    public static var LOADED = "LOADED";
    //public static var ALL_LOADED = "ALL_LOADED";
    public function new(type:String){
        super(type);
    }
}

