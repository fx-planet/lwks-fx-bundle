// @Maintainer jwrl
// @Released 2021-10-07
// @Author khaver
// @Created 2011-05-18
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromaticAbberationFixer_640.png

/**
 This effect is pretty self explanatory.  When you need it, you need it.  It zooms in and
 out of the red, green and blue channels independently to help remove the colour fringing
 (chromatic aberration) in areas near the edges of the frame often produced by cheaper
 lenses.  To see the fringing better while adjusting click the saturation check box.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaticAbFixer.fx
//
// Version history:
//
// Update 2021-10-07 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Addressing has been changed from Clamp to Mirror to bypass a bug in XY sampler
// addressing on Linux and OS-X platforms.  This effect should now function correctly
// when used with all current and previous Lightworks versions.
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to correct for platform default sampler state differences.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromatic aberration fixer";
   string Category    = "Stylize";
   string SubCategory = "Repair tools";
   string Notes       = "Generates or removes chromatic aberration";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (V, s_RawInp);

DefineTarget (FixInp, VSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float radjust
<
   string Description = "Red adjust";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 0.0; // Default value

float gadjust
<
   string Description = "Green adjust";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 0.0; // Default value

float badjust
<
   string Description = "Blue adjust";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 0.0; // Default value

bool saton
<
   string Description = "Saturation";
   string Group = "Saturation";
> = false;

float sat
<
   string Description = "Adjustment";
   string Group = "Saturation";
   float MinVal       = 0.0;
   float MaxVal       = 4.0;
> = 2.0; // Default value

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 CAFix (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float satad = (!saton) ? 1.0 : sat;
   float rad = ((radjust * 2.0 + 4.0) / 100.0) + 0.96;
   float gad = ((gadjust * 2.0 + 4.0) / 100.0) + 0.96;
   float bad = ((badjust * 2.0 + 4.0) / 100.0) + 0.96;

   float2 xy = uv2 - 0.5.xx;

   float3 source;

   source.r = tex2D (VSampler, (xy / rad) + 0.5.xx).r;
   source.g = tex2D (VSampler, (xy / gad) + 0.5.xx).g;
   source.b = tex2D (VSampler, (xy / bad) + 0.5.xx).b;

   float alpha = tex2D (VSampler, uv2).a;

   float3 lum  = dot (source, float3 (0.299, 0.587, 0.114)).xxx;
   float3 dest = lerp (lum, source, satad);

   return Overflow (uv1) ? EMPTY : float4 (dest, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique CAFixer
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (CAFix)
}

