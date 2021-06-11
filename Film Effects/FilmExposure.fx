// @Maintainer jwrl
// @Released 2021-06-10
// @Author jwrl
// @Author abelmilanes
// @Created 2017-03-04
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmExp_640.png

/**
 This is an effect that simulates exposure adjustment using a Cineon profile.  It is
 fairly accurate at the expense of requiring some reasonably complex maths.  With current
 GPU types this shouldn't be an issue.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmExposure.fx
//
// Version history:
//
// Update 2021-06-10 jwrl.
// Updated for LW 2021 resolution independence support.
//
// Prior to 2020-04-16:
// Various cross-platform upgrades.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film exposure";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates exposure adjustment using a Cineon profile";
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

#define EMPTY 0.0.xxxx

#define IsOutOfBounds(XY) any(saturate(XY) - XY)
#define GetPixel(S,XY) (IsOutOfBounds(XY) ? EMPTY : tex2D (S, XY))

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = ClampToEdge;           \
      AddressV  = ClampToEdge;           \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DeclareInput (Input, InpSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Exposure
<
   string Group = "Exposure";
   string Description = "Master";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CyanRed
<
   string Group = "Exposure";
   string Description = "Cyan/red";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float MagGreen
<
   string Group = "Exposure";
   string Description = "Magenta/green";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float YelBlue
<
   string Group = "Exposure";
   string Description = "Yellow/blue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Amount
<
   string Description = "Original";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval, Src = GetPixel (InpSampler, uv);

   // Convert RGB to linear

   float test = max (Src.r, max (Src.g, Src.b));   // Workaround to address Cg's all() bug

   float3 lin = (test < 0.04045) ? Src.rgb / 12.92 : pow ((Src.rgb + 0.055.xxx) / 1.055, 2.4);

   // Convert linear to Kodak Cineon

   float3 logOut   = ((log10 ((lin * 0.9892) + 0.0108) * 300.0) + 685.0) / 1023.0;
   float3 exposure = { CyanRed, MagGreen, YelBlue };

   exposure = (exposure + Exposure) * 0.1;

   // Adjust exposure then convert back to linear

   logOut = (((logOut + exposure) * 1023.0) - 685.0) / 300.0;
   lin = (pow (10.0.xxx, logOut) - 0.0108.xxx) * 1.0109179;

   // Back to RGB

   test = max (lin.r, max (lin.g, lin.b));

   retval.rgb = (test < 0.0031308) ? lin * 12.92 : (1.055 * pow (lin, 0.4166667)) - 0.055;
   retval = float4 (saturate (retval.rgb), Src.a);

   return lerp (retval, Src, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FilmExposure
{
   pass pass_one CompileShader (ps_main)
}
