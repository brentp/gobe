Gobe: interactive comparative genomics viewer
=============================================

.. image:: http://lh4.ggpht.com/_uU_kLC5AdTc/S9Oz2FAE0MI/AAAAAAAAAz0/o9bOod42qA4/s800/screen1.png
    :align: right

a fast, interactive, light-weight, customizable, web-based comparative genomics viewer with simple text input format.  

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
genes, mRNAs, UTRs or any feature you define. An `HSP` is a special type that
allows you to draw relationships between features.
An annotation file is a simple
text file with 7 **comma-delimited** columns per row:

    1) `id`: a unique identifier for this annotation. this is anything you 
       want, can be your own database id or gene name or just an enumeration.

    2) `type`: a feature type (CDS, gene etc).

    3) `start`: the start of the feature.

    4) `end`: the end of the feature.

    5) `strand`: either '+' or '-', the strand of the feature. `HSP`'s with a
       +/- match should both be assigned - as the strand

    6) `track`: the track on which to draw this feature. See `Tracks`.

    7) `name`: the name of the feature e.g. 'At2g26540'. Can be anythign.

an example looks like ::

    1,HSP,25,38,+,4,4
    At2g26540,gene,1110,1683,+,4,feature name
    3,CDS,1210,1653,+,4,4
    4,CDS,1210,1653,-,4,4
    5,HSP,22,123,+,4,4

Note the first 4 will all be drawn in a `track` with id 4. The 5th will be
drawn in track with id '5' and only the 3rd item is on the - strand. You may 
have thousands of annotations. The ids do not have to be numeric.

Tracks
------

A track defines the name and extent of regions to be drawn. Since Gobe is for 
comparative genomics, you will usually draw more than one region. The track
id is used in the annotations (column 6) to indicate where to draw the features.
A track definition has 4 comma delimited columns per row:

    1) `id`: a unique id. used by the annotation to indicate it belongs to 
       this track.

    2) `name`: a name for this track displayed in the viewer.

    3) `start`: the minimum bound of this track.

    4) `end`: the maximum bound of this track.

an example looks like::
    
    4,Track Title,19,1999

So in that example, the bounds are from 9 to 1999 in basepair coordinates and
any annotation beloning to this track will use '4' in the track column.


Edges
-----
An edge defines a relationship between 2 annotations. The format is extremely
simple. It is 3 comma-delimited columns:

   1) `id`: id of annotation a

   2) `id`: id of annotation b

   3) `strength`: the strength of the edge between a and b.

and example looks like ::

    1,5,0.9

Where that would add an edge between the annotations 1, 5 described in the
section above.

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

    /gobe/?tracks=data/t.tracks&annotations=data/t.annos&edges=data/t.edges&style=gobe.css

Once you have each of those files in the proper location, gobe will render the 
interactive flash movie.

TODO
====

  * improve docs.
  * nicer ticks, axis labelling
  * automatically guess tracks based on annotations if not given.
  * customizable fonts
  * move HSP colors to CSS.

.. image:: http://lh4.ggpht.com/_uU_kLC5AdTc/S9O1wilCMBI/AAAAAAAAA0A/NniSF6OhTps/s800/screen2.png

.. _`haxe`: http://haxe.org/

