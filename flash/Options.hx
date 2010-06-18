
class Options {
    // height in pixels of info/title track. dont use proprotion because it
    // must have some minimum height regardless of the height of the movie.
    public static var info_track_height:Float = 28;


    // HSP track height relative to anno_track. note that anno_track is actually 2 tracks,
    // so this should be 0.5 to make it equal to a single strand. and < 0.5 to make it smaller.
    public static var sub_track_height_ratio:Float = 0.4;

    // used by the ruler graphics to determine an array of tick locs in bp
    // the algorithm used here attempts to make the array close to 'optimal' size
    public static var optimal_ticks:Int = 12;


    // color of the annotrack background.
    //public static var anno_track_background_color:UInt = 0xdcdcdc;
    public static var anno_track_background_color:UInt = 0xf0f0d7;
    //public static var anno_track_background_color:UInt = 0x000000;


}
