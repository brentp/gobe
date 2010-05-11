import HSP;
import Gobe;
import flash.events.Event;

class PlotTrack extends Track {


}

class Plot extends BaseAnnotation {
    /*
    #id,track_id,xmin,xmax,style,data-source
    plot1,q,71630143,71695587,plot_line,data/pair/gc_content.txt
    */
    public var data_url:String;
    public var data:Array<Float>;
    public var ymin:Float;
    public var ymax:Float;


    public function new(aline:Array<String>){
        super(aline);
        this.data_url = aline[6];
        Gobe.geturl(this.data_url, dataReturn);
        ymin = Math.POSITIVE_INFINITY;
        ymax = Math.NEGATIVE_INFINITY;
    }

    public function dataReturn(e:Event){
        var lines:Array<String> = StringTools.ltrim(e.target.data).split("\n");
        data = new Array<Float>();
        var d:Float;
        for(line in lines){
            if(line.length == 0 || line.charAt(0) == "#"){ continue; }
            d = Std.parseFloat(line);
            data.push(d);
            if(d < ymin) { ymin = d; }
            if(d > ymax) { ymax = d; }
        }
        trace(ymin + "," + ymax);
        // NOTE: this only works if the tracks are added to the movie before
        // we get here. should base on events...
        this.set_track();
    }

    public override function draw(){
        this.style = Gobe.styles.get(this.ftype);
        var lw:Float = 2, lc:Int = 0;
        if (style != null){
            lw = style.line_width;
            lc = style.line_color;
        }

        var st = this.subtrack;
        var h = this.subtrack.height;
        var g = this.graphics;
        x = 0; y = 0;
        var rng = ymax - ymin;
        g.moveTo(x, 0);
        g.lineStyle(lw, lc, 0.4);

        var i = 0;
        for(d in data){
            var yy = -h + (d - ymin) / rng * h;
            var xx = this.track.rw2pix(this.bpmin + i);
            if(i % 1000 == 0){
                trace(xx + "," + yy);
            }
            g.lineTo(xx, yy);
            i += 1;
        }
    }

    public function set_track(){
        var st = this.track.subtracks.get(this.strand == 1 ? '+' : '-');
        this.subtrack = st;
        st.addChild(this);
    }

}
