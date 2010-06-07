import flash.events.Event;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.net.URLRequest;

/*
extra graphics for Gobe, modeled after GBROWSE <http://gmod.org/wiki/Glyphs_and_Glyph_Options>

feature_type will maps to glyph in the stylesheet
*/

class Glyph {
    static public function draw(t:Dynamic) {
        // factory method, dispatch draw function based on glyph type
        var glyph = t.style.glyph;
        // TODO: use switch or hash later
        if (glyph=="generic" || glyph=="arrow") { Box.draw(t); }
        else if (glyph=="dot") { Dot.draw(t); }
    }
}

class Box {
    static public function draw(t:Dynamic) {
        var is_hsptrack = t.is_hsp; //Std.is(subtrack, HSPTrack);
        var tw = t.pxmax - t.pxmin;
        var alen = t.style.arrow_len * tw * t.strand;
        var xstart = t.strand == 1 ? 0 : tw;
        var xend = t.strand == 1 ? tw : 0;
        var style = t.style;
        var h = t.h;
        var subtrack = t.subtrack;
        var g = t.graphics;

        // try to get the color. if it's not set, then get it from the style.
        var c:UInt;
        if(t.color != 0x000001){
            c = t.color;
        }
        else {
            c = is_hsptrack ? subtrack.fill_color : style.fill_color;
        }

        g.clear();
        g.lineStyle(style.line_width, is_hsptrack ? subtrack.fill_color : style.line_color, 0.3);

        g.moveTo(xstart, h/2);
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
}

class Dot {
    static public function draw(t:Dynamic) {
        var g = t.graphics;
        var tw = t.pxmax - t.pxmin;
        var xstart = t.strand == 1 ? 0 : tw;
        var xend = t.strand == 1 ? tw : 0;
        var x = xstart;
        var h = t.h;

        g.beginFill(t.color, .5);
        g.drawEllipse(x, -h/2, h, h);
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
