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
    try:
        from django.utils import simplejson
    except:
        import simplejson
    post_data = urllib.urlencode({"annos": r, "title": title})
    response = urllib.urlopen("http://try-gobe.appspot.com/", post_data).read()
    response = simplejson.loads(response)
    return "# http://try-gobe.appspot.com/#!!%s\n%s" % (response["anno_id"], r)


def main(bed_file, format='bed', feature_types=None, title=None):

    if not isinstance(feature_types, list):
        feature_types = [x.strip() for x in feature_types.split(",")] \
            if feature_types else None

    # they sent in a filepath.
    if isinstance(bed_file, basestring):
        contents = open(bed_file).readlines()
    else:
        # they sent in a list of lines.
        contents = bed_file

    if feature_types and title:
        title += (" (%s)" % ", ".join(feature_types))

    gobe_contents = bed_to_gobe(contents, format=format,
            feature_types=feature_types, title=title)
    return gobe_contents

def guess_format(annos_str):
    r"""
    guess gff3/bed/gobe given an input string of
    annotations
    >>> guess_format("##gff-version")
    'gff3'
    >>> guess_format("1,2,3,4,5")
    'gobe'
    >>> guess_format("1\n2")
    'gobe'
    >>> guess_format("seqid\tstart\tstop\taccn\ttype\tstrand")
    'bed'
    >>> guess_format("seqid\tstart\tstop\taccn\ttype\tstrand")
    'bed'
    >>> guess_format("chr22\t.\tBED_feature\t20100001\t20100100\t.\t.\t.\t.")
    'gff3'

    """
    alist = annos_str.split("\n")
    if alist[0].startswith("##gff-version"):
        return "gff3"
    alist = [a for a in alist if not a[0] == "#"]

    if alist[0].count(",") > alist[0].count("\t"):
        return "gobe"

    # it's gobe line data with only 1 column.
    if alist[0].count(",") + alist[0].count("\t") == 0:
        return "gobe"

    if len(alist[0].split("\t")) != 9:
        return "bed"

    return "gff3"

if __name__ == "__main__":
    import doctest
    doctest.testmod()
