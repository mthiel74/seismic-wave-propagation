#!/usr/bin/env wolframscript
(* ::Package:: *)

(*  fetch_real_data.wls
    ------------------
    Fetch REAL broadband vertical seismograms for the 2025-03-28 Mandalay,
    Myanmar M7.7 (USGS us7000pn9s) from the FDSN / IRIS-EarthScope
    irisws-timeseries web service, and build a record section with our
    from-scratch PREM P/S travel-time curves overlaid.

    Data source: IRIS/EarthScope DMC (FDSN). Networks IU (GSN, Albuquerque
    Seismological Lab / IRIS) and II (GSN, UC San Diego / IDA). Waveforms
    are band-pass filtered 0.02-0.1 Hz and decimated to 1 sps; the tidy
    per-station CSVs are written to data/ so the figure rebuilds offline.

    Requires internet. Run:  wolframscript -file wolfram/fetch_real_data.wls
*)

scriptDir = DirectoryName[$InputFileName];
repoRoot  = ParentDirectory[scriptDir];
libDir    = FileNameJoin[{repoRoot, "community"}];
dataDir   = FileNameJoin[{repoRoot, "data"}];
wfDir     = FileNameJoin[{dataDir, "waveforms"}];
imgDir    = FileNameJoin[{repoRoot, "docs", "images"}];
Do[If[!DirectoryQ[d], CreateDirectory[d, CreateIntermediateDirectories -> True]],
  {d, {wfDir, imgDir}}];

Print["Loading library (PREM travel-time curves)..."];
SetDirectory[libDir]; Quiet @ Get["SeismicWavePropagation.wl"];

(* ---- Event ---- *)
originStr = "2025-03-28T06:20:52";
epi = {22.011, 95.936};                 (* USGS us7000pn9s *)
gcDeg[{la1_, lo1_}, {la2_, lo2_}] := ArcCos[Clip[
   Sin[la1 Degree] Sin[la2 Degree] +
   Cos[la1 Degree] Cos[la2 Degree] Cos[(lo2 - lo1) Degree], {-1., 1.}]]/Degree;

(* ---- Station selection (even spread, one per ~6 deg bin) ---- *)
rawFile = FileNameJoin[{dataDir, "gsn_stations_raw.txt"}];
lines = StringSplit[Import[rawFile, "Text"], "\n"];
rows  = Select[StringSplit[#, "|"] & /@ lines,
   Length[#] >= 7 && ! StringStartsQ[First[#], "#"] &];
endT[r_] := If[Length[r] >= 8, StringTrim[r[[8]]], ""];
active = Select[rows, (endT[#] === "" || endT[#] > "2025-03-28") &];
allst = {#[[1]], #[[2]], ToExpression[#[[3]]], ToExpression[#[[4]]],
    gcDeg[epi, {ToExpression[#[[3]]], ToExpression[#[[4]]]}]} & /@ active;
inrange = Sort[Select[allst, 24 <= #[[5]] <= 98 &], #1[[5]] < #2[[5]] &];
picks = First /@ GatherBy[inrange, Floor[#[[5]]/6] &];
Print["selected ", Length[picks], " stations, ",
   Round[Min[picks[[All, 5]]]], "-", Round[Max[picks[[All, 5]]]], " deg"];

(* ---- Fetch one BHZ trace (try loc 00, 10, blank) ---- *)
$ProgressReporting = False;
base = "https://service.iris.edu/irisws/timeseries/1/query";
(* LHZ = long-period vertical, 1 sample/s. This is the natural channel for
   teleseismic body + surface waves in the 0.02-0.1 Hz band, and the 1 sps
   record is ~50x smaller to transfer and parse than 20-40 sps BHZ. *)
(* Catch/Throw (not Return) — Return inside Do does not exit the enclosing
   Module in this runtime, so the loop must Throw out of a Catch. *)
fetchTrace[nt_, st_] := Catch[Module[{r},
  Do[
    r = Quiet @ URLRead[HTTPRequest[base, <|"Query" -> {
        "net" -> nt, "sta" -> st, "loc" -> lc, "cha" -> "LHZ",
        "starttime" -> originStr, "endtime" -> "2025-03-28T07:11:00",
        "format" -> "ascii", "demean" -> "true", "bp" -> "0.02-0.1"}|>]];
    If[Head[r] === HTTPResponse && r["StatusCode"] == 200 &&
       StringContainsQ[r["Body"], "TIMESERIES"],
      Throw[parseTSPAIR[r["Body"]]]],
    {lc, {"00", "10", "", "--"}}];
  $Failed]];

parseTSPAIR[body_] := Module[{tbl},
  tbl = Quiet @ ImportString[body, "Table"];  (* whitespace-split rows *)
  tbl = Select[tbl, Length[#] == 2 && NumericQ[#[[2]]] &];  (* drop header *)
  If[tbl === {}, $Failed, tbl[[All, 2]]]];

(* ---- Gather traces (cache to data/waveforms) ---- *)
traces = {};
Do[
  Module[{net = p[[1]], sta = p[[2]], d = p[[5]], cache, samples},
    cache = FileNameJoin[{wfDir, net <> "_" <> sta <> "_BHZ.csv"}];
    If[FileExistsQ[cache],
      samples = Flatten[Import[cache, "CSV"]],
      samples = fetchTrace[net, sta];   (* LHZ, already 1 sps *)
      If[ListQ[samples] && Length[samples] > 100,
        Export[cache, Partition[samples, 1]]]];
    If[ListQ[samples] && Length[samples] > 50,
      AppendTo[traces, <|"id" -> net <> "." <> sta, "dist" -> d,
         "samples" -> N[samples]|>];
      Print["  + ", net, ".", sta, "  ", Round[d, 0.1], " deg  ",
         Length[samples], " pts"],
      Print["  ! no data ", net, ".", sta]];
  ], {p, picks}];
Print["got ", Length[traces], " / ", Length[picks], " traces"];

(* ---- Build record section ---- *)
dt = 1.0;   (* sps after decimation *)
(* Manifest: {waveform-filename, distance} for each fetched trace. The
   library's plotRecordSection[dataDir] reads this + the CSVs. *)
recMeta = {StringReplace[#["id"], "." -> "_"] <> "_BHZ.csv", #["dist"]} & /@ traces;
Export[FileNameJoin[{dataDir, "record_meta.csv"}], recMeta];

Export[FileNameJoin[{imgDir, "record_section.png"}],
   Rasterize[plotRecordSection[dataDir], ImageResolution -> 130]];
Print["wrote docs/images/record_section.png (via library plotRecordSection)"];


(* ================================================================= *)
(*  Single-station 3-component trace, arrivals at PREM times         *)
(* ================================================================= *)
fetchCha[nt_, st_, ch_] := Catch[Module[{r},
  Do[
    r = Quiet @ URLRead[HTTPRequest[base, <|"Query" -> {
        "net" -> nt, "sta" -> st, "loc" -> lc, "cha" -> ch,
        "starttime" -> originStr, "endtime" -> "2025-03-28T07:11:00",
        "format" -> "ascii", "demean" -> "true", "bp" -> "0.02-0.1"}|>]];
    If[Head[r] === HTTPResponse && r["StatusCode"] == 200 &&
       StringContainsQ[r["Body"], "TIMESERIES"], Throw[parseTSPAIR[r["Body"]]]],
    {lc, {"00", "10", "", "--"}}]; $Failed]];

ssNet = "II"; ssSta = "OBN";         (* Obninsk, Russia, ~55 deg *)
ssDist = SelectFirst[picks, #[[2]] == ssSta &][[5]];
(* GSN horizontals are named either LHN/LHE or LH1/LH2 -- try both *)
fetchChaAlt[nt_, st_, chList_] := Catch[
   Do[Module[{s, cf},
      cf = FileNameJoin[{wfDir, nt <> "_" <> st <> "_" <> ch <> ".csv"}];
      If[FileExistsQ[cf], s = Flatten[Import[cf, "CSV"]],
        s = fetchCha[nt, st, ch];
        If[ListQ[s] && Length[s] > 100, Export[cf, Partition[s, 1]]]];
      If[ListQ[s] && Length[s] > 100, Throw[s]]], {ch, chList}];
   $Failed];
(* fetch the 3 components (writes CSVs under their real channel names) *)
fetchChaAlt[ssNet, ssSta, {"LHZ"}];
fetchChaAlt[ssNet, ssSta, {"LHN", "LH1"}];
fetchChaAlt[ssNet, ssSta, {"LHE", "LH2"}];
fname[ch_] := ssNet <> "_" <> ssSta <> "_" <> ch <> ".csv";
pickCh[chs_] := SelectFirst[chs, FileExistsQ[FileNameJoin[{wfDir, fname[#]}]] &, First[chs]];
ssMeta = {{ssNet <> "." <> ssSta, ssDist},
   {"Z", fname["LHZ"]}, {"N", fname[pickCh[{"LHN", "LH1"}]]}, {"E", fname[pickCh[{"LHE", "LH2"}]]}};
Export[FileNameJoin[{dataDir, "single_meta.csv"}], ssMeta];

Export[FileNameJoin[{imgDir, "single_station.png"}],
   Rasterize[plotSingleStation[dataDir], ImageResolution -> 130]];
Print["wrote docs/images/single_station.png (via library plotSingleStation)"];
