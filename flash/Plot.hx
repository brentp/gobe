import HSP;
import Gobe;
import flash.events.Event;

class PlotTrack extends Track {


}

typedef Data = {
    var xmin : Int;
    var xmax : Int;
    var yraw : Float;
    var y    : Float;
    var color: Int;
}

class Plot extends BaseAnnotation {
    public var data_url:String;
    public var ymin:Float;
    public var ymax:Float;

    public function new(aline:Array<String>){
        super(aline);
        this.data_url = aline[6];
        Gobe.geturl(this.data_url, _dataReturn);
        ymin = Math.POSITIVE_INFINITY;
        ymax = Math.NEGATIVE_INFINITY;

    }
    public function _dataReturn(e:Event){
        var lines:Array<String> = StringTools.ltrim(e.target.data).split("\n");
        var cleaned = new Array<String>();
        for(line in lines){
            if(line.length == 0 || line.charAt(0) == "#"){ continue; }
            cleaned.push(line);
        }
        this.dataReturn(cleaned);
        Gobe.addPlot(this);
    }
    public function dataReturn(lines:Array<String>){
        trace('override this');
    }

}


class PlotLine extends Plot {
    /*
    #id,track_id,xmin,xmax,style,data-source
    plot1,q,71630143,71695587,plot_line,data/pair/gc_content.txt
    */
    public var data:Array<Float>;

    public override function dataReturn(lines:Array<String>){
        data = new Array<Float>();
        var d:Float;
        for(line in lines){
            d = Std.parseFloat(line);
            data.push(d);
            if(d < ymin) { ymin = d; }
            if(d > ymax) { ymax = d; }
        }
    }

    public override function draw(){
        this.style = Gobe.styles.get(this.ftype);
        var lw:Float = 2, lc:Int = 0;
        if (style != null){
            lw = style.line_width;
            lc = style.line_color;
        }

        var st = this.subtrack;
        var h = st.height;
        var g = this.graphics;
        x = 0; y = 0;
        var rng = ymax - ymin;
        g.moveTo(x, 0);
        g.lineStyle(lw, lc, 0.4);

        var i = 0;
        for(d in data){
            var yy = (d - ymin) / rng * h;
            var xx = this.track.rw2pix(this.bpmin + i);
            if(i % 1000 == 0){
                //trace(xx + "," + yy);
            }
            g.lineTo(xx, -yy);
            i += 1;
        }
    }


}
class PlotHist extends Plot {
    public override function draw(){
        var lw:Float = 1, lc:Int = 0;
        var rw2pix = this.track.rw2pix;
        var st = this.subtrack;
        var g = this.graphics;
        x = 0; y = 0;
        for(d in data){
            var x0 = rw2pix(d.xmin), x1 = rw2pix(d.xmax);
            g.lineStyle(lw, d.color, 0.6);
            g.beginFill(d.color);
            g.moveTo(x0, -h);
            g.lineTo(x0, -d.y);
            g.lineTo(x1, -d.y);
            g.lineTo(x1, -h);
            g.endFill();
        }
    }
    /*
    format from file is xstart,xstop,zvalue [, color]
    */
    public var data:Array<Data>;

    public override function dataReturn(lines:Array<String>){
        data = new Array<Data>();
        var a:Array<String>;
        var y:Float;
        var xmin:Float, xmax:Float;
        for(line in lines){
            a = line.split(",");
            y = Std.parseFloat(a[2]);
            var pt:Data;
            pt = { xmin : Std.parseInt(a[0]),
                   xmax : Std.parseInt(a[1]),
                   yraw : y,
                   y    : y,
                   color: Util.color_string_to_uint(a[3]) };

            data.push(pt);
            if(y < ymin) { ymin = y; }
            if(y > ymax) { ymax = y; }
        }
        trace('hist data return ok');
    }

    public override function added(e:Event){
        this.rescale();
        super.added(e);
    }

    public function rescale(){
        var d:Data;
        var rng = ymax - ymin;
        var h = this.subtrack.height;
        for(d in data){
            d.y = (d.yraw - ymin) / rng * h;
        }
        trace('rescaled hist');
    }
}
