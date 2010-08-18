import sys
import collections
import re


class FeatureLine(object):
    """
    Parsing a line of bed, supporting three required plus three optional columns
    """
    __slots__ = ("seqid", "start", "end", "name", "type", "strand",
                'qseqid', 'sseqid', 'pctid', 'hitlen', 'nmismatch', 'ngaps',
                 'qstart', 'qstop', 'sstart', 'sstop', 'evalue', 'score',
                 'qseqid', 'sseqid', 'qadjust', 'sadjust')

    def __init__(self, sline, format="bed", qadjust=0, sadjust=0):
        self.qadjust = qadjust
        self.sadjust = sadjust
        args = sline.strip().split("\t")
        method = getattr(self, "_%sline" % format)
        method(args)

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

    def _blastline(self, args):
        self.qseqid = args[0]
        self.sseqid = args[1]
        self.pctid = float(args[2])
        self.hitlen = int(args[3])
        self.nmismatch = int(args[4])
        self.ngaps = int(args[5])
        self.qstart = int(args[6]) + self.qadjust
        self.qstop = int(args[7]) + self.qadjust
        self.sstart = int(args[8]) + self.sadjust
        self.sstop = int(args[9]) + self.sadjust
        self.evalue = float(args[10])
        self.score = float(args[11])


class FeatureList(list):

    def __init__(self, lines, format="bed", feature_types=None, title="", qadjust=0, sadjust=0):
        # list of FeatureLines
        self.title = title.strip()
        for line in lines:
            if line[0] == "#" or line.strip()=="": continue
            if line.startswith("track"): continue
            self.append(FeatureLine(line, format=format, qadjust=qadjust, sadjust=sadjust))

        self.feature_types = feature_types

    def iter_tracks(self):

        # first get an ordered dictionary with seqid => (seqid_start, seqid_end)
        # this is useful to generate track info
        track_order = []
        track_extents = collections.defaultdict(lambda: [sys.maxint, 0])
        for b in self:
            is_blast = hasattr(b, 'qseqid')
            qs, starts, stops, seqids = ('', ),('start',), ('end',), ('seqid',)
            # if it's a blast, have to do query and subject.
            if is_blast:
                qs, starts, stops, seqids = ('q', 's'), \
                                        ('qstart', 'sstart'), \
                                        ('qstop', 'sstop'), \
                                        ('qseqid', 'sseqid')
                qs = ("", "")
            for q_or_s, nseqid, nstart, nend in zip(qs, seqids, starts, stops):
                seqid, start, end = [getattr(b, attr) for attr in (nseqid, nstart, nend)]
                fseqid = q_or_s + seqid
                t_extents = track_extents[fseqid]
                # update track extents
                if start < t_extents[0]: t_extents[0] = start
                if end > t_extents[1]: t_extents[1] = end
                if fseqid not in track_order:
                    track_order.append(fseqid)

        for t in track_order:
            t_extents = track_extents[t]
            track_start, track_end = t_extents
            track_len = track_end - track_start
            # expand 5% on both ends
            margin = track_len / 20
            track_start -= margin
            track_end += margin
            # (@gobe doc) track_id, name, start, end, track
            title = self.title + " : " if self.title else ""
            yield ",".join(str(x) for x in (t, title + t, track_start, track_end, \
                "track"))

    def iter_features(self):

        for i, b in enumerate(self):
            is_blast = hasattr(b, "qseqid")
            if self.feature_types and not b.type in self.feature_types: continue
            # (@gobe doc) id, track_id, start, end, type, strand, name
            if is_blast:
                strand = "+" if b.sstart < b.sstop else '-'
                # TODO: can allow user to specify a prefix here...
                qprefix, sprefix = "", ""
                yield ",".join(str(x) for x in (qprefix + str(i), b.qseqid, b.qstart, b.qstop, "HSP", strand))
                yield ",".join(str(x) for x in (sprefix + str(i), b.sseqid, b.sstart, b.sstop, "HSP", strand))

            else:
                yield ",".join(str(x) for x in (i, b.seqid, b.start, b.end, \
                    b.type or "", b.strand or "", b.name or ""))



def feats_to_gobe(lines, format="bed", feature_types=None, title=None,
                 qadjust=0, sadjust=0):
    """
    This calls the conversion and puts two sections (tracks and features)
    """

    feats = FeatureList(lines, format=format, feature_types=feature_types, title=title or "",
                       qadjust=qadjust, sadjust=sadjust)
    output = ["### Tracks "]
    output.extend(feats.iter_tracks())
    output.append("### Features ")
    output.extend(feats.iter_features())
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


def main(feat_file, format='bed', feature_types=None, title=None, force_tabs=False,
        qadjust=0, sadjust=0):
    """
    for a blast result, qadjust and sadjust can be used to transfrom from local
    coordinates to chromosomal coordinates
    """

    if not isinstance(feature_types, list):
        feature_types = [x.strip() for x in feature_types.split(",")] \
            if feature_types else None

    # they sent in a filepath.
    if isinstance(feat_file, basestring):
        contents = open(feat_file).readlines()
    else:
        # they sent in a list of lines.
        contents = feat_file
    if force_tabs:
        contents = [re.sub("\s+", "\t", l) for l in contents]
    if feature_types and title:
        title += (" (%s)" % ", ".join(feature_types))

    gobe_contents = feats_to_gobe(contents, format=format,
            feature_types=feature_types, title=title, qadjust=qadjust, sadjust=sadjust)
    return gobe_contents

def guess_format(annos_str, force_tabs=False):
    r"""
    guess gff3/bed/gobe/blast given an input string of
    annotations
    >>> guess_format("##gff-version")
    'gff'
    >>> guess_format("1,2,3,4,5")
    'gobe'
    >>> guess_format("1\n2")
    'gobe'
    >>> guess_format("seqid\tstart\tstop\taccn\ttype\tstrand")
    'bed'
    >>> guess_format("seqid\tstart\tstop\taccn\ttype\tstrand")
    'bed'
    >>> guess_format("chr22\t.\tBED_feature\t20100001\t20100100\t.\t.\t.\t.")
    'gff'

    >>> guess_format("AT1G77500.1\tfgenesh2_kg.2__2045__AT1G77500.1\t95.2\t2612\t125\t9\t1\t2636\t201\t2836\t0\t4577.5")
    'blast'

    """

    alist = annos_str.split("\n")
    if alist[0].startswith("##gff-version"):
        return "gff"
    alist = [a for a in alist if not a[0] == "#"]
    l1 = alist[0]
    if force_tabs:
        l1 = re.sub("\s+", "\t", l1)

    if l1.count(",") > l1.count("\t"):
        return "gobe"

    # it's gobe line data with only 1 column.
    if l1.count(",") + l1.count("\t") == 0:
        return "gobe"

    s1 = l1.split("\t")
    if len(s1) == 12 and s1[3].isdigit() and s1[4].isdigit():
        return 'blast'

    if len(s1) != 9:
        return "bed"

    return "gff"

if __name__ == "__main__":
    import doctest
    doctest.testmod()
