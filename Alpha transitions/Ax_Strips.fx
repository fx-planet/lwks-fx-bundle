// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Strips.fx
//
// An alpha transition that splits title(s) into strips and compresses them to zero
// height.  The vertical centring can be adjusted so that the collapse is symmetrical.
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Strips.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha strips";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Splits a title into strips and compresses them to nothing";
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
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Uncompress in,Compress out";
> = 0;

float Spacing
<
   string Group = "Strips";
   string Description = "Spacing";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Spread
<
   string Group = "Strips";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreX
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Group = "Strips";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

#define EMPTY    (0.0).xxxx

float _Progress;

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
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv.y * PI);
   float Height   = 1.0 + ((1.0 - cos (Amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * Amount;

   float2 xy = uv + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Strips_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Strips_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

