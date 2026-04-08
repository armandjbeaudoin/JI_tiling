/*
There are several blocks to run in order:

   1. Options
   2. Global variables & functions (data, JI, geometry)
   3. Boot the server
   4. Audio buses (vocoder mode only)
   5. Synth definitions
   6. OSC initialization
   7. MIDI initialization (not currently used)
   8. Start synth instances
   9. Create window
  10. Clean up
*/

//====================================================================================================
// OPTIONS
//====================================================================================================
(
~baseFreq = 261.63/2;        // reference frequency for unity
~ampRef = 0.9;             // reference amplification

~constantTone = false; //true;     // constant tone, for use with modular and vocoder
~vocoderMode = false; // true;      // true = software vocoder (requires ~constantTone = true)
~vocoderAmp = 2.0;        // carrier pre-gain; compensates for power loss through narrow BPF bands (rq=0.05 passes ~6x less energy than rq=0.3)

~modulo2 = false;          // points along axis are taken as [...-1,0,-1,0,1,0,1,...]
~oneOctave = false;        // restrict frequencies to a single octave

~selectedTile = -1;        // index of currently highlighted tile (-1 = none)
)

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

	for(0, 3, { arg i;
		var frq;
		frq = ~freqScale.value(tile, i);
		if (~oneOctave, { frq = ~singleOctave.value(frq) });
		frq = ~baseFreq * frq;

		if (~vocoderMode) {
			~toneArray[i].set(\freq, frq);
			~vocoderArray[i].set(\amp, sqrt(amps[i] * ~ampRef));
		} {
			if (~constantTone,
				{ ~toneArray[i].set(\freq, frq, \amp, sqrt(amps[i]*~ampRef)); },
				{ Synth(\triangle, ["freq", frq, "out", i%o.numOutputBusChannels, "amp", amps[i]*~ampRef]); }
			);
		};
	});
};
)

//====================================================================================================
// BOOT THE SERVER
//====================================================================================================
/*
This is coded in an interactive fashion, because of the different types of equipment that may
be used.
*/
(
s.boot;

s.plotTree;

// create a new analyzer
FreqScope.new(400, 200, 0, server: s);

o = Server.default.options;

)

// for 4 channels
(
o.numOutputBusChannels_(4); // for Scarlett

// Execute this line after changing number of channels
Server.default.reboot;
)

o.numOutputBusChannels.postln;

// If the above worked, then outputs will appear in meter
s.meter;

s.scope.window.bounds_(Rect(1000,50,300,900));

// To use other devices:
ServerOptions.devices; // all devices
ServerOptions.inDevices; // input devices
ServerOptions.outDevices; // output devices

Server.default.options.inDevice_("Scarlett 8i6 USB");     // Scarlett
Server.default.options.outDevice_("Scarlett 8i6 USB");    // for both output and input (sample rate of 44100)
Server.default.reboot;

s.quit;  // to quit the server

//====================================================================================================
// Audio buses and node groups — evaluate only when ~vocoderMode = true
//====================================================================================================
(
if (~vocoderMode) {
	~modBus     = Bus.audio(s, 1);
	~carrierBus = Array.fill(4, { Bus.audio(s, 1) });
	~srcGroup     = Group.new(s, \addToHead);
	~vocoderGroup = Group.after(~srcGroup);
};
)

//====================================================================================================
// Synth definitions
//====================================================================================================
(
// Vocoder SynthDefs — only needed when ~vocoderMode = true
if (~vocoderMode) {

	// Reads live mic (hardware input 0) and writes it to ~modBus so all
	// vocoder units share a single SoundIn instance.
	SynthDef(\modulator, {
		arg out = 0, amp = 1.0;
		Out.ar(out, SoundIn.ar(0) * amp);
	}).add;

	// Carrier oscillator: JI-tuned triangle wave written to a per-voice ~carrierBus[i].
	// Fold.ar clips the LFTri waveform at ±0.75, then rescales to ±1, producing
	// a brighter, more saturated triangle with stronger upper harmonics — useful as a
	// vocoder carrier because it spreads energy across many harmonics for the bandpass
	// filters to sculpt.  Adjust the -/+ arguments in Fold to specify amound of folding.
	SynthDef(\carrierVocode, {
		arg out = 0, freq = 220, amp = 0.5, lag = 0.0, fld = 0.75;
		var sig, laggedFreq;

		laggedFreq = VarLag.kr(freq, lag, -8);

		sig =  0.6  * (1.0/fld) * Fold.ar(LFTri.ar(laggedFreq),     fld.neg, fld) +  // Fundamental
		       0.25 * (1.0/fld) * Fold.ar(LFTri.ar(laggedFreq * 2), fld.neg, fld) +  // 2nd harmonic
		       0.05 * (1.0/fld) * Fold.ar(LFTri.ar(laggedFreq * 3), fld.neg, fld) +  // 3rd harmonic
		       0.1  * (1.0/fld) * Fold.ar(LFTri.ar(laggedFreq * 4), fld.neg, fld);   // 4th harmonic

		Out.ar(out, amp * sig);
	}).add;

	// Channel vocoder: imposes the spectral envelope of the modulator (speech/mic) onto
	// one JI carrier oscillator.
	//
	// Signal flow per band k:
	//   1. BPF the modulator signal → extract energy in that frequency band
	//   2. Amplitude.ar follows the band's loudness with a fast attack (catches consonants)
	//      and a slow release (smooths vowel transitions)
	//   3. BPF the carrier at the same centre frequency → isolate carrier harmonics in band k
	//   4. Multiply carrier band by the modulator envelope → transfer speech formants to carrier
	//   5. Mix.fill sums all bands into a single output signal
	//
	// rq (reciprocal of Q) = 0.05 → Q ≈ 20.  Narrow bands are essential: wide bands (rq > 0.2)
	// blend all frequency content together and the vocoder degenerates into simple AM.
	//
	// Frequency grid: 32 bands spaced geometrically from 100 Hz to ~8 kHz (ratio 80^(1/31) ≈ 1.16).
	// With rq = 0.07 (Q ≈ 14), each band's -3 dB width is ~7% of its centre frequency.
	// Adjacent bands are ~16% apart, so bands overlap slightly at their edges — good spectral
	// tiling without the intelligibility loss of wider filters.
	// The ~vocoderAmp carrier pre-gain and the amp argument here jointly compensate for the
	// power loss introduced by narrow bandpass filtering.
	SynthDef(\vocoderUnit, {
		arg modBus = 0, carrierBus = 1, out = 0, amp = 1.0;
		var mod, carrier, sig;
		var numBands = 32;
		var freqs = Array.geom(numBands, 100, 80 ** (1/31));  // 100 Hz to ~8 kHz, 32 bands

		mod     = In.ar(modBus);
		carrier = In.ar(carrierBus);

		sig = Mix.fill(numBands, { |k|
			var modBand, carrierBand, env;
			modBand     = BPF.ar(mod,     freqs[k], 0.07,3.0);  // analyse speech spectrum
			carrierBand = BPF.ar(carrier, freqs[k], 0.07,3.0);  // isolate matching carrier harmonics
			env = Amplitude.ar(modBand, attackTime: 0.005, releaseTime: 0.1);  // envelope follower
			carrierBand * env;                                                  // transfer formant
		});

		Out.ar(out, sig * amp);
	}).add;
};

SynthDef(\toneConstant, {
	arg amp = 0.05, freq = 220, out = 0, lag = 0.0, fld=0.9;
	var snd, laggedFreq;

	// The lag of -8 was taken from Fieldsteel video of large projects @9:45
	// https://www.youtube.com/watch?v=wC-bj7Ajvhs&t=1963s
	// sounds less sweepy than the default
	laggedFreq = VarLag.kr(freq, lag,-8);
	// Create three harmonics (fundamental + 2 overtones)
	// snd = SinOsc.ar(laggedFreq);
	snd = (1.0/fld)*Fold.ar(LFTri.ar(laggedFreq),fld.neg,fld);
	Out.ar(out, amp*snd);
}).add;

SynthDef(\triangle, {
	arg out=0, freq = 300, amp = 0.3, attack = 0.1, sustain = 0.5, release = 1.5;
	var numHarmonics = 30;
	var sig = 0, env;

	env = Env.linen(attack, sustain, release, amp, \welch).kr(doneAction: Done.freeSelf);

	for(1, numHarmonics, {
		|i|
		var n = 2 * i - 1; // Create the harmonic number
		var phase = if(i % 2 == 0, {0}, {pi}); // Alternate phase - a conditional is an expression
		sig = sig + SinOsc.ar(freq * n, phase, amp * (1/n.squared));

	});
	sig = sig * env;
	Out.ar(out, sig); // ! 2); // Stereo output
}).add;
)

//====================================================================================================
// OSC
//====================================================================================================
(
~tileTones = OSCFunc(
	{
		arg msg, time, addr, recvPort;
		var tile;

		tile = msg[1].asInteger - 1;

		~playTile.value(tile, nil);
	},
	'/Tile');

~lagSlider = OSCFunc(
	{
		arg msg, time, addr, recvPort;
		var lg;

		lg = 8*msg[1];
		~toneArray.do(_.set(\lag, lg));
	},
	'/lag');

~foldSlider = OSCFunc(
	{
		arg msg, time, addr, recvPort;
		var fl;

		fl = 0.5+(0.5*msg[1]);
		~toneArray.do(_.set(\fld, fl));
	},
	'/fold');
)

// Free the OSC function
(
~tileTones.free;
~lagSlider.free;
~foldSlider.free;
)
// Some code for debugging the OSC connection

// OSCFunc.trace(true);
// OSCFunc.trace(false);
// basically like OSCFunc.trace but filters out /status.reply messages

(
f = { |msg, time, addr, recvPort|
	if (msg[0] != '/status.reply') {
        "time: % sender: % recvPort: %\n  message: %\n".postf(time, addr, recvPort, msg);
    }
};
thisProcess.addOSCRecvFunc(f);
)

// stop posting.
thisProcess.removeOSCRecvFunc(f);

//====================================================================================================
// Set up the midi, to send note-on & note-off to the Arturia Keystep, to get gate with modular
//====================================================================================================
/*
MIDIClient.init;

MIDIClient.destinations;

// Needed something like this when connecting to the Keystep through USB
// m = MIDIOut(0,MIDIClient.destinations[1].uid);

// This works for use with midi cable from the Scarlett to Keystep
m = MIDIOut(0);
*/

//====================================================================================================
// Start up the synths
//====================================================================================================
//  Sets the reference base frequency.  Loads up an array of oscillators the will be used
(
~toneArray = Array.newClear(4);

if (~vocoderMode) {
	// Software vocoder: modulator (mic), carriers, and vocoder units
	~modSynth = Synth(\modulator, [\out, ~modBus], ~srcGroup);

	for (0, 3, { |i|
		~toneArray[i] = Synth(\carrierVocode, [\freq, ~baseFreq, \amp, ~vocoderAmp, \out, ~carrierBus[i]], ~srcGroup);
	});

	~vocoderArray = Array.newClear(4);
	for (0, 3, { |i|
		var op;
		op = if (o.numOutputBusChannels > 2, { i }, { i % 2 });
		~vocoderArray[i] = Synth(\vocoderUnit, [
			\modBus,     ~modBus.index,
			\carrierBus, ~carrierBus[i].index,
			\out,        op,
			\amp,        1.0
		], ~vocoderGroup);
	});
} {
	// Standard / hardware-vocoder startup
	for (0, 3, {
		arg i;
		var ap, op;

		if (o.numOutputBusChannels>2,{op=i;ap=0.1},{op=i%2;ap=0.15});
		if (~constantTone,
			{
				~toneArray[i] = Synth.new(\toneConstant, ["freq", ~baseFreq, "out", op, "amp", ap ]);
				~toneArray[i].set(\lag, 0.5);
			}
		);
	});
};
)

//====================================================================================================
// Create window and draw the tiling
//====================================================================================================
/*
As it currently stands, the vertices are scaled to the window.  To recover the original
vertex coordinates, it is necessary to re-read the file.
*/
(
w = Window.new("Penrose", Rect(600, 100, 600, 600)).front;
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

		// DO NOT RE-DEFINE s HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! CHANGE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
							break.value(true)
						}
					);
				};
			);

			break.value(false);
		};

		if (s>(-1),
			{
				// Build ratios/notes for display
				for(0, 3, { arg i;
					var frq;
					frq = ~freqScale.value(s, i);
					if (~oneOctave, { frq = ~singleOctave.value(frq) });
					ratios[i] = frq;
					notes[i] = noteNames[ round(12*log2(~singleOctave.value(frq))).asInteger ];
				});

				~playTile.value(s, amps);

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


// CLEAN UP
(
~button.free;
w.close;

if (~vocoderMode) {
	~modSynth.free;
	~vocoderArray.do(_.free);
	~toneArray.do(_.free);
	// To also free buses: ~modBus.free; ~carrierBus.do(_.free);
} {
	~toneArray.do(_.free);
};
)

~toneArray.do(_.set(\fld, 0.8))

s.record // start again

s.stopRecording;

thisProcess.platform.recordingsDir