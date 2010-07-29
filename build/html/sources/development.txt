For Developers
=================

The gobe binary is a swf flash movie. It does not use the Adobe compiler. Instead it uses
`haxe <http://haxe.org/>`__ , an open source language that can compile for the flash player.
It has a syntax very similar to actionscript 3.

Get The Source
---------------

    git clone git://github.com/brentp/gobe.git


Install Haxe
-------------

Download the appropriate installer `here <http://haxe.org/download>`__.


Build gobe.swf
----------------

    cd gobe/flash
    haxe gobe.hxml

and you should see no output, but a new ``gobe.swf`` file will be created. If it does not, make sure haxe is installed correctly.

View index.html
----------------

put the gobe directory in a web directory and point your browser to: ``http://yourhost/web/path/to/gobe/`` and you should see a page with several demo links. You may have to have Firebug or some console enabled as the movie will try to log events to the console and your browser may error if there's no console to write to.

Write some code
----------------

you do **not** need an IDE to write haxe, simply edit any of the .hx files in the `flash directory <http://github.com/brentp/gobe/tree/master/flash/>`__ and re-run ``haxe gobe.hxml``

For debugging, ``trace()`` messages will go to the browser console (either FireBug in firefox or the developer console ``[ctrl+shift+j]`` in chrome).

Code Layout
-------------

`Gobe.hx <http://github.com/brentp/gobe/tree/master/flash/Gobe.hx>`__ contains the code simply to load the annotations data and distribute work to the ``Track``, ``SubTrack``, and ``Annotation`` classes in ``HSP.hx``.

`Track.hx <http://github.com/brentp/gobe/tree/master/flash/Track.hx>`__ contains the ``Track``, ``SubTrack``, ``Edge`` and ``Annotation`` classes. a ``Track`` contains data from a single dataset. It has ``bpmin`` and ``bpmax`` that determine its extent--these are used for drawing and scaling. Each ``Track`` has at least 2 subtracks--``AnnoTracks``. One for the + strand, and one for the minus. For each HSP between a given track and another track there will be 2 additional subtracks, one for the + and one for the - strand. These subtracks are stored in a Hash called ``subtracks`` for each Track. Tracks are stored in the static hash ``Gobe.tracks``. 

An ``Annotation`` is any feature that is drawn in the flash movie other than a track (e.g. HSP, CDS, gene, etc). The ``draw()`` method on the ``Annotation`` class contains the logic for rendering all feature types. It depends on the information parsed from the stylesheet (default is `gobe.css <http://github.com/brentp/gobe/tree/master/static/gobe.css>`__ ). The information in the stylesheet tells the ``Annotation`` class how to render each feature type. For example, the stylesheet contains a CDS block that indicates the ``line_color``, ``width`` and ``fill_color`` to be used when rendering an Annotation with a type of CDS. This allows the user to specify any feature type as long as they also specify a corresponding entry in the stylesheet.

`Util.hx <http://github.com/brentp/gobe/tree/master/flash/Util.hx>`__ contains miscellaneous code for doing stuff. Any code that is repeated or general or hacky should be made as clean as possible and put into ``Util.hx`` as a static method.

`Glyph.hx <http://github.com/brentp/gobe/tree/master/flash/Glyph.hx>`__ handles most of the drawing of features. ``Glyph`` class will dispatch the drawing method based on the glyph style. Define your own glyph style in the css file.

References
-----------

The `haxe api docs <http://haxe.org/api/>`__ are pretty good. For flash stuff, use the flash9 (not flash). For much of the code, you can probably find existing examples in the codebase of using ``Hash`` or ``Array`` or looping.

The adobe docs are good when they come up on a google search for a particular class or method.
