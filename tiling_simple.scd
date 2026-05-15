//====================================================================================================
// OPTIONS
//====================================================================================================
(
~baseFreq = 261.63/3;      // reference frequency for unity
~ampRef = 0.3;             // reference amplification

~modulo2 = false;          // points along axis are taken as [...-1,0,-1,0,1,0,1,...]
~oneOctave = false;        // restrict frequencies to a single octave

~selectedTile = -1;        // index of currently highlighted tile (-1 = none)
~tileWindowSize = 600;     // size of the tile window
)

~baseFreq = 261.63/2;
//====================================================================================================
// GLOBAL VARIABLES & FUNCTIONS
//====================================================================================================
(
// Read the files for tiling and computer frequencies on dual graph
// Set the file directory
~dir = thisProcess.nowExecutingPath.dirname +/+ "Data/";

~indices = CSVFileReader.readInterpret(~dir ++ "indices_5Dprojection.txt").postcs;
~verts = CSVFileReader.readInterpret(~dir ++ "verts_5Dprojection.txt").postcs;
~faces = CSVFileReader.readInterpret(~dir ++ "faces_5Dprojection.txt").postcs;

if (File.exists(~dir ++ "ji_membership.json"), {
	var d = File.readAllString(~dir ++ "ji_membership.json").parseJSON;
	~freqRatioScalar = d["freqRatioScalar"].asFloat;
	~diamondNodes    = d["diamondNodes"].collect { |pt| pt.collect(_.asFloat) };
	~eikosanyNodes   = d["eikosanyNodes"].collect { |pt| pt.collect(_.asFloat) };
	("ji_membership.json loaded: Diamond=" ++ ~diamondNodes.size
		++ "  Eikosany=" ++ ~eikosanyNodes.size).postln;
}, {
	~freqRatioScalar = 1.0;
	~diamondNodes    = [];
	~eikosanyNodes   = [];
	"ji_membership.json not found — freqRatioScalar = 1.0".postln;
});

~lattice_limit = {
	arg v;
	var xmn, xmx, ymn, ymx;

	xmn = 1e6;
	xmx = -1e6;
	ymn = 1e6;
	ymx = -1e6;

	for (0,v.size-1,
		{
			arg i;
			for (0,3,
				{
					arg j;

					if (v[i][2*j]<xmn, {xmn = v[i][2*j]});
					if (v[i][2*j]>xmx, {xmx = v[i][2*j]});
					if (v[i][(2*j)+1]<ymn, {ymn = v[i][(2*j)+1]});
					if (v[i][(2*j)+1]>ymx, {ymx = v[i][(2*j)+1]});
				}
			);
		}
	);
	[xmn,xmx,ymn,ymx]
};

~lattice_scale = {
	// will overwrite the original lattice array
	arg l, b, v; // lattice limits, window bounds and vertices
	var ofst, s, scl;

	s = [(b[0]-1)/(l[1]-l[0]), (b[1]-1)/(l[3]-l[2])];
	if (s[1]>s[0],{scl=s[0]},{scl=s[1]});
	ofst = [(b[0]-(scl*(l[1]-l[0])))/2, (b[1]-(scl*(l[3]-l[2])))/2];
	ofst.postln;

	for (0,v.size-1,
		{
			arg i;
			for (0,3,
				{
					arg j;

					// v[i][2*j]     = (s[0]*(v[i][2*j]-l[0]));
					// v[i][(2*j)+1] = (s[1]*(v[i][(2*j)+1]-l[2]));
					v[i][2*j]     = ofst[0] + (scl*(v[i][2*j]-l[0]));
					// Flip vertical coordinate (subtract from upper vertical limit
					v[i][(2*j)+1] = ofst[1] + (scl*(l[3]-v[i][(2*j)+1]));  // flip vertical coordinate
				}
			);
		}
	);

	[~diamondNodes, ~eikosanyNodes].do { |nodeList|
		nodeList.do { |pt|
			pt[0] = ofst[0] + (scl * (pt[0] - l[0]));
			pt[1] = ofst[1] + (scl * (l[3] - pt[1]));
		};
	};
};

~lim = ~lattice_limit.value(~verts);

// The next line OVERWRITES the lattice with translated & scaled lattice for plotting
~lattice_scale.value(~lim,[600,600],~verts);

// FREQUENCIES (ratios)
/*
Set up the just intonation intervals for the 5D lattice.  The lattice is really a hyperplane in
4D, so use the ratio of 2 to eliminate one of the dimensions.

The lattice choices are arrays of strings in the variable ~latticeParameters, with the prefix "/"
to indicate an undertone.  There is logic to convert to fractions and place in the range of [1,2].
The reason for the strings is to make a clear presentation of the current choice of intervals
in the button (used to select different lattice parameter choices).
*/

~freqScale = {
	arg cell,node;
	var f = 1.0, p;
	for(0, 4, {arg i;
		if (~modulo2,
			{ p = ((~indices[cell][(node*5)+i])%2)*sign(~indices[cell][(node*5)+i]);},
			{ p = ~indices[cell][(node*5)+i];}
		);
		f = f * (~intervals[i]**p);
		// [f,p].postln;
	});
	f;
};

~freqRatio = {
	arg cell,node;
	var num=1, den=1, p, itvl;

	itvl = ~latticeParameters[~currentInterval];

	for(0, 4, {arg i;
		p = ~indices[cell][(node*5)+i];
		[itvl[i], p, itvl[i]**p].postln;
		if (p>0,{num = num * (itvl[i]**p);});
		if (p<0,{den = den * (itvl[i]**p);});
	});
	[num,den];
};

~singleOctave = {
	arg f;
	var r;

	r = f;
	while ( {r>=2.0}, {r = r/2.0} );
	while ( {r<1.0}, {r = r*2.0} );
	r
};

~limitRange = {
	arg f;
	var r;

	r = f;
	while ( {r>=16.0}, {r = r/2.0} );
	while ( {r<0.25}, {r = r*2.0} );
	r
};

~latticeParameters = [
	["3", "5", "7", "9", "11"],
	["2", "3", "5", "7", "9"],
	["2", "3", "5", "7", "11"],
	["3", "5", "7", "11", "13"],
	["1", "2", "3", "5", "7"],
	["2", "3", "/3", "5", "/5"],
	["3", "/3", "5", "/5", "7"]
	];

~latticeIntervals=Array.fill2D(~latticeParameters.size, ~latticeParameters[0].size, 0.0);

~latticeParameters.do {
	arg i, ii;
	i.do {
		arg j, jj;
		var f;

		if ( "/".matchRegexp(j),
			{
				f = ("1.0"++j).interpret;  // if this is undertone, make it a fraction
				f = ~singleOctave.value(f);
			},{
				f=~singleOctave.value(j.asFloat);   // Place in range [1,2]
			};
		);
		~latticeIntervals[ii][jj]=f;
	};
};

~currentInterval = 0;
~intervals = ~latticeIntervals[~currentInterval];  // Initialize with 1st set of lattice parameters

// IDENTIFY TILE
/*
Identify the tile, and set relative amplitudes based on position selected within the tile

Locate the tile containing the coordinate selected through use of cross product. From
https://stackoverflow.com/questions/1119627/how-to-test-if-a-point-is-inside-of-a-convex-polygon-in-2d-integer-coordinates
*/

~cosine_sign = {
	arg a, b;
	var c;

	c = (a[0]*b[1])-(a[1]*b[0]);
	c;
};

~get_side = {
	arg a, b;
	var r, x;

    x = ~cosine_sign.value(a, b);
	r = if (x<0, {-1}, {if (x>0,  {1},{0})});
	r;
};

~v_sub = {
	arg a, b;
	[a[0]-b[0], a[1]-b[1]];
};

~inside_convex_polygon = {
	arg point, vertices;
	var previous_side, n_vertices, affine_segment, affine_point, current_side;

    previous_side = 0;
    n_vertices = vertices.size;

	block { |break|
		for (0,n_vertices-1,
			{
				arg n;
				var a, b;

				a = vertices[n];
				b = vertices[(n+1)%n_vertices];
				affine_segment = ~v_sub.value(b, a);
				affine_point = ~v_sub.value(point, a);
				current_side = ~get_side.value(affine_segment, affine_point);
				if (current_side==0, {break.value(false)},
					{
						if (previous_side==0, {previous_side = current_side;},
							{
								if (previous_side != current_side, {break.value(false); });
							}
						);
					}
				);
			}
		);
		break.value(true);
	};
};

// INTERPOLATION
/*
Routine to develop relative amplitudes based on position selected within the tile.

The shape functions present a bilinear system, with products s*t, the internal
variables in range [-1,1].  Trying to solve for s & t in terms of tile coordinates
and point selected using SymPy did not work out.

There are some excellent observations given in

https://math.stackexchange.com/questions/2007116/quadrilateral-interpolation

where a Jacobian-like term is indicated for numerical root search as an approach
for an arbitrary quadrilateral.

So, a "Newton's method" is employed,requiring a single interation ("linear" system).
[Wonder if this is actually a least squares approach???]

Note that, as the tiles appear to be parallelograms, it may be possible to use an
esplicit solution given in the link above -- for this specific case.
*/

~ampScale = {
	arg v, x, y;

	var s, t, x1, x2, x3, x4, y1, y2, y3, y4;
	var f1, f2, j, jInv, n1, n2, n3, n4;

	s = 0.0;
	t = 0.0;

	x1 = v[2];
	y1 = v[3];
	x2 = v[0];
	y2 = v[1];
	x3 = v[4];
	y3 = v[5];
	x4 = v[6];
	y4 = v[7];

	n1 = ((1-s)*(1-t))/4;
	n2 = ((1+s)*(1-t))/4;
	n3 = ((1+s)*(1+t))/4;
	n4 = ((1-s)*(1+t))/4;

	f1 = ((n1*x1) + (n2*x2) + (n3*x3) + (n4*x4)) - x;
	f2 = ((n1*y1) + (n2*y2) + (n3*y3) + (n4*y4)) - y;

	j = Matrix.with([[ ((x1*(t-1))/4) - ((x2*(t-1))/4) + ((x3*(t+1))/4) - ((x4*(t+1))/4),
		               ((x1*(s-1))/4) - ((x2*(s+1))/4) + ((x3*(s+1))/4) - ((x4*(s-1))/4)],
	                 [ ((y1*(t-1))/4) - ((y2*(t-1))/4) + ((y3*(t+1))/4) - ((y4*(t+1))/4),
		               ((y1*(s-1))/4) - ((y2*(s+1))/4) + ((y3*(s+1))/4) - ((y4*(s-1))/4)]]);

	jInv = j.inverse().asArray;

	s = s - ((jInv[0][0]*f1)+(jInv[0][1]*f2));
	t = t - ((jInv[1][0]*f1)+(jInv[1][1]*f2));

	[ ((1-s)*(1-t))/4, ((1+s)*(1-t))/4, ((1+s)*(1+t))/4, ((1-s)*(1+t))/4 ];
};

~playTile = { arg tile, amps;
	if (amps.isNil) { amps = [0.25, 0.25, 0.25, 0.25] };
	~selectedTile = tile;
	{ w.refresh }.defer;

	for(0, 3, { arg i; var frq;
		frq = ~freqScale.value(tile, i) * ~freqRatioScalar;
		if (~oneOctave, { frq = ~singleOctave.value(frq) }, { frq = ~limitRange.value(frq) });
		frq = ~baseFreq * frq;
		Synth(\triangle, ["freq", frq, "out", i%o.numOutputBusChannels, "amp", sqrt(amps[i]*~ampRef)]);
	});
};
)


//====================================================================================================
// BOOT THE SERVER
//====================================================================================================
(
s.boot;

s.plotTree;

// create a new analyzer
FreqScope.new(400, 200, 0, server: s);

o = Server.default.options;

s.meter;
)


//====================================================================================================
// Synth definitions
//====================================================================================================
(
SynthDef(\triangle, {
	arg out=0, freq = 300, amp = 0.3, attack = 0.1, sustain = 0.5, release = 1.5;
	var numHarmonics = 30;
	var sig = 0, env;

	env = Env.linen(attack, sustain, release, amp, \welch).kr(doneAction: Done.freeSelf);

	sig = LFTri.ar(freq);
	sig = sig * env;
	Out.ar(out, sig); // ! 2); // Stereo output
}).add;
)


//====================================================================================================
// Create window and draw the tiling
//====================================================================================================
/*
As it currently stands, the vertices are scaled to the window.  To recover the original
vertex coordinates, it is necessary to re-read the file.
*/
(
w = Window.new("Penrose", Rect(100, 100, ~tileWindowSize,~tileWindowSize)).front;
w.view.background_(Color.white);

w.drawFunc = {
    // set the Color
	var clrs;

/*
From python code used to generate tiling

clrs = ['grey','limegreen','darkorange','grey','darkgrey','violet','deepskyblue','lightgrey',
 'firebrick',
 'lightgrey'
 ]*/

	clrs = Array.with(
		Color.new255(161, 161, 161, 200),
		Color.new255(50, 205, 50, 200),
		Color.new255(255, 140, 0, 200),
		Color.new255(141, 141, 141, 200),
		Color.new255(122, 122, 122, 200),
		Color.new255(148, 0, 211, 200),
		Color.new255(0, 191, 255, 200),
		Color.new255(161, 161, 161, 200),
		Color.new255(178, 34, 34, 200),
		Color.new255(161, 161, 161, 200)
	);


	Pen.strokeColor = Color.white;

	for (0,~verts.size-1,
		{
			arg i;
			var s, alpha, c;

			s = (sqrt(squared(~verts[i][6]-~verts[i][0])+squared(~verts[i][7]-~verts[i][1])) * sqrt(squared(~verts[i][4]-~verts[i][2])+squared(~verts[i][5]-~verts[i][3])))/2;
			// Next line needs to be generalized, instead of hard-code s>
			// if (s>1400, {Pen.fillColor = Color.red(0.8, 0.5);}, {Pen.fillColor = Color.cyan(0.5, 0.5);});
			alpha = if (~selectedTile < 0,
				{ 200 },
				{ if (i == ~selectedTile, { 255 }, { 80 }) }
			);
			c = clrs[~faces[i][0]].copy.alpha_(alpha / 255);
			Pen.fillColor = c;
			Pen.moveTo((~verts[i][0].asInteger)@(~verts[i][1].asInteger));
			Pen.lineTo((~verts[i][2].asInteger)@(~verts[i][3].asInteger));
			Pen.lineTo((~verts[i][6].asInteger)@(~verts[i][7].asInteger));
			Pen.lineTo((~verts[i][4].asInteger)@(~verts[i][5].asInteger));
			Pen.lineTo((~verts[i][0].asInteger)@(~verts[i][1].asInteger));
			Pen.draw(3);
		});

	// Diamond nodes (steel blue), Eikosany nodes (firebrick); drawn on top of tiles
	~diamondNodes.do { |pt|
		Pen.fillColor = Color.new255(70, 130, 180, 230);
		Pen.fillOval(Rect.aboutPoint(pt[0] @ pt[1], 5, 5));
	};
	~eikosanyNodes.do { |pt|
		Pen.fillColor = Color.new255(178, 34, 34, 230);
		Pen.fillOval(Rect.aboutPoint(pt[0] @ pt[1], 5, 5));
	};
	};

w.acceptsMouseOver = true;

w.refresh;

v = UserView(w, w.view.bounds);

v.mouseOverAction_(
	{
		arg v, ax, ay;

		x = ax; y = ay;
	}
);

v.mouseDownAction_(
	{
		arg v,ax,ay;
		var sTile, vs, x, y, in;
		var notes, noteNames, ratios, id, amps=[0.25,0.25,0.25,0.25];

		x = ax; y = ay;

		sTile = -1;
		ratios = Array.newClear(4);

		block { |break|
			for(0,~verts.size-1,
				{
					arg i;

					vs = [[~verts[i][0],~verts[i][1]],[~verts[i][2],~verts[i][3]],[~verts[i][6],~verts[i][7]],[~verts[i][4],~verts[i][5]]];
					if (~inside_convex_polygon.value([x,y],vs),
						{
							sTile=i;
							amps = ~ampScale.value(~verts[sTile],x,y);
							break.value(true)
						}
					);
				};
			);

			break.value(false);
		};

		if (sTile>(-1),
			{
				// Build ratios/notes for display
				for(0, 3, { arg i;
					var frq;
					frq = ~freqScale.value(sTile, i) * ~freqRatioScalar;
					if (~oneOctave, { frq = ~singleOctave.value(frq) }, { frq = ~limitRange.value(frq) });
					ratios[i] = frq;
				});

				~playTile.value(sTile, amps);
				id = ratios.order;
				ratios[id].asFraction(fasterBetter: true).postln;
			}
		);
	};
);

// Create a button, update with the current choices for the lattice

~button = Button(w,
	Rect(10, 550, 120, 40)
);

~button.string_(format("%",~latticeParameters[~currentInterval]));

~button.action_({
	~currentInterval = (~currentInterval+1) % ~latticeIntervals.size;
	~intervals = ~latticeIntervals[~currentInterval];
	~intervals.postln;
	~button.string_(format("%",~latticeParameters[~currentInterval]));
});

w.front;
)


//====================================================================================================
// CLEAN UP
//====================================================================================================
(
~button.free;
w.close;
)