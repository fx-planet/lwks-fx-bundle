// @Maintainer jwrl
// @Released 2018-04-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_CnrSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_CnrSqueeze.mp4
//-----------------------------------------------------------------------------------------//
// User effect Ax_CnrSqueeze.fx
//
// This is similar to the corner squeeze effect, customised to suit its use with alpha
// effects.
//
// This is a revision of an earlier effect, aDx_CnrSqueeze.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha corner squeeze";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Squeezes a title to or from the corners of the screen";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Horiz : RenderColorTarget;

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

sampler s_Horizontal = sampler_state
{
   Texture   = <Horiz>;
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
   string Enum = "Wipe in,Wipe out";
> = 0;

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

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_exp_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   float4 retval = (uv.x > posAmt) ? fn_tex2D (s_Super, xy1)
                 : (uv.x < negAmt) ? fn_tex2D (s_Super, xy2) : EMPTY;

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_sqz_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt *= 0.5;

   float4 retval = (uv.x > posAmt) ? fn_tex2D (s_Super, xy1)
                 : (uv.x < negAmt) ? fn_tex2D (s_Super, xy2) : EMPTY;

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_exp_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, (uv.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv.x, uv.y / Amount);

   float4 Fgd = (uv.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_sqz_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
   float2 xy2 = float2 (uv.x, uv.y / negAmt);

   negAmt *= 0.5;

   float4 Fgd = (uv.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_CnrSqueeze_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_exp_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE ps_exp_main (); }
}

technique Ax_CnrSqueeze_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_sqz_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE ps_sqz_main (); }
}

