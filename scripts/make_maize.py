#!/usr/bin/env python
# -*- coding: UTF-8 -*-

"""
This script demonstrates how to convert gff to bed formatted file. Given the
complexity of gff, this needs to be handled differently. although bed format is
more easily uniform, with

seqid  start  stop  name  type  strand

First three columns are required, the rest are optional
"""

fp = file("ZmB73_4a.53_FGS.gff")
for row in fp:
    #9       ensembl gene    15067   15907   .       -       .       ID=GRMZM2G335242;Name=GRMZM2G335242;biotype=protein_coding
    if row[0]=="#": continue
    atoms = row.split("\t")
    chr, start, stop, name, feature, strand = atoms[0], atoms[3], atoms[4], \
            atoms[-1], atoms[2], atoms[6]
    name = name.split(";")[0].split("=")[1].strip()
    print "\t".join((chr, start, stop, name, feature, strand))
