// @Maintainer jwrl
// @Released 2020-06-27
// @Author jwrl
// @Created 2020-06-27
// @see https://www.lwks.com/media/kunena/attachments/6375/Rainbow__640.png

/**
 This is a special effect that simply generates rainbows.  You can use it to create standard
 single rainbows, so-called moon dogs and sun dogs, and even double rainbows, the second
 rainbow inverted and outside the primary one.  The blue end of the spectrum has adjustable
 falloff.

 The rainbow is blended with the background image using a screen blend and can be varied
 in intensity.  The default settings produce a 90 degree arch (plus and minus 45 degrees),
 but that can be adjusted to whatever angle that you need.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow.fx
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
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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
   string Enum = "Standard rainbow,Double rainbow,Moon/sun dog";
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
   float MinVal = 0.2;
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
   string Group = "Crop angle";
   string Description = "Left side";
   float MinVal = -90.0;
   float MaxVal = 90.0;
> = -45.0;

float L_softness
<
   string Group = "Crop angle";
   string Description = "Left softness";
   float MinVal = 0.0;
   float MaxVal = 30.0;
> = 10.0;

float R_angle
<
   string Group = "Crop angle";
   string Description = "Right side";
   float MinVal = -90.0;
   float MaxVal = 90.0;
> = 45.0;

float R_softness
<
   string Group = "Crop angle";
   string Description = "Right softness";
   float MinVal = 0.0;
   float MaxVal = 30.0;
> = 10.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CIRCLE  0.7927904259
#define RADIUS  1.6666666667
#define SUNDOG  0.2642634753
#define FEATHER 0.002

#define WHITE   1.0.xxxx
#define EMPTY   0.0.xxxx

#define HUE     float3(1.0, 2.0 / 3.0, 1.0 / 3.0)

float _OutputAspectRatio;

float2 _rotate [] = { { 0.1305261922, 0.9914448614 }, { 0.3826834324, 0.9238795325 },
                      { 0.6087614290, 0.7933533403 }, { 0.7933533403, 0.6087614290 },
                      { 0.9238795325, 0.3826834324 }, { 0.9914448614, 0.1305261922 } };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD0) : COLOR
{
   float4 retval = WHITE;

   float2 xy1, xy2, xy = float2 (uv.x - Pos_X, 1.0 - uv.y - Pos_Y);
   float2 shadow, inv = float2 (xy.y, -xy.x);

   float shading, angle = L_angle - 90.0;

   sincos (radians (angle), xy1.y, xy1.x);
   angle += L_softness;
   sincos (radians (angle), xy2.y, xy2.x);

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   float2 edg = (xy * xy1.x) - (inv * xy1.y);
   float2 bdr = (xy * xy2.x) - (inv * xy2.y);

   if ((bdr.x <= 0.0) || (bdr.y <= 0.0)) { shading = 1.0;}
   else {
      shadow  = saturate (bdr / distance (bdr, edg));
      shading = 1.0 - min (shadow.x, shadow.y);
   }

   retval = (edg.x < 0.0) || (edg.y < 0.0)
          ? (xy.x < 0.0) && (L_angle > 0.0) ? EMPTY : shading.xxxx : EMPTY;

   angle = 270.0 - R_angle;
   inv = xy.yx;
   xy.x = -xy.x;

   sincos (radians (angle), xy1.y, xy1.x);
   angle += R_softness;
   sincos (radians (angle), xy2.y, xy2.x);

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   edg = (xy * xy1.x) - (inv * xy1.y);
   bdr = (xy * xy2.x) - (inv * xy2.y);

   if ((bdr.x <= 0.0) || (bdr.y <= 0.0)) { shading = 1.0;}
   else {
      shadow  = saturate (bdr / distance (bdr, edg));
      shading = 1.0 - min (shadow.x, shadow.y);
   }

   retval.g = (edg.x < 0.0) || (edg.y < 0.0)
            ? (xy.x < 0.0) && (R_angle < 0.0) ? 0.0 : shading : 0.0;

   return (xy.y < 0.0) ? EMPTY : (retval.g * retval.a).xxxx;
}

float4 ps_sundog (float2 uv : TEXCOORD0) : COLOR
{
   float radius = max (0.2, Radius);
   float width  = Width * radius;
   float inner  = radius * SUNDOG;
   float outer  = inner + (width * 17.0);
   float alpha;

   float2 posXY = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (posXY.x, posXY.y / _OutputAspectRatio)) * RADIUS;

   if ((radius < inner) || (radius > outer)) return EMPTY;

   float4 Fgnd = saturate ((radius - inner) / width).xxxx;

   Fgnd.rgb = 1.0.xxx - Fgnd.aaa;
   Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
   Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
   alpha    = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
   Fgnd.a   = lerp (alpha, alpha * (Fgnd.a - (Fgnd.g / 3.0)), Falloff);

   return saturate (Fgnd);
}

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Input, uv);
   float4 Mask = tex2D (s_Mask, uv);

   float radius = max (0.2, Radius);
   float width  = Width * radius;
   float inner  = radius * CIRCLE;
   float outer  = inner + (width * 17.0);
   float alpha;

   float2 posXY = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (posXY.x, posXY.y / _OutputAspectRatio)) * RADIUS;

   if ((radius < inner) || (radius > outer)) return Bgnd;

   float4 Fgnd = saturate ((radius - inner) / width).xxxx;

   Fgnd.rgb = 1.0.xxx - Fgnd.aaa;
   Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
   Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
   alpha    = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
   Fgnd.a   = lerp (alpha, alpha * (Fgnd.a - (Fgnd.g / 3.0)), Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);

   Fgnd = saturate (Fgnd);

   return lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a * Amount), Mask.a);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Rainbow, uv);
   float4 Mask = tex2D (s_Mask, uv);

   float radius = max (0.2, Radius) * 1.2;
   float width  = Width * radius;
   float inner  = radius * CIRCLE;
   float outer  = inner + (width * 17.0);
   float alpha;

   float2 posXY = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   radius = length (float2 (posXY.x, posXY.y / _OutputAspectRatio)) * RADIUS;

   if ((radius < inner) || (radius > outer)) return Bgnd;

   float4 Fgnd = saturate ((radius - inner) / width).xxxx;

   Fgnd.rgb = saturate ((Fgnd.rgb * 1.2) - 0.1.xxx);
   Fgnd.rgb = saturate (abs (frac ((Fgnd.rgb * 0.8) + HUE) * 6.0 - 3.0) - 1.0.xxx);
   alpha    = 3.0 - (abs (Fgnd.a - 0.5) * 6.0);
   Fgnd.a   = lerp (alpha, alpha * (1.0 - Fgnd.a - (Fgnd.g / 3.0)), Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);

   Fgnd = saturate (Fgnd);

   return lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a * Amount * 0.25), Mask.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Rainbow, uv);
   float4 Bgnd = tex2D (s_Input, uv);

   float2 xy, feather = float2 (1.0, _OutputAspectRatio) * FEATHER;

   for (int i = 0; i < 6; i++) {
      xy = feather * _rotate [i];
      Fgnd += tex2D (s_Rainbow, uv + xy);
      Fgnd += tex2D (s_Rainbow, uv - xy);
      xy.y = -xy.y;
      Fgnd += tex2D (s_Rainbow, uv + xy);
      Fgnd += tex2D (s_Rainbow, uv - xy);
   }

   Fgnd /= 25.0;
   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
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
   < string Script = "RenderColorTarget0 = Bow;"; > 
   { PixelShader = compile PROFILE ps_sundog (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_2 (); }
}

