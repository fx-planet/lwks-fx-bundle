// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze.mp4

/**
This is similar to the split squeeze effect, customised to suit its use with delta
keys.  It moves the separated foreground image halves apart and squeezes them to the
edge of screen or expands the halves from the edges.  It operates either vertically
or horizontally depending on the user setting.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarndoorSqueeze_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door squeeze (delta)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Separates foreground from background then splits it and squeezes the halves apart horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

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
   string Description = "Transition";
   string Enum = "Expand horizontal,Squeeze horizontal,Expand vertical,Squeeze vertical";
> = 0;

float Split
<
   string Description = "Split centre";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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

float4 ps_expand_H (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgnd = (uv.x > posAmt) ? fn_tex2D (s_Title, float2 ((uv.x + amount) / Amount, uv.y))
               : (uv.x < negAmt) ? fn_tex2D (s_Title, float2 (uv.x / Amount, uv.y)) : EMPTY;

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_H (float2 uv : TEXCOORD1) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * Split;
   float posAmt = 1.0 - (amount * (1.0 - Split));

   float4 Fgnd = (uv.x > posAmt) ? fn_tex2D (s_Title, float2 ((uv.x - Amount) / amount, uv.y))
               : (uv.x < negAmt) ? fn_tex2D (s_Title, float2 (uv.x / amount, uv.y)) : EMPTY;

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

float4 ps_expand_V (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgnd = (uv.y > posAmt) ? fn_tex2D (s_Title, float2 (uv.x, (uv.y + amount) / Amount))
               : (uv.y < negAmt) ? fn_tex2D (s_Title, float2 (uv.x, uv.y / Amount)) : EMPTY;

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a);
}

float4 ps_squeeze_V (float2 uv : TEXCOORD1) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * (1.0 - Split);
   float posAmt = 1.0 - (amount * Split);

   float4 Fgnd = (uv.y > posAmt) ? fn_tex2D (s_Title, float2 (uv.x, (uv.y - Amount) / amount))
               : (uv.y < negAmt) ? fn_tex2D (s_Title, float2 (uv.x, uv.y / amount)) : EMPTY;

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Expand_H
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_expand_H (); }
}

technique Squeeze_H
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_H (); }
}

technique Expand_V
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_expand_V (); }
}

technique Squeeze_V
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_squeeze_V (); }
}

