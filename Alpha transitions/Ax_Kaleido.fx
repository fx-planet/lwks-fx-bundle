// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Kaleido_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Kaleido.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Kaleido.fx
//
// This is loosely based on the user effect Kaleido.fx by Lightworks user baopao
// (http://www.alessandrodallafontana.com/) which was in turn based on a pixel shader
// at http://pixelshaders.com/ which was fine tuned for Cg compliance by Lightworks user
// nouanda.  This effect has been built from that original.  In the process some further
// code optimisation has been done, mainly to address potential divide by zero errors.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Kaleido.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha kaleido mix";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Breaks a title into a rotary kaleidoscope pattern";
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

int Ttype
<
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out";
> = 0;

float Sides
<
   string Group = "Kaleidoscope";
   string Description = "Sides";
   float MinVal = 5.0;
   float MaxVal = 50.0;
> = 25.0;

float scaleAmt
<
   string Group = "Kaleidoscope";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float zoomFactor
<
   string Group = "Kaleidoscope";
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosX
<
   string Group = "Kaleidoscope";
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Group = "Kaleidoscope";
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268
#define PI      3.1415926536
#define TWO_PI  6.2831853072

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

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Ttype == 0 ? 1.0 - Amount : Amount;
   float Scale = 1.0 + (amount * (1.2 - scaleAmt));
   float mixval = cos (amount * HALF_PI);
   float sideval = 1.0 + (amount * Sides);
   float Zoom = 1.0 + (amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv.x, uv.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgd = fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a * mixval);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Kaleido
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

