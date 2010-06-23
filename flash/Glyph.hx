import flash.events.Event;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.net.URLRequest;
import StringTools;
import Annotation;
import Gobe;

/*
extra graphics for Gobe, modeled after GBROWSE <http://gmod.org/wiki/Glyphs_and_Glyph_Options>

feature_type will maps to glyph in the stylesheet
*/

class Glyph {
    static public function draw(a:Annotation) {
        // factory method, dispatch draw function based on glyph type
        var glyph = a.style.glyph;
        if (StringTools.startsWith(glyph, "avatar")) {
            var img_src = glyph.split("(\"")[1].split("\")")[0];
            var avatar = new Avatar(a, img_src);
            avatar.draw(a);
        }
        else {
            switch (glyph) {
                case "circle": Circle.draw(a);
                case "cross": Cross.draw(a);
                case "square": Square.draw(a);
                case "star": Star.draw(a);
                case "mask": Mask.draw(a);
                case "text_glyph": TextGlyph.draw(a);
                default: Box.draw(a);
            }
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
        var alen = a.style.arrow_len * tw * (a.strand == 0 ? 1 : a.strand);
        var xstart = (a.strand != -1) ? 0 : tw;
        var xend = (a.strand != -1) ? tw : 0;
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
        var c = Glyph.get_color(a);
        var x = (a.pxmax - a.pxmin)/2;

        g.beginFill(c, a.style.fill_alpha);
        g.drawCircle(x, 0, a.h/2);
        g.endFill();
    }
}

class Cross {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var c = Glyph.get_color(a);
        var x = (a.pxmax - a.pxmin)/2;

        g.beginFill(c, a.style.fill_alpha);
        g.drawRect(x-a.h/2, -a.h/6, a.h, a.h/3);
        g.endFill();

        g.beginFill(c, a.style.fill_alpha);
        g.drawRect(x-a.h/6, -a.h/2, a.h/3, a.h);
        g.endFill();
    }
}

class Star {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var c = Glyph.get_color(a);

        var x = (a.pxmax - a.pxmin)/2; // x-coordinate of center point
        var y = -a.h/2; // y-coordinate of top of the star
        var r = a.h/2; // radius of the star

        // code from <http://lionpath.com/haxeflashtutorial/release/library.html>
        var phi : Float = 2*Math.PI/5; // 2/5 of a circle
        var r2 : Float = ((Math.cos(phi*1)*r)-r)*((Math.sin(phi*2)*r)-0)/(Math.cos(phi*2)*r-r);
        r2 = Math.sqrt(r2*r2+Math.pow(Math.cos(phi)*r,2));

        g.beginFill(c, a.style.fill_alpha);
        g.moveTo(x,y);
        g.lineTo(x+Math.sin(0.5*phi)*r2,y+r-Math.cos(0.5*phi)*r2);
        g.lineTo(x+Math.sin(1*phi)*r,y+r-Math.cos(1*phi)*r);
        g.lineTo(x+Math.sin(1.5*phi)*r2,y+r-Math.cos(1.5*phi)*r2);
        g.lineTo(x+Math.sin(2*phi)*r,y+r-Math.cos(2*phi)*r);
        g.lineTo(x+Math.sin(2.5*phi)*r2,y+r-Math.cos(2.5*phi)*r2);
        g.lineTo(x+Math.sin(3*phi)*r,y+r-Math.cos(3*phi)*r);
        g.lineTo(x+Math.sin(3.5*phi)*r2,y+r-Math.cos(3.5*phi)*r2);
        g.lineTo(x+Math.sin(4*phi)*r,y+r-Math.cos(4*phi)*r);
        g.lineTo(x+Math.sin(4.5*phi)*r2,y+r-Math.cos(4.5*phi)*r2);
        g.endFill();
    }
}

class Square {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var c = Glyph.get_color(a);
        var x = (a.pxmax - a.pxmin)/2;

        g.beginFill(c, a.style.fill_alpha);
        g.drawRoundRect(x-a.h/2, -a.h/2, a.h, a.h, .2*a.h);
        g.endFill();
    }
}

class TextGlyph extends Sprite {
    public static function draw(a:Annotation){
        var t = new MTextField();
        a.addChild(t);
        t.htmlText = "<p>" + a.fname + "</p>";
        //t.y = -a.h/2;
        t.autoSize = flash.text.TextFieldAutoSize.LEFT;
        // start at the left edge.
        //t.x = -t.width;
        t.multiline = false;
        var s = a.style;
        var color = s.style_object.color ? s.style_object.color : "#" + StringTools.hex(s.line_color);
        var fw = s.style_object.fontWeight ? s.style_object.fontWeight : 'normal';
        var fs = s.style_object.fontSize ? Std.parseInt(s.style_object.fontSize) : Gobe.fontSize;
        t.styleSheet.setStyle('p', {fontSize: fs, display: 'inline', color: color, fontWeight: fw});
        t.y -= t.height / 2;
    }
}

class Mask {
    static public function draw(a:Annotation) {
        var g = a.graphics;
        var c = Glyph.get_color(a);
        var tw = a.pxmax - a.pxmin;

        g.beginFill(c, a.style.fill_alpha);
        g.drawRect(0, -a.h/2, tw, a.h);
        g.endFill();
    }
}


class Avatar extends Sprite {
    var feature:Annotation;
    private var _loader:Loader;

    public function new(a:Annotation, path:String) {
        super();
        this._loader = new Loader();
        this._loader.load(new URLRequest(path));
        this._loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
        this.feature = a;
    }

    private function onComplete(e:Event) {
        var image = cast(this._loader.content, Bitmap);
        image.smoothing = true;
        image.width = image.height = this.feature.h;
        this.addChild(image);
    }

    public function draw(a:Annotation) {
        var x = (a.pxmax - a.pxmin)/2;
        this.x = x-a.h/2;
        this.y = -a.h/2;
        a.addChild(this);
    }
}

