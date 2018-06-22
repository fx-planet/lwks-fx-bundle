// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Colour.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Colour.fx
//
// This effect fades a title to or from through a user-selected colour gradient.  The
// gradient can be a single flat colour, a vertical gradient, a horizontal gradient or
// a four corner gradient.  It can also composite the result over a background layer.
// When fading the title in or out it uses non-linear transitions to reveal the colour
// at its maximum strength midway through the transition.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Colour.fx, which also had the ability to
// dissolve between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha dissolve thru colour";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Fades a title through a colour gradient in or out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture colourFrame : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Gradient = sampler_state { Texture = <colourFrame>; };

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
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define EMPTY   (0.0).xxxx

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

float4 ps_colour (float2 uv : TEXCOORD0) : COLOR
{
   if (colourGrad == 0) return topLeft;

   if (colourGrad == 1) return lerp (topLeft, botLeft, uv.y);

   float4 topRow = lerp (topLeft, topRight, uv.x);

   if (colourGrad == 2) return topRow;

   float4 botRow = lerp (botLeft, botRight, uv.x);

   return lerp (topRow, botRow, uv.y);
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 gradient = tex2D (s_Gradient, uv);

   if (gradSetup) return gradient;

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = cos (saturate (level * Amount) * HALF_PI);

   level = sin (Amount * HALF_PI);

   float4 Fgnd = fn_tex2D (s_Super, uv);

   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * level);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 gradient = tex2D (s_Gradient, uv);

   if (gradSetup) return gradient;

   float level = min (1.0, cAmount * 2.0);
   float c_Amt = sin (saturate (level * Amount) * HALF_PI);

   level = cos (Amount * HALF_PI);

   float4 Fgnd = fn_tex2D (s_Super, uv);

   Fgnd.rgb = lerp (Fgnd.rgb, gradient.rgb, c_Amt);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * level);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Colour_in
{
   pass P_1 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Colour_out
{
   pass P_1 < string Script = "RenderColorTarget0 = colourFrame;"; >
   { PixelShader = compile PROFILE ps_colour (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}

