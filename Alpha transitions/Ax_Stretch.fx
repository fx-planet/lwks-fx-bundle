// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Stretch.fx
//
// This effect stretches the title(s) horizontally or vertically to transition into or
// out of a title.  It also composites the result over a background layer.  Alpha levels
// are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Stretch.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha stretch dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Stretches a title horizontally or vertically to transition into or out of it";
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
   string Enum = "Horizontal in,Horizontal out,Vertical in,Vertical out";
> = 0;

float Stretch
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CENTRE  (0.5).xx
#define EMPTY   (0.0).xxxx

#define PI      3.1415926536
#define HALF_PI 1.5707963268

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

float4 ps_horiz_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_horiz_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_vert_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_vert_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x  = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Hstretch_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_in (); }
}

technique Ax_Hstretch_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_out (); }
}

technique Ax_Vstretch_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_in (); }
}

technique Ax_Vstretch_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_out (); }
}

