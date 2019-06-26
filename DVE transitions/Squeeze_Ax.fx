// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Squeeze.mp4

/**
This mimics the Lightworks squeeze effect but supports alpha channel transitions.  Alpha
levels can be boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Squeeze_Ax.fx
//
// This is a revision of an earlier effect, Adx_Squeeze.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Squeeze transition (alpha)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Squeezes a title on or off screen horizontally or vertically";
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

int SetTechnique
<
   string Description = "Type";
   string Enum = "Squeeze Right,Squeeze Down,Squeeze Left,Squeeze Up";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define FX_IN 0

#define EMPTY (0.0).xxxx

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

float4 ps_squeeze_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == FX_IN) {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x / Amount, uv.y);
   }
   else {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / (1.0 - Amount) + 1.0, uv.y);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == FX_IN) {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 ((uv.x - 1.0) / Amount + 1.0, uv.y);
   }
   else {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x  / (1.0 - Amount), uv.y);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == FX_IN) {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x, uv.y / Amount);
   }
   else {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x, (uv.y - 1.0) / (1.0 - Amount) + 1.0);
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_up (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Ttype == FX_IN) {
      xy = (Amount == 0.0) ? float2 (2.0, uv.y) : float2 (uv.x, (uv.y - 1.0) / Amount + 1.0);
   }
   else {
      xy = (Amount == 1.0) ? float2 (2.0, uv.y) : float2 (uv.x, uv.y  / (1.0 - Amount));
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Squeeze_right
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_right (); }
}

technique Ax_Squeeze_down
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_down (); }
}

technique Ax_Squeeze_left
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_left (); }
}

technique Ax_Squeeze_up
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_up (); }
}
