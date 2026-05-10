//====================================================================================================
// Eikosany on the Hexadic Diamond — Sonification
//
// Reads Data/eikosany_diamond.json (written by notebooks/eikosany_diamond_coxeter.ipynb).
// 141 distinct 5D positions from the 20-variant Eikosany overlay on the Hexadic Diamond.
// Click any point: the nearest one plays as an octave-reduced JI ratio above ~baseFreq.
//
// Colors:  grey   = diamond  (31)
//          blue   = outer-ring family Eikosany   (80)
//          red    = inner-ring family only        (30)
//====================================================================================================


//====================================================================================================
// OPTIONS
//====================================================================================================
(
~baseFreq      = 261.63;       // reference frequency for unison (Hz)
~ampRef        = 0.3;          // amplitude scale
~windowSize    = 700;          // window pixel size
~margin        = 40;           // window margin
~selectedPoint = -1;           // -1 = none highlighted
)


//====================================================================================================
// LOAD DATA
//====================================================================================================
(
~dir = thisProcess.nowExecutingPath.dirname +/+ "Data/";
~jsonData = File.readAllString(~dir ++ "eikosany_diamond.json").parseJSON;

~baseFreq = ~jsonData["baseFreq"].asFloat;
~xRaw     = ~jsonData["x"].collect(_.asFloat);
~yRaw     = ~jsonData["y"].collect(_.asFloat);
~nums     = ~jsonData["num"].collect(_.asInteger);
~dens     = ~jsonData["den"].collect(_.asInteger);
~upStrs   = ~jsonData["primes_up"];
~dnStrs   = ~jsonData["primes_dn"];
~cats     = ~jsonData["category"];
~nPts     = ~xRaw.size;

("Loaded " ++ ~nPts ++ " points  (baseFreq = " ++ ~baseFreq ++ " Hz)").postln;
)


//====================================================================================================
// SCALE COORDINATES TO WINDOW
//====================================================================================================
(
var xmn, xmx, ymn, ymx, sx, sy, scl, ox, oy, inner;

xmn = ~xRaw.minItem; xmx = ~xRaw.maxItem;
ymn = ~yRaw.minItem; ymx = ~yRaw.maxItem;
inner = ~windowSize - (2 * ~margin);

sx  = inner / (xmx - xmn);
sy  = inner / (ymx - ymn);
scl = if (sx < sy, { sx }, { sy });
ox  = ~margin + ((inner - (scl * (xmx - xmn))) / 2);
oy  = ~margin + ((inner - (scl * (ymx - ymn))) / 2);

~xs = ~xRaw.collect { |x| ox + (scl * (x   - xmn)) };
~ys = ~yRaw.collect { |y| oy + (scl * (ymx - y))   };   // flip vertical
)


//====================================================================================================
// HELPERS
//====================================================================================================
(
~singleOctave = { |f|
    var r = f;
    while ({ r >= 2.0 }, { r = r / 2.0 });
    while ({ r <  1.0 }, { r = r * 2.0 });
    r
};

~nearestPoint = { |x, y|
    var bestIdx = -1, bestDist = inf;
    ~nPts.do { |i|
        var d = ((~xs[i] - x).squared + (~ys[i] - y).squared).sqrt;
        if (d < bestDist, { bestDist = d; bestIdx = i; });
    };
    bestIdx
};

~categoryColor = { |c|
    if (c == "diamond",
        { Color.new255(140, 140, 140, 220) },
        { if (c == "outer",
            { Color.new255( 50, 100, 220, 220) },     // blue
            { Color.new255(220,  50,  50, 220) }      // red (inner)
        )}
    )
};
)


//====================================================================================================
// BOOT THE SERVER
//====================================================================================================
(
s.boot;
FreqScope.new(400, 200, 0, server: s);
o = Server.default.options;
s.meter;
)


//====================================================================================================
// SYNTH DEF
//====================================================================================================
(
SynthDef(\triangle, {
    arg out = 0, freq = 300, amp = 0.3, attack = 0.05, sustain = 0.3, release = 1.0;
    var sig, env;
    env = Env.linen(attack, sustain, release, amp, \welch).kr(doneAction: Done.freeSelf);
    sig = LFTri.ar(freq) * env;
    Out.ar(out, sig);
}).add;
)


//====================================================================================================
// WINDOW + DRAW + CLICK
//====================================================================================================
(
w = Window.new("Eikosany–Diamond", Rect(100, 100, ~windowSize, ~windowSize)).front;
w.view.background_(Color.white);

w.drawFunc = {
    ~nPts.do { |i|
        var c, alpha, sz;
        alpha = if (~selectedPoint < 0,
            { 200 },
            { if (i == ~selectedPoint, { 255 }, { 80 }) }
        );
        c  = ~categoryColor.value(~cats[i]).copy.alpha_(alpha / 255);
        sz = if (i == ~selectedPoint, { 8 }, { 4 });
        Pen.fillColor = c;
        Pen.fillOval(Rect.aboutPoint(~xs[i] @ ~ys[i], sz, sz));
    };
};

w.refresh;

v = UserView(w, w.view.bounds);

v.mouseDownAction_({ |v, ax, ay|
    var idx, ratio, frq, up, dn;
    idx   = ~nearestPoint.value(ax, ay);
    ratio = ~nums[idx] / ~dens[idx];
    frq   = ~baseFreq * ~singleOctave.value(ratio);
    ~selectedPoint = idx;
    { w.refresh }.defer;
    Synth(\triangle, ["freq", frq, "amp", ~ampRef, "out", 0]);
    up = if (~upStrs[idx] == "—", { "1" }, { ~upStrs[idx] });
    dn = if (~dnStrs[idx] == "—", { "1" }, { ~dnStrs[idx] });
    (~nums[idx].asString ++ "/" ++ ~dens[idx].asString
        ++ "   [" ++ up ++ " / " ++ dn ++ "]"
        ++ "   → " ++ frq.round(0.01) ++ " Hz"
        ++ "   (" ++ ~cats[idx] ++ ")").postln;
});

w.front;
)

(1.).postln;
1.asString++2.asString
//====================================================================================================
// CLEAN UP
//====================================================================================================
(
w.close;
)
