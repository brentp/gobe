#!/usr/bin/env python
# -*- coding: UTF-8 -*-

"""
%prog [options] bed_file > gobe_file

Converts bed format into gobe format. bed file often has 5 fields:

seqid  start  stop  name  type  strand

Note that the first three fields are required, per bed format specification. The next
two columns are optional. Use "--features" to select subset of the types.

or gff files are also accepted (with columns processed similarly in another
order)

"""
import sys
import os.path as op
sys.path.insert(0, op.join(op.dirname(__file__), "..", "try-gobe.appspot.com"))
import utils

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

    utils.main(bed_file, opts.format, opts.feature_types)

