// @Maintainer jwrl
// @Released 2020-06-02
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Kaleido_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Kaleido.mp4

/**
 This is loosely based on the user effect Kaleido, converted to function as a transition.
 The foreground is produced by means of a delta key which is used to separate any title
 or graphic from the background.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoTurbineMix_Adx.fx
//
// This is loosely based on the user effect Kaleido.fx by Lightworks user baopao
// (http://www.alessandrodallafontana.com/) which was in turn based on a pixel shader
// at http://pixelshaders.com/ which was fine tuned for Cg compliance by Lightworks user
// nouanda.  This effect has been built from that original.  In the process some further
// code optimisation has been done, mainly to address potential divide by zero errors.
//
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido turbine mix (delta)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Separates foreground from background and breaks it into a rotary kaleidoscope pattern";
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
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
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

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

bool Ftype
<
   string Description = "Folded effect";
> = true;

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

   return Ftype ? float4 (Bgd, smoothstep (0.0, KeyGain, kDiff))
                : float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
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

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float2 PosXY = float2 (PosX, 1.0 - PosY);
   float2 uv = PosXY - xy1;

   float amount = 1.0 - Amount;
   float sides  = TWO_PI / (1.0 + (amount * Sides));
   float radius = length (uv) / (1.0 + (amount * zoomFactor));
   float angle  = amount < 0.1 ? atan (uv.x / uv.y) : atan2 (uv.x, uv.y);

   angle -= sides * (floor (angle / sides) + 0.5);

   if (amount < 0.05) sincos (abs (angle), uv.x, uv.y);
   else sincos (abs (angle), uv.y, uv.x);

   uv = ((uv * radius) + PosXY) / ((amount * (1.2 - scaleAmt)) + 1.0);

   float4 Fgd = fn_tex2D (s_Title, uv);

   return Ftype ? lerp (tex2D (s_Foreground, xy2), Fgd, Fgd.a * cos (amount * HALF_PI))
                : lerp (tex2D (s_Background, xy2), Fgd, Fgd.a * cos (amount * HALF_PI));
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float2 PosXY = float2 (PosX, 1.0 - PosY);
   float2 uv = PosXY - xy1;

   float amount = Amount + 0.002;
   float sides  = TWO_PI / (1.0 + (amount * Sides));
   float radius = length (uv) / (1.0 + (amount * zoomFactor));
   float angle  = amount < 0.1 ? atan (uv.x / uv.y) : atan2 (uv.x, uv.y);

   angle -= sides * (floor (angle / sides) + 0.5);

   if (amount < 0.05) sincos (abs (angle), uv.x, uv.y);
   else sincos (abs (angle), uv.y, uv.x);

   uv = ((uv * radius) + PosXY) / ((amount * (1.2 - scaleAmt)) + 1.0);

   float4 Fgd = fn_tex2D (s_Title, uv);

   return lerp (tex2D (s_Background, xy2), Fgd, Fgd.a * cos (amount * HALF_PI));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KaleidoTurbineMix_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique KaleidoTurbineMix_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}
