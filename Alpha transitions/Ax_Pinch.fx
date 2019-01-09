// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Pinch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Pinch.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Pinch.fx
//
// This effect pinches the outgoing video to a user-defined point to reveal the incoming
// shot.  It can also reverse the process to bring in the incoming video.  It's the alpha
// version of Wx_Pinch.
//
// This is a revision of an earlier effect, Adx_Pinch.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha Pinch";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Pinches the outgoing video to a user-defined point to reveal the incoming shot";
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

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float centreX
<
   string Description = "Pinch centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Description = "Pinch centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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
   float amount = (Amount * 0.5) + 0.5;

   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - sin (amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -cos ((amount + 0.01) * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Amount * 0.5;

   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - cos (amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -sin (amount * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 Fgd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PinchIn
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique PinchOut
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

