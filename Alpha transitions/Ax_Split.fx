// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split.mp4
//-----------------------------------------------------------------------------------------//
// User effect Ax_Split.fx
//
// This is really the classic barn door effect, but since a wipe with that name already
// exists in Lightworks another name had to be found.  This version moves the separated
// image halves apart rather than just wipe them off.  Alpha levels can be boosted to
// support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Split.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha split";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Splits a title in half and separates the halves horizontally or vertically";
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
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Horizontal join in,Horizontal split out,Vertical join in,Vertical split out";
> = 0;

float Split
<
   string Description = "Split centre";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

float4 ps_horiz_in (float2 uv : TEXCOORD1) : COLOR
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv.x > Split) ? fn_tex2D (s_Super, xy1) : fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_horiz_out (float2 uv : TEXCOORD1) : COLOR
{
   float range = Amount * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv.x > Split) ? fn_tex2D (s_Super, xy1) : fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_vert_in (float2 uv : TEXCOORD1) : COLOR
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv.y > split) ? fn_tex2D (s_Super, xy1) : fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_vert_out (float2 uv : TEXCOORD1) : COLOR
{
   float split = 1.0 - Split;
   float range = Amount * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv.y > split) ? fn_tex2D (s_Super, xy1) : fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Hsplit_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_in (); }
}

technique Ax_Hsplit_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_out (); }
}

technique Ax_Vsplit_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_in (); }
}

technique Ax_Vsplit_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_out (); }
}

