#!/usr/bin/env wolframscript
(* ::Package:: *)

(*  build_real_gmv.wls
    -----------------
    Build a REAL Ground Motion Visualization of the 2025-03-28 Mandalay
    M7.7 (USGS us7000pn9s) across the European broadband network, using
    actual LHZ (1 sps) waveforms fetched from FDSN / IRIS-EarthScope and
    the library's gmvFrame renderer (flat country-border basemap).

    Writes docs/images/RealSeismicGMV.mp4 (full) and docs/images/
    real_gmv.gif (downsampled, embedded in the notebook). Per-station
    waveforms are cached under data/gmv_waveforms/.

    Data: FDSN networks GE, II, IU, MN, CH, SL, ... (see data/
    eu_stations_raw.txt). Requires internet. Run:
        wolframscript -file wolfram/build_real_gmv.wls
*)

$ProgressReporting = False;
scriptDir = DirectoryName[$InputFileName];
repoRoot  = ParentDirectory[scriptDir];
libDir    = FileNameJoin[{repoRoot, "community"}];
dataDir   = FileNameJoin[{repoRoot, "data"}];
wfDir     = FileNameJoin[{dataDir, "gmv_waveforms"}];
imgDir    = FileNameJoin[{repoRoot, "docs", "images"}];
If[!DirectoryQ[wfDir], CreateDirectory[wfDir, CreateIntermediateDirectories -> True]];

Print["Loading library..."];
SetDirectory[libDir]; Quiet @ Get["SeismicWavePropagation.wl"];

originStr = "2025-03-28T06:20:52";
endStr    = "2025-03-28T07:11:00";       (* origin + ~50 min *)
base = "https://service.iris.edu/irisws/timeseries/1/query";

parseTSPAIR[body_] := Module[{tbl},
  tbl = Quiet @ ImportString[body, "Table"];
  tbl = Select[tbl, Length[#] == 2 && NumericQ[#[[2]]] &];
  If[tbl === {}, $Failed, tbl[[All, 2]]]];

fetchLHZ[nt_, st_] := Catch[Module[{r},
  Do[
    r = Quiet @ URLRead[HTTPRequest[base, <|"Query" -> {
        "net" -> nt, "sta" -> st, "loc" -> lc, "cha" -> "LHZ",
        "starttime" -> originStr, "endtime" -> endStr,
        "format" -> "ascii", "demean" -> "true", "bp" -> "0.02-0.1"}|>]];
    If[Head[r] === HTTPResponse && r["StatusCode"] == 200 &&
       StringContainsQ[r["Body"], "TIMESERIES"], Throw[parseTSPAIR[r["Body"]]]],
    {lc, {"00", "10", "", "--"}}]; $Failed]];

(* ---- station list ---- *)
lines = StringSplit[Import[FileNameJoin[{dataDir, "eu_stations_raw.txt"}], "Text"], "\n"];
rows = Select[StringSplit[#, "|"] & /@ lines,
   Length[#] >= 7 && ! StringStartsQ[First[#], "#"] &];
endT[r_] := If[Length[r] >= 8, StringTrim[r[[8]]], ""];
active = Select[rows, (endT[#] === "" || endT[#] > "2025-03-28") &];
cands = {#[[1]], #[[2]], ToExpression[#[[3]]], ToExpression[#[[4]]]} & /@ active;
cands = DeleteDuplicatesBy[cands, #[[2]] &];       (* unique station codes *)
Print[Length[cands], " candidate European stations"];

(* ---- fetch every station's LHZ (cache) ---- *)
epi = {22.011, 95.936};
gcDeg[{la1_, lo1_}, {la2_, lo2_}] := ArcCos[Clip[
   Sin[la1 Degree] Sin[la2 Degree] +
   Cos[la1 Degree] Cos[la2 Degree] Cos[(lo2 - lo1) Degree], {-1., 1.}]]/Degree;

got = {};
Do[Module[{nt = c[[1]], st = c[[2]], lat = c[[3]], lon = c[[4]], cf, s},
   cf = FileNameJoin[{wfDir, nt <> "_" <> st <> ".csv"}];
   If[FileExistsQ[cf], s = Flatten[Import[cf, "CSV"]],
     s = fetchLHZ[nt, st];
     If[ListQ[s] && Length[s] > 2000, Export[cf, Partition[s, 1]], s = $Failed]];
   If[ListQ[s] && Length[s] > 2000,
     AppendTo[got, <|"pos" -> {lat, lon}, "dist" -> gcDeg[epi, {lat, lon}],
        "seis" -> N[s]|>]];
  ], {c, cands}];
Print["fetched ", Length[got], " / ", Length[cands], " real LHZ traces"];

(* ---- assemble matrices for gmvFrame ---- *)
nMin = Min[Length[#["seis"]] & /@ got];
tArray = N @ Range[0, nMin - 1];                 (* seconds after origin, 1 sps *)
stations = #["pos"] & /@ got;
(* Render via the library (single source of truth): realGMVFrames reads
   the CSVs we just cached in data/gmv_waveforms/ and feeds real motion
   into gmvFrame. *)
Print["rendering frames from ", Length[got], " stations..."];
frames = realGMVFrames[dataDir];

(* full-quality MP4 *)
Export[FileNameJoin[{imgDir, "RealSeismicGMV.mp4"}],
   AnimatedImage[frames, FrameRate -> 8], "MP4"];
Print["wrote docs/images/RealSeismicGMV.mp4"];

(* downsampled GIF for embedding: flat basemap quantises small *)
gframes = ColorQuantize[ImageResize[#, 620], 128, Dithering -> False] & /@ frames;
Export[FileNameJoin[{imgDir, "real_gmv.gif"}],
   AnimatedImage[gframes, FrameRate -> 8, AnimationRepetitions -> Infinity], "GIF"];
Print["wrote docs/images/real_gmv.gif (", Length[frames], " frames, ",
   Round[FileByteCount[FileNameJoin[{imgDir, "real_gmv.gif"}]]/1024], " KB)"];
