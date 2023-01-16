# Lightworks user Fx library, January 16, 2023 - WIP.

(Unfortunately I cannot test the revised effects in Lightworks 2023.1 without having them on line so that they can be browsed.  Without that ability I cannot verify thumbnail generation.  Sorry.)

The effects in this ZIP file were created by Lightworks users - thank you to all who have contributed, especially khaver, who started things off.  They will run versions of Lightworks from 2023.1 on.  In the versions that support it you can directly browse and load these effects from within the Lightworks effects engine.

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
|Foreground glow               |FgndGlow.fx             |Applies a Lightworks-style glow to the foreground of a keyed or blended image |
|Four tone                     |FourTone.fx             |Extends the existing Two Tone and Tri-Tone effects to four tonal values       |
|Pencil Sketch                 |PencilSketch.fx         |Pencil sketch effect with sat/gamma/cont/bright/gain/overlay/alpha controls   |
|Poster paint                  |PosterPaint.fx          |A fully adjustable posterize effect                                           |
|Sketch                        |Sketch.fx               |Converts any standard video source or graphic to a simple sketch              |
|The dark side                 |DarkSide.fx             |Creates a shadow enhancing soft darkness "glow"                               |
|Toon                          |Toon.fx                 |The image is posterized then edge outlines are added to give a cartoon look   |

## CATEGORY FOLDER: Backgrounds
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Fractal matte 1               |FractalMatte1.fx        |Produces fractal patterns for background generation                           |
|Fractal matte 2               |FractalMatte2.fx        |Produces more fractal patterns for background generation                      |
|Fractal matte 3               |FractalMatte3.fx        |Produces still more fractal patterns for background generation                |
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
|Unpremultiply                 |UnpremultiplyFx.fx      |Removes the hard outline you can get with some blend effects                  |

## CATEGORY FOLDER: Blurs and Sharpens
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Bilateral blur                |BilateralBlur.fx        |A strong bilateral blur created by baopao with a little help from his friends |
|Directional sharpen           |DirectionalSharpen.fx   |A directional unsharp mask for when directional blurring must be corrected    |
|Focal blur                    |FocalBlur.fx            |Uses a depth map to create a faux depth of field                              |
|Ghostly blur                  |GhostlyBlur.fx          |The sort of effect that you get when looking through a fogged window          |
|Iris bokeh                    |IrisBokeh.fx            |Similar to Bokeh.fx, provides control of the iris (5 to 8 segments or round)  |
|Soft foggy blur               |SoftFoggyBlur.fx        |This blur effect mimics the classic 'petroleum jelly on the lens' look        |
|Soft motion blur              |SoftMotionBlur.fx       |This effect gives a very smooth, soft directional blur                        |
|Soft spin blur                |SoftSpinBlur.fx         |This effect uses a bidirectional blur to give an extremely smooth spin blur   |
|Soft zoom blur                |SoftZoomBlur.fx         |Similar to the Lightworks radial blur effect but very much softer             |
|Tilt shift                    |TiltShift.fx            |Simulates the shallow depth of field encountered in close-up photography      |
|Visual motion blur            |VisualMblur.fx          |Directional blur that can be set up by visually dragging a central pin point  |
|Yet another sharpen           |YAsharpen.fx            |A sharpen utility that can give extremely clean results                       |

## CATEGORY FOLDER: Border and crop
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|3D bevelled crop              |3Dbevel.fx              |A simple crop with an inner 3D bevelled edge and a flat coloured outer border |
|Bevel edged crop              |BevelCrop.fx            |This provides a crop with a bevelled border and a hard-edged drop shadow      |
|Bordered crop                 |BorderedCrop.fx         |A crop tool with border, feathering and drop shadow                           |
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

## CATEGORY FOLDER: Distortion
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|Bulge                         |BulgeFx.fx              |Allows a variable area of the frame to have a concave or convex bulge applied |
|Flag wave                     |FlagWave.fx             |Simulates a waving flag (what a surprise)                                     |
|Liquify                       |Liquify.fx              |Distorts the image in a soft liquid manner                                    |
|Magnifying glass              |Magnify.fx              |Similar in operation to a bulge effect, but performs a flat linear zoom       |
|Perspective                   |Perspective.fx          |A neat, simple effect for adding a perspective illusion to a flat plane       |
|Refraction                    |Refraction.fx           |Simulates the distortion effect of an image seen through textured glass       |
|Regional zoom                 |RegionalZoom.fx         |This allows you to apply localised distortion to any region of the frame      |
|Ripples (automatic expansion) |RipplesAuto.fx          |Radiating ripples are produced under semi-automatic control                   |
|Ripples (manual expansion)    |RipplesManual.fx        |Radiating ripples are produced under full user control                        |
|Water                         |Water.fx                |Makes waves as well as refraction, and provides X and Y adjustment            |
|Whirl                         |Whirl.fx                |Simulates what happens when water empties out of a sink                       |

## CATEGORY FOLDER: DVE Extras
|EFFECT                        |FILE NAME               |DESCRIPTION                                                                   |
|:---------------------------- |:---------------------- |:---------------------------------------------------------------------------- |
|2D DVE with repeats           |2dDVErepeats.fx         |A 2D DVE that can duplicate the foreground image as you zoom out              |
|Art Deco DVE                  |ArtDecoDVE.fx           |Art Deco flash lines are included in the 2D DVE borders                       |
|2D DVE (enhanced)             |DVEenhanced.fx          |An enhanced 2D DVE for the 21st century with Z-axis rotation                  |
|DVE with vignette             |DVEvignette.fx          |A simple DVE with circular, diamond or square shaped masking                  |
|Framed DVE                    |FramedDVE.fx            |Creates a textured frame around the foreground and resizes and positions it   |
|Rosehaven                     |Rosehaven.fx            |Creates mirrored top/bottom or left/right images                              |
|Spin zoom                     |SpinZoom.fx             |Similar to the 3D DVE, but the settings are much easier to use                |
|Tiled images                  |TiledImages.fx          |Creates tile patterns from the image, which can be rotated                    |
|Triple DVE                    |TripleDVE.fx            |Foreground, background and the overall effect have independent DVE adjustment |
|Zoom in, simple, 2021         |ZoomInSimple.fx         |Designed for simple zooming in (not recommended for negative zoom values)     |

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
|Chromakey and background      |ChromakeyAndBg.fx       |A chromakey effect with a simple DVE and cyclorama background generation      |
|Chromakey with DVE            |ChromakeyWithDVE.fx     |A version of the Lightworks Chromakey effect with cropping and a simple DVE   |
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
|Dot screen                    |DotScreen.fx            |An emulation of the dot pattern of a black and white half-tone print image    |
|Halftone                      |Halftone.fx             |Simulates the dot pattern used in a black and white half-tone print image     |
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
|RGB registration              |RGBregistration.fx      |Adjusts the X-Y registration of the RGB channels of a video stream            |
|Simple S curve                |SimpleS.fx              |This applies an S curve to the video levels to give an image that extra zing  |
|Simple star                   |SimpleStar.fx           |Creates a single rotatable star glint, with 4, 5, 6, 7 or 8 arms              |
|Vibrance                      |Vibrance.fx             |Adjusts the video vibrance                                                    |
|White and black balance       |WhiteBalance.fx         |A simple black and white balance utility                                      |

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
|Video glitch                  |VideoGlitch.fx          |Applies a glitch effect to video                                              |

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
|Color bars                    |Colorbars.fx            |Provides SMPTE-standard colour bars as an alternative to the LW EBU version   |
|Expand 16-235 to 0-255        |Expand_16_235.fx        |Expands legal video levels to full gamut RGB                                  |
|Exposure leveller             |ExposeLevel.fx          |This corrects the levels of shots where the exposure varies over time         |
|Frame lock                    |FrameLock.fx            |Locks the frame size and aspect ratio of the image to that of the sequence    |
|Safe area                     |SafeArea.fx             |This effect is probably edundant but may be useful for viewfinder simulations |
|Show highs and lows           |ShowHiLo.fx             |This effect flashes blacks and whites that exceed preset levels               |
|Shrink 0-255 to 16-235        |Shrink_16_235.fx        |Shrinks full gamut RGB signals to broadcast legal video                       |
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
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Abstraction #1            |Abstract_1_Dx.fx        |                        |Abstract geometric transition #1 between two sources |
|Abstraction #2            |Abstract_2_Dx.fx        |                        |Abstract geometric transition #2 between two sources |
|Abstraction #3            |Abstract_3_Dx.fx        |                        |Abstract geometric transition #3 between two sources |
|Erosion                   |Erosion_Dx.fx           |                        |Transitions between two sources using a mixed key    |
|Fractal dissolve          |Fractal_Dx.fx           |Fractal_Kx.fx           |Uses a fractal-like pattern as a transition          |
|Transmogrify              |Transmogrify_Dx.fx      |Transmogrify_Kx.fx      |Explodes an image into a cloud of particles          |
|Warped dissolve           |Warp_Dx.fx              |Warp_Kx.fx              |Warps between two shots                              |

## CATEGORY FOLDER: Art transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Border transition         |                        |Border_Kx.fx            |Key materialises / dematerialises in four directions |
|Dry brush mix             |DryBrush_Dx.fx          |DryBrush_Kx.fx          |Angled brush stroke transitions between shots        |
|FlareTran                 |FlareTran_Dx.fx         |                        |Dissolves between images using a burnout flare       |
|Granular dissolve         |Granular_Dx.fx          |Granular_Kx.fx          |A granular noise driven dissolve between shots       |
|Toon transition           |Toon_Dx                 |Toon_Kx                 |A stylised cartoon transition between images         |

## CATEGORY FOLDER: Blend transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|DissolveX                 |DissolveX_Dx.fx         |DissolveX_Kx.fx         |Allows blend modes to be used in a dissolve          |
|Folded neg dissolve       |FoldNeg_Dx.fx           |FoldNeg_Kx.fx           |Dissolves through a negative mix between images      |
|Folded pos dissolve       |FoldPos_Dx.fx           |FoldPos_Kx.fx           |Dissolves through a positive mix between images      |
|Non-additive mix          |NonAdd_Dx.fx            |NonAdd_Kx.fx            |Emulates the classic analog vision mixer non-add mix |
|Non-add mix ultra         |NonAddUltra_Dx.fx       |NonAddUltra_Kx.fx       |A more extreme version of a non-add mix              |
|Optical dissolve          |Optical_Dx.fx           |Optical_Kx.fx           |Simulates the burn effect of a film optical dissolve |
|S dissolve                |Sdissolve_Dx.fx         |Sdissolve_Kx.fx         |Dissolve using a trigonometric or a quadratic curve  |
|Subtractive dissolve      |Subtract_Dx.fx          |Subtract_Kx.fx          |An inverted non-additive mix                         |

## CATEGORY FOLDER: Blur transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Blur dissolve             |Blur_Dx.fx              |Blur_Kx.fx              |Uses a blur to transition between two video sources  |
|Directional blur dissolve |DirectionalBlur_Dx.fx   |DirectionalBlur_Kx.fx   |Uses a directional blur to dissolve between sources  |
|Spin dissolve             |Spin_Dx.fx              |Spin_Kx.fx              |Uses a rotational blur to dissolve between sources   |
|Swirl mix                 |SwirlMix_Dx.fx          |SwirlMix_Kx.fx          |Uses a spin effect to transition between two sources |
|Whip pan                  |WhipPan_Dx.fx           |WhipPan_Kx.fx           |Uses a directional blur to simulate a whip pan       |
|Zoom dissolve             |Zoom_Dx.fx              |Zoom_Kx.fx              |Zooms between the two sources                        |

## CATEGORY FOLDER: Colour transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Colour sizzler            |ColourSizzler_Dx.fx     |ColourSizzler_Kx.fx     |Dissolves through a complex colour translation       |
|Dissolve thru colour      |Colour_Dx.fx            |Colour_Kx.fx            |Dissolves through a user-selected colour field       |
|Dissolve thru flat colour |FlatColour_Dx.fx        |                        |Dissolves through a flat colour between shots        |
|RGB drifter               |RGBdrifter_Dx.fx        |RGBdrifter_Kx.fx        |Dissolves using different R, G and B curves          |

## CATEGORY FOLDER: DVE transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Barn door squeeze         |BarndoorSqueeze_Dx.fx   |BarndoorSqueeze_Kx.fx   |A barn door squeeze to/from the edge of frame        |
|Corner squeeze            |CornerSqueeze_Dx.fx     |CornerSqueeze_Kx.fx     |Corner wipe effect that squeezes or expands images   |
|Pinch transition          |Pinch_Dx.fx             |Pinch_Kx.fx             |Pinches the outgoing video to a user-defined point   |
|Radial pinch              |rPinch_Dx.fx            |rPinch_Kx.fx            |Radially pinches the outgoing video                  |
|Split and zoom            |SplitAndZoom_Dx.fx      |                        |Splits outgoing video to reveal incoming zoom shot   |
|Squeeze transition        |                        |Squeeze_Kx.fx           |A squeeze effect for blended images                  |
|Stretch transition        |Stretch_Dx.fx           |Stretch_Kx.fx           |Stretches the image horizontally through dissolve    |
|X-pinch                   |xPinch_Dx.fx            |xPinch_Kx.fx            |Pinches outgoing video to an X-shape then a point    |

## CATEGORY FOLDER: Fades and non mixes
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Chinagraph pencil         |Chinagraph_Dx.fx        |                        |Simulates the chinagraph marks used by film editors  |
|Fades                     |Fades_Dx.fx             |                        |Fades video to or from black                         |
|Optical fades             |OpticalFades_Dx.fx      |                        |Simulates the black crush effect of a film optical   |

## CATEGORY FOLDER: Geometric transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Block dissolve            |Block_Dx.fx             |Block_Kx.fx             |Builds the outgoing image into growing blocks        |
|Coloured tiles            |ColourTile_Dx.fx        |                        |Transition using a highly coloured mosaic pattern    |
|Kaleido turbine mix       |KaleidoTurbineMix_Dx.fx |KaleidoTurbineMix_Kx.fx |A kaleidoscope transitions between two clips         |
|Mosaic transfer           |Mosaic_Dx.fx            |                        |Obliterates the outgoing image into expanding blocks |
|Rotating transition       |Rotating_Dx.fx          |Rotating_Kx.fx          |X or Y axis rotating transition                      |
|Tiled split               |TiledSplit_Dx.fx        |TiledSplit_Kx.fx        |Splits the video into tiles and blows them apart     |

## CATEGORY FOLDER: Special Fx transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Dream sequence            |Dream_Dx.fx             |Dream_Kx.fx             |Ripples the images as it dissolves between them      |
|Fireball transition       |Fireballs_Dx.fx         |                        |Uses a hot fireball to transition between sources    |
|Fireball transition B     |Fireballs_B_Dx.fx       |                        |A varaiant of the previous fireball effect           |
|Fly away                  |Fly_Away_Dx.fx          |                        |Flies the outgoing image out to reveal the incoming  |
|Page Roll                 |Page_Roll_Dx.fx         |                        |The classic page turn transition                     |
|Sinusoidal mix            |Sine_Dx.fx              |Sine_Kx.fx              |Uses a sine distortion to transition between inputs  |
|The twister               |Twister_Dx.fx           |Twister_Kx.fx           |Performs a rippling twist transition between images  |
|Twist it                  |TwistIt_Dx.fx           |                        |Twists one image to another vertically/horizontally  |
|Wave collapse             |                        |WaveCollapse_Kx.fx      |Compresses the foreground to sinue strips or waves   |

## CATEGORY FOLDER: Wipe transitions
|EFFECT                    |DISSOLVE                |KEYED TRANSITION        |DESCRIPTION                                          |
|:------------------------ |:---------------------- |:---------------------- |:--------------------------------------------------- |
|Bar wipe                  |                        |Bars_Kx.fx              |Splits a foreground image into strips which separate |
|Barn door split           |BarnDoorSplit_Dx.fx     |BarnDoorSplit_Kx.fx     |Splits the image in half and separates the halves    |
|Corner split              |CornerSplit_Dx.fx       |CornerSplit_Kx.fx       |Splits an image four ways to or from the corners     |
|Push transition           |                        |Push_Kx.fx              |Pushes the foreground on or off screen               |
|Slice transition          |Slice_Dx.fx             |Slice_Kx.fx             |Separates and splits the image into strips           |
|Strips                    |                        |Strips_Kx.fx            |Splits the foreground into compressed strips         |

