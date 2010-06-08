import flash.events.Event;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.net.URLRequest;
import HSP;

/*
extra graphics for Gobe, modeled after GBROWSE <http://gmod.org/wiki/Glyphs_and_Glyph_Options>

feature_type will maps to glyph in the stylesheet
*/

class Glyph {
    static public function draw(a:Annotation) {
        // factory method, dispatch draw function based on glyph type
        var glyph = a.style.glyph;
        // TODO: use switch or hash later
        if (glyph=="generic" || glyph=="arrow") { Box.draw(a); }
        else if (glyph=="dot") { Dot.draw(a); }
    }

    public static inline function get_color(a:Annotation):UInt{
        // try to get the color. if it's not set, then get it from the style.
        var c:UInt;
        if(a.color != 0x000001){
            c = a.color;
        }
        else {
            c = a.is_hsp ? a.subtrack.fill_color : a.style.fill_color;
        }
        return c;

    }
}

class Box {

    static public function draw(a:Annotation) {
        var tw = a.pxmax - a.pxmin;
        var alen = a.style.arrow_len * tw * a.strand;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var g = a.graphics;

        var c = Glyph.get_color(a);

        g.clear();
        g.lineStyle(a.style.line_width, a.is_hsp ? a.subtrack.fill_color : a.style.line_color, 0.3);

        g.moveTo(xstart, a.h/2);
        var m = new flash.geom.Matrix();
        m.createGradientBox(tw, a.h/3, 290, 0, -a.h/6);
        g.beginGradientFill(flash.display.GradientType.LINEAR,
                         [Util.color_shift(c, -24), Util.color_shift(c, 24)],
                         [a.style.fill_alpha, a.style.fill_alpha],
                        [0x00, 0xFF], m);

        g.lineTo(xstart, -a.h/2);
        g.lineTo(xend - alen, -a.h/2);
        g.lineTo(xend, 0);
        g.lineTo(xend - alen, a.h/2);

        g.endFill();
    }
}

class Dot {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var tw = a.pxmax - a.pxmin;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var c = Glyph.get_color(a);

        g.beginFill(c, .5);
        g.drawEllipse(xstart, -a.h/2, a.h, a.h);
        g.endFill();
    }
}

// TODO: glyph: avatar("filename.jpg")
class Avatar {
    static public function draw(t:Dynamic) {
        var img_src = "";
        var im = new Image(img_src, function(_) {trace('loaded');});
        im.x = 50;
        im.y = 50;
        t.addChild(im);
    }
}

// brentp/learnflash
class Image extends Sprite {

    public var path:String;
    public var bitmap:Bitmap;
    public var onLoaded:Bitmap->Void;
    private var _loader:Loader;

    public function new(path:String, onLoaded:Bitmap->Void=null){
        super();
        this.path = path;
        this._loader = new Loader();
        this._loader.load(new URLRequest(path));
        this.onLoaded = onLoaded;
    }
}
