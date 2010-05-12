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
import Plot;


class Gobe extends Sprite {

    public static var fontSize:Int = 12;

    public static  var ctx = new LoaderContext(true);

    private var track:String;
    public var cnss:Array<Int>;
    public var stage_height:Int;
    public var stage_width:Float;

    public var wedge_alpha:Float;

    public var drag_sprite:DragSprite;
    public static var zi : flash.ui.ContextMenuItem;

    public var panel:Sprite; // holds the lines.
    public var feature_stylesheet:StyleSheet; // how to draw stuff..

    private var _all:Bool;
    public static var tracks:Hash<Track>;
    public var annotations:Hash<Annotation>;
    public static var plots:Hash<Plot>;
    public static var styles:Hash<Style>; // {'CDS': CDSINFO }
    public static var edges = new Array<Edge>();

    public var annotations_url:String;
    public var style_url:String;

    public function clearPanelGraphics(e:MouseEvent){
        while(panel.numChildren != 0){ panel.removeChildAt(0); }
    }
    public static function js_onclick(fid:String, fname:String, bpmin:Int, bpmax:Int, track_id:String){
        ExternalInterface.call('Gobe.onclick', fid, fname, bpmin, bpmax, track_id);
    }
    public static function js_warn(warning:String){
        ExternalInterface.call('Gobe.warn', warning);
    }
    public static function js_onmouseover(fid:String, fname:String, bpmin:Int, bpmax:Int, track_id:String){
        ExternalInterface.call('Gobe.onmouseover', fid, fname, bpmin, bpmax, track_id);
    }

    public static function main(){
        haxe.Firebug.redirectTraces();
        var stage = flash.Lib.current.stage;
        // this one the event gets called anywhere.
        stage.focus = stage.stage;
        stage.align     = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.addChild(new Gobe());
    }
    private function add_callbacks(){
        ExternalInterface.addCallback("set_hsp_colors", Util.set_hsp_colors);
        ExternalInterface.addCallback("redraw", redraw);
        ExternalInterface.addCallback("clear_wedges", clear_wedges);
        ExternalInterface.addCallback("set_data", set_data);
        ExternalInterface.addCallback("set_url", set_url);
    }
    public function reset(){
        for(a in annotations.iterator()){ a.graphics.clear(); }
        // and remove edges.
        for(e in edges){ flash.Lib.current.removeChild(e); /*e.graphics.clear();*/ }
        for(t in tracks.iterator()){ t.clear(); }
        edges = new Array<Edge>();
        tracks = new Hash<Track>();
        annotations = new Hash<Annotation>();
        plots = new Hash<Plot>();
    }
    public function set_data(data:String){
        this.handleAnnotationData(data);
    }
    public function set_url(url:String){
        this.annotations_url = url;
        geturl(url, annotationReturn);
    }

    public function clear_wedges(){
        for(w in edges){ w.visible = false; }
    }
    public function redraw(){
        for(w in edges){ w.drawn = false; w.graphics.clear(); }
        for(a in annotations) { a.draw(); }

    }
    public function onMouseWheel(e:MouseEvent){
        var change = e.delta > 0 ? 1 : - 1;
        this.wedge_alpha += (change / 10.0);
        if(this.wedge_alpha > 1){ this.wedge_alpha = 1.0; }
        if(this.wedge_alpha < 0.1){ this.wedge_alpha = 0.1; }
    }
    public function onMouseMove(e:MouseEvent){
        var x = e.localX;
        var tid = tracks.keys().next();
        var t = tracks.get(tid);
        trace(x);
    }

    public function new(){
        super();
        var p = flash.Lib.current.loaderInfo.parameters;

        this.drag_sprite = new DragSprite();
        this.wedge_alpha = 0.3;
        this.annotations_url = p.annotations;
        this.style_url = p.style;

        panel = new Sprite();
        addChild(panel);
        addChild(this.drag_sprite);
        this.add_callbacks();
        var i:Int;
        tracks = new Hash<Track>();
        annotations = new Hash<Annotation>();
        plots = new Hash<Plot>();

        // the event only gets called when mousing over an HSP.
        var stage = flash.Lib.current.stage;
        addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

        stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyPress);
        this.stage_width = flash.Lib.current.stage.stage.stageWidth;
        this.stage_height = flash.Lib.current.stage.stage.stageHeight;
        geturl(this.style_url, styleReturn);
        /*
        var cm = new flash.ui.ContextMenu();
        cm.hideBuiltInItems();
        zi = new flash.ui.ContextMenuItem("Zoom In", true, true, true);
        zi.addEventListener(flash.events.ContextMenuEvent.MENU_ITEM_SELECT, function (e:Event){
            trace('selected');
        }, false, 0, true);
        cm.customItems = [zi];
        trace(cm.customItems);
        flash.Lib.current.contextMenu = cm;
        */

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
        if(StringTools.startsWith(this.annotations_url, "javascript:")){
            // getting the data directly from javascript call..
            var jsfn = this.annotations_url.substr(9);
            var data = ExternalInterface.call(jsfn);
            handleAnnotationData(data);
        }
        else {
            geturl(this.annotations_url, annotationReturn);
        }
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
    public static function geturl(url:String, handler:Event -> Void){
        url = StringTools.urlDecode(url);
        trace("getting:" + url);
        var ul = new URLLoader();
        ul.load(new URLRequest(url));
        ul.addEventListener(Event.COMPLETE, handler);
        ul.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event){
            Gobe.js_warn("failed to get:" + url + "\n" + e);
        });
    }

    private function updateEdgeTracks(a:Annotation, b:Annotation, strength:Float, edge_tracks:Hash<Hash<Int>>){
        // used in addAnnotation to add annos to edge_tracsk whic
       // keeps track of unique track pairs.
            var edge = Util.add_edge_line(a, b, strength);
            if (edge == null){ return; }

            // so here we tabulate all the unique track pairs...
            var aid = edge.a.track.id;
            var bid = edge.b.track.id;

            // for each edge, need to see the annos.tracks it's associated with...
            if(! edge_tracks.exists(aid)) { edge_tracks.set(aid, new Hash<Int>()); }
            if(! edge_tracks.exists(bid)) { edge_tracks.set(bid, new Hash<Int>()); }
            edge_tracks.get(bid).set(aid, 1);
            edge_tracks.get(aid).set(bid, 1);

    }
    private function initializeSubTracks(edge_tracks:Hash<Hash<Int>>){
        // so here, it knows all the annotations and edges, so we figure out
        // the subtracks it needs to show the relationships.
        var atrack_ids = Util.sorted_keys(tracks.keys());
        var colors = new Hash<UInt>();
        for(aid in atrack_ids){
            var atrack = tracks.get(aid);
            var i = 1;
            var ex = edge_tracks.exists(aid);
            var btrack_ids = ex ?
                    Util.sorted_keys(edge_tracks.get(aid).keys()) : [];
            var ntracks = btrack_ids.length;

            // the height used per HSP row.
            var sub_height = 0.95 * atrack.track_height / (2 * (ntracks + 1));
            var remaining = atrack.track_height - (sub_height * 2 * ntracks);
            for(bid in btrack_ids){
                var color_key = aid < bid ? aid + "|" + bid : bid + "|" + aid;
                // TODO: allow getting this from css.
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
            atrack.subtracks.set('+', plus);
            atrack.subtracks.set('-', minus);
            atrack.addChildAt(plus, 0);
            atrack.addChildAt(minus, 0);
        }
    }

    private function addAnnotations(arr:Array<Annotation>){
        var a:Annotation;
        arr.sort(function(a:Annotation, b:Annotation):Int {
            return a.style.zindex < b.style.zindex ? -1 : 1;
        });
        for(a in arr){
            if(! a.is_hsp){
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
        }
    }
    public function annotationReturn(e:Event){
        handleAnnotationData(e.target.data);
    }
    public function handleAnnotationData(data:String){
        var t = haxe.Timer.stamp();
        var lines:Array<String> = StringTools.ltrim(data).split("\n");
        if(!Lambda.empty(annotations)){ this.reset(); }
        var anno_lines:Array<Array<String>> = [];
        for(l in lines){ if (!(l.length == 0 || l.charAt(0) == "#")) { anno_lines.push(l.split(",")); } }
        var hsps = new Array<Annotation>();
        var edge_tracks = new Hash<Hash<Int>>();

        // first get the tracks either implicitly or from feature type == track.
        var t0 = haxe.Timer.stamp();
        trace("seconds to split:" + (t0 - t));
        var anarr = Util.add_tracks_from_annos(anno_lines);
        var t1 = haxe.Timer.stamp();
        trace("seconds to parse:" + (t1 - t0));

        for(a in anarr){
            var astyle = styles.get(a.ftype);
            if (astyle == null && a.is_hsp){
                astyle = styles.get('hsp');
            }
            if(astyle == null){
                Gobe.js_warn("no style defined for:" + a.ftype);
                a.style = styles.get('cds');
            }
            else {
                a.style = astyle;
            }
            if(annotations.exists(a.id)) {
                Gobe.js_warn(a.id + " is not a unique annotation id. overwriting");
            }
            annotations.set(a.id, a);
            // we set the edges implicitly based on consecutive hsps.
            if(a.is_hsp){
                hsps.push(a);
                if(hsps.length % 2 == 0){
                    updateEdgeTracks(hsps[0], hsps[1], 1.0, edge_tracks);
                    hsps = [];
                }
            }
            else if (hsps.length != 0) {
                Gobe.js_warn("non-consecutive hsps");
            }
        }
        var t2 = haxe.Timer.stamp();
        trace("seconds to reparse, make edges:" + (t2 - t1));
        initializeSubTracks(edge_tracks);
        var t3 = haxe.Timer.stamp();
        trace("seconds to add subtracks:" + (t3 - t2));
        addAnnotations(anarr);
        var t4 = haxe.Timer.stamp();
        trace("seconds to add annotations:" + (t4 - t3));
        trace("seconds tototal:" + (t4 - t));
    }

    public function mouseMove(e:MouseEvent){
        if(! e.buttonDown){ return; }
        if (!e.buttonDown){
            var e2 = new MouseEvent(MouseEvent.MOUSE_UP, false, false, e.localX, e.localY);
            this.dispatchEvent(e2);
            return;
        }
        //trace(e.stageX + "," + e.stageY);
        var r = this.drag_sprite.do_draw(e.stageX, e.stageY);
        drawEdgesInRect(r);
   }

    public function mouseDown(e:MouseEvent){
        var d = this.drag_sprite;
        d.graphics.clear();
        d.startx = e.stageX;
        d.starty = e.stageY;
    }

    public function drawEdgesInRect(r:Rectangle){
        for(ed in edges){
            ed.visible = false;
            if(r.intersects(ed.a.getRect(this)) || r.intersects(ed.b.getRect(this))){
                ed.draw();
            }
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
        return new Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
    }
}


class GEvent extends Event {
    public static var LOADED = "LOADED";
    //public static var ALL_LOADED = "ALL_LOADED";
    public function new(type:String){
        super(type);
    }
}

