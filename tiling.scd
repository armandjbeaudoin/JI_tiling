// Some options
(
~constantTone = false;    // use envelope, if false then constant oscillation (e.g. for modular)

s.boot;

s.plotTree;

// create a new analyzer
FreqScope.new(400, 200, 0, server: s);

o = Server.default.options;

)

~constantTone = true;

// for CLEAT system ========================================================================
// Execute the following lines to get access to the 24 output channels
// for windows.  MAKE SURE MOTU rate is set to rate Windows is expecting (it could be 44.1!)
// o.outDevice_("ASIO : MOTU Pro Audio");
/*(
/*o.numOutputBusChannels_(24);*/  // CLEAT

o.numOutputBusChannels_(4); // for Scarlett

// Execute this line after changing number of channels
Server.default.reboot;
)*/


o.numOutputBusChannels.postln;

// If the above worked, then outputs will appear in meter
s.meter;

//====================================================================================================
// Set up the midi, to send note-on & note-off to the Arturia Keystep, to get gate with modular
/*
MIDIClient.init;

MIDIClient.destinations;

// Needed something like this when connecting to the Keystep through USB
// m = MIDIOut(0,MIDIClient.destinations[1].uid);

// This works for use with midi cable from the Scarlett to Keystep
m = MIDIOut(0);
*/

//====================================================================================================
// Read the files for tiling and computer frequencies on dual graph

(
// ~indices = CSVFileReader.readInterpret("/Users/abeaudoi/Dropbox/Projects/super_collider/Tiling/indices_3a.txt").postcs;
// ~verts = CSVFileReader.readInterpret("/Users/abeaudoi/Dropbox/Projects/super_collider/Tiling/verts_3a.txt").postcs;


~indices = CSVFileReader.readInterpret("/Users/abeaudoi/Dropbox/Projects/super_collider/Tiling/indices_5Dprojection.txt").postcs;
~verts = CSVFileReader.readInterpret("/Users/abeaudoi/Dropbox/Projects/super_collider/Tiling/verts_5Dprojection.txt").postcs;
~faces = CSVFileReader.readInterpret("/Users/abeaudoi/Dropbox/Projects/super_collider/Tiling/faces_5Dprojection.txt").postcs;

~lattice_limit = {
	arg v;
	var xmn, xmx, ymn, ymx;

	xmn = 1e6;
	xmx = -1e6;
	ymn = 1e6;
	ymx = -1e6;

	for (1,v.size-1,
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
	var s;

	s = [(b[0]-1)/(l[1]-l[0]), (b[1]-1)/(l[3]-l[2])];

	for (0,v.size-1,
		{
			arg i;
			for (0,3,
				{
					arg j;

					v[i][2*j]     = (s[0]*(v[i][2*j]-l[0]));
					v[i][(2*j)+1] = (s[1]*(v[i][(2*j)+1]-l[2]));
				}
			);
		}
	);
};

~lim = ~lattice_limit.value(~verts);

// The next line OVERWRITES the lattice with translated & scaled lattice for plotting
~lattice_scale.value(~lim,[600,600],~verts);
)

//====================================================================================================
// Frequency (ratios)
/*
Set up the just intonation intervals for the 5D lattice.  The lattice is really a hyperplane in
4D, so use the ratio of 2 to eliminate one of the dimensions.

The lattice choices are arrays of strings in the variable ~latticeParameters, with the prefix "/"
to indicate an undertone.  There is logic to convert to fractions and place in the range of [1,2].
The reason for the strings is to make a clear presentation of the current choice of intervals
in the button (used to select different lattice parameter choices).
*/

(
~freqScale = {
	arg cell,node;
	var f = 1.0;
	for(0, 4, {arg i;
		f = f * (~intervals[i]**~indices[cell][(node*5)+i]);

	});
	f;
};

~singleOctave = {
	arg f;
	var r;

	r = f;
	while ( {r>2.0}, {r = r/2.0} );
	while ( {r<=1.0}, {r = r*2.0} );
	r
};

~latticeParameters = [
	["2", "3", "5", "7", "9"],
	["2", "3", "5", "7", "11"],
	["3", "5", "7", "9", "11"],
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
)

//====================================================================================================
// Identify the tile, and set relative amplitudes based on position selected within the tile
//
// Locate the tile containing the coordinate selected through use of cross product.
// From
// https://stackoverflow.com/questions/1119627/how-to-test-if-a-point-is-inside-of-a-convex-polygon-in-2d-integer-coordinates

(
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
	[s,t].postln;

	[ ((1-s)*(1-t))/4, ((1+s)*(1-t))/4, ((1+s)*(1+t))/4, ((1-s)*(1+t))/4 ];
};
)

//====================================================================================================
// Synth definitions

//a simple sine wave with envelope
(
SynthDef(\tone, {arg amp = 0.05, freq = 220, out = 0,
	attack = 0.1, sustain = 0.5, release = 1.5;
var env, snd;
env = Env.linen(attack, sustain, release, amp, \welch).kr(doneAction: Done.freeSelf);
	snd = SinOsc.ar(freq);
Out.ar(out, env*snd);
}).add;

SynthDef(\toneConstant, {
	arg amp = 0.05, freq = 220, out = 0;
	var snd;

	snd = SinOsc.ar(freq);
	Out.ar(out, amp*snd);
}).add;

//Carp Lust Wrong
SynthDef(\pluck, {arg out=0, amp = 0.05, wnamp=0.1, freq = 440, decay = 5, mutedString = 0.05;
var env, snd;
env = Env.linen(0, decay, 0).kr(doneAction: 2);
snd = Pluck.ar(
in: WhiteNoise.ar(wnamp),
trig: Impulse.kr(0),
maxdelaytime: 0.1,
delaytime: freq.reciprocal,
decaytime: decay,
coef: mutedString);
Out.ar(out, amp*snd);
}).add;

// Define the synth with three harmonics
SynthDef(\harmonicSynth, {
    arg out=0, freq = 440, amp = 0.3, attack = 0.1, sustain = 0.5, release = 1.5;
    var sig, env;

    // Create three harmonics (fundamental + 2 overtones)
    sig = SinOsc.ar(freq, 0, amp * 0.5) +      // Fundamental
          SinOsc.ar(freq * 2, 0, amp * 0.125) +  // 2nd harmonic
          SinOsc.ar(freq * 3, 0, amp * 0.075) +  // 3rd harmonic
	      SinOsc.ar(freq / 2, 0, amp * 0.125) +  // 2nd subharmonic
          SinOsc.ar(freq / 3, 0, amp * 0.075);   // 3rd subharmonic

    // Envelope for smooth attack and release
    // env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
	env = Env.linen(attack, sustain, release, amp, \welch).kr(doneAction: Done.freeSelf);

    sig = sig * env;

    Out.ar(out, sig ! 2); // Stereo output
}).add;

)

//====================================================================================================
// Start up the synths
//  Sets the reference base frequency.  Loads up an array of oscillators the will be used
//  if constantTone is .
(
~toneArray = Array.newClear(4);

~baseFreq = 261.63;

for (0,3,
	{
		arg i;
		var ap, op;

		if (o.numOutputBusChannels>2,{op=i;ap=0.1},{op=i%2;ap=0.05});
		if (~constantTone,
			{
				~toneArray[i] = Synth.new(\toneConstant, ["freq", ~baseFreq, "out", op, "amp", ap ]);
			}
		);
	}
);

)

//====================================================================================================
// Create window and draw the tiling
//
// As it currently stands, the vertices are scaled to the window.  To recover the original
// vertex coordinates, it is necessary to re-read the file.

(
// ~ampRef = 1.0;  // for modular
~ampRef = 0.25;   // for computer

w = Window.new("Penrose", Rect(600, 100, 600, 600)).front;
w.view.background_(Color.white);



w.drawFunc = {
    // set the Color
	var alpha=200, clrs;


/*
From python code used to generate tiling

clrs = ['grey','limegreen','darkorange','grey','darkgrey','violet','deepskyblue','lightgrey',
 'firebrick',
 'lightgrey'
 ]*/

	clrs = Array.with(
		Color.new255(161, 161, 161, alpha),
		Color.new255(50, 205, 50, alpha),
		Color.new255(255, 140, 0, alpha),
		Color.new255(161, 161, 161, alpha),
		Color.new255(122, 122, 122, alpha),
		Color.new255(148, 0, 211, alpha),
		Color.new255(0, 191, 255, alpha),
		Color.new255(207, 207, 207, alpha),
		Color.new255(178, 34, 34, alpha),
		Color.new255(207, 207, 207, alpha)
	);


	Pen.strokeColor = Color.white;

	for (0,~verts.size-1,
		{
			arg i;
			var s;

			s = (sqrt(squared(~verts[i][6]-~verts[i][0])+squared(~verts[i][7]-~verts[i][1])) * sqrt(squared(~verts[i][4]-~verts[i][2])+squared(~verts[i][5]-~verts[i][3])))/2;
			[i,s].postln;
			// Next line needs to be generalized, instead of hard-code s>
			// if (s>1400, {Pen.fillColor = Color.red(0.8, 0.5);}, {Pen.fillColor = Color.cyan(0.5, 0.5);});
			Pen.fillColor = clrs[~faces[i][0]];
			Pen.moveTo((~verts[i][0].asInteger)@(~verts[i][1].asInteger));
			Pen.lineTo((~verts[i][2].asInteger)@(~verts[i][3].asInteger));
			Pen.lineTo((~verts[i][6].asInteger)@(~verts[i][7].asInteger));
			Pen.lineTo((~verts[i][4].asInteger)@(~verts[i][5].asInteger));
			Pen.lineTo((~verts[i][0].asInteger)@(~verts[i][1].asInteger));
			Pen.draw(3);
		});
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
		var s, vs, x, y, in;
		var notes, noteNames, ratios, id, amps=[0.25,0.25,0.25,0.25];

		x = ax; y = ay;
		s = -1;
		notes = Array.newClear(4);
		ratios = Array.newClear(4);
		noteNames = Array.with('C','C#','D','D#','E','F','F#','G','G#','A','A#','B','C');

		// m.noteOn(16,60,60);
		block { |break|
			for(0,~verts.size-1,
				{
					arg i;

					vs = [[~verts[i][0],~verts[i][1]],[~verts[i][2],~verts[i][3]],[~verts[i][6],~verts[i][7]],[~verts[i][4],~verts[i][5]]];
					if (~inside_convex_polygon.value([x,y],vs),
						{
							s=i;
							amps = ~ampScale.value(~verts[s],x,y);
							amps.postln;
							break.value(true)
						}
					);
				};
			);

			break.value(false);
		};

		if (s>(-1),
			{
				for(0,3,
					{
						arg i;
						var frq, id;

						frq = ~freqScale.value(s,i);
						// frq = ~singleOctave.value(frq);
						ratios[i] = frq;
						notes[i] = noteNames[ round(12*log2(~singleOctave.value(frq))).asInteger ];
						frq = ~baseFreq*frq;

						if (~constantTone,
							{
								~toneArray[i].set(\freq, frq, \amp, amps[i]*~ampRef);  // for modular
							},
							{
								//Synth(\tone, ["freq", frq, "out", i%o.numOutputBusChannels, "amp", amps[i]*~ampRef ] );
								Synth(\harmonicSynth, ["freq", frq, "out", i%o.numOutputBusChannels, "amp", amps[i]*~ampRef ] );
							}
						);
					}
				);
				id = ratios.order;
				ratios[id].postln;
				notes[id].postln;
			}
		);
		// m.noteOff(16,60,60);
	};
);

// Create a button, update with the current choices for the lattice

~button = Button(w,
	Rect(10, 10, 120, 40)
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


~ampRef=0.25;

// CLEAN UP
(
~button.free;
w.close;
)

(
for (0,3,
	{
		arg i;

		~toneArray[i].free;
	}
);
)
