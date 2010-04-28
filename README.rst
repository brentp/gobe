Gobe: interactive comparative genomics viewer
=============================================

.. image:: http://lh4.ggpht.com/_uU_kLC5AdTc/S9Oz2FAE0MI/AAAAAAAAAz0/o9bOod42qA4/s800/screen1.png
    :align: right

interactive, light-weight, customizable, web-based comparative genomics viewer with simple text input format.

:Author: Brent Pedersen (brentp)
:Email: bpederse@gmail.com
:License: MIT

.. contents ::


Summary
=======
You define a set of features, a set of tracks, and a css for styling features
and you get a flash movie that allows you to interact with genomic data. The
simple format makes it trivial to implement further interactivity including
panning and zooming.

Interaction is customizable via javascript callbacks, css, and the input data.
No server-side rendering is required. `haxe`_ programming language is used for
development, but it is not required to use the library.

File Formats
============

The file formats are very simple. The best way to understand them is to briefly
skim the summaries below and have a look at the examples in the `data/`
directory.

Annotations
-----------
An annotation is anything you wish to draw. These will be things like CDSs,
genes, mRNAs, UTRs or any feature you define. An `HSP`_ is a special type that
allows you to draw relationships between features. Consecutive `HSP`_'s are
automatically linked so that clicking either one will draw a wedge to its pair.

The annotation file is a text file with 7 **comma-delimited** columns per row:

    1) `id`: a unique identifier for this annotation. this is anything you
       want, can be your own database id or gene name or just an enumeration.

    2) `track_id`: the id of the track on which to draw this feature.
       See `Track`_.

    3) `start`: the start of the feature.

    4) `end`: the end of the feature.

    5) `type`: a feature type (CDS, gene etc). If not specified, 'default' is used.

    6) `strand`: either '+' or '-', the strand of the feature. `HSP`_'s with a
       +/- match should both be assigned - as the strand. If not specified '+' is used.

    7) `name`: the name of the feature e.g. 'At2g26540'. Can be anything. If not specified
       `id` is used.

an example looks like ::

    1,5,25,38,HSP,+,name1
    2,4,22,123,HSP,+,name2
    At2g26540,4,1110,1683,gene,+,feature name
    3,4,1210,1653,CDS,+,name3
    4,4,1210,1653,CDS,-,name4

Note the last 4 will all be drawn in a `Track`_ with id 4. The 5th will be
drawn in track with id '5' and only the 3rd item is on the - strand. You may
have thousands of annotations. The ids do not have to be numeric.
Consecutive `HSP`_'s will be linked with an edge.

Track
-----

A track defines the name and extent of regions to be drawn. Since Gobe is for
comparative genomics, you will usually draw more than one region. The track
id is used in the annotations (column 6) to indicate where to draw the features.
A track definition has 4 comma delimited columns per row:

    1) `id`: a unique id. used by the annotation to indicate it belongs to
       this track.

    2) `start`: the minimum bound of this track.

    3) `end`: the maximum bound of this track.

    4) `name`: a name for this track displayed in the viewer. If not 
       specified `id` is used.

an example looks like::

    4,19,1999,Track Title

So in that example, the bounds are from 9 to 1999 in basepair coordinates and
any annotation beloning to this track will use '4' in the track column.

**NOTE** that if no track is specified, or if it is specified as
&track=implicit then the track ids and extents will be inferred from the
annotations. The extent of the annotations for each track will be padded
slightly to calculate the extent of the track.

HSP
===

Consecutive HSP's specified in the `Annotations`_ file are related.
Inside the flash movie, clicking either part of an HSP will result in
a wedge being drawn between it and its pair (as in the example images).

edges are inferred between consecutive HSP's.  So that annotation lines like::

    1,HSP,25,38,+,4,4
    2,HSP,22,123,+,5,5
    3,HSP,35,68,+,4,4
    4,HSP,99,223,+,5,5

will infer edges between HSP's 1,2 and HSP's 3,4. This is common e.g. when
parsing a blast, where it's very simple to output consecutive lines for a
single blast pair.

Any annotation **beginning with** "HSP" will be treated in this manner. This
allows one to have different style classes for HSPs. e.g. HSP_blue, HSP_red.

Javascript Callbacks
====================

Whenever you click an annotation Gobe.onclick() is called with arguments:
id, name, bpx, px, track_id corresponding to the values in the annotations
file you specified. You should override this callback to perform sophisticated
queries on an annotation, e.g.: via an AJAX call to a server-side script which
will return more information about the feature.

Getting Started
===============

The best way is to copy the index.html example included in the repository,
adjust the paths to correctly point to your own gobe.js and the gobe.swf and
then specify the paths to your own data with a url like:

    /gobe/?tracks=data/t.tracks&annotations=data/t.annos&style=gobe.css

Once you have each of those files in the proper location, gobe will render the
interactive flash movie.

TODO
====

  * improve docs.
  * nicer ticks, axis labelling
  * automatically guess tracks based on annotations if not given.
  * customizable fonts
  * move HSP colors to CSS.
  * wiggle tracks.

.. image:: http://lh4.ggpht.com/_uU_kLC5AdTc/S9O1wilCMBI/AAAAAAAAA0A/NniSF6OhTps/s800/screen2.png

.. _`haxe`: http://haxe.org/

