// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2018-06-15
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DissolveX_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DissolveX.mp4

/**
 This expanded alpha dissolve allows blend modes to be applied during the transition
 using a drop down menu to select different dissolve methods.  The intention behind
 this effect was to get as close as possible visually to the standard Photoshop blend
 modes.

 In addition to the Lightworks blends, this effect provides Linear burn, Darker colour,
 Vivid light, Linear light, Pin light, Hard mix, Divide, Hue and Saturation.  The
 Lightworks effect Add has been replaced by Linear Dodge which is functionally identical,
 Burn has been replaced by Colour burn, and Dodge by Colour dodge.  "In Front" has been
 replaced by "Normal" to better match the Photoshop model.
*/

//-----------------------------------------------------------------------------------------//
// User effect DissolveX_Ax.fx
//
// Although dissolveX.fx by khaver was a trigger for this, this implementation is my own.
// While I have retained some of the blend choices in his original, they are definitely
// not the Lightworks ones that he used.  I didn't look at khaver's or the Lightworks
// effect until after I had produced the ones used here.
//
// The Photoshop Dissolve blend has not been included as there would be little point.
// The Lightworks Average effect has also been dropped, since it isn't part of the
// Photoshop library.  If it's needed exactly the same effect can be produced by adjusting
// the timing setting.  The "Fill" parameter from Photoshop has also been dropped as in
// this context its behaviour would be identical to "Opacity".
//
// In every respect possible the naming, order and behaviour of each effect is as near as
// I can get to the Photoshop versions.  A/B comparisons between an effect in Lightworks
// and the Photoshop equivalent have verified the similarity of the two.  I would prefer
// it if Overlay, Saturation and Hue were more accurate, but for the time being they will
// have to do.  The differences are extremely slight.
//
// The timing adjustment in khaver's effect ran from -100% to +100%.  I opted not to do
// that, because it made the programming simpler.  In any case, to me 50% means mid-point.
// It has also been scaled to actually run from 10% to 90% so that we don't inadvertently
// get the effect popping on or off.  I have also not implemented an effect bypass.  That
// is possible in the standard Lightworks effect settings in any case.
//
// Version history:
//
// Modified 29 Sept. 2020 jwrl.
// Changed "Transition" to "Transition position".
// Changed Boost dialogue.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "DissolveX (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "This expanded dissolve allows blend modes to be applied during the transition";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

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
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

int SetTechnique
<
   string Description = "Method";
   string Enum = "Normal,Darken,Multiply,Colour Burn,Linear Burn,Darker Colour,Lighten,Screen,Colour Dodge,Linear Dodge (Add) ,Lighter Colour,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard Mix,Difference,Exclusion,Subtract,Divide,Hue,Saturation,Colour,Luminosity";
> = 0;

float Timing
<
   string Description = "Timing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CrR     0.439
#define CrG     0.368
#define CrB     0.071

#define CbR     0.148
#define CbG     0.291
#define CbB     0.439

#define Rr_R    1.596
#define Rg_R    0.813
#define Rg_B    0.391
#define Rb_B    2.018

#define WHITE   (1.0).xxxx
#define EMPTY   (0.0).xxxx

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

float2 fn_amount ()
{
   float amount  = (Ttype == 1) ? 1.0 - Amount : Amount;
   float timeRef = (saturate (Timing) * 0.8) + 0.1;
   float timing  = saturate (amount / timeRef);

   amount = saturate ((amount - timeRef) / (1.0 - timeRef));

   return float2 (timing, amount);
}

float4 fn_tex2D (sampler Vsample, float2 uv)
{
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

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, (Fgnd + Bgnd) / 2.0, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, min (Fgnd, Bgnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_multiply (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, Bgnd * Fgnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_colourBurn (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? Fgnd.r : max (1.0 - ((1.0 - Bgnd.r) / Fgnd.r), 0.0);
   blnd.g = (Fgnd.g == 0.0) ? Fgnd.g : max (1.0 - ((1.0 - Bgnd.g) / Fgnd.g), 0.0);
   blnd.b = (Fgnd.b == 0.0) ? Fgnd.b : max (1.0 - ((1.0 - Bgnd.b) / Fgnd.b), 0.0);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, min (blnd, WHITE), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_linearBurn (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, max (Fgnd + Bgnd - WHITE, EMPTY), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_darkerColour (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float  luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) < luma) ? Fgnd : Bgnd;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, max (Fgnd, Bgnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_screen (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, saturate (Fgnd + Bgnd - (Fgnd * Bgnd)), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_colourDodge (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   blnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   blnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, min (blnd, WHITE), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_linearDodge (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, min (Fgnd + Bgnd, WHITE), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_lighterColour (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float  luma = dot (Bgnd, LUMA);

   float4 blnd = (dot (Fgnd, LUMA) > luma) ? Fgnd : Bgnd;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = (Bgnd < 0.5) ? 2.0 * Bgnd * Fgnd : 1.0 - 2.0 * (1.0 - Bgnd) * (1.0 - Fgnd);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_softLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = (Fgnd < 0.5) ? (2.0 * Bgnd * Fgnd + Bgnd * Bgnd * (1.0 - 2.0 * Fgnd))
                               : (sqrt (Bgnd) * (2.0 * Fgnd - 1.0) + 2.0 * Bgnd * (1.0 - Fgnd));

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_hardLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 minBlend = saturate (2.0 * Bgnd * Fgnd);
   float4 maxBlend = saturate (1.0 - 2.0 * (1.0 - Bgnd) * (1.0 - Fgnd));
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Fgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Fgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_vividLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
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

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_linearLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 minBlend = max ((2.0 * Fgnd) + Bgnd - WHITE, EMPTY);
   float4 maxBlend = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Fgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Fgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_pinLight (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = (Fgnd < 0.5) ? min (Bgnd, 2.0 * Fgnd) : max (Bgnd, (2.0 * Fgnd) - WHITE);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_hardMix (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 minBlend = max (WHITE - ((WHITE - Fgnd) / (2.0 * Bgnd)), 0.0);
   float4 maxBlend = min (Fgnd / (2.0 * (1.0 - Bgnd)), WHITE);
   float4 blnd = Fgnd;

   blnd.r = (Bgnd.r < 0.5) ? minBlend.r : maxBlend.r;
   blnd.g = (Bgnd.g < 0.5) ? minBlend.g : maxBlend.g;
   blnd.b = (Bgnd.b < 0.5) ? minBlend.b : maxBlend.b;

   blnd.r = (blnd.r < 0.5) ? 0.0 : 1.0;
   blnd.g = (blnd.g < 0.5) ? 0.0 : 1.0;
   blnd.b = (blnd.b < 0.5) ? 0.0 : 1.0;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, abs (Fgnd - Bgnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_exclusion (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, saturate (Fgnd + Bgnd - (2.0 * Fgnd * Bgnd)), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_subtract (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float2 amount = fn_amount ();

   float4 blnd = lerp (Bgnd, max (Bgnd - Fgnd, EMPTY), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_divide (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = Fgnd;

   blnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   blnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   blnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, blnd, Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.x = (fn_rgb2hsv (Fgnd)).x;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_saturation (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.y = fn_rgb2hsv (Fgnd).y;

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_colour (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = Fgnd;

   float Y  = dot (Bgnd, LUMA);
   float Cr = (Fgnd.r * CrR) - (Fgnd.g * CrG) - (Fgnd.b * CrB);
   float Cb = (Fgnd.b * CbB) - (Fgnd.g * CbG) - (Fgnd.r * CbR);

   blnd.r = Y + (Rr_R * Cr);
   blnd.g = Y - (Rg_R * Cr) - (Rg_B * Cb);
   blnd.b = Y + (Rb_B * Cb);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, saturate (blnd), Fgnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

float4 ps_luminosity (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 blnd = Fgnd;

   float Y  = dot (Fgnd, LUMA);
   float Cr = (Bgnd.r * CrR) - (Bgnd.g * CrG) - (Bgnd.b * CrB);
   float Cb = (Bgnd.b * CbB) - (Bgnd.g * CbG) - (Bgnd.r * CbR);

   blnd.r = Y + (Rr_R * Cr);
   blnd.g = Y - (Rg_R * Cr) - (Rg_B * Cb);
   blnd.b = Y + (Rb_B * Cb);

   float2 amount = fn_amount ();

   blnd = lerp (Bgnd, saturate (blnd), blnd.a * amount.x);

   return lerp (blnd, lerp (Bgnd, Fgnd, Fgnd.a), amount.y);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Normal        { pass P_1 { PixelShader = compile PROFILE ps_main (); } }

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Darken        { pass P_1 { PixelShader = compile PROFILE ps_darken (); } }
technique Multiply      { pass P_1 { PixelShader = compile PROFILE ps_multiply (); } }
technique ColourBurn    { pass P_1 { PixelShader = compile PROFILE ps_colourBurn (); } }
technique LinearBurn    { pass P_1 { PixelShader = compile PROFILE ps_linearBurn (); } }
technique DarkerColour  { pass P_1 { PixelShader = compile PROFILE ps_darkerColour (); } }

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Lighten       { pass P_1 { PixelShader = compile PROFILE ps_lighten (); } }
technique Screen        { pass P_1 { PixelShader = compile PROFILE ps_screen (); } }
technique ColourDodge   { pass P_1 { PixelShader = compile PROFILE ps_colourDodge (); } }
technique LinearDodge   { pass P_1 { PixelShader = compile PROFILE ps_linearDodge (); } }
technique LighterColour { pass P_1 { PixelShader = compile PROFILE ps_lighterColour (); } }

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Overlay       { pass P_1 { PixelShader = compile PROFILE ps_overlay (); } }
technique SoftLight     { pass P_1 { PixelShader = compile PROFILE ps_softLight (); } }
technique Hardlight     { pass P_1 { PixelShader = compile PROFILE ps_hardLight (); } }
technique Vividlight    { pass P_1 { PixelShader = compile PROFILE ps_vividLight (); } }
technique Linearlight   { pass P_1 { PixelShader = compile PROFILE ps_linearLight (); } }
technique Pinlight      { pass P_1 { PixelShader = compile PROFILE ps_pinLight (); } }
technique HardMix       { pass P_1 { PixelShader = compile PROFILE ps_hardMix (); } }

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Difference    { pass P_1 { PixelShader = compile PROFILE ps_difference (); } }
technique Exclusion     { pass P_1 { PixelShader = compile PROFILE ps_exclusion (); } }
technique Subtract      { pass P_1 { PixelShader = compile PROFILE ps_subtract (); } }
technique Divide        { pass P_1 { PixelShader = compile PROFILE ps_divide (); } }

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Hue           { pass P_1 { PixelShader = compile PROFILE ps_hue (); } }
technique Saturation    { pass P_1 { PixelShader = compile PROFILE ps_saturation (); } }
technique Colour        { pass P_1 { PixelShader = compile PROFILE ps_colour (); } }
technique Luminosity    { pass P_1 { PixelShader = compile PROFILE ps_luminosity (); } }
