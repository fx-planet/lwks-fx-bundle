// @Maintainer jwrl
// @Released 2020-07-31
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
// Version history:
//
// Modified 2020-07-31 jwrl.
// Changed code to that used in Ax version.
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
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
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
   float mixval = sin (Amount * HALF_PI);
   float amount = 1.0 - Amount;
   float Scale = 1.0 + (amount * (1.2 - scaleAmt));
   float sideval = 1.0 + (amount * Sides);
   float Zoom = 1.0 + (amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv.x, uv.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgd = fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Foreground, uv), Fgd, Fgd.a * mixval);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float Scale = 1.0 + (Amount * (1.2 - scaleAmt));
   float mixval = cos (Amount * HALF_PI);
   float sideval = 1.0 + (Amount * Sides);
   float Zoom = 1.0 + (Amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv.x, uv.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgd = fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Background, uv), Fgd, Fgd.a * mixval);
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float mixval = sin (Amount * HALF_PI);
   float amount = 1.0 - Amount;
   float Scale = 1.0 + (amount * (1.2 - scaleAmt));
   float sideval = 1.0 + (amount * Sides);
   float Zoom = 1.0 + (amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv.x, uv.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgd = fn_tex2D (s_Super, xy2);

   return lerp (tex2D (s_Background, uv), Fgd, Fgd.a * mixval);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KaleidoTurbineMix_Adx_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique KaleidoTurbineMix_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique KaleidoTurbineMix_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
