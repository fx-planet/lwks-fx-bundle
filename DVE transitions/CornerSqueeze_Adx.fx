// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_CnrSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_CnrSqueeze.mp4

/**
This is similar to the alpha corner squeeze effect, except that it expands a delta key
from the corners or compresses it to the corners of the screen.
*/

//-----------------------------------------------------------------------------------------//
// User effect CornerSqueeze_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Corner squeeze (delta)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Separates foreground from background and expands it from or squeezes it to the corners of the screen";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture Horiz : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
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
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_horiz_I (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv.x + Amount - 1.0) / Amount, uv.y);
   float2 xy2 = float2 (uv.x / Amount, uv.y);

   float4 retval = (uv.x > posAmt) ? fn_tex2D (s_Title, xy1)
                 : (uv.x < negAmt) ? fn_tex2D (s_Title, xy2) : EMPTY;

   return retval;
}

float4 ps_horiz_O (float2 uv : TEXCOORD1) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
   float2 xy2 = float2 (uv.x / negAmt, uv.y);

   negAmt *= 0.5;

   float4 retval = (uv.x > posAmt) ? fn_tex2D (s_Title, xy1)
                 : (uv.x < negAmt) ? fn_tex2D (s_Title, xy2) : EMPTY;

   return retval;
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv1.x, (uv1.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv1.x, uv1.y / Amount);

   float4 Fgd = (uv1.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv1.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   return lerp (tex2D (s_Foreground, uv2), Fgd, Fgd.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   float2 xy1 = float2 (uv1.x, (uv1.y - Amount) / negAmt);
   float2 xy2 = float2 (uv1.x, uv1.y / negAmt);

   negAmt *= 0.5;

   float4 Fgd = (uv1.y > posAmt) ? fn_tex2D (s_Horizontal, xy1)
              : (uv1.y < negAmt) ? fn_tex2D (s_Horizontal, xy2) : EMPTY;

   return lerp (tex2D (s_Background, uv2), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_CornerSqueeze_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_horiz_I (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_CornerSqueeze_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Horiz;"; >
   { PixelShader = compile PROFILE ps_horiz_O (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}

