# Lightworks user Fx library, November 5, 2023.

The effects in this ZIP file were created by Lightworks users - thank you to all who have contributed, especially khaver, who started things off.  They will run on versions of Lightworks from 2023.1 upwards.  In the versions that support it you can directly browse and load these effects from within the Lightworks effects engine.

You may notice that there have been several effects and even whole categories removed from this library.  This has in part been because with the addition of LW masking several user effects that added a mask to an existing effect are no longer necessary.  There is no checking in this library for effects with duplicate functionality, although with the reduction of the number of effects that should not be an issue.  It's up to you to check that any given effect does what you want, and does it better/faster/simpler than any alternative.

If you don't have an internet connection on your edit system you can download and install these effects manually:

1. Copy the FX file(s) that you need to your computer.  Anywhere will do as long as you know where to find them.
2. Launch Lightworks, open a project, then open the Effects panel by clicking the F9 key.
3. Select the orange "+" symbol, and right click in the window displaying the Lightworks effects.
4. From the drop down menu that appears choose "Create template from .FX file..".
5. In the top left of the window that appears click on "Places" and navigate to the folder in which you stored the FX file.
6. Select the Fx file and then click OK.

The effect will be copied and a further window will appear giving details.

Lightworks does not overwrite existing effects but simply adds new ones to the list, even if they have the same name and category as a currently installed effect. If you want to replace an effect you need to destroy the existing version first. In the effects panel right-click on the effect you wish to change, and from the menu that appears, select "Destroy current effect". Then install your new version in the usual way. Note that you cannot delete effects supplied with Lightworks this way.

If you need to use two effects that have the same name, simply open one of them with any plain text editor (definitely not a word processor) and look for the line up near the top of the file that says something like ' string Description = "Effect name"; '. Type in your new name in place of the existing effect name inside the quotes and save the file. When you load that version it will now have the name that you gave it.

**NOTE:** Every attempt has been made to ensure that these effects will compile and run on Lightworks on any supported operating system. If you have trouble installing them, please make a note of any error message that Lightworks gives you. Post the complete details [here](https://forum.lwks.com/threads/custom-and-user-effects-feedback.191071/). It will be followed up.

## CATEGORY FOLDER: Animated Lower 3rds
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Lower 3rd toolkit A           |Lower3rdToolkitA.fx     |A general purpose toolkit designed to help build custom lower thirds          |
|Lower 3rd toolkit B           |Lower3rdToolkitB.fx     |A second general purpose toolkit to help build custom lower thirds            |
|Lower third A                 |LowerThirdA.fx          |Moves a coloured bar from edge of screen and lowers/raises it to reveal text  |
|Lower third B                 |LowerThirdB.fx          |Moves a bar along a coloured line to reveal the text                          |
|Lower third C                 |LowerThirdC.fx          |Opens a text ribbon to reveal the lower third text                            |
|Lower third D                 |LowerThirdD.fx          |Pushes a text block on from the edge of frame to reveal the lower third text  |
|Lower third E                 |LowerThirdE.fx          |Page turns a text overlay over a ribbon background                            |
|Lower third F                 |LowerThirdF.fx          |Twists a text overlay to reveal it over a ribbon background                   |
|Lower third G                 |LowerThirdG.fx          |This uses a clock wipe to wipe on a box which then reveals the text           |

## CATEGORY FOLDER: Art Effects
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|70s psychedelia               |70sPsychedelia.fx       |An extreme highly adjustable posterization style of effect                    |
|Edge                          |Edge.fx                 |Detects edges to give a similar result to the well known art program effect   |
|Edge glow                     |EdgeGlow.fx             |Adds a level-based or edge-based glow to an image                             |
|Five tone                     |FiveTone.fx             |Extends the existing Two Tone and Tri-Tone effects to five tonal values       |
|Foreground glow               |FgndGlow.fx             |Applies a glow to the foreground of a keyed or blended image                  |
|Four tone                     |FourTone.fx             |Extends the existing Two Tone and Tri-Tone effects to four tonal values       |
|Pencil Sketch                 |PencilSketch.fx         |Pencil sketch effect with sat/gamma/cont/bright/gain/overlay/alpha controls   |
|Poster paint                  |PosterPaint.fx          |A fully adjustable posterize effect                                           |
|Sketch                        |Sketch.fx               |Converts any standard video source or graphic to a simple sketch              |
|The dark side                 |DarkSide.fx             |Creates a shadow enhancing soft darkness "glow"                               |
|Toon                          |Toon.fx                 |The image is posterized then edge outlines are added to give a cartoon look   |

## CATEGORY FOLDER: Backgrounds
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Fractal mattes                |FractalMattes.fx        |Produces fractal patterns for background generation                           |
|Multicolour gradient          |MultiGradient.fx        |Creates a colour field with a wide range of possible gradients                |
|Plasma matte                  |PlasmaMatte.fx          |Generates moving soft plasma-like cloud patterns                              |
|Sinusoidal lights             |SinusoidalLights.fx     |A pattern generator that creates stars in Lissajou curves over a flat colour  |

## CATEGORY FOLDER: Blend Effects
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Alpha feather                 |AlphaFeather.fx         |Helps bed an externally generated graphic with transparency into a background |
|Blend tools                   |BlendTools.fx           |A wide range of blend and key adjustments, can generate alpha from black      |
|Boolean blend plus            |BoolBlendPlus.fx        |Combines two images with an analogue of boolean logic, blends it over video   |
|Crawl and roll fix            |CrawlRollFix.fx         |Directionally blurs a roll or crawl to smooth its motion                      |
|Drop shadow and border        |DropShadowBdr.fx        |Drop shadow and border generator for text graphics                            |
|Enhanced blend                |EnhancedBlend.fx        |This is a customised blend for use in conjunction with other effects          |
|Extrusion blend               |ExtrusionBlend.fx       |Extrudes a foreground image linearly or radially towards a centre point       |
|Floating images               |FloatingImages.fx       |Generates up to four overlayed images from a foreground graphic               |
|Glittery edges                |GlitteryEdges.fx        |Sparkly edges, best over darker backgrounds                                   |
|Light ray blend               |LightRayBlend.fx        |Adds directional blurs to a key or any image with an alpha channel            |
|Magical edges                 |MagicalEdges.fx         |Fractal edges with star-shaped radiating blurs                                |
|Unpremultiply                 |Unpremultiply.fx        |Removes the hard outline you can get with some blend effects                  |

## CATEGORY FOLDER: Blurs and Sharpens
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Bilateral blur                |BilateralBlur.fx        |A strong bilateral blur created by baopao with a little help from his friends |
|Directional sharpen           |DirectionalSharpen.fx   |A directional unsharp mask for when directional blurring must be corrected    |
|Focal blur                    |FocalBlur.fx            |Uses a depth map to create a faux depth of field                              |
|Ghostly blur                  |GhostlyBlur.fx          |The sort of effect that you get when looking through a fogged window          |
|Iris bokeh                    |IrisBokeh.fx            |Similar to Bokeh.fx, provides control of the iris (5 to 8 segments or round)  |
|Soft blurs                    |SoftBlurs.fx            |A selection of very smooth, soft blurs                                        |
|Tilt shift                    |TiltShift.fx            |Simulates the shallow depth of field encountered in close-up photography      |
|Visual motion blur            |VisualMblur.fx          |Directional blur that can be set up by visually dragging a central pin point  |
|Yet another sharpen           |YAsharpen.fx            |A sharpen utility that can give extremely clean results                       |

## CATEGORY FOLDER: Border and crop
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|3D bevelled crop              |3Dbevel.fx              |A simple crop with an inner 3D bevelled edge and a flat coloured outer border |
|Bevel edged crop              |BevelCrop.fx            |This provides a crop with a bevelled border and a hard-edged drop shadow      |
|Flexible crop                 |Flexicrop.fx            |A flexible bordered crop with drop shadow based on LW masking                 |
|Polymask                      |Polymask.fx             |A multi-sided mask with feathered edges and optional background colour        |
|Rounded crop                  |RoundedCrop.fx          |A bordered, drop shadowed crop with rounded corners                           |
|Simple crop                   |SimpleCrop.fx           |A simple crop tool with blend                                                 |

## CATEGORY FOLDER: Colour Tools
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|ALE smooth chroma             |ALEsmoothChroma.fx      |Smooths the colour component of video media.  The luminance is unaffected     |
|Midtone kicker                |MidKicker.fx            |Adjusts mid-range RGB levels to enhance or reduce them                        |
|Peak desaturate               |PeakDesaturate.fx       |Desaturate whites and blacks contaminated during other grading operations     |
|RGB-CMY correction            |RGBCMYcorrect.fx        |A colorgrade tool based on red, green, blue, cyan, magenta and yellow colours |
|S-Curve                       |Scurve.fx               |Adjusts RGB and/or HSV levels to give a smooth S-curve                        |
|Vibrance                      |Vibrance.fx             |Adjusts the video vibrance                                                    |
|White and black balance       |WhiteBlackBalance.fx    |A simple black and white balance utility                                      |

## CATEGORY FOLDER: Distortion
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Bulge                         |BulgeFx.fx              |Allows a variable area of the frame to have a concave or convex bulge applied |
|Flag wave                     |FlagWave.fx             |Simulates a waving flag (what a surprise)                                     |
|Liquify                       |Liquify.fx              |Distorts the image in a soft liquid manner                                    |
|Magnifying glass              |Magnify.fx              |Similar in operation to a bulge effect, but performs a flat linear zoom       |
|Perspective                   |Perspective.fx          |Warps one rectangle to another using a perspective transform                  |
|Perspective overlay           |PerspectiveOvl.fx       |Uses a 3D transform to give perspective to a 2D shape                         |
|Refraction                    |Refraction.fx           |Simulates the distortion effect of an image seen through textured glass       |
|Regional zoom                 |RegionalZoom.fx         |This allows you to apply localised distortion to any region of the frame      |
|Ripples (automatic expansion) |RipplesAuto.fx          |Radiating ripples are produced under semi-automatic control                   |
|Ripples (manual expansion)    |RipplesManual.fx        |Radiating ripples are produced under full user control                        |
|Skew                          |Skew.fx                 |A neat, simple effect for adding a perspective illusion to a flat plane       |
|Water                         |Water.fx                |Makes waves as well as refraction, and provides X and Y adjustment            |
|Whirl                         |Whirl.fx                |Simulates what happens when water empties out of a sink                       |

## CATEGORY FOLDER: Film Effects
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Bleach bypass                 |BleachBypass.fx         |Emulates the altered contrast and saturation when the bleach step is skipped  |
|Colour negative               |ColourNegative.fx       |Simulates the look of 35 mm colour film dye-masked negative                   |
|Duotone print                 |DuotonePrint.fx         |This simulates the look of the old Duotone colour film process                |
|Film exposure                 |FilmExposure.fx         |Simulates exposure adjustment using a Cineon profile                          |
|Film lab                      |FilmLab.fx              |This is simulates a colour film processing lab for video                      |
|Filmic look                   |FilmLook.fx             |Simulates a filmic curve with exposure adjustment, halation and vibrance      |
|Multi toner                   |MultiToner.fx           |Select from sepia, selenium, gold tone, copper tone and ferrotone simulation  |
|Old film look                 |OldFilmLook.fx          |Emulates black and white film with scratches, sprocket holes, weave & flicker |
|Technicolor                   |Technicolor.fx          |Simulates the look of classic 2-strip and 3-strip Technicolor film processes  |
|Vintage look                  |VintageLook.fx          |Simulates what happens when dye layers of old colour film stock start to fade |

## CATEGORY FOLDER: Filters
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Anamorphic lens flare         |AnamorphicLensFlare.fx  |Simulates the horizontal non-linear flare that an anamorphic lens produces    |
|Chromatic aberration          |ChromaticAberration.fx  |Generates or removes chromatic aberration                                     |
|De-blemish                    |DeBlemish.fx            |Smooths skin tones to reduce visible skin blemishes using a radial blur       |
|Flare                         |Flare.fx                |Creates an adjustable lens flare effect                                       |
|Glint                         |Glint.fx                |Creates rotatable star filter-like highlights, with 4, 6 or 8 points          |
|Graduated ND filter           |GraduatedNDfilter.fx    |A tintable neutral density filter with adjustable blend modes                 |
|Lens flare                    |LensFlare.fx            |Basic lens flare                                                              |
|Rays                          |Rays.fx                 |Radiates light rays away from the highlights in the image                     |
|Skin smooth                   |SkinSmooth.fx           |Smooths flesh tones to reduce visible skin blemishes                          |

## CATEGORY FOLDER: Key Extras
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|ALE chromakey                 |AleChromakey.fx         |A sophisticated chromakey that is particularly effective on fine detail       |
|Alpha opaque                  |AlphaOpq.fx             |Makes a transparent image or title completely opaque                          |
|Analogue lumakey              |AnalogLumakey.fx        |A digital keyer which behaves in a very similar way to a vision mixer keyer   |
|Chromakey with transform      |ChromakeyTransform.fx   |A version of the Lightworks Chromakey effect with cropping and transform      |
|Chromakey with cyclorama      |ChromakeyWithCyc.fx     |A chromakey effect with simple transform and cyclorama background generation  |
|Delta mask                    |DeltaMask.fx            |This delta mask effect removes the background from the foreground             |
|Easy overlay                  |EasyOverlay.fx          |Used with overlays where luminance represents transparency                    |
|INK                           |Ink.fx                  |INK is a quick, simple and effective proportionate colour difference keyer    |
|Key despill                   |KeyDespill.fx           |This is a background-based effect that removes key colour spill in chromakeys |
|Lumakey and matte             |LumakeyAndMatte.fx      |Generates a key from video with border/shadow, fills it with colour or video  |
|Lumakey with DVE              |LumakeyWithDVE.fx       |A keyer which respects the foreground alpha and passes the composite alpha on |
|Simple chromakey              |SimpleChromakey.fx      |An extremely simple chromakeyer with feathering and spill reduction           |

## CATEGORY FOLDER: Multiscreen Effects
|EFFECT                          |FILE NAME             |DESCRIPTION                                                                   |
|:------------------------------ |:-------------------- |:---------------------------------------------------------------------------- |
|Quad split screen, simply       |QuadScreenS.fx        |This is a fast simple single effect with 4 inputs                             |
|Quad split screen, dynamic zoom |QuadScreenZ.fx        |This is an advanced dynamic effect with 4 inputs                              |
|Quad split plus                 |QuadSplitPlus.fx      |Creates four split screen images with borders over a daisy-chained background |

## CATEGORY FOLDER: Print Effects
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Color halftone                |ColorHalftone.fx        |Emulates the dot pattern of a colour half-tone print image                    |
|Dot screen                    |DotScreen.fx            |Simulates the dot pattern used in a black and white half-tone print image     |
|Manga pattern                 |MangaPattern.fx         |Simulates the star pattern and hard contours of Manga half-tone images        |

## CATEGORY FOLDER: Repair tools
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Chromatic aberration fixer    |ChromaticAbFixer.fx     |Generates or removes chromatic aberration                                     |
|Clone stamp                   |CloneStamp.fx           |Clones sections of the image into other sections similarly to art software    |
|Cubic lens distortion         |CubicLensDistortion.fx  |Can be used for reducing fish-eye distortion with wide angle lenses           |
|Pixel fixer                   |PixelFixer.fx           |Pixel Fixer repairs dead pixels based on adjacent pixel content               |
|Warped stretch                |WarpedStretch.fx        |A means of helping handle mixed aspect ratio media                            |

## CATEGORY FOLDER: Simple Tools
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Auto fill                     |Autofill.fx             |Fills the blank edges of clips which differ in aspect ratio from the sequence |
|Flip flop                     |FlipFlop.fx             |Rotates video by 180 degrees, similar to a combination of LW flip and flop    |
|Highlight widgets             |HighlightWidgets.fx     |Used to highlight sections of video that you want to emphasize                |
|Progress bar                  |ProgressBar.fx          |A simple progress bar generator with border                                   |
|RGB registration              |RGBregistration.fx      |Adjusts the X-Y registration of the RGB channels of a video stream            |
|Simple S curve                |SimpleS.fx              |This applies an S curve to the video levels to give an image that extra zing  |
|Simple star                   |SimpleStar.fx           |Creates a single rotatable star glint, with 4, 5, 6, 7 or 8 arms              |

## CATEGORY FOLDER: Special Effects
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Binocular mask                |BinocularMask.fx        |Creates the classic binocular effect                                          |
|Double vision                 |DoubleVision.fx         |Gives a blurry double vision effect suitable for impaired vision POVs         |
|Fireballs                     |Fireballs.fx            |Produces a hot fireball and optionally blends it with a background image      |
|Glitch                        |Glitch.fx               |Applies a glitch to titles or keys.  Just apply on top of your effect         |
|Kaleido                       |Kaleido.fx              |Number of sides, centering, scaling and zoom can be set in this kaleidoscope  |
|Kaleidoscope                  |Kaleidoscope.fx         |This kaleidoscope effect varies the number of sides, position and scale       |
|Lightning flash               |LightningFlash.fx       |Simulates a high energy lightning flash at the cut point                      |
|Rainbow                       |Rainbow.fx              |This is a special effect that generates single and double rainbows            |
|Rainbow connection            |RainbowConnect.fx       |Changes colours through rainbow patterns according to levels                  |
|Sea scape                     |SeaScape.fx             |Seascape produces a very realistic ocean simulation                           |
|Spotlight effect              |Spotlight.fx            |Creates a spotlight highlight over a slightly blurred darkened background     |
|String theory                 |stringTheory.fx         |You really have to try this to see what it does                               |
|Transporter                   |Transporter.fx          |A modified chromakey to provide a Star Trek-like transporter effect           |

## CATEGORY FOLDER: Switches
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Channel selector              |ChannelSelector.fx      |Selectively combine RGBA channels from up to four layers                      |
|Output selector               |OutputSelector.fx       |A means of choosing from up to four different sources for monitoring purposes |
|Random flicker                |RandomFlicker.fx        |Does a pseudo random switch between two inputs                                |
|Strobe light                  |StrobeLight.fx          |Strobe is a two-input effect which switches rapidly between two video layers  |

## CATEGORY FOLDER: Technical
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Antialias                     |Antialias.fx            |A two pass rotary anti-alias tool that gives a very smooth result             |
|Channel diagnostics           |ChannelDiags.fx         |Can display individual RGB, luminance, summed RGB, U, V and alpha channels    |
|Clamp to 16-235               |Clamp_16_235.fx         |Clamps full swing RGB signal to legal video gamut                             |
|Colour smoother               |ColourSmooth.fx         |Interpolates colours to correct contouring and banding                        |
|Expand 16-235 to 0-255        |Expand_16_235.fx        |Expands legal video levels to full gamut RGB                                  |
|Exposure leveller             |ExposeLevel.fx          |This corrects the levels of shots where the exposure varies over time         |
|Frame lock                    |FrameLock.fx            |Locks the frame size and aspect ratio of the image to that of the sequence    |
|Show highs and lows           |ShowHiLo.fx             |This effect flashes blacks and whites that exceed preset levels               |
|Shrink 0-255 to 16-235        |Shrink_16_235.fx        |Shrinks full gamut RGB signals to broadcast legal video                       |
|SMPTE color bars              |SMPTEcolorbars.fx       |Provides SMPTE-standard colour bars as an alternative to the LW EBU version   |
|Tenderizer                    |Tenderizer.fx           |Converts 8 bit video to 10 bit video using intermediate spline interpolation  |
|Test greyscale                |TestGreyscale.fx        |Ten unique greyscale test patterns, either full gamut or broadcast limited    |
|Zebra stripes                 |ZebraStripes.fx         |Displays zebra patterning in over white and under black areas of the frame    |

## CATEGORY FOLDER: Textures
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Acidulate                     |AcidulateFx.fx          |I was going to call this LSD, but this name will do                           |
|Grain (Variable)              |GrainVariable.fx        |A flexible means of adding grain to an image                                  |
|Texturiser                    |Texturiser.fx           |Generates bump mapped textures on an image using external texture artwork     |
|Tiling                        |Tiling.fx               |Breaks the image into a bevelled mosaic or glass tiles                        |
|Variable film grain           |VarFilmGrain.fx         |This effect reduces the grain as the luminance values approach their limits   |
|Video noise                   |VideoNoise.fx           |Generates either monochrome or colour video noise                             |

## CATEGORY FOLDER: Transform plus
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Art Deco transform            |ArtDecoTransform.fx     |Art Deco flash lines are included in the transform borders                    |
|Flexible transform            |FlexiTransform.fx       |A flexible masked transform with Z-axis rotation                              |
|Framed DVE                    |FramedDVE.fx            |Creates a textured frame around the foreground and resizes and positions it   |
|Repeated transform            |RepeatTransform.fx      |A transform that can duplicate the foreground image as you zoom out           |
|Rosehaven                     |Rosehaven.fx            |Creates mirrored top/bottom or left/right images                              |
|Simple zoom in                |SimpleZoomIn.fx         |Designed for simple zooming in (not recommended for negative zoom values)     |
|Spin zoom                     |SpinZoom.fx             |Similar to the transform 3D, but the settings are much easier to use          |
|Tiled images                  |TiledImages.fx          |Creates tile patterns from the image, which can be rotated                    |
|Triple DVE                    |TripleDVE.fx            |Foreground, background and the overall effect have independent DVE adjustment |

## CATEGORY FOLDER: Video artefacts
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Analog TV disaster            |AnalogTVdisaster.fx     |Simulates just about anything that could go wrong with analog TV              |
|Camera distortion             |CameraDistortion.fx     |Simulates a range of digital camera distortion artefacts                      |
|Camera shake                  |CameraShake.fx          |Adds simulated camera motion horizontally, vertically and/or rotationally     |
|Chroma bleed                  |ChromaBleed.fx          |Gives the horizontal smeared colour look of early helical scan recorders      |
|CRT TV screen                 |CRTscreen.fx            |Simulates close-up looks at one of three different analogue colour TV screens |
|Low-res camera                |LowResCamera.fx         |Simulates the pixellation seen when a low-res camera is blown up too much     |
|Night vision                  |NightVision.fx          |Simulates infra-red night time cinematography                                 |
|Old monitor                   |OldMonitor.fx           |This effect gives a black and white image with fully adjustable scan lines    |
|Quadruplex VTR simulator      |QuadVTRsimulator.fx     |Emulates the faults that could occur with Quadruplex videotape playback       |
|Screen shake                  |Screenshake.fx          |Random screen shake, slightly zoomed in, no motion blur                       |
|VHS simulator                 |VHSsimulator.fx         |Simulates a damaged VHS tape                                                  |

## TRANSITIONS

## CATEGORY FOLDER: Abstract transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Erosion transition           |Yes      |Yes      |ErodeTrans.fx           |Transitions between two sources using a mixed key      |
|Fractal transition           |Yes      |Yes      |FractalTrans.fx         |Uses a fractal-like pattern as a transition            |
|Warp transition              |Yes      |Yes      |WarpTrans.fx            |Warps between two shots                                |

## CATEGORY FOLDER: Art transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Border transition            |No       |Yes      |BorderTrans.fx          |Key materialises / dematerialises in four directions   |
|Dry brush transition         |Yes      |Yes      |DryBrushTrans.fx        |Angled brush stroke transitions between shots          |
|Flare transition             |Yes      |No       |FlareTran.fx            |Dissolves between images using a burnout flare         |
|Granular transition          |Yes      |Yes      |GranularTrans.fx        |A granular noise driven dissolve between shots         |
|Toon transition              |Yes      |Yes      |ToonTrans.fx            |A stylised cartoon transition between images           |

## CATEGORY FOLDER: Blend transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Dissolve X transitions       |Yes      |Yes      |DissolveXTrans.fx       |Allows blend modes to be used in a dissolve            |
|Non-linear transitions       |Yes      |Yes      |NonlinearTrans.fx       |A series of four non-linear dissolves                  |
|Optical transition           |Yes      |Yes      |OpticalTrans.fx         |Simulates the burn effect of a film optical dissolve   |

## CATEGORY FOLDER: Blur transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Blur transition              |Yes      |Yes      |BlurTrans.fx            |Uses a blur to transition between two video sources    |
|Directional blur transition  |Yes      |Yes      |DirectionalBlurTrans.fx |Uses a directional blur to dissolve between sources    |
|Spin transition              |Yes      |Yes      |SpinTrans.fx            |Uses a rotational blur to dissolve between sources     |
|Swirl transition             |Yes      |Yes      |SwirlMixTrans.fx        |Uses a spin effect to transition between two sources   |
|Whip pan transition          |Yes      |Yes      |WhipPanTrans.fx         |Uses a directional blur to simulate a whip pan         |
|Zoom transition              |Yes      |Yes      |ZoomTrans.fx            |Zooms between the two sources                          |

## CATEGORY FOLDER: Colour transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Colour gradient transition   |Yes      |Yes      |ColourGradTrans.fx      |Transitions through monochrome or a colour gradient    |
|Colour transition            |Yes      |Yes      |ColourTrans.fx          |Transitions through monochrome video or a flat colour  |
|RGB drift transition         |Yes      |Yes      |RGBdriftTrans.fx        |Dissolves using different R, G and B curves            |
|Sizzler transition           |Yes      |Yes      |SizzlerTrans.fx         |Transitions using a complex colour translation         |

## CATEGORY FOLDER: Fades and non mixes
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Chinagraph markup            |Yes      |No       |ChinagraphMarkup.fx     |Simulates the chinagraph marks used by film editors    |
|Fades                        |Yes      |No       |Fades.fx                |Fades video to or from black                           |
|Optical fades                |Yes      |No       |OpticalFades.fx         |Simulates the black crush effect of a film optical     |

## CATEGORY FOLDER: Geometric transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Kaleidoscope transition      |Yes      |No       |KaleidoTrans.fx         |A kaleidoscope transitions between two clips           |
|Rotation transition          |Yes      |Yes      |RotationTrans.fx        |X or Y axis rotating transition                        |
|Tile transitions             |Yes      |Yes      |TileTrans.fx            |Uses tile patterns to transition between video sources |

## CATEGORY FOLDER: Special Fx transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Dream sequence               |Yes      |Yes      |DreamTrans.fx           |Ripples the images as it dissolves between them        |
|Fireball transitions         |Yes      |No       |FireballTrans.fx        |Uses a hot fireball to transition between sources      |
|Fly away transition          |Yes      |No       |FlyAwayTrans.fx         |Flies the outgoing image out to reveal the incoming    |
|Page Roll transition         |Yes      |No       |PageRollTrans.fx        |The classic page turn transition                       |
|Sine transition              |Yes      |Yes      |SineTrans.fx            |Uses a sine distortion to transition between inputs    |
|Soft twist transition        |Yes      |Yes      |SoftTwistTrans.fx       |Performs a rippling twist transition between images    |
|Transporter transition       |Yes      |Yes      |TransporterTrans.fx     |A Star Trek-like transporter fade in or out            |
|Twist transition             |Yes      |No       |TwistTrans.fx           |Twists one image to another vertically/horizontally    |
|Wave fall transition         |Yes      |Yes      |WaveFallTrans.fx        |Compresses the foreground to sinue strips or waves     |

## CATEGORY FOLDER: Transform transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Barn door squeeze transition |Yes      |Yes      |BarndoorSqueezeTrans.fx |A barn door squeeze to/from the edge of frame          |
|Bounce transition            |Yes      |Yes      |BounceTrans.fx          |Bounces the foreground up then falls back              |
|Corner squeeze transition    |Yes      |Yes      |CornerSqueezeTrans.fx   |Corner wipe effect that squeezes or expands images     |
|Indiarubber transition       |Yes      |Yes      |IndiarubberTrans.fx     |Stretches the image horizontally through dissolve      |
|Pinch transitions            |Yes      |Yes      |PinchTrans.fx           |Pinches the outgoing video to a user-defined point     |
|Split and zoom transition    |Yes      |No       |SplitAndZoomTrans.fx    |Splits outgoing video to reveal incoming zoom shot     |
|Squeeze transition           |No       |Yes      |SqueezeTrans.fx         |A squeeze effect for blended images                    |

## CATEGORY FOLDER: Wipe transitions
|EFFECT                       |DIRECT   |KEYED    |FILE NAME               |DESCRIPTION                                            |
|:--------------------------- |:------- |:------- |:---------------------- |:----------------------------------------------------- |
|Barn door transition         |Yes      |Yes      |BarnDoorTrans.fx        |Splits the image in half and separates the halves      |
|Bar transition               |No       |Yes      |BarTrans.fx             |Splits a foreground image into strips which separate   |
|Compound push                |Yes      |No       |CompoundPush.fx         |Pushes inner and outer image sections separately       |
|Corner split transition      |Yes      |Yes      |CornerTrans.fx          |Splits an image four ways to or from the corners       |
|Push transition              |No       |Yes      |PushTrans.fx            |Pushes the foreground on or off screen                 |
|Sliced transition            |Yes      |Yes      |SliceTrans.fx           |Separates and splits the image into strips             |
|Strips transition            |No       |Yes      |StripsTrans.fx          |Splits the foreground into compressed strips           |

