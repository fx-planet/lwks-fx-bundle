// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Corners.mp4

/**
 This is a four-way split which moves the image to or from the corners of the frame.  It
 has been adapted for use with titles and other alpha effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSplit_Ax.fx
//
// This is a revision of an earlier effect, Adx_Corners.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Reworded Boost text to match requirements for 2020.1 and up.
// Reworded Transition text to match requirements for 2020.1 and up.
// Move Boost code into separate shader so that the foreground is always correct.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner split (alpha)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits a title four ways to or from the corners of the frame";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Super : RenderColorTarget;
texture Horiz : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
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
   string Description = "Transition position";
   string Enum = "At start,At end";
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

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

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

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
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

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CornerSplit_Ax_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_shut_horiz (); }

   pass P_3
   { PixelShader = compile PROFILE ps_shut_main (); }
}

technique CornerSplit_Ax_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_open_horiz (); }

   pass P_3
   { PixelShader = compile PROFILE ps_open_main (); }
}
