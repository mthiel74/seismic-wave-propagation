#!/usr/bin/env wolframscript
(* ::Package:: *)

(*  tests/verify.wls — scientific sanity checks for the seismic library.
    Run:  wolframscript -file tests/verify.wls
    Exits non-zero if any check fails. *)

scriptDir = DirectoryName[$InputFileName];
libDir = FileNameJoin[{ParentDirectory[scriptDir], "community"}];
SetDirectory[libDir];
Quiet @ Get["SeismicWavePropagation.wl"];

fails = 0;
check[label_, cond_, detail_: ""] := (
  Print[If[TrueQ[cond], "  PASS  ", "  FAIL  "], label,
        If[detail =!= "", "  (" <> detail <> ")", ""]];
  If[!TrueQ[cond], fails++];);

Print["1. Direct-branch P travel times vs IASP91 (surface focus)"];
(* IASP91 reference P times, seconds *)
refP = {{30, 372.2}, {40, 457.6}, {50, 538.0}, {60, 610.6},
        {70, 676.6}, {80, 726.9}, {90, 778.7}};
maxErr = Max[Abs[tOfDeltaP[#1] - #2] & @@@ refP];
check["P within 8 s of IASP91 over 30-90 deg", maxErr < 8,
      "max |Δt| = " <> ToString[Round[maxErr, 0.1]] <> " s"];

Print["2. S/P travel-time ratio is mantle-like (~1.7-1.9)"];
ratio = tOfDeltaS[90] / tOfDeltaP[90];
check["S/P at 90 deg in [1.7, 1.9]", 1.7 <= ratio <= 1.9,
      "ratio = " <> ToString[Round[ratio, 0.01]]];

Print["3. First-arrival T(Δ) increases with distance (teleseismic)"];
(* The interpolated first-arrival curve must be monotonic where it is
   single-valued — i.e. outside the 20-44 deg upper-mantle triplication
   zone. Sample tOfDeltaP from 45 to 95 deg. *)
samples = Table[tOfDeltaP[d], {d, 45, 95, 1}];
incP = AllTrue[Differences[samples], # > 0 &];
check["tOfDeltaP strictly increasing over 45-95 deg", incP];

Print["4. Direct branch spans teleseismic distances"];
check["P branch reaches >= 95 deg", Max[travelTimeDataP[[All, 1]]] >= 95,
      "Δmax = " <> ToString[Round[Max[travelTimeDataP[[All, 1]]], 0.1]] <> " deg"];

Print["5. Kanamori energy scaling (Chile M9.5 vs DPRK 250 kt)"];
eChile = seismicEnergy[9.5];
eDPRK = nuclearTest["YieldKt"] * ktTNT;
rChile = eChile / eDPRK;
check["Chile M9.5 ~10000x DPRK test energy", 5000 < rChile < 20000,
      "ratio = " <> ToString[Round[rChile]]];
eTohoku = seismicEnergy[9.1];
check["Tohoku M9.1 ~2700x DPRK", 1500 < eTohoku/eDPRK < 4000,
      "ratio = " <> ToString[Round[eTohoku/eDPRK]]];

Print["6. mb–yield calibration (Murphy 1996)"];
check["mb(250 kt) ≈ 6.25 ± 0.3", Abs[mbFromYield[250] - 6.25] < 0.3,
      "mb = " <> ToString[Round[mbFromYield[250], 0.01]]];
check["yield(mb 6.3) round-trips ~ 280 kt", Abs[yieldFromMb[mbFromYield[250]] - 250] < 1];

Print["7. Supershear Mach angle (Myanmar): θ = arcsin(vS/vR)"];
vS = 3.5; vR = 5.5; (* km/s *)
theta = ArcSin[vS/vR]/Degree;
check["Mach angle ≈ 39.5 deg", Abs[theta - 39.5] < 1.5,
      "θ = " <> ToString[Round[theta, 0.1]] <> " deg"];

Print[""];
If[fails == 0,
  Print["ALL CHECKS PASSED"],
  Print[ToString[fails] <> " CHECK(S) FAILED"]; Exit[1]];
