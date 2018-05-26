# Lightworks user Fx archive, May 26, 2018.


The effects in this ZIP file were created by Lightworks users – thank you to all who have contributed, especially khaver, who started things off. Previous users of the library will of course have noticed that this library is no longer sorted by simple alphabetical order. Details of the library contents can be found at the following on-line locations. The first is sorted by order of posting and the second thread is sorted by category as is this library, and is rather more detailed.


[https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=9259&Itemid=81#ftop](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=9259&Itemid=81#ftop)


[https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&Itemid=81#ftop](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&Itemid=81#ftop)


First, a warning: you shouldn't import effects files that you're unlikely to need. If you do Lightworks startup times can become very slow. This is a **library** and should be treated as such – you don't take home all the books in your local library at once either.

In this library where alternative versions of the effects exist they are separately listed and the entry includes the path that they are in. Where necessary a Read Me file may also be included in the folder with those versions.

Use of these effects is simple.

1. Copy the FX file(s) that you need to your computer. Anywhere will do as long as you know where to find them.
2. Launch Lightworks, open a project, then open the Effects panel.
3. In the top left of the window that appears click on "Places" and navigate to the folder in which you stored the FX file.
4. Select the FX file and then click OK.
5. The effect will be copied, compiled and a further window will appear giving details.

**NOTE:** Every attempt has been made to ensure that these effects will compile and run on any version of Lightworks on any supported operating system. If you have trouble installing them, please make a note of any error message that Lightworks gives you. Post the complete details [here](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=9259&Itemid=81). It will be followed up.

There is no checking in this zip file for effects with duplicate functionality. These are all included largely as supplied by the original creator. Some of the earlier effects may have been superseded by Editshare-supplied equivalents. It's up to you to check that any given effect does what you want, and does it better/faster/simpler than any alternative.

Lightworks does not overwrite existing effects but simply adds new ones to the list, even if they have the same name and category as a currently installed effect. If you want to replace an effect you need to destroy the existing version first. In the effects panel right-click on the effect you wish to change, and from the menu that appears, select "Destroy current effect". Then install your new version in the usual way. Note that you cannot delete effects supplied with Lightworks this way.

If you need to use two effects that have the same name, simply open one of them with any plain text editor (definitely not a word processor) and look for the line up near the top of the file that says something like ' string Description = "Effect name"; '. Type in your new name in place of the existing effect name inside the quotes and save the file. When you load that version it will now have the name that you gave it.

One alternative approach is to change the category the effect is stored under. Look for a line that says something like ' string Category = "Stylize"; '. Type in a new category name and save the file. The effect will be added to the category that you gave it, even if that category hasn't previously existed. The other alternative for version 14 users and up is to change the subcategory assigned to the effect. Look for a line near the start of the effect that is similar to ' string SubCategory = "Vignette"; '. Type in the new subcategory you wish to use. If the effect has no subcategory line you can add one after the category, but it must be spelled exactly as shown, i.e., SubCategory.

Alpha transitions are a special kind of effect, and require slightly different setting up to other transitions. The setup instructions for them can be found at the following link. https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&Itemid=81#135925 A newer group of composite wipe transitions have also been developed. They are also a special kind of effect. The very simple technique for using them can be found at the following link. https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&Itemid=81#135945 Finally, there is a special category of remote control effects, the brain child of user schrauber. The way that they work is unique, and the special setup and control instructions for them can be found in the thread [here](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=127918&Itemid=81#127918).

## CATEGORY FOLDER: Alpha and blends
|EFFECT                 |FILE NAME          |
|:--------------------- |:----------------- |
|Adjustable blend       |AdjBlend.fx        |
|Alpha adjust           |alphaAdjust.fx     |
|Alpha Feather          |AlphaFeather.fx    |
|Border                 |Border.fx          |
|Drop shadow and border |DropShadow.fx      |
|Drop shadow plus       |DropShadowPlus.fx  |
|Extrusion Matte        |Extrusion_Matte.fx |
|Floating images        |FloatImage.fx      |
|Glitter edge           |GlitterEdge.fx     |
|Light ray keys         |light_ray_keys.fx  |
|Magic edges            |MagicEdges.fx      |
|Matte key              |mattekey.fx        |
|Unpremultiply          |Unpremultiply.fx   |

## CATEGORY FOLDER: Alpha transitions
|EFFECT                     |FILE NAME           |
|:------------------------- |:------------------ |
|Alpha bar transition¹      |Adx_Bars.fx         |
|Alpha block dissolve¹      |Adx_Blocks.fx       |
|Alpha blur dissolve¹       |Adx_Blur.fx         |
|Alpha border transition¹   |Adx_Borders.fx      |
|Alpha corner split¹        |Adx_Corners.fx      |
|Alpha corner squeeze¹      |Adx_CnrSqueeze.fx   |
|Alpha dissolve thru colour¹|Adx_Colour.fx       |
|Alpha fractal dissolve¹    |Adx_Fractals.fx     |
|Alpha granular dissolve¹   |Adx_Granular.fx     |
|Alpha kaleido mix¹         |Adx_Kaleido.fx      |
|Alpha optical transition¹  |Adx_Optical.fx      |
|Alpha pinch¹               |Adx_Pinch.fx        |
|Alpha push¹                |Adx_Push.fx         |
|Alpha radial pinch¹        |Adx_PinchR.fx       |
|Alpha ripple dissolve¹     |Adx_Ripples.fx      |
|Alpha rotate¹              |Adx_Rotate.fx       |
|Alpha S dissolve¹          |Adx_Scurve.fx       |
|Alpha sine mix¹            |Adx_Sine.fx         |
|Alpha spin dissolve¹       |Adx_Spin.fx         |
|Alpha split¹               |Adx_Split.fx        |
|Alpha split squeeze¹       |Adx_SplitSqueeze.fx |
|Alpha squeeze¹             |Adx_Squeeze.fx      |
|Alpha stretch dissolve¹    |Adx_Stretch.fx      |
|Alpha strips¹              |Adx_Strips.fx       |
|Alpha tile transition¹     |Adx_Tiles.fx        |
|Alpha transmogrify¹        |Adx_Transmogrify.fx |
|Alpha twister¹             |Adx_Twister.fx      |
|Alpha warp dissolve¹       |Adx_Warp.fx         |
|Alpha wave collapse¹       |Adx_Wave.fx         |
|Alpha X-pinch¹             |Adx_PinchX.fx       |
|Alpha zoom dissolve¹       |Adx_Zoom.fx         |

## CATEGORY FOLDER: Art effects
|EFFECT                   |FILE NAME                                       |
|:----------------------- |:---------------------------------------------- |
|Colour mask              |ColourMask.fx                                   |
|Edge                     |Edge.fx                                         |
|Edge glow                |EdgeGlow.fx                                     |
|Four Tone                |fourtone.fx                                     |
|Five Tone                |fivetone.fx                                     |
|Pencil Sketch            |/PencilSketch/PencilSketch.fx                   |
|> Windows legacy version |/PencilSketch/Legacy Windows/PencilSketchWin.fx |
|Sketch                   |Sketch.fx                                       |
|Tiles                    |Tiles.fx                                        |
|Toon                     |Toon.fx                                         |

## CATEGORY FOLDER: Blurs and sharpens
|EFFECT                   |FILE NAME                                 |
|:----------------------- |:---------------------------------------- |
|Big Blur                 |BigBlur.fx                                |
|bilateral blur           |bilateral_blur.fx                         |
|Bokeh                    |Bokeh.fx                                  |
|Focal Blur               |FocalBlur.fx                              |
|FxSpinBlur               |FxSpinBlur.fx                             |
|FxTiltShift              |FxTiltShift.fx                            |
|Ghost blur               |GhostBlur.fx                              |
|Iris Bokeh               |/IrisBokeh/IrisBokeh.fx                   |
|> Windows legacy version |/IrisBokeh/Legacy Windows/IrisBokehWin.fx |
|Masked Blur              |MaskBlur.fx                               |
|Masked Motion Blur       |MaskedMotionBlur.fx                       |
|Motion Blur              |motionblur.fx                             |
|Soft foggy blur          |SoftFoggyBlur.fx                          |
|Soft motion blur         |SoftMotionBlur.fx                         |
|Soft spin blur           |SoftSpinBlur.fx                           |
|Soft zoom blur           |SoftZoomBlur.fx                           |
|Super blur               |SuperBlur.fx                              |
|Unsharp Mask             |UnsharpMask.fx                            |
|Zoom Blur                |ZoomBlur.fx                               |

## CATEGORY FOLDER: Broadcast tools
|EFFECT                   |FILE NAME                        |
|:----------------------- |:------------------------------- |
|Antialias                |AntiAlias.fx                     |
|Channels                 |Channels.fx                      |
|Clamp to 16-235          |/Maintain_16_235/Clamp16-235.fx  |
|Color Bars               |ColorBars.fx                     |
|Colour swizzler          |Swizzler.fx                      |
|De-interlace             |De-interlace.fx                  |
|Expand 16-235 to 0-255   |/Maintain_16_235/Expand16-235.fx |
|Exposure Leveler         |ExpoLeveler.fx                   |
|JH Show Hi/Lo            |jh_analysis_show_hilo.fx         |
|OutputSelect             |OutputSelect.fx                  |
|Safe area and crosshatch |Crosshatch.fx                    |
|Shrink 0-255 to 16-235   |/Maintain_16_235/Shrink16-235.fx |
|Tenderizer               |Tenderizer.fx                    |
|Test greyscale           |Test_greyscale.fx                |
|Two-axis vector balance  |TwoAxisVector.fx                 |
|Zebra pattern            |ZebraStripes.fx                  |

## CATEGORY FOLDER: Cleanup and repair
|EFFECT                     |FILE NAME              |
|:------------------------- |:--------------------- |
|Chromatic Aberration Fixer |CAFixer.fx             |
|Clone Stamp                |CloneStamp_03.fx       |
|Cubic lens distortion      |CubicLensDistortion.fx |
|Pixel Fixer                |PixFix.fx              |

## CATEGORY FOLDER: Colour grading
|EFFECT                    |FILE NAME            |
|:------------------------ |:------------------- |
|3 Axis Colour Temperature |3AxisColTemp.fx      |
|ALE_SMOOTH_CHROMA         |ALE_Smooth_Chroma.fx |
|CC Helper                 |CCHelper2.fx         |
|CC_RGBCMY                 |CC_RGBCMY.fx         |
|Film exposure             |FilmExp.fx           |
|HSV Wheel                 |HSVWheel.fx          |
|Hue rotate                |HueRotate.fx         |
|Peak desaturate           |PeakDesat.fx         |
|PolyGrad                  |PolyGrad.fx          |
|S-Curve                   |SCurve.fx            |
|S-curve adjustment        |RGBsCurve.fx         |
|Two-axis colour balance   |TwoAxis.fx           |

## CATEGORY FOLDER: Distortions
|EFFECT                        |FILE NAME                      |
|:---------------------------- |:----------------------------- |
|Bulge                         |bulge.fx                       |
|Glass Tiles                   |GlassTiles.fx                  |
|Magnifying glass              |magnifying_glass.fx            |
|Regional zoom                 |Regional zoom.fx               |
|Ripples (automatic expansion) |Ripples_automatic_expansion.fx |
|Ripples (manual expansion)    |Ripples_manual_expansion.fx    |
|WarpedStretch                 |Warped Stretch.fx              |
|Whirl                         |whirl20171106.fx               |

## CATEGORY FOLDER: DVE reposition and crop
|EFFECT        |FILE NAME             |
|:------------ |:-------------------- |
|Bordered crop |BorderCrop.fx         |
|Deco DVE      |Deco_DVE.fx           |
|Flip/flop     |FlipFlop.fx           |
|Format fixer  |FormatFixer.fx        |
|FxPerspective |FxPerspective.fx      |
|Perspective   |Perspective.fx        |
|Simple crop   |SimpleCrop.fx         |
|Spin Zoom     |Spin_Zoom_20171022.fx |
|Triple DVE    |Triple_DVE.fx         |
|VisualCrop    |vicrop.fx             |
|zoom-out-in   |zoom-out-in.fx        |

## CATEGORY FOLDER: Filmstock effects
|EFFECT             |FILE NAME         |
|:----------------- |:---------------- |
|Bleach Bypass      |bleachbypass.fx   |
|Colour film ageing |ColourFilmAge.fx  |
|Duotone            |Duotone.fx        |
|Film negative      |FilmNeg.fx        |
|FilmFx             |FilmFx.fx         |
|Filmic look        |FilmicLook2018.fx |
|Old Time Movie     |OldTime.fx        |
|Technicolor        |Technicolor.fx    |
|Vintage Look       |vintagelook.fx    |

## CATEGORY FOLDER: Filters
|EFFECT                   |FILE NAME            |
|:----------------------- |:------------------- |
|Anamorphic Lens Flare    |AnaFlare.fx          |
|Flare                    |Flare.fx             |
|Glint                    |Glint.fx             |
|Graduated ND Filter      |GradNDFilter.fx      |
|JB's Chromatic Aberation |ChromAb.fx           |
|Rays                     |Rays.fx              |
|SkinSmooth               |SkinSmooth.fx        |
|The dark side            |TheDarkSide.fx       |

## CATEGORY FOLDER: Keying
|EFFECT             |FILE NAME        |
|:----------------- |:--------------- |
|Ale_ChromaKey      |ALE_ChromaKey.fx |
|Chromakey with DVE |ChromakeyDVE.fx  |
|Chromakey plus     |ChromakeyPlus.fx |
|DeltaMask          |DeltaMask.fx     |
|INK                |INK.fx           |
|KeyDespill         |KeyDespill.fx    |
|Lumakey with DVE   |LumakeyDVE.fx    |
|Simple chromakey   |SimpleCkey.fx    |

## CATEGORY FOLDER: Lower thirds
|EFFECT              |FILE NAME     |
|:------------------ |:------------ |
|Lower 3rd toolkit A |Lower3dTkA.fx |
|Lower 3rd toolkit B |Lower3dTkB.fx |
|Lower third A       |Lower3d_A.fx  |
|Lower third B       |Lower3d_B.fx  |
|Lower third C       |Lower3d_C.fx  |
|Lower third D       |Lower3d_D.fx  |
|Lower third E       |Lower3d_E.fx  |
|Lower third F       |Lower3d_F.fx  |
|Lower third G       |Lower3d_G.fx  |

## CATEGORY FOLDER: Masks and vignettes
|EFFECT                   |FILE NAME                                   |
|:----------------------- |:------------------------------------------ |
|DVE with vignette        |DVE_vignette.fx                             |
|JH Vignette              |jh_stylize_vignette.fx                      |
|Letterbox                |Letterbox.fx                                |
|Octagonal vignette       |Octagonal_Vignette.fx                       |
|Poly03                   |/Poly Masks/PolyMask03.fx                   |
|Poly04                   |/Poly Masks/PolyMask04.fx                   |
|Poly05                   |/Poly Masks/PolyMask05.fx                   |
|Poly06                   |/Poly Masks/PolyMask06.fx                   |
|Poly07                   |/Poly Masks/PolyMask07.fx                   |
|Poly08                   |/Poly Masks/PolyMask08.fx                   |
|Poly10                   |/Poly Masks/PolyMask10.fx                   |
|Poly12                   |/Poly Masks/PolyMask12.fx                   |
|Poly14                   |/Poly Masks/PolyMask14.fx                   |
|> Windows legacy version |/Poly Masks/Legacy Windows/PolyMask14Win.fx |
|Poly16                   |/Poly Masks/PolyMask16.fx                   |
|> Windows legacy version |/Poly Masks/Legacy Windows/PolyMask16Win.fx |

## CATEGORY FOLDER: Motion
|EFFECT             |FILE NAME             |
|:----------------- |:-------------------- |
|Camera Shake       |CameraShake.fx        |
|New Strobe         |NewStrobe_20180523.fx |
|Rhythmic pulsation |Rhythmic_pulsation.fx |
|Strobe             |Strobe.fx             |

## CATEGORY FOLDER: Noise and grain
|EFFECT              |FILE NAME        |
|:------------------ |:--------------- |
|Film Grain          |FilmGrain.fx     |
|FxNoise             |FxNoise.fx       |
|Grain               |Grain.fx         |
|Grain(Variable)     |VariGrain.fx     |
|Variable Film Grain |VariFilmGrain.fx |

## CATEGORY FOLDER: Pattern and bgd genes
|EFFECT                   |FILE NAME                                    |
|:----------------------- |:------------------------------------------- |
|Fractal magic 1          |FractalMagic1.fx                             |
|Fractal magic 2          |FractalMagic2.fx                             |
|Fractal magic 3          |FractalMagic3.fx                             |
|FxTile                   |FxTile.fx                                    |
|Kaleido                  |Kaleido.fx                                   |
|Kaleidoscope             |Kaleidoscope.fx                              |
|Lissajou stars           |/Lissajou/Lissajou.fx                        |
|> Windows legacy version |/Lissajou/Legacy Windows/LissajouWin.fx      |
|Multigradient            |Multigrad.fx                                 |
|SineLight                |/Sine lights/SineLights.fx                   |
|> Windows legacy version |/Sine lights/Legacy Windows/SineLightsWin.fx |

## CATEGORY FOLDER: Simulation
|EFFECT             |FILE NAME                |
|:----------------- |:----------------------- |
|Camera distortions |CameraDistortions.fx     |
|CRT TV screen      |CRTscreen.fx             |
|JH Old Monitor     |jh_stylize_oldmonitor.fx |
|Low-res camera     |Low_res_cam.fx           |
|Night vision 2018  |NightVision_20180523.fx  |
|VHS v2             |VHSv2.fx                 |
|Water              |Water.fx                 |

## CATEGORY FOLDER: Special Fx
|EFFECT        |FILE NAME      |
|:------------ |:------------- |
|Lens Flare #1 |LensFlare_1.fx |
|Sea Scape     |SeaScape.fx    |
|Transporter   |Transporter.fx |

## CATEGORY FOLDER: Textures
|EFFECT            |FILE NAME           |
|:---------------- |:------------------ |
|70s Psychedelia   |70s_psych.fx        |
|Acidulate         |Acidulate.fx        |
|FxColorHalftone2  |FxColorHalftone2.fx |
|FxDotScreen       |FxDotScreen.fx      |
|FxHalftone2       |FxHalftone2.fx      |
|FxMangaShader     |FxManga.fx          |
|FxRefraction      |FxRefraction.fx     |
|Texturizer        |Texturizer.fx       |

## CATEGORY FOLDER: Transitions A
|EFFECT                  |FILE NAME                 |
|:---------------------- |:------------------------ |
|Block dissolve          |Dx_Blocks.fx              |
|Blur dissolve           |Dx_Blurs.fx               |
|Chinagraph pencil       |Dx_Chinagraph.fx          |
|Colour sizzler          |Dx_Sizzler.fx             |
|Coloured tiles          |Dx_ColourTile.fx          |
|Dissolve through Colour |Dx_Colour.fx              |
|DissolveX               |dissolveX.fx              |
|Dream sequence          |Dx_Dreams.fx              |
|Erosion                 |Erosion.fx                |
|Fade to or from black   |Dx_FadeOutIn.fx           |
|FlareTran               |FlareTran.fx              |
|Fly away                |Fly away.fx               |
|Folded neg dissolve     |Dx_FoldNeg.fx             |
|Folded pos dissolve     |Dx_FoldPos.fx             |
|Fractal dissolve        |Dx_Fractals.fx            |
|Granular dissolve       |Dx_Granular.fx            |
|Kaleido turbine mixer   |Kaleido turbine mixer.fx  |
|Mosaic transfer         |Dx_Mosaic.fx              |
|Non-add dissolve ultra  |Dx_NonAddUltra.fx         |
|Non-additive mixer      |Dx_NonAdd.fx              |
|Optical dissolve        |Dx_Optical.fx             |
|RGB drifter             |Dx_RGBdrift.fx            |
|S dissolve              |Dx_Scurve.fx              |
|Sinusoidal mix          |Dx_Sine.fx                |
|Slice transition        |Dx_Slice.fx               |
|Spin dissolve           |Dx_Spin.fx                |
|Stretch dissolve        |Dx_Stretch.fx             |
|Subtractive dissolve    |Dx_Subtract.fx            |
|Swirl mix               |Swirl_mix_20171113.fx     |
|Transmogrify            |Dx_Transmogrify.fx        |
|Warp dissolve           |Dx_Warp.fx                |
|Zoom dissolve           |Dx_Zoom.fx                |

## CATEGORY FOLDER: Transitions B
|EFFECT                    |FILE NAME          |
|:------------------------ |:----------------- |
|Barn door split           |Wx_Split.fx        |
|Barn door squeeze         |Wx_SplitSqueeze.fx |
|Composite corner split ²  |Cx_Corners.fx      |
|Composite corner squeeze² |Cx_CnrSqueeze.fx   |
|Composite pinch²          |Cx_Pinch.fx        |
|Composite push²           |Cx_Push.fx         |
|Composite radial pinch²   |Cx_rPinch.fx       |
|Composite split²          |Cx_Split.fx        |
|Composite split squeeze²  |Cx_SplitSqueeze.fx |
|Composite squeeze²        |Cx_Squeeze.fx      |
|Composite twister²        |Cx_Twister.fx      |
|Composite X-pinch²        |Cx_xPinch.fx       |
|Corner split              |Wx_Corners.fx      |
|Corner squeeze            |Wx_CnrSqueeze.fx   |
|Pinch transition          |Wx_Pinch.fx        |
|Radial pinch              |Wx_rPinch.fx       |
|The twister               |Wx_Twister.fx      |
|X-pinch                   |Wx_xPinch.fx       |

## SPECIAL REMOTE CONTROL CATEGORY FOLDER: Z_RC³
|EFFECT                       |FILE NAME                    |
|:--------------------------- |:--------------------------- |
|RC 1, Five channel remote    |RC1_Remote_control.fx        |
|RC 3001, cyclic User control |RC3001_Cyclic_Remote.fx      |
|Settings Display Unit        |Setting_Display_Unit.fx      |
|RC Gain                      |RC_Gain.fx                   |
|RC RGB-Gain                  |RC_Gain_RGB.fx               |
|RC Gamma                     |RC_Gamma.fx                  |
|RC RGB-Gamma                 |RC_Gamma_RGB.fx              |
|RC Lift                      |RC_Lift_20180418.fx          |
|RC RGB-Lift                  |RC_Lift_RGB_20180421.fx      |
|RC regional zoom             |RC_Zoom_Regional.fx          |
|RC regional zoom plus        |RC_Zoom_Regional_20180506.fx |
|Spin Zoom, RC                |Spin_Zoom_RC_180516.fx       |

(1) [Install and use alpha dissolves and transitions](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&Itemid=81#135925)

(2) [Simple instructions on how to use these composite transitions](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=135923&limit=15&limitstart=15&Itemid=81#135945)

(3) [Instructions on how to install and use these rather complex effects. Since they are in very active development by schrauber that thread is also a good place to go to ensure that you have the most up-to-date versions.](https://www.lwks.com/index.php?option=com_kunena&func=view&catid=7&id=127918&Itemid=81#127918)


# MetaParser

MetaParser is a simple tool for extracting metadata from FX files.

It expects path to the effects directory as an argument and it results
with JSON output describing metadata for all files found.

Meta attribute syntax is:
```
    @<attribute> <value>
```
or
```
    @<attribute> "<value>"
```

where:
    - `<attribute>` can contain only letters and digits (`[a-zA-Z0-9]`)
    - `<value>` can contain any character

Value enclosed with double quotes will be trimmed respectively.
Otherwise value will contain all characters up to end of line (EOL).

Supported meta attributes:

  - `author`: name of the author (multiple)
  - `maintainer`: name of the maintainer (multiple)
  - `created`: date of the first release (one)
  - `released`: date of the release (one)
  - `version`: actual version (one)
  - `license`': license name (one)
  - `see`: an URL to related resource of any type (multiple); can be
    link to the screenshot, picture, video, document, webpage, etc
  - `name`: name of the effect (one); provide only when
    `_LwksEffectInfo` is missing or contains no description

_Meta attributes are case insensitive._


Category, subcategory and effect name are taken from `_LwksEffectInfo`
section automatically.

## Prerequisites

Install dependencies:

```
$ pip install --user -r metaparser-requirements.txt
```

## Usage

``` 
python metaparser.py <path-to-fx-directory>
```

## Example

```
$ ./metaparser.py  Simulation/ | jq
```

### Output (fragment)

```json
{
    "items": [
    {
      "name": "Glow amount",
      "filename": "CRTscreen.fx",
      "description": " CRTscreen.fx developed by jwrl 22 February 2017.\n\n This effect simulates a close-up look at an analogue colour\n TV screen.  Three options are available: Trinitron (Sony),\n Diamondtron (Mitusbishi/NEC) and Linitron.  For copyright\n reasons they are identified as type 1, type 2 and type 3\n respectively in this effect.  No attempt has been made to\n emulate a dot matrix shadow mask tube, because in early\n tests we just lost too much luminance for the effect to be\n useful.  That's pretty much why the manufacturers stopped\n using the real shadowmask too.\n\n The stabilising wires have not been emulated in the type\n 1 tube for anything other than the lowest two pixel sizes.\n They just looked absurd with the larger settings.\n\n The glow/halation effect is just a simple box blur, slightly\n modified to give a reasonable simulation of the burnout that\n could be obtained by overdriving a CRT.\n\n Cross platform compatibility check 3 August 2017 jwrl.\n Explicitly defined InpSampler{} to reduce the risk of cross\n platform default sampler state differences.\n Inputs\n Samplers\n Parameters\n Definitions and declarations\n Shaders\n New code for Sony Trinitron stabilising wires\n Techniques",
      "category": "Stylize",
      "subcategory": "Simulation"
    },
    {
      "name": "Waves",
      "filename": "Water.fx",
      "description": " Header\n\n Lightworks effects have to have a _LwksEffectInfo block\n which defines basic information about the effect (ie. name\n and category). EffectGroup must be \"GenericPixelShader\".\n\n Version 14 update 18 Feb 2017 jwrl.\n Added subcategory to effect header.\n The title\n Governs the category that the effect appears in in Lightworks\n Inputs\n For each 'texture' declared here, Lightworks adds a matching\n input to your effect (so for a four input effect, you'd need\n to delcare four textures and samplers)\n Define parameters here.\n\n The Lightworks application will automatically generate\n sliders/controls for all parameters which do not start\n with a a leading '_' character\n Pixel Shader\n\n This section defines the code which the GPU will\n execute for every pixel in an output image.\n\n Note that pixels are processed out of order, in parallel.\n Using shader model 2.0, so there's a 64 instruction limit -\n use multple passes if you need more.\n Technique\n\n Specifies the order of passes (we only have a single pass, so\n there's not much to do)",
      "category": "Stylize",
      "subcategory": "Simulation"
    }
  ],
  "count": 7,
  "date": "2018-03-31T21:14:56.170227"
}

```
