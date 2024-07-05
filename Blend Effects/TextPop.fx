// @Maintainer jwrl
// @Released 2024-07-05
// @Author schrauber
// @Author jwrl
// @Created 2024-07-05

/**
 So what does Text pop actually do?  It changes the softness, transparency and edge
 sharpness of text connected to the Fg input.  That in turn makes it possible to
 change fonts in the standard text effect in very interesting ways.  It can alter
 its contouring, modify the edge sharpness, increase the outline thickness and
 add internal glow effects.  To get the most out of it you will need to experiment,
 but it will definitely repay the effort.

 It will work with both title and image key effects.  When key mode is set to normal
 blend the text or image key must not have it's input connected.  If it does the Bg
 (background) video will also be affected.

 When key mode is set to auto extract the video connected to Fg must include the
 background video.  The clean background video must also be connected to Bg.  That
 will then be used to calculate the difference between the two inputs which will
 extract the text from the background.  The separation can be fine tuned using the
 extraction control, which only functions in this mode.

 NOTE 1:  This effect was first mocked up by schrauber using a combination of his
 own and Lightworks effects.  The functionality of those effects was then combined
 into new code by me, jwrl.  It clearly uses schrauber's ideas and design so he is
 very definitely the co-author.

 NOTE 2:  Schrauber's original effect combination used much more blur than this one
 does.  I found that too much blur destroyed the readability of the text.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TextPop.fx
//
// Version history:
//
// Built 2024-07-05 by jwrl from schrauber's design.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Text pop", "Stylize", "Blend Effects", "Applies a range of effects to make text pop", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Mixture, "Mix",     kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam   (Display, "Display",    "Text source", 3, "Passthrough / blend|Extracted text|Processed text|Composite output");
DeclareIntParam   (KeyMode, "Key mode",   "Text source", 1, "Internal blend|Auto extract");
DeclareFloatParam (Extract, "Extraction", "Text source", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (TextSpread, "Text spread", "Text processing", kNoFlags, 0.1,  0.0, 1.0);
DeclareFloatParam (TextGamma,  "Text gamma",  "Text processing", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (EdgeHarden, "Edge harden", "Text processing", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (Feathering, "Feathering",  "Text processing", kNoFlags, 0.0,  0.0, 1.0);

DeclareFloatParam (Sharpen,      "Sharpen",       "Text sharpness", kNoFlags, 0.5,   0.0, 1.0);
DeclareFloatParam (SampleOffset, "Sample offset", "Text sharpness", kNoFlags, 2.0,   0.0, 6.0);
DeclareFloatParam (EdgeClamp,    "Edge clamp",    "Text sharpness", kNoFlags, 0.125, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA     float3(0.897, 1.761, 0.342)

#define PI_HALF  1.5708    // 90 degrees in radians
#define PI_SIXTH 0.5236    // 30 degrees in radians

#define OFFSET_1 0.1309    // 7.5 degrees in radians
#define OFFSET_2 0.2618    // 15
#define OFFSET_3 0.3927    // 22.5

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 checkerboard (float2 uv)
{
   float x = round (frac (uv.x * _OutputWidth  / 40.0));
   float y = round (frac (uv.y * _OutputHeight / 40.0));

   return float4 (clamp (abs (x - y), 0.6, 0.8).xxx, 0.0);
}

float4 fn_Blur (sampler2D S, float2 uv, float offset)
{
   if (Display < 2) return tex2D (S, uv);

   float blur = TextSpread * 0.006;

   uv -= 0.5.xx;
   uv *= 1.0 - (blur * 0.1);
   uv += 0.5.xx;

   float2 radius = float2 (1.0, _OutputAspectRatio) * blur;
   float2 angle  = float2 (offset + PI_HALF, offset);
   float2 coord, sample;

   float4 cOut = tex2D (S, uv);

   for (int tap = 0; tap < 12; tap++) {
      sample = sin (angle);
      coord  = (1.0.xx - abs (1.0.xx - abs (uv))) + (sample * radius);
      cOut  += tex2D (S, coord);
      angle += PI_SIXTH;
   }

   return cOut / 13.0;
}

float4 fixVideo (float4 video)
{
   float gamma = 1.0 / pow ((TextGamma * 0.9) + 1.0, 3.5875);

   return float4 (pow (video.rgb, clamp (gamma, 0.1, 10.0)), video.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   if (KeyMode) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, Extract, distance (Bgnd.rgb, Fgnd.rgb));
   }

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (B_1)
{
   return fn_Blur (Fgd, uv3, 0.0);
}

DeclarePass (B_2)
{
   return fn_Blur (B_1, uv3, OFFSET_1);
}

DeclarePass (B_3)
{
   return fn_Blur (B_2, uv3, OFFSET_2);
}

DeclarePass (Blur)
{
   return fn_Blur (B_3, uv3, OFFSET_3);
}

DeclareEntryPoint (TextPop)
{
   float4 Fgnd = tex2D (Blur, uv3);
   float4 Bgnd = (Display > 0) && (Display < 3) ? checkerboard (uv3) : tex2D (Bgd, uv3);

   float mask = tex2D (Mask, uv3).x;

   if (Display > 1) {
      float clamp = max (1.0e-6, EdgeClamp);

      float2 sampleX = float2 (SampleOffset / _OutputWidth, 0.0);
      float2 sampleY = float2 (0.0, SampleOffset / _OutputHeight);

      float4 luma_val = float4 (LUMA * Sharpen / clamp, 0.5);
      float4 edges = tex2D (Blur, uv3 + sampleY);

      edges += tex2D (Blur, uv3 - sampleX);
      edges += tex2D (Blur, uv3 + sampleX);
      edges += tex2D (Blur, uv3 - sampleY);
      edges = Fgnd - (edges / 4.0);
      edges.a = 1.0;

      Fgnd.rgb += ((saturate (dot (edges, luma_val)) * clamp * 2.0) - clamp).xxx;

      float clipMin = saturate (EdgeHarden) * 0.9;
      float clipRng = lerp (clipMin + 1e-6, 1.0, saturate (Feathering)) - clipMin;
      float alpha   = saturate ((Fgnd.a - clipMin) / clipRng);

      Fgnd   = fixVideo (Fgnd);
      Fgnd.a = alpha;
      Fgnd   = lerp (tex2D (Fgd, uv3), Fgnd, Mixture);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a * mask * Opacity);
}

