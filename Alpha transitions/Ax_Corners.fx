// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Corners.fx
//
// This is a four-way split which moves the image to or from the corners of the frame.
// It has been adapted for use with alpha effects.
//
// This is a revision of an earlier effect, Adx_Corners.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha corner split";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Splits a title four ways to or from the corners of the frame";
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
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) EMPTY;

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_open_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float posAmt = Amount * 0.5;
   float negAmt = 0.5 - posAmt;

   float2 xy1 = float2 (uv.x - posAmt, uv.y);
   float2 xy2 = float2 (uv.x + posAmt, uv.y);

   posAmt += 0.5;

   return (uv.x > posAmt) ? fn_tex2D (s_Super, xy1)
        : (uv.x < negAmt) ? fn_tex2D (s_Super, xy2) : EMPTY;
}

float4 ps_shut_horiz (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 0.5 - negAmt;

   float2 xy1 = float2 (uv.x - posAmt, uv.y);
   float2 xy2 = float2 (uv.x + posAmt, uv.y);

   posAmt += 0.5;

   return (uv.x > posAmt) ? fn_tex2D (s_Super, xy1)
        : (uv.x < negAmt) ? fn_tex2D (s_Super, xy2) : EMPTY;
}

float4 ps_open_main (float2 uv : TEXCOORD1) : COLOR
{
   float posAmt = Amount * 0.5;
   float negAmt = 0.5 - posAmt;

   float2 xy1 = float2 (uv.x, uv.y - posAmt);
   float2 xy2 = float2 (uv.x, uv.y + posAmt);

   posAmt += 0.5;

   float4 Fgnd = (uv.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_shut_main (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 0.5 - negAmt;

   float2 xy1 = float2 (uv.x, uv.y - posAmt);
   float2 xy2 = float2 (uv.x, uv.y + posAmt);

   posAmt += 0.5;

   float4 Fgnd = (uv.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Corners_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_shut_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE ps_shut_main (); }
}

technique Ax_Corners_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_open_horiz (); }

   pass P_2
   { PixelShader = compile PROFILE ps_open_main (); }
}

