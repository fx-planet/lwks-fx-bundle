// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchR_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchR.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_PinchR.fx
//
// This effect pinches the outgoing video to a user-defined point to reveal the incoming
// shot.  It can also reverse the process to bring in the incoming video.  It's the alpha
// version of Wx_rPinch.  Unlike "Pinch", this version compresses to the diagonal radii
// of the images.
//
// This is a revision of an earlier effect, Adx_PinchR.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha radial pinch";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Pinches the outgoing video radially to a user-defined point to reveal the incoming shot";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define HALF_PI 1.5707963268

#define EMPTY   (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float progress = (1.0 - Amount) / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float progress = Amount / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_PinchR_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_PinchR_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

