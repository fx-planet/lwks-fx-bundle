// @Maintainer jwrl
// @Released 2020-08-10
// @Author jwrl
// @Created 2020-06-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Rainbow__640.png

/**
 This is a special effect that simply generates rainbows.  You can use it to create single
 rainbows, so-called moon dogs and even double rainbows and moondogs.  Cropping is disabled
 in moondog mode.  The blue end of the spectrum has adjustable falloff to give a fade out
 that is more like what happens in nature.  The second rainbow is inverted and positioned
 outside of the primary one by an adjustable offset amount.  It is also reduced in level.

 The rainbow is blended with the background image using a screen blend and can be varied
 in intensity.  The default crop settings will produce a 90 degree arc (plus and minus 45
 degrees), but that can be adjusted to whatever angle that you need over a 180 degree span.
 The secondary rainbow if used inherits most settings from the primary one, but the crop
 angle can be independently adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow.fx
//
// Version history:
//
// Modified jwrl 2020-08-10:
// Rewrote the mask generation so that the mask shader is very much simpler and only
// need be executed once, even in double rainbow mode.
// As a result of the above, only the mask angle calculation is now done in fn_mask().
//
// Modified jwrl 2020-07-02:
// Added radius and level adjustment for moonglow.
// Split mask generation core code into a function to avoid needless duplication.
//
// Modified jwrl 2020-06-30:
// Added offset and crops for second rainbow.
// Added a second outer moondog layer.
// Added moonglow to moondog.
// Dropped references to sundog.  At the moment I can't simulate that to my satisfaction.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rainbow";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Red and yellow and pink and green, purple and orange and blue ...";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Bow : RenderColorTarget;
texture Msk : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_Rainbow = sampler_state { Texture = <Bow>; };

sampler s_Mask = sampler_state
{
   Texture   = <Msk>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Mode";
   string Enum = "Single rainbow,Double rainbow,Single moondog,Double moondog";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Radius
<
   string Description = "Radius";
   float MinVal = 0.1;
   float MaxVal = 2.0;
> = 0.6666666666;

float Width
<
   string Description = "Width";
   float MinVal = 0.05;
   float MaxVal = 0.2;
> = 0.075;

float Falloff
<
   string Description = "Falloff";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_X
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_Y
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3333333333;

float L_angle
<
   string Group = "Crop angle / moondog glow";
   string Description = "Left / amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float L_softness
<
   string Group = "Crop angle / moondog glow";
   string Description = "Left softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.525;
> = 0.175;

float R_angle
<
   string Group = "Crop angle / moondog glow";
   string Description = "Right / radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float R_softness
<
   string Group = "Crop angle / moondog glow";
   string Description = "Right softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.525;
> = 0.175;

float Offset
<
   string Group = "Double rainbow";
   string Description = "Offset";
   float MinVal = 0.2;
   float MaxVal = 0.8;
> = 0.2;

float L_angle_2
<
   string Group = "Double rainbow";
   string Description = "Left crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float R_angle_2
<
   string Group = "Double rainbow";
   string Description = "Right crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CIRCLE     0.7927904259
#define RADIUS     1.6666666667
#define MOONDOG    0.2642634753

#define EMPTY      0.0.xxxx

#define PI         3.1415926536

#define HUE        float3(1.0, 2.0 / 3.0, 1.0 / 3.0)
#define LUMA       float3(0.2989, 0.5866, 0.1145)

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s_Sampler, uv);
}

float4 fn_mask (float angL, float angR, float2 uv)
{
   float c, s;

   sincos (PI * angL, s, c);

   float2 edges = float2 (angL * L_softness, angR * R_softness) * 0.762;
   float3 xyz = float3 (-uv.x, (edges - uv.yy) / _OutputAspectRatio) * 0.25;
   float2 xy = mul (float2x2 (c, -s, s, c), xyz.xy);

   xy.x += 0.5;
   xy.y *= _OutputAspectRatio;

   float mask = fn_tex2D (s_Mask, xy).w;

   sincos (PI * angR, s, c);
   xy = mul (float2x2 (c, -s, s, c), xyz.xz);
   xy.x += 0.5;
   xy.y *= _OutputAspectRatio;

   return 1.0 - max (mask, fn_tex2D (s_Mask, xy).x);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD0) : COLOR
{
   float range = uv.y * 19.05;

   float L = (range > L_softness) ? 1.0 : range / max (1e-10, L_softness);
   float R = (range > R_softness) ? 1.0 : range / max (1e-10, R_softness);

   return float4 (R, L, R, L);
}

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Input, uv);

   float radius = max (0.1, Radius);
   float width  = Width * radius;
   float inner  = radius * CIRCLE;
   float outer  = inner + (width * 17.0);
   float alpha;

   float2 xy = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (xy.x, xy.y / _OutputAspectRatio)) * RADIUS;

   if ((xy.y < 0.0) || (radius < inner) || (radius > outer)) return Bgnd;

   float4 Fgnd = saturate ((radius - inner) / width).xxxx;

   Fgnd.rgb = 1.0.xxx - Fgnd.aaa;
   Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
   Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
   alpha    = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
   Fgnd.a   = lerp (alpha, alpha * (Fgnd.a - (Fgnd.g / 3.0)), Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Bgnd, Fgnd, fn_mask (-L_angle, 1.0 - R_angle, xy));
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Rainbow, uv);

   float radius = max (0.1, Radius) * (1.0 + Offset);
   float width  = Width * radius;
   float inner  = radius * CIRCLE;
   float outer  = inner + (width * 17.0);
   float alpha;

   float2 xy = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (xy.x, xy.y / _OutputAspectRatio)) * RADIUS;

   if ((xy.y < 0.0) || (radius < inner) || (radius > outer)) return Bgnd;

   float4 Fgnd = saturate ((radius - inner) / width).xxxx;

   Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
   Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
   alpha    = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
   Fgnd.a   = lerp (alpha, alpha * (1.0 - Fgnd.a - (Fgnd.g / 3.0)), Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount * 0.25);

   return lerp (Bgnd, Fgnd, fn_mask (-L_angle_2, 1.0 - R_angle_2, xy));
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float radius = max (0.1, Radius);
   float width  = Width * radius * 4.0;
   float inner  = radius * MOONDOG;
   float outer  = inner + (width * 35.0);
   float alpha  = 0.0;

   float2 posXY = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (posXY.x, posXY.y / _OutputAspectRatio)) * RADIUS;

   float4 Fgnd, Bgnd = tex2D (s_Input, uv);

   if (radius > outer) { Fgnd = EMPTY; }
   else {
      if (radius < inner) { Fgnd = EMPTY; }
      else {
         Fgnd = saturate ((radius - inner) / width).xxxx;

         Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
         Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
         alpha  = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
         Fgnd.a = lerp (alpha, alpha * (1.0 - Fgnd.a - (Fgnd.g / 3.0)), Falloff);
         Fgnd.a = saturate (Fgnd.a);
         Fgnd.rgb *= saturate (Fgnd.a * 10.0);
      }

      alpha = (1.0 - smoothstep (0.0, R_angle * Radius * 2.5, radius)) * L_angle;
   }

   Bgnd.rgb = saturate (Bgnd.rgb + alpha.xxx - (Bgnd.rgb * alpha));
   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_3 (float2 uv : TEXCOORD1) : COLOR
{
   float radius = max (0.1, Radius) * (1.35 + Offset);
   float width  = Width * radius * 2.0;
   float inner  = radius * MOONDOG;
   float outer  = inner + (width * 35.0);

   float2 posXY = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (posXY.x, posXY.y / _OutputAspectRatio)) * RADIUS;

   float4 Fgnd, Bgnd = tex2D (s_Rainbow, uv);

   if ((radius < inner) || (radius > outer)) { Fgnd = EMPTY; }
   else {
      Fgnd = saturate ((radius - inner) / width).xxxx;

      Fgnd.rgb = 1.0.xxx - Fgnd.aaa;
      Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
      Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);

      float alpha = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);

      Fgnd.a = saturate (lerp (alpha, alpha * (Fgnd.a - (Fgnd.g / 3.0)), Falloff));
      Fgnd.rgb *= saturate (Fgnd.a * 10.0);
   }

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount * 0.25);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Rainbow_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Msk;"; > 
   { PixelShader = compile PROFILE ps_mask (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique Rainbow_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Msk;"; > 
   { PixelShader = compile PROFILE ps_mask (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bow;"; > 
   { PixelShader = compile PROFILE ps_main_0 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Rainbow_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

technique Rainbow_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bow;"; > 
   { PixelShader = compile PROFILE ps_main_2 (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_3 (); }
}
