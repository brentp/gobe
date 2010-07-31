#!/usr/bin/env python
# -*- coding: UTF-8 -*-

"""
%prog [options] bed_file > gobe_file

Converts bed format into gobe format. bed file often has 5 fields:

seqid  start  stop  name  type  strand

Note that the first three fields are required, per bed format specification. The next
two columns are optional. Use "--features" to select subset of the types.
"""

import sys
import cStringIO
import collections


class BedLine(object):
    """ 
    Parsing a line of bed, supporting three required plus three optional columns
    """
    __slots__ = ("seqid", "start", "end", "name", "type", "strand")

    def __init__(self, sline):
        args = sline.strip().split("\t")
        self.seqid = args[0]
        self.start = int(args[1])
        self.end = int(args[2])
        self.name = args[3] if len(args) > 3 else None
        self.type = args[4] if len(args) > 4 else None
        self.strand = args[5] if len(args) > 5 else None


class Bed(list):
    """ 
    >>>
    """
    def __init__(self, lines, include_features=None):
        # list of BedLines
        for line in lines:
            if line[0] == "#" or line.strip()=="": continue
            if line.startswith("track"): continue
            self.append(BedLine(line))

        self.include_features = include_features
    
    def iter_tracks(self):
        # returns an ordered dictionary with seqid => (seqid_start, seqid_end)
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
            if self.include_features and not b.type in self.include_features: continue
            # (@gobe doc) id, track_id, start, end, type, strand, name
            yield ",".join(str(x) for x in (i, b.seqid, b.start, b.end, \
                    b.type or "", b.strand or "", b.name or ""))



def bed_to_gobe(lines, include_features=None):
    """
    >>>
    """
    bed = Bed(lines, include_features=include_features)
    output = cStringIO.StringIO()
    print >>output, "### Tracks "
    print >>output, "\n".join(bed.iter_tracks())
    print >>output, "### Features " 
    print >>output, "\n".join(bed.iter_features())
    return output.getvalue()


def main(bed_file, include_features=None):

    contents = open(bed_file).readlines()
    gobe_contents = bed_to_gobe(contents, include_features=include_features)
    print gobe_contents


if __name__ == '__main__':

    import doctest
    doctest.testmod()

    from optparse import OptionParser

    parser = OptionParser(__doc__)
    parser.add_option("--features", dest="features", default=None,
            help="include list of features (separated by comma); features not "
            "in the list are excluded")

    opts, args = parser.parse_args()
    if len(args) != 1:
        sys.exit(parser.print_help())
    
    bed_file = args[0]
    include_features = set(opts.features.split(",")) if opts.features else None 

    main(bed_file, include_features)

