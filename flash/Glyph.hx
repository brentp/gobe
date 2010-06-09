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
        switch (glyph) {
            case "circle": Circle.draw(a);
            case "cross": Cross.draw(a);
            case "square": Square.draw(a);
            case "star": Star.draw(a);
            default: Box.draw(a);
        }
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

class Circle {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var tw = a.pxmax - a.pxmin;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var c = Glyph.get_color(a);

        g.beginFill(c, a.style.fill_alpha);
        g.drawEllipse(xstart-a.h/2, -a.h/2, a.h, a.h);
        g.endFill();
    }
}

class Cross {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var tw = a.pxmax - a.pxmin;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var c = Glyph.get_color(a);
        
        g.beginFill(c, a.style.fill_alpha);
        g.drawRect(xstart-a.h/2, -a.h/6, a.h, a.h/3);
        g.endFill(); 

        g.beginFill(c, a.style.fill_alpha);
        g.drawRect(xstart-a.h/6, -a.h/2, a.h/3, a.h);
        g.endFill(); 
    }
}

class Star {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var tw = a.pxmax - a.pxmin;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var c = Glyph.get_color(a);

        var x = xstart; // x-coordinate of center point
        var y = -a.h/2; // y-coordinate of top of the star
        var r = a.h/2; // radius of the star

        // code from <http://lionpath.com/haxeflashtutorial/release/library.html>
        var phi : Float = 2*Math.PI/5; // 2/5 of a circle
        var r2 : Float = ((Math.cos(phi*1)*r)-r)*((Math.sin(phi*2)*r)-0)/(Math.cos(phi*2)*r-r);
        r2 = Math.sqrt(r2*r2+Math.pow(Math.cos(phi)*r,2));

        g.beginFill(c, a.style.fill_alpha);
        g.moveTo(x,y+r-r);
        g.lineTo(x+Math.sin(0.5*phi)*r2,y+r-Math.cos(0.5*phi)*r2);
        g.lineTo(x+Math.sin(1*phi)*r,y+r-Math.cos(1*phi)*r);
        g.lineTo(x+Math.sin(1.5*phi)*r2,y+r-Math.cos(1.5*phi)*r2);
        g.lineTo(x+Math.sin(2*phi)*r,y+r-Math.cos(2*phi)*r);
        g.lineTo(x+Math.sin(2.5*phi)*r2,y+r-Math.cos(2.5*phi)*r2);
        g.lineTo(x+Math.sin(3*phi)*r,y+r-Math.cos(3*phi)*r);
        g.lineTo(x+Math.sin(3.5*phi)*r2,y+r-Math.cos(3.5*phi)*r2);
        g.lineTo(x+Math.sin(4*phi)*r,y+r-Math.cos(4*phi)*r);
        g.lineTo(x+Math.sin(4.5*phi)*r2,y+r-Math.cos(4.5*phi)*r2);
        g.lineTo(x,y+r-r);
        g.endFill();
    }
}

class Square {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var tw = a.pxmax - a.pxmin;
        var xstart = a.strand == 1 ? 0 : tw;
        var xend = a.strand == 1 ? tw : 0;
        var c = Glyph.get_color(a);

        g.beginFill(c, a.style.fill_alpha);
        g.drawRoundRect(xstart-a.h/2, -a.h/2, a.h, a.h, .2*a.h);
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
