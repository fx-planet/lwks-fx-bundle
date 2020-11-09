// @Maintainer jwrl
// @Released 2020-11-09
// @Author jwrl
// @Created 2020-11-09
// @see https://www.lwks.com/media/kunena/attachments/6375/ThreeZoneTrim_640.png

/**
 This adjusts levels to enhance or reduce them in each of three zones, low (blacks), mid
 and high (whites).  Both level and saturation can be adjusted, and the effect on the
 individual red, green and blue channels can be reduced or increased.  The most powerful
 visible effect will always be in the mids, but often the ability to desaturate white
 and/or black levels can be a lifesaver.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ThreeZoneTrim.fx
//
// Version history:
//
// Built 2020-11-09 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Three zone trim";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Adjusts low, mid and high range levels to enhance or reduce them";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Contrast_W
<
   string Group = "White levels";
   string Description = "Levels";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_W
<
   string Group = "White levels";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast_M
<
   string Group = "Mid levels";
   string Description = "Levels";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_M
<
   string Group = "Mid levels";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast_B
<
   string Group = "Black levels";
   string Description = "Levels";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_B
<
   string Group = "Black levels";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Trim_R
<
   string Group = "RGB fine tuning";
   string Description = "Red trim";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Trim_G
<
   string Group = "RGB fine tuning";
   string Description = "Green trim";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Trim_B
<
   string Group = "RGB fine tuning";
   string Description = "Blue trim";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI     3.1415926536

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 inp = tex2D (s_Input, uv);
   float4 hsv = fn_rgb2hsv (inp);

   float mids = 0.5 + (cos (smoothstep (0.0, 0.5, abs (0.5 - hsv.z)) * PI) * 0.5);
   float high = (hsv.z > 0.5) ? 1.0 - mids : 0.0;
   float lows = (hsv.z < 0.5) ? 1.0 - mids : 0.0;

   hsv.y = lerp (hsv.y, hsv.y * (Saturate_W + 1.0), high);
   hsv.y = lerp (hsv.y, hsv.y * (Saturate_M + 1.0), mids);
   hsv.y = lerp (hsv.y, hsv.y * (Saturate_B + 1.0), lows);

   hsv.z += (Contrast_W - 1.0) * high * 0.25;
   hsv.z += (Contrast_M - 1.0) * mids * 0.25;
   hsv.z += (Contrast_B - 1.0) * lows * 0.25;

   float4 retval = fn_hsv2rgb (hsv);

   retval.r = lerp (inp.r, retval.r, (Trim_R * 0.5) + 1.0);
   retval.g = lerp (inp.g, retval.g, (Trim_G * 0.5) + 1.0);
   retval.b = lerp (inp.b, retval.b, (Trim_B * 0.5) + 1.0);

   return lerp (inp, retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ThreeZoneTrim
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
