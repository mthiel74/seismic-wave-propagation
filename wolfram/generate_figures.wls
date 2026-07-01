#!/usr/bin/env wolframscript
(* ::Package:: *)

(*  generate_figures.wls
    --------------------
    Renders every figure used by the Wolfram Community notebook into
    docs/images/. Pure Wolfram Language. Loads the function library
    SeismicWavePropagation.wl (which computes the PREM travel-time
    curves on load), then rasterises each plot and exports the two
    embedded animations (global wavefront "hero" + earthquake-vs-
    explosion comparison) as looping GIFs.

    Run from the repo root or anywhere:
        wolframscript -file wolfram/generate_figures.wls

    The wavefront animations and the event map use GeoGraphics with a
    relief-map background, so an internet connection is required for
    the map tiles. *)

scriptDir = DirectoryName[$InputFileName];
repoRoot  = ParentDirectory[scriptDir];
imgDir    = FileNameJoin[{repoRoot, "docs", "images"}];
If[!DirectoryQ[imgDir], CreateDirectory[imgDir, CreateIntermediateDirectories -> True]];

Print["Loading function library (computes PREM travel times)..."];
SetDirectory[FileNameJoin[{repoRoot, "community"}]];
Quiet @ Get["SeismicWavePropagation.wl"];
Print["  travel-time branches: P ", Length[travelTimeDataP],
      " pts, S ", Length[travelTimeDataS], " pts"];

(* ---- helpers ---------------------------------------------------- *)
save[name_, expr_, size_: 760] := Module[{img, path},
  path = FileNameJoin[{imgDir, name <> ".png"}];
  img = Quiet @ Check[Rasterize[expr, ImageSize -> size, ImageResolution -> 144], $Failed];
  If[Head[img] === Image,
    Export[path, img];
    Print["  + ", name, ".png  ", ImageDimensions[img]],
    Print["  ! FAILED ", name]];
];

saveGif[name_, frames_, rate_: 2.] := Module[{path, q},
  path = FileNameJoin[{imgDir, name <> ".gif"}];
  q = ColorQuantize[#, 160, Dithering -> False] & /@ frames;
  Export[path, AnimatedImage[q, FrameRate -> rate, AnimationRepetitions -> Infinity], "GIF"];
  Print["  + ", name, ".gif  ", Length[frames], " frames  ",
        Round[FileByteCount[path]/1024], " KB"];
];

(* ================================================================= *)
(*  Static figures                                                   *)
(* ================================================================= *)
Print["\nStatic figures:"];
save["prem_profiles",   plotPREMProfiles[], 720];
save["prem_cross",      plotPREMCrossSection[], 620];
save["ray_paths",       plotRayPaths[], 680];
save["travel_curves",   plotTravelTimeCurves[], 820];
save["energy_bars",     plotEnergyBarChart[], 760];
save["mach_cone",       plotMachCone[], 700];
save["yield_mb",        plotYieldMbRelation[], 760];
save["mb_ms",           plotMbMsDiscrimination[], 720];
save["source_mech",     plotSourceMechanisms[], 820];
save["event_map",       plotEventMap[], 820];          (* GeoGraphics: needs network *)
save["catalog_table",   displayCatalog[], 900];
save["verification_table", displayVerificationTable[], 900];

(* ================================================================= *)
(*  Idealized wavefront snapshots (Myanmar M7.7) — static 3-panel     *)
(* ================================================================= *)
Print["\nStatic: idealized wavefront snapshots (Myanmar M7.7)..."];
myanmar = earthquakeCatalog[[1]];
wfSnap[t_] := makeWavefrontFrame[myanmar["Position"], t, False,
   "t = " <> ToString[Round[t/60]] <> " min"] /. (ImageSize -> _) -> (ImageSize -> 330);
save["wavefront_snapshots",
   GraphicsRow[wfSnap /@ {300, 700, 1150}, Spacings -> 8, ImageSize -> 980], 980];

(* ================================================================= *)
(*  Animation 2 — earthquake vs nuclear explosion (same location)    *)
(*  Side-by-side orthographic globes initialised at the DPRK test    *)
(*  site: a hypothetical M6.3 double-couple earthquake (P + S +      *)
(*  Rayleigh) next to the real isotropic explosion (P only).         *)
(* ================================================================= *)
Print["\nAnimation: earthquake vs explosion discrimination..."];
dprkPos = nuclearTest["Position"];
cmpTimes = Range[20, 900, 70];
cmpPanel[t_, isNuc_, lab_] := (
   makeWavefrontFrame[dprkPos, t, isNuc, ""]
     /. (PlotLabel -> _) -> (PlotLabel -> Style[lab, Bold, 13])
     /. (ImageSize -> _) -> (ImageSize -> 430));
cmpFrames = Table[
   Rasterize[
     GraphicsRow[{
        cmpPanel[t, False, "Earthquake (double-couple)"],
        cmpPanel[t, True,  "Explosion (isotropic)"]
     }, Spacings -> 20, ImageSize -> 900],
     ImageSize -> 900],
   {t, cmpTimes}];
saveGif["quake_vs_explosion", cmpFrames, 2.2];

Print["\nDone. Figures written to ", imgDir];
