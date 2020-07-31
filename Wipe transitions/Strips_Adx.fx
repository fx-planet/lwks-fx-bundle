// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Strips.mp4

/**
 A transition that splits a delta key into strips and compresses it to zero height.  The
 vertical centring can be adjusted so that the collapse is symmetrical.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Strips_Adx.fx
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Moved folded effect support into "Transition position".
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strips (delta)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates foreground from background then splits it into strips and compresses it to zero height";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
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

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

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

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_F (float2 uv : TEXCOORD1) : COLOR
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

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
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

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * amount);
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
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

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Strips_Adx_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique Strips_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique Strips_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
