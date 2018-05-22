// @Maintainer jwrl
// @Released 2018-04-29
// @Author jwrl
// @Created 2017-12-29
// @see https://www.lwks.com/media/kunena/attachments/6375/SpotlightEffect_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect SpotlightEffect.fx
//
// This effect is designed to produce a highlighted spotlight effect on the source video.
// It's a simple single effect solution for the alternative, a wipe/matte combination
// used in conjunction with a blend or DVE.  The spot can be scaled, have its aspect
// ratio adjusted, and rotated through plus or minus 90 degrees.  The edge of the effect
// can also be feathered.
//
// Foreground and background exposure can be adjusted, as can saturation and vibrance.
// The background can also be slightly blurred to give a soft focus effect, and the
// foreground and background can be individually tinted.
//
// Modified 2018-04-29
// Corrected a bug which caused the angular adjustment to be always centred on the frame
// centre, regardless of the spot position.  In the process the subcategory was changed
// to "Matte" and the filename from SpotEffect.fx to SpotlightEffect.fx.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spotlight effect";
   string Category    = "Stylize";
   string SubCategory = "Matte";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;

texture FgdProc : RenderColorTarget;
texture BgdProc : RenderColorTarget;
texture BgdBlur : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_FgdProc    = sampler_state { Texture = <FgdProc>; };

sampler s_BgdProc = sampler_state
{
   Texture   = <BgdProc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BgdBlur = sampler_state
{
   Texture   = <BgdBlur>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float SpotSize
<
   string Group = "Spot shape";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float SpotFeather
<
   string Group = "Spot shape";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float SpotAspect
<
   string Group = "Spot shape";
   string Description = "Aspect ratio";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float SpotAngle
<
   string Group = "Spot shape";
   string Description = "Angle";
   float MinVal = -90.0;
   float MaxVal = 90.0;
> = 0.0;

float CentreX
<
   string Group = "Spot shape";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Group = "Spot shape";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float FgdExposure
<
   string Group = "Spot settings";
   string Description = "Exposure";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float FgdSaturation
<
   string Group = "Spot settings";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float FgdVibrance
<
   string Group = "Spot settings";
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float FgdTint
<
   string Group = "Spot settings";
   string Description = "Tint";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 FgdColour
<
   string Group = "Spot settings";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.8, 0.0, 1.0 };

float BgdFocus
<
   string Group = "Background settings";
   string Description = "Focus";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BgdExposure
<
   string Group = "Background settings";
   string Description = "Exposure";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.5;

float BgdSaturation
<
   string Group = "Background settings";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.5;

float BgdVibrance
<
   string Group = "Background settings";
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.5;

float BgdTint
<
   string Group = "Background settings";
   string Description = "Tint";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 BgdColour
<
   string Group = "Background settings";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.5, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MIN_EXP  0.00000001
#define LUMAFIX  float3(0.299,0.587,0.114)

#define ASPECT_RATIO  0.2
#define FEATHER_SCALE 0.05
#define RADIUS_SCALE  1.6666667

#define PI            3.1415926536
#define ROTATE        PI/180.0

float Pascal [] = { 0.3125, 0.234375, 0.09375, 0.015625 };

float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fgd (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   float alpha = retval.a;
   float gamma = saturate ((1.0 - FgdExposure) * 0.5);

   // Process the exposure

   gamma  = max (MIN_EXP, (gamma * gamma * 2.0) + 0.5);
   retval = saturate (pow (retval, gamma));

   // Process the saturation

   float luma = dot (retval.rgb, LUMAFIX);

   retval = lerp (luma.xxxx, retval, 1.0 + FgdSaturation);

   // Process the vibrance

   float vibval = (retval.r + retval.g + retval.b) / 3.0;
   float maxval = max (retval.r, max (retval.g, retval.b));

   vibval = 3.0 * FgdVibrance * (vibval - maxval);
   retval = lerp (retval, maxval.xxxx, vibval);

   // Process the tint settings

   float4 tint = FgdColour * sin (luma * PI) + retval;

   float Tluma = dot (tint.rgb, LUMAFIX);

   retval   = lerp (retval, saturate (tint * luma / Tluma), FgdTint);
   retval.a = alpha;

   return retval;
}

float4 ps_bgd (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   float alpha = retval.a;
   float gamma = saturate ((1.0 - BgdExposure) * 0.5);

   gamma  = max (MIN_EXP, (gamma * gamma * 2.0) + 0.5);
   retval = saturate (pow (retval, gamma));

   float luma = dot (retval.rgb, LUMAFIX);

   retval = lerp (luma.xxxx, retval, 1.0 + BgdSaturation);

   float vibval = (retval.r + retval.g + retval.b) / 3.0;
   float maxval = max (retval.r, max (retval.g, retval.b));

   vibval = 3.0 * BgdVibrance * (vibval - maxval);
   retval = lerp (retval, maxval.xxxx, vibval);

   float4 tint = BgdColour * sin (luma * PI) + retval;

   float Tluma = dot (tint.rgb, LUMAFIX);

   retval   = lerp (retval, saturate (tint * luma / Tluma), BgdTint);
   retval.a = alpha;

   return retval;
}

float4 ps_bgd_blur (float2 uv : TEXCOORD1) : COLOR
{
   // This is a simple box blur using Pascal's triangle to calculate the blur

   float4 retval = tex2D (s_BgdProc, uv);

   float2 xy1 = float2 ((2.0 - 2.0 * BgdFocus) / _OutputWidth, 0.0);
   float2 xy2 = xy1 + xy1;
   float2 xy3 = xy1 + xy2;

   float alpha = retval.a;

   // Blur the background component horizontally

   retval *= Pascal [0];
   retval += tex2D (s_BgdProc, uv + xy1) * Pascal [1];
   retval += tex2D (s_BgdProc, uv - xy1) * Pascal [1];
   retval += tex2D (s_BgdProc, uv + xy2) * Pascal [2];
   retval += tex2D (s_BgdProc, uv - xy2) * Pascal [2];
   retval += tex2D (s_BgdProc, uv + xy3) * Pascal [3];
   retval += tex2D (s_BgdProc, uv - xy3) * Pascal [3];

   retval.a = alpha;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_BgdBlur, uv);

   float2 xy1 = float2 (0.0, (2.0 - 2.0 * BgdFocus) / _OutputHeight);
   float2 xy2 = xy1 + xy1;
   float2 xy3 = xy1 + xy2;

   // Blur the background component vertically

   retval *= Pascal [0];
   retval += tex2D (s_BgdBlur, uv + xy1) * Pascal [1];
   retval += tex2D (s_BgdBlur, uv - xy1) * Pascal [1];
   retval += tex2D (s_BgdBlur, uv + xy2) * Pascal [2];
   retval += tex2D (s_BgdBlur, uv - xy2) * Pascal [2];
   retval += tex2D (s_BgdBlur, uv + xy3) * Pascal [3];
   retval += tex2D (s_BgdBlur, uv - xy3) * Pascal [3];

   // Now calculate the spotlight size, aspect ratio and angle.  We must
   // first set up the size, aspect ratio and edge feathering parameters

   float size    = max (0.0, SpotSize);
   float aspect  = SpotAspect * ASPECT_RATIO;
   float feather = SpotFeather * FEATHER_SCALE;

   // Now compensate for the frame aspect ratio when scaling the spot vertically
   // If the aspect ratio is negative we scale it, if not we use it as-is

   aspect = 1.0 - max (aspect, 0.0) - (min (aspect, 0.0) * _OutputAspectRatio);

   // Put position adjusted uv in xy2 and the rotational x and y scale factors in xy3

   xy2 = float2 (CentreX, 1.0 - CentreY) - uv;
   sincos (SpotAngle * ROTATE, xy3.y, xy3.x);

   // Calculate the angular rotation and put the corrected position in xy1

   xy1.x = (xy2.x * xy3.x) + (xy2.y * xy3.y / _OutputAspectRatio);
   xy1.y = (xy2.y * xy3.x) - (xy2.x * xy3.y * _OutputAspectRatio);

   // Now determine if the current pixel falls inside the spot boundaries, and if so
   // generate the appropriate alpha value to key the foreground over the background.

   float radius = length (float2 (xy1.x / aspect, (xy1.y / _OutputAspectRatio) * aspect)) * RADIUS_SCALE;
   float alpha  = feather > 0.0 ? saturate ((size + feather - radius) / (feather * 2.0))
                : radius < size ? 1.0 : 0.0;

   // Exit, inserting the processed foreground into the processed background.

   return lerp (retval, tex2D (s_FgdProc, uv), alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SpotEffect
{
   pass P_1
   < string Script = "RenderColorTarget0 = FgdProc;"; > 
   { PixelShader = compile PROFILE ps_fgd (); }

   pass P_2
   < string Script = "RenderColorTarget0 = BgdProc;"; > 
   { PixelShader = compile PROFILE ps_bgd (); }

   pass P_3
   < string Script = "RenderColorTarget0 = BgdBlur;"; > 
   { PixelShader = compile PROFILE ps_bgd_blur (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
