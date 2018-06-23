// @Maintainer jwrl
// @Released 2018-06-23
// @Author jwrl
// @Created 2018-06-15
// @see https://www.lwks.com/media/kunena/attachments/6375/BlendX_640.png
//-----------------------------------------------------------------------------------------//
// User effect BlendX.fx
//
// This is a variant of the Lightworks blend effect with the option to boost the alpha
// channel (transparency) to match the blending used by title effects.  It can help
// when using titles with their inputs disconnected and used with other effects such
// as DVEs.  It also closely emulates most of the Photoshop blend modes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Enhanced blend";
   string Category    = "Mix";
   string SubCategory = "Custom";
   string Notes       = "This is a customised blend for use in conjunction with other effects.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <fg>; };
sampler s_Background = sampler_state { Texture = <bg>; };

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
   string Description = "Fg Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Description = "Blend mode";
   string Enum = "Normal,Export fg with alpha,____________________,Darken,Multiply,Colour Burn,Linear Burn,Darker Colour,____________________,Lighten,Screen,Colour Dodge,Linear Dodge (Add),Lighter Colour,____________________,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard Mix,____________________,Difference,Exclusion,Subtract,Divide,____________________,Hue,Saturation,Colour,Luminosity";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CrR    0.439
#define CrG    0.368
#define CrB    0.071

#define CbR    0.148
#define CbG    0.291
#define CbB    0.439

#define Rr_R   1.596
#define Rg_R   0.813
#define Rg_B   0.391
#define Rb_B   2.018

#define WHITE  (1.0).xxxx
#define EMPTY  (0.0).xxxx

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   float4 retval = tex2D (Vsample, uv);

   if (Boost == 1) return retval;

   retval.a = pow (retval.a, 0.5);

   return float4 (retval.rgb / retval.a, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a * Amount);
}

float4 ps_export (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Foreground, uv);
}

float4 ps_dummy (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Background, uv);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, min (Fgnd, Bgnd), Fgnd.a * Amount);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, Bgnd * Fgnd, Fgnd.a * Amount);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? Fgnd.r : max (1.0 - ((1.0 - Bgnd.r) / Fgnd.r), 0.0);
   blnd.g = (Fgnd.g == 0.0) ? Fgnd.g : max (1.0 - ((1.0 - Bgnd.g) / Fgnd.g), 0.0);
   blnd.b = (Fgnd.b == 0.0) ? Fgnd.b : max (1.0 - ((1.0 - Bgnd.b) / Fgnd.b), 0.0);

   return lerp (Bgnd, min (blnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, max (Fgnd + Bgnd - WHITE, EMPTY), Fgnd.a * Amount);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) < luma) ? Fgnd : Bgnd;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, max (Fgnd, Bgnd), Fgnd.a * Amount);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, saturate (Fgnd + Bgnd - (Fgnd * Bgnd)), Fgnd.a * Amount);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   blnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   blnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return lerp (Bgnd, min (blnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, min (Fgnd + Bgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float  luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) > luma) ? Fgnd : Bgnd;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd = (Bgnd < 0.5) ? 2.0 * Bgnd * Fgnd : 1.0 - 2.0 * (1.0 - Bgnd) * (1.0 - Fgnd);

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd = (Fgnd < 0.5) ? (2.0 * Bgnd * Fgnd + Bgnd * Bgnd * (1.0 - 2.0 * Fgnd))
                              : (sqrt (Bgnd) * (2.0 * Fgnd - 1.0) + 2.0 * Bgnd * (1.0 - Fgnd));

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 minBlend = saturate (2.0 * Bgnd * Fgnd);
   float4 maxBlend = saturate (1.0 - 2.0 * (1.0 - Bgnd) * (1.0 - Fgnd));
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Fgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Fgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_vividLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = Fgnd;

   float3 maxBlend, minBlend;

   minBlend.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   minBlend.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   minBlend.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   maxBlend.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   maxBlend.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   maxBlend.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   minBlend = min (minBlend, (1.0).xxx);
   maxBlend = min (maxBlend, (1.0).xxx);

   blnd.r = (Fgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Fgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Fgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_linearLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 minBlend = max ((2.0 * Fgnd) + Bgnd - WHITE, EMPTY);
   float4 maxBlend = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Fgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Fgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_pinLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = (Fgnd < 0.5) ? min (Bgnd, 2.0 * Fgnd) : max (Bgnd, (2.0 * Fgnd) - WHITE);

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

float4 ps_hardMix (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 minBlend = max (WHITE - ((WHITE - Fgnd) / (2.0 * Bgnd)), 0.0);
   float4 maxBlend = min (Fgnd / (2.0 * (1.0 - Bgnd)), WHITE);
   float4 blnd = Fgnd;

   blnd.r = (Bgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Bgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Bgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   blnd.r = (blnd.r < 0.5) ? 0.0 : 1.0;
   blnd.g = (blnd.g < 0.5) ? 0.0 : 1.0;
   blnd.b = (blnd.b < 0.5) ? 0.0 : 1.0;

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, abs (Fgnd - Bgnd), Fgnd.a * Amount);
}

float4 ps_exclusion (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, saturate (Fgnd + Bgnd - (2.0 * Fgnd * Bgnd)), Fgnd.a * Amount);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   return lerp (Bgnd, max (Bgnd - Fgnd, EMPTY), Fgnd.a * Amount);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   blnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   blnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   return lerp (Bgnd, blnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.x = (fn_rgb2hsv (Fgnd)).x;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_saturation (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.y = fn_rgb2hsv (Fgnd).y;

   return lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd  = Fgnd;

   float Y  = dot (Bgnd, LUMA);
   float Cr = (Fgnd.r * CrR) - (Fgnd.g * CrG) - (Fgnd.b * CrB);
   float Cb = (Fgnd.b * CbB) - (Fgnd.g * CbG) - (Fgnd.r * CbR);

   blnd.r = Y + (Rr_R * Cr);
   blnd.g = Y - (Rg_R * Cr) - (Rg_B * Cb);
   blnd.b = Y + (Rb_B * Cb);

   return lerp (Bgnd, saturate (blnd), Fgnd.a * Amount);
}

float4 ps_luminosity (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 blnd  = Fgnd;

   float Y  = dot (Fgnd, LUMA);
   float Cr = (Bgnd.r * CrR) - (Bgnd.g * CrG) - (Bgnd.b * CrB);
   float Cb = (Bgnd.b * CbB) - (Bgnd.g * CbG) - (Bgnd.r * CbR);

   blnd.r = Y + (Rr_R * Cr);
   blnd.g = Y - (Rg_R * Cr) - (Rg_B * Cb);
   blnd.b = Y + (Rb_B * Cb);

   return lerp (Bgnd, saturate (blnd), Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Normal        { pass P_1 { PixelShader = compile PROFILE ps_main (); } }
technique Export        { pass P_1 { PixelShader = compile PROFILE ps_export (); } }
technique Group_1       { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Darken        { pass P_1 { PixelShader = compile PROFILE ps_darken (); } }
technique Multiply      { pass P_1 { PixelShader = compile PROFILE ps_multiply (); } }
technique ColourBurn    { pass P_1 { PixelShader = compile PROFILE ps_colourBurn (); } }
technique LinearBurn    { pass P_1 { PixelShader = compile PROFILE ps_linearBurn (); } }
technique DarkerColour  { pass P_1 { PixelShader = compile PROFILE ps_darkerColour (); } }
technique Group_2       { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Lighten       { pass P_1 { PixelShader = compile PROFILE ps_lighten (); } }
technique Screen        { pass P_1 { PixelShader = compile PROFILE ps_screen (); } }
technique ColourDodge   { pass P_1 { PixelShader = compile PROFILE ps_colourDodge (); } }
technique LinearDodge   { pass P_1 { PixelShader = compile PROFILE ps_linearDodge (); } }
technique LighterColour { pass P_1 { PixelShader = compile PROFILE ps_lighterColour (); } }
technique Group_3       { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Overlay       { pass P_1 { PixelShader = compile PROFILE ps_overlay (); } }
technique SoftLight     { pass P_1 { PixelShader = compile PROFILE ps_softLight (); } }
technique Hardlight     { pass P_1 { PixelShader = compile PROFILE ps_hardLight (); } }
technique Vividlight    { pass P_1 { PixelShader = compile PROFILE ps_vividLight (); } }
technique Linearlight   { pass P_1 { PixelShader = compile PROFILE ps_linearLight (); } }
technique Pinlight      { pass P_1 { PixelShader = compile PROFILE ps_pinLight (); } }
technique HardMix       { pass P_1 { PixelShader = compile PROFILE ps_hardMix (); } }
technique Group_4       { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Difference    { pass P_1 { PixelShader = compile PROFILE ps_difference (); } }
technique Exclusion     { pass P_1 { PixelShader = compile PROFILE ps_exclusion (); } }
technique Subtract      { pass P_1 { PixelShader = compile PROFILE ps_subtract (); } }
technique Divide        { pass P_1 { PixelShader = compile PROFILE ps_divide (); } }
technique Group_5       { pass P_1 { PixelShader = compile PROFILE ps_dummy (); } }

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Hue           { pass P_1 { PixelShader = compile PROFILE ps_hue (); } }
technique Saturation    { pass P_1 { PixelShader = compile PROFILE ps_saturation (); } }
technique Colour        { pass P_1 { PixelShader = compile PROFILE ps_colour (); } }
technique Luminosity    { pass P_1 { PixelShader = compile PROFILE ps_luminosity (); } }

