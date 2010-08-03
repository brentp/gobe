import sys
import collections
import os.path as op


class BedLine(object):
    """
    Parsing a line of bed, supporting three required plus three optional columns
    """
    __slots__ = ("seqid", "start", "end", "name", "type", "strand")

    def __init__(self, sline, format="bed"):
        args = sline.strip().split("\t")
        if format=="bed":
            self._bedline(args)
        else:
            self._gffline(args)

    def _bedline(self, args):
        self.seqid = args[0]
        self.start = int(args[1])
        self.end = int(args[2])
        self.name = args[3] if len(args) > 3 else None
        self.type = args[4] if len(args) > 4 else None
        self.strand = args[5] if len(args) > 5 else None

    def _gffline(self, args):
        self.seqid = args[0]
        self.start = int(args[3])
        self.end = int(args[4])
        self.name = args[-1].split(";")[0].split("=")[1].split(",")[0].strip()
        self.type = args[2]
        self.strand = args[6]


class Bed(list):

    def __init__(self, lines, format="bed", feature_types=None):
        # list of BedLines
        for line in lines:
            if line[0] == "#" or line.strip()=="": continue
            if line.startswith("track"): continue
            self.append(BedLine(line, format=format))

        self.feature_types = feature_types

    def iter_tracks(self):

        # first get an ordered dictionary with seqid => (seqid_start, seqid_end)
        # this is useful to generate track info
        track_order = []
        track_extents = collections.defaultdict(lambda: [sys.maxint, 0])
        for b in self:
            t_extents = track_extents[b.seqid]
            # update track extents
            if b.start < t_extents[0]: t_extents[0] = b.start
            if b.end > t_extents[1]: t_extents[1] = b.end
            if b.seqid not in track_order:
                track_order.append(b.seqid)

        for t in track_order:
            t_extents = track_extents[t]
            track_start, track_end = t_extents
            track_len = track_end - track_start
            # expand 5% on both ends
            margin = track_len / 20
            track_start -= margin
            track_end += margin
            # (@gobe doc) track_id, name, start, end, track
            yield ",".join(str(x) for x in (t, t, track_start, track_end, \
                "track"))

    def iter_features(self):

        for i, b in enumerate(self):
            if self.feature_types and not b.type in self.feature_types: continue
            # (@gobe doc) id, track_id, start, end, type, strand, name
            yield ",".join(str(x) for x in (i, b.seqid, b.start, b.end, \
                    b.type or "", b.strand or "", b.name or ""))



def bed_to_gobe(lines, format="bed", feature_types=None, title=None):
    """
    This calls the conversion and puts two sections (tracks and features)
    """
    bed = Bed(lines, format=format, feature_types=feature_types)
    output = ["### Tracks "]
    output.extend(bed.iter_tracks())
    output.append("### Features ")
    output.extend(bed.iter_features())
    r = "\n".join(output)
    if title is None:
        return r

    import urllib
    import simplejson
    post_data = urllib.urlencode({"annos": r, "title": title})
    response = urllib.urlopen("http://try-gobe.appspot.com/", post_data).read()
    response = simplejson.loads(response)
    return "# http://try-gobe.appspot.com/#!!%s\n%s" % (response["anno_id"], r)


def main(bed_file, format='bed', feature_types=None):

    if not isinstance(feature_types, list):
        feature_types = [x.strip() for x in feature_types.split(",")] \
            if feature_types else None

    # they sent in a filepath.
    if isinstance(bed_file, basestring):
        contents = open(bed_file).readlines()
        title = op.basename(bed_file)
    else:
        # they sent in a list of lines.
        contents = bed_file
        title = contents[0]

    if feature_types:
        title += (" (%s)" % ", ".join(feature_types))

    gobe_contents = bed_to_gobe(contents, format=format,
            feature_types=feature_types, title=title)
    print gobe_contents


if __name__ == '__main__':

    import doctest
    doctest.testmod()

    from optparse import OptionParser

    parser = OptionParser(__doc__)
    supported_fmts = ("bed", "gff")
    parser.add_option("--format", dest="format", default="bed",
            choices=supported_fmts,
            help="choose one of %s" % (supported_fmts,) + " [default: %default]")
    parser.add_option("-t", "--feature-types", dest="feature_types",
                      default=None, help=
            "include list of feature types (separated by comma); types not "
            "in the list are excluded")

    opts, args = parser.parse_args()
    if len(args) != 1:
        sys.exit(parser.print_help())

    bed_file = args[0]

    main(bed_file, opts.format, opts.feature_types)

