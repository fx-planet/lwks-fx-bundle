// @Author: jwrl
// @ReleaseDate: 2017-01-11
// @Picture: https://www.lwks.com/media/kunena/attachments/6375/MagicEdge_2.png
//--------------------------------------------------------------//
// Lightworks user effect MagicEdges.fx
//
// Created by LW user jwrl 8 May 2016.
//  LW 14+ version by jwrl 11 January 2017
//  Category changed from "Mixes" to "Keying"
//  Subcategory "Edge Effects" added.
//
// The fractal generation component was created by Robert
// Schütze in GLSL sandbox (http://glslsandbox.com/e#29611.0).
// It has been somewhat modified to better suit the needs of its
// use in this context.
//
// The star point component is based on khaver's Glint.fx, but
// modified to have no blur component, no choice of star points,
// and to compile and run under the ps_2_0 shader5 profile.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  It returns only half the actual frame
// height when interlaced media is playing and only when it
// is playing.  This fix will be reliable even if the LW bug
// is fixed.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for
// undefined samplers they have now been explicitly declared.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Magic edges";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Fractals : RenderColorTarget;
texture Borders  : RenderColorTarget;
texture built    : RenderColorTarget;

texture Sample1 : RenderColorTarget;
texture Sample2 : RenderColorTarget;
texture Sample3 : RenderColorTarget;
texture Sample4 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Frac_Sampler = sampler_state {
   Texture   = <Fractals>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler bord_Sampler = sampler_state {
   Texture   = <Borders>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler buildSampler = sampler_state {
   Texture   = <built>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state {
   Texture   = <Sample1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state {
   Texture = <Sample2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp3 = sampler_state {
   Texture = <Sample3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp4 = sampler_state {
   Texture = <Sample4>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeWidth
<
   string Description = "Edge width";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Rate
<
   string Description = "Speed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Description = "Start point";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float adjust
<
   string Group = "Stars";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float bright
<
   string Group = "Stars";
   string Description = "Brightness";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float StarLen
<
   string Group = "Stars";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 5.0;

float Rotation
<
   string Group = "Stars";
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 0.0;

float Strength
<
   string Group = "Stars";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Size
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointZ";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ColourMix
<
   string Description = "Colour modulation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Modulation value";
   bool SupportsAlpha = false;
> = (0.69, 0.26, 1.0, 1.0);

bool ShowFractal
<
   string Description = "Show pattern";
> = false;

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

#define PI_2       6.28319

#define R_VAL      0.2989
#define G_VAL      0.5866
#define B_VAL      0.1145

#define ROTATE_45  0.7854     // 45.0, 1.0
#define ROTATE_135 2.35619    // 135.0, 1.0
#define ROTATE_225 3.92699    // 45.0, -1.0
#define ROTATE_315 5.49779    // 135.0, -1.0

#define SCL_RATE   224

#define LOOP       60

#define DELTANG    25
#define ALIASFIX   50         // DELTANG * 2
#define ANGLE      0.125664

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_fractals (float2 uv : TEXCOORD1) : COLOR
{
   float progress = ((_Progress + StartPoint) * PI_2) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5;
   float2 xy = uv - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.01), seed.x);

   float4 fg = tex2D (FgSampler, uv);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   retval = saturate (retval);

   float luma = (retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL);
   float Yscl = (Colour.r * R_VAL) + (Colour.g * G_VAL) + (Colour.b * B_VAL);

   Yscl = saturate (Yscl - 0.5);
   Yscl = 1 / (Yscl + 0.5);

   float4 buffer = Colour * luma  * Yscl;

   return float4 (lerp (retval, buffer.rgb, ColourMix), fg.a);
}

float4 ps_border (float2 uv : TEXCOORD1) : COLOR
{
   float4 fgImage = tex2D (FgSampler, uv);

   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * 10.0 / _OutputWidth;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   float4 retval;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (FgSampler, uv + offset).a;
      border += tex2D (FgSampler, uv - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, fgImage.a);

   return border.xxxx;
}

float4 ps_build (float2 uv : TEXCOORD1) : COLOR
{
   float4 fractal = tex2D (Frac_Sampler, uv);
   float4 retval;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float border = 0.0;
   float angle  = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (bord_Sampler, uv + offset).a;
      border += tex2D (bord_Sampler, uv - offset).a;
      angle += ANGLE;
   }

   retval.a   = border / ALIASFIX;
   retval.rgb = lerp (0.0.xxx, fractal.rgb, retval.a);

   return retval;
}

float4 ps_adjust (float2 uv : TEXCOORD1) : COLOR
{
   float4 Color = tex2D (buildSampler, uv);

   return !((Color.r + Color.g + Color.b) / 3.0 > 1.0 - adjust) ? 0.0.xxxx : Color;
}

float4 ps_stretch_1 (float2 uv : TEXCOORD1, uniform float rn_angle) : COLOR
{
   float3 delt, ret = 0.0;

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float lenStar = StarLen * pixel;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= lenStar;
   offset.y *= _OutputAspectRatio;

   for (int count = 0; count < 16; count++) {
      delt = tex2D (Samp1, uv - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   for (int count = 16; count < 22; count++) {
      delt = tex2D (Samp1, uv - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 uv : TEXCOORD1, uniform float rn_angle, uniform int samp) : COLOR
{
   float3 delt, ret = 0.0;

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float lenStar = StarLen * pixel;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= lenStar;
   offset.y *= _OutputAspectRatio;

   float4 insamp = (samp == 0) ? tex2D (Samp3, uv) : (samp != -1) ? tex2D (Samp4, uv) : 0.0;

   for (int count = 22; count < 36; count++) {
      delt = tex2D (Samp1, uv - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   ret = (ret + tex2D (Samp2, uv).rgb) / 36;

   return saturate (max (float4 (ret * bright, 1.0), insamp));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd    = tex2D (FgSampler, uv);
   float4 Bgd    = tex2D (BgSampler, uv);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   float4 border = tex2D (buildSampler, uv);

   if (ShowFractal) return lerp (tex2D (Frac_Sampler, uv), border, (border.a + 1.0) / 2);

   retval = lerp (border, retval, 1.0 - border.a);

   float4 glint = tex2D (Samp4, uv);
   float4 comb  = retval + (glint * (1.0 - retval));

   return lerp (retval, comb, Strength);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique doMatte
{
   pass Pass_zero
   <
      string Script = "RenderColorTarget0 = Fractals;";
   >
   {
      PixelShader = compile PROFILE ps_fractals ();
   }

   pass Pass_one
   <
      string Script = "RenderColorTarget0 = Borders;";
   >
   {
      PixelShader = compile PROFILE ps_border ();
   }

   pass Pass_two
   <
      string Script = "RenderColorTarget0 = built;";
   >
   {
      PixelShader = compile PROFILE ps_build ();
   }

   pass Pass_three
   <
      string Script = "RenderColorTarget0 = Sample1;";
   >
   {
      PixelShader = compile PROFILE ps_adjust ();
   }

   pass Pass_four
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_45);
   }

   pass Pass_five
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_45, -1);
   }

   pass Pass_six
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_135);
   }

   pass Pass_seven
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_135, 0);
   }

   pass Pass_eight
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_225);
   }

   pass Pass_nine
   <
      string Script = "RenderColorTarget0 = Sample3;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_225, 1);
   }

   pass Pass_ten
   <
      string Script = "RenderColorTarget0 = Sample2;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_1 (ROTATE_315);
   }

   pass Pass_eleven
   <
      string Script = "RenderColorTarget0 = Sample4;";
   >
   {
      PixelShader = compile PROFILE ps_stretch_2 (ROTATE_315, 0);
   }

   pass Pass_twelve
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

