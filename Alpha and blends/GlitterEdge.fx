// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2016-05-10
// @see https://www.lwks.com/media/kunena/attachments/6375/GlitterEdge_3.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect GlitterEdge.fx
//
// The star point component is based on khaver's Glint.fx, but modified to have no blur
// component, no choice of star points, and to compile and run under the ps_2_b shader
// profile in Windows.
//
// LW 14+ version 11 January 2017
// Subcategory "Edge Effects" added.
//
// Bug fix 26 February 2017
// This corrects for a bug in the way that Lightworks handles interlaced media.  It
// returns only half the actual frame height when interlaced media is stationary.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for undefined samplers they
// have now been explicitly declared.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glitter edge";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture noiseGen : RenderColorTarget;
texture Borders  : RenderColorTarget;
texture built    : RenderColorTarget;

texture Sample1 : RenderColorTarget;
texture Sample2 : RenderColorTarget;
texture Sample3 : RenderColorTarget;
texture Sample4 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

sampler noiseSampler = sampler_state {
        Texture   = <noiseGen>;
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
        Texture   = <Sample2>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

sampler Samp3 = sampler_state {
        Texture   = <Sample3>;
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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Master opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Opacity
<
   string Description = "Fgd opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float FxOpacity
<
   string Group = "Edges";   
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeWidth
<
   string Group = "Edges";   
   string Description = "Width";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Rate
<
   string Group = "Edges";   
   string Description = "Speed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Group = "Edges";   
   string Description = "Noise seed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float T_hold
<
   string Group = "Stars";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Strength
<
   string Group = "Stars";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StarLen
<
   string Group = "Stars";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rotation
<
   string Group = "Stars";
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 0.0;

float4 Colour
<
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.8, 0.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Common
//-----------------------------------------------------------------------------------------//

# define ROTATE_45   0.7854
# define ROTATE_135  2.35619
# define ROTATE_225  3.92699
# define ROTATE_315  5.49779

#define DELTANG      25
#define ALIASFIX     50
#define ANGLE        0.125664

float _Progress;

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_noise (float2 uv : TEXCOORD1) : COLOR
{
   float seed = (_Progress * (0.01 + Rate) * 0.005) + StartPoint;
   float2 xy  = saturate (float2 (uv.x + 0.00013, uv.y + 0.00123));

   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   float noise = saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 15 - 12.0);

   float4 retval = saturate ((Colour * noise) + Colour * 0.05);

   return float4 (retval.rgb, 1.0);
}

float4 ps_border (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * 10.0 / _OutputWidth;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (FgSampler, uv + offset).a;
      border += tex2D (FgSampler, uv - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, tex2D (FgSampler, uv).a);

   return border.xxxx;
}

float4 ps_build (float2 uv : TEXCOORD1) : COLOR
{
   float4 sparkle = tex2D (noiseSampler, uv);

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

   border  /= ALIASFIX;

   float4 retval = lerp (0.0.xxxx, sparkle, border);

   return float4 (retval.rgb, border);
}

float4 ps_adjust (float2 uv : TEXCOORD1) : COLOR
{
   float4 Color = tex2D (buildSampler, uv);

   return ((Color.r + Color.g + Color.b) / 3.0 < T_hold) ? 0.0.xxxx : Color;
}

float4 ps_stretch_1 (float2 uv : TEXCOORD1, uniform float rn_angle) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float lenStar = StarLen * pixel * 7.0;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= lenStar;
   offset.y *= _OutputAspectRatio;

   for (int count = 0; count < 16; count++) {
      delt = tex2D (Samp1, uv - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   for (int count = 16; count < 22; count++) {
      delt = tex2D (Samp1, uv - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 uv : TEXCOORD1, uniform float rn_angle, uniform int samp) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 offset;

   float pixel = 0.5 / _OutputWidth;
   float lenStar = StarLen * pixel * 7.0;

   float MapAngle = rn_angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= lenStar;
   offset.y *= _OutputAspectRatio;

   float4 insamp = (samp == 0) ? tex2D (Samp3, uv) : (samp != -1) ? tex2D (Samp4, uv) : 0.0.xxxx;

   for (int count = 22; count < 36; count++) {
      delt = tex2D (Samp1, uv - (offset * count));
      delt *= 1.0 - (count / 36.0);
      ret += delt;
   }

   ret = (ret + tex2D (Samp2, uv).rgb) / 3.6;

   return saturate (max (float4 (ret, 1.0), insamp));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd  = tex2D (FgSampler, uv);
   float4 Bgd  = tex2D (BgSampler, uv);

   float4 glint  = tex2D (Samp4, uv);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Opacity);

   float brdr = tex2D (buildSampler, uv).a;

   float4 ret_1 = lerp (retval, Colour * 0.95, brdr);

   glint = ret_1 + (glint * (1.0 - ret_1));

   ret_1  = lerp (ret_1, glint, Strength);
   retval = lerp (retval, ret_1, FxOpacity);

   return lerp (Bgd, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique doMatte
{
   pass Pass_zero
   <
      string Script = "RenderColorTarget0 = noiseGen;";
   >
   {
      PixelShader = compile PROFILE ps_noise ();
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
