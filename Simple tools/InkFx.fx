// @Maintainer jwrl
// @Released 2021-10-19
// @Author "Nicholas Carroll"
// @Created 2016-05-02
// @see https://www.lwks.com/media/kunena/attachments/6375/INK_640.png

/**
 INK is a proportionate colour difference keyer
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect InkFx.fx
//
// Copyright 2016 Nicholas Carroll http://casanico.com
//
// INK is free software: you can redistribute it and/or modify it under the terms of
// the GNU General Public License published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version. See
// http://www.gnu.org/licenses/gpl-3.0.html
//
// VERSION HISTORY
// 1.0  N. Carroll  2-MAY-16  First version
// 1.1  jwrl        2-MAY-16  Reworked to remove array indexing which didn't work
// 1.2  N. Carroll  4-MAY-16  Put the matte in the alpha channel.
//
// Version history:
//
// Update 2021-10-19 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "INK";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "INK is a quick, simple and effective proportionate colour difference keyer";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0,1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_RawFg);
DefineInput (bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 keyColor
<
   string Description = "Key Colour";
> = { 0.2, 1.0, 0.0, 1.0 };

float bal
<
   string Description = "Key Balance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_main (float2 xy : TEXCOORD3) : COLOR
{
   float4 foreground = tex2D (s_Foreground, xy);
   float4 background = tex2D (s_Background, xy);

   float3 chan, P = foreground.rgb;
   float3 K = keyColor.rgb;

   float nbal = 1 - bal;

   int minKey = 0;
   int midKey = 1;
   int maxKey = 2;

   if (keyColor.b <= keyColor.r && keyColor.r <= keyColor.g) {
      minKey = 2;
      midKey = 0;
      maxKey = 1;
      P = foreground.brg;
      K = keyColor.brg;
   }
   else if (keyColor.r <= keyColor.b && keyColor.b <= keyColor.g) {
      minKey = 0;
      midKey = 2;
      maxKey = 1;
      P = foreground.rbg;
      K = keyColor.rbg;
   }
   else if (keyColor.g <= keyColor.b && keyColor.b <= keyColor.r) {
      minKey = 1;
      midKey = 2;
      maxKey = 0;
      P = foreground.gbr;
      K = keyColor.gbr;
   }
   else if (keyColor.g <= keyColor.r && keyColor.r <= keyColor.b) {
      minKey = 1;
      midKey = 0;
      maxKey = 2;
      P = foreground.grb;
      K = keyColor.grb;
   }
   else if (keyColor.b <= keyColor.g && keyColor.g <= keyColor.r) {
      minKey = 2;
      midKey = 1;
      maxKey = 0;
      P = foreground.bgr;
      K = keyColor.bgr;
   }

   // solve minKey

   float min1 = (P.x / (P.z - bal * P.y) - K.x / (K.z - bal * K.y))
              / (1 + P.x / (P.z - bal * P.y) - (2 - bal) * K.x / (K.z - bal * K.y));
   float min2 = min (P.x, (P.z - bal * P.y) * min1 / (1 - min1));

   if (minKey == 0) chan.r = saturate (min2);
   else if (minKey == 1) chan.g = saturate (min2);
   else chan.b = saturate (min2);

   // solve midKey

   float mid1 = (P.y / (P.z - nbal * P.x) - K.y / (K.z - nbal * K.x)) 
              / (1 + P.y / (P.z - nbal * P.x) - (1 + bal) * K.y / (K.z - nbal * K.x));
   float mid2 = min (P.y, (P.z - nbal * P.x) * mid1 / (1 - mid1));

   if (midKey == 0) chan.r = saturate (mid2);
   else if (midKey == 1) chan.g = saturate (mid2);
   else chan.b = saturate (mid2);

   // solve chan.z (chan [maxKey])

   float max1 = min (P.z, (bal * min (P.y, (P.z - nbal * P.x) * mid1 / (1 - mid1))
              + nbal * min (P.x, (P.z - bal * P.y) * min1 / (1 - min1))));

   if (maxKey == 0) chan.r = saturate (max1);
   else if (maxKey == 1) chan.g = saturate (max1);
   else chan.b = saturate (max1);

   // solve alpha

   float a1 = (1 - K.z) + (bal * K.y + (1 - bal) * K.x);
   float a2 = 1 + a1 / abs (1 - a1);
   float a3 = (1 - P.z) - P.z * (a2 - (1 + (bal * P.y + (1 - bal) * P.x) / P.z * a2));
   float a4 = max (chan.g, max (a3, chan.b));

   float matte = saturate (a4);          // alpha

   return float4 ((chan + background.rgb * (1 - matte)), matte);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique MyTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_main)
}

