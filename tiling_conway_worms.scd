//====================================================================================================
// CONWAY WORMS — zigzag walk that plays tiles along Conway worms in the Penrose tiling.
//
// Inspect, then paste these blocks into tiling_simple.scd AFTER the existing block that creates the
// window (the one that ends with `w.front;`).  Requires the globals already defined there:
//
//     ~verts, ~indices, ~faces, ~playTile, w
//
// What it does
// ------------
// A Conway worm is a chain of adjacent rhombic tiles that share parallel edges of a single basis
// direction.  Each tile belongs to exactly two worms — one for each axis of its face pair (j,k).
// `~playWormWalk` starts at a boundary tile, follows a worm inward until it hits another boundary
// tile, then switches to that tile's OTHER worm direction and continues.  This repeats for `maxLegs`.
//
// Data layout reminder (see notebooks/penrose5D.ipynb):
//     Storage corner order is [base, base+e_j, base+e_k, base+e_j+e_k] where (j,k) = ~spans[face].
//     Axis-j edges → storage-corner pairs (0,1) and (2,3).
//     Axis-k edges → storage-corner pairs (0,2) and (1,3).
//====================================================================================================


//====================================================================================================
// 1. Build worm adjacency.  Run once after tiling_simple.scd has loaded ~verts/~indices/~faces.
//====================================================================================================
(
// Face direction (0..9) -> (j,k).  Matches Python: subSet([0,1,2,3,4], 2).
~spans = [
	[0,1], [0,2], [0,3], [0,4],
	[1,2], [1,3], [1,4],
	[2,3], [2,4], [3,4]
];

// For each axis-slot (0 or 1) inside a face pair, the two storage-corner pairs that form
// the two parallel edges of that worm direction.
~tileEdgePairs = [
	[[0,1], [2,3]],   // axis-slot 0 (j-direction)
	[[0,2], [1,3]]    // axis-slot 1 (k-direction)
];

// Canonical string key for a corner's 5D lattice index.
~cornerKey = { arg tile, corner;
	var o = corner * 5;
	(~indices[tile][o].asInteger.asString ++ "_"
	++ ~indices[tile][o+1].asInteger.asString ++ "_"
	++ ~indices[tile][o+2].asInteger.asString ++ "_"
	++ ~indices[tile][o+3].asInteger.asString ++ "_"
	++ ~indices[tile][o+4].asInteger.asString)
};

// Canonical key for one of a tile's edges (sorted endpoints so both incident tiles agree).
~edgeKey = { arg tile, axis, edge;
	var pair = ~tileEdgePairs[axis][edge];
	var a = ~cornerKey.value(tile, pair[0]);
	var b = ~cornerKey.value(tile, pair[1]);
	if (a < b, { a ++ "|" ++ b }, { b ++ "|" ++ a })
};

// Build:
//   ~tileNeighbors[tile][axis][edge] -> neighborTileId or nil
//   ~tileBoundary[tile] -> true iff any of its 4 edges has no neighbor
~buildWormAdjacency = {
	var nTiles = ~verts.size;
	var edgeMap = Dictionary.new(nTiles * 4);

	~tileNeighbors = Array.fill(nTiles, { Array.fill(2, { Array.fill(2, { nil }) }) });
	~tileBoundary  = Array.fill(nTiles, { false });

	// Index every (tile, axis, edge) by its canonical edge key.
	nTiles.do { arg i;
		2.do { arg axis;
			2.do { arg edge;
				var k = ~edgeKey.value(i, axis, edge);
				var entry = [i, axis, edge];
				if (edgeMap[k].isNil,
					{ edgeMap[k] = [entry] },
					{ edgeMap[k] = edgeMap[k].add(entry) }
				);
			};
		};
	};

	// Each key should map to 1 (boundary) or 2 (interior) entries.
	edgeMap.keysValuesDo { arg k, entries;
		if (entries.size == 2, {
			var e0 = entries[0], e1 = entries[1];
			~tileNeighbors[e0[0]][e0[1]][e0[2]] = e1[0];
			~tileNeighbors[e1[0]][e1[1]][e1[2]] = e0[0];
		});
	};

	// A tile is a boundary tile if any of its 4 edge slots is nil.
	nTiles.do { arg i;
		var isBnd = false;
		2.do { arg ax;
			2.do { arg ed;
				if (~tileNeighbors[i][ax][ed].isNil, { isBnd = true });
			};
		};
		~tileBoundary[i] = isBnd;
	};

	("Worm adjacency built.  Boundary tiles: "
		++ ~tileBoundary.count(_ == true) ++ " / " ++ nTiles).postln;
};

~buildWormAdjacency.value;
)


//====================================================================================================
// 2. Walk a single worm leg.
//    Starts at `startTile`, exits through edge (startAxis, startEdge), and steps neighbor-to-neighbor
//    along that worm until the worm itself terminates — i.e. the current tile's exit edge has no
//    neighbor.  By construction the leg's final tile is then an edge cell of THIS worm; it does NOT
//    need to be on the boundary of the perpendicular worm.  Returns [startTile, t1, t2, ..., tN].
//====================================================================================================
(
~walkWormLeg = { arg startTile, startAxis, startEdge;
	var path     = [startTile];
	var curTile  = startTile;
	var curAxis  = startAxis;
	var exitEdge = startEdge;
	var safety   = 5000;

	block { arg break;
		loop {
			var nextTile, basis, nextFace, nextAxis, sharedKey, entryEdge;

			nextTile = ~tileNeighbors[curTile][curAxis][exitEdge];
			// Worm ends — curTile is this worm's edge cell.
			if (nextTile.isNil, { break.value(nil) });

			// The shared edge lives along basis axis `basis`.  Find which slot (0 or 1)
			// of nextTile's face holds that same basis axis.
			basis    = ~spans[~faces[curTile][0]][curAxis];
			nextFace = ~spans[~faces[nextTile][0]];
			nextAxis = if (nextFace[0] == basis, { 0 }, { 1 });

			// Which of nextTile's two parallel worm-edges is the one we crossed?
			sharedKey = ~edgeKey.value(curTile, curAxis, exitEdge);
			entryEdge = nil;
			2.do { arg ed;
				if (~edgeKey.value(nextTile, nextAxis, ed) == sharedKey, { entryEdge = ed });
			};
			if (entryEdge.isNil, { break.value(nil) });   // shouldn't happen, but be safe

			// Exit through the OTHER parallel edge of nextTile.
			path     = path.add(nextTile);
			curTile  = nextTile;
			curAxis  = nextAxis;
			exitEdge = 1 - entryEdge;

			safety = safety - 1;
			if (safety <= 0, { "walkWormLeg: safety limit hit".postln; break.value(nil) });
		};
	};
	path
};

// Helpers — pick an inward edge (one whose neighbor exists) at a boundary tile.
~axisHasInward = { arg tile, axis;
	~tileNeighbors[tile][axis][0].notNil or: { ~tileNeighbors[tile][axis][1].notNil }
};

~inwardEdge = { arg tile, axis;
	if (~tileNeighbors[tile][axis][0].notNil, { 0 },
		{ if (~tileNeighbors[tile][axis][1].notNil, { 1 }, { nil }) })
};
)


//====================================================================================================
// 3. Zigzag walk.  At every boundary tile encountered, switch to the OTHER worm direction.
//
//   ~playWormWalk.value;                                    // random boundary, default cadence
//   ~playWormWalk.value(startTile: 0);                      // start at a specific tile
//   ~playWormWalk.value(startTile: 0, period: 0.15, maxLegs: 20);
//   ~stopWormWalk.value;                                    // stop a running walk
//====================================================================================================
(
~wormWalkTask = nil;

~stopWormWalk = {
	if (~wormWalkTask.notNil, {
		~wormWalkTask.stop;
		~wormWalkTask = nil;
		~selectedTile = -1;
		{ w.refresh }.defer;
		"worm walk stopped".postln;
	});
};

~playWormWalk = { arg startTile, startAxis, period = 0.25, maxLegs = 12;
	var boundaryTiles;

	~stopWormWalk.value;

	if (startTile.isNil, {
		boundaryTiles = (0..~verts.size-1).select { arg i; ~tileBoundary[i] };
		if (boundaryTiles.isEmpty, { "No boundary tiles found.".postln });
		startTile = boundaryTiles.choose;
	});

	if (startAxis.isNil, {
		startAxis = if (~axisHasInward.value(startTile, 0), { 0 },
			{ if (~axisHasInward.value(startTile, 1), { 1 }, { nil }) });
	});

	if (startAxis.isNil, {
		("Start tile " ++ startTile ++ " has no inward neighbors; nothing to do.").postln;
	}, {
		("Starting worm walk at tile " ++ startTile
			++ "  face=" ++ ~spans[~faces[startTile][0]]
			++ "  axis=" ++ startAxis
			++ "  basis=" ++ ~spans[~faces[startTile][0]][startAxis]).postln;

		~wormWalkTask = Routine {
			var curTile = startTile;
			var axis    = startAxis;
			var edge    = ~inwardEdge.value(curTile, axis);
			var leg     = 0;

			block { arg break;
				while ({ leg < maxLegs }, {
					var path, startIdx, walkBasis, endFace, endSlot;
					leg = leg + 1;

					if (edge.isNil, {
						("dead end at tile " ++ curTile
							++ " — no inward neighbor on axis " ++ axis).postln;
						break.value(nil);
					});

					// Remember the basis-axis (0..4) of the worm we are about to walk.
					// It stays constant for the whole leg, even though the axis-slot
					// (0 or 1 within each tile's face pair) may change tile-to-tile.
					walkBasis = ~spans[~faces[curTile][0]][axis];

					path = ~walkWormLeg.value(curTile, axis, edge);
					("leg " ++ leg
						++ "  basis=" ++ walkBasis
						++ "  start=" ++ curTile
						++ "  end="   ++ path.last
						++ "  tiles=" ++ path.size).postln;

					// On leg 1 play the whole path; on later legs skip path[0] because it
					// is the same boundary tile that ended the previous leg (already played).
					startIdx = if (leg == 1, { 0 }, { 1 });
					(startIdx..path.size-1).do { arg i;
						~playTile.value(path[i], nil);
						period.wait;
					};

					// Move to leg's end tile, then switch to its OTHER worm direction —
					// i.e. the basis-axis in the end tile's face pair that is NOT walkBasis.
					// Computing this from the END tile (not the start tile) is what guarantees
					// we always step onto a different worm; flipping the slot relative to the
					// start tile can leave us on the same worm when face pairs of start and
					// end tiles place walkBasis in different slots.
					curTile = path.last;
					endFace = ~spans[~faces[curTile][0]];
					endSlot = if (endFace[0] == walkBasis, { 0 }, { 1 });
					axis    = 1 - endSlot;
					edge    = ~inwardEdge.value(curTile, axis);
				});
			};
			"worm walk done".postln;
			~wormWalkTask = nil;
		}.play(AppClock);
	});
};
)

~playWormWalk.value(startTile: 0, period: 0.2, maxLegs: 20);

//====================================================================================================
// 4. (Optional) Silent inspector — highlight one worm leg without playing audio.
//    Useful for visualising which tiles belong to a single worm.
//====================================================================================================
(
~showWormLeg = { arg startTile, axis = 0, edge, stepSec = 0.15;
	var path;
	edge = edge ? ~inwardEdge.value(startTile, axis) ? 0;
	path = ~walkWormLeg.value(startTile, axis, edge);
	("worm tiles (" ++ path.size ++ "): " ++ path).postln;
	path.do { arg t, i;
		AppClock.sched(i * stepSec, {
			~selectedTile = t;
			{ w.refresh }.defer;
			nil
		});
	};
	path
};
)
