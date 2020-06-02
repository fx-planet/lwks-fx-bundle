// @Maintainer jwrl
// @Released 2020-06-02
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour.mp4

/**
 This effect fades a delta key in or out through a user-selected colour gradient.  The
 gradient can be a single flat colour, a vertical gradient, a horizontal gradient or a
 four corner gradient.  The colour is at its maximum strength half way through the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colour_Adx.fx
//
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dissolve thru colour (delta)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Separates foreground from background and fades it in or out through a colour gradient";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Blend : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Blend = sampler_state { Texture = <Blend>; };

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

float cAmount
<
   string Group = "Colour setup";
   string Description = "Colour mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool gradSetup
<
   string Group = "Colour setup";
   string Description = "Show gradient full screen";
> = false;

int colourGrad
<
   string Group = "Colour setup";
   string Description = "Colour gradient";
   string Enum = "Top left flat colour,Top to bottom left,Top left to top right,Four way gradient";
> = 0;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 1.0, 1.0 };

float4 topRight
<
   string Description = "Top Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Colour setup";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 1.0, 1.0 };

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

float4 ps_colour (float2 uv : TEXCOORD0) : COLOR
{
   if (colourGrad == 0) return topLeft;

   if (colourGrad == 1) return lerp (topLeft, botLeft, uv.y);

   float4 topRow = lerp (topLeft, topRight, uv.x);

   if (colourGrad == 2) return topRow;

   float4 botRow = lerp (botLeft, botRight, uv.x);

   return lerp (topRow, botRow, uv.y);
}

float4 ps_main_I (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd, gradient = tex2D (s_Blend, xy0);

   if (gradSetup) return gradient;

   if (Ftype) {
      Bgnd = tex2D (s_Foreground, xy1);
      Fgnd = tex2D (s_Background, xy2);
   }
   else {
      Fgnd = tex2D (s_Foreground, xy1);
      Bgnd = tex2D (s_Background, xy2);
   }

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));
   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

float4 ps_main_O (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 gradient = tex2D (s_Blend, xy1);

   if (gradSetup) return gradient;

   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));
   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * Amount) * HALF_PI);

   level = cos (Amount * HALF_PI);
   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (Bgnd, Fgnd, Fgnd.a * level);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Colour_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Blend;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_Colour_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Blend;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}
