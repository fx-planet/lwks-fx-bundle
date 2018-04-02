// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect FilmicLook.fx
//
// Originally created by LW user jwrl 19 March 2017.
// Modified by LW user jwrl 19 March 2017.
//
// This simulates a filmic curve with controllable halation and
// vibrance.  There are five parameters, which are:
//
// Amount     : Mixes the modified image with the original.
// Curve      : Adjusts the ammount of S-curve correction.
// Vibrance   : Allows the midtone saturation to be increased.
// Halation   : Mimics the back layer scatter of old film stocks.
// Saturation : Increases or reduces master saturation.
//
// Both vibrance and halation are adjusted logarithmically.  By
// doing this we get a more natural feel to the adjustment.
//
// The modification does two things.  It cleans up a bug that
// caused the effect to only work in monochrome on Linux/Mac
// platforms.  It also adds an extra parameter to provide
// adjustment of colour temperature.
//
// The code to adjust colour temperature started out as a direct
// transplant of the Editshare Colour Temperature effect with
// some slight tweaks but has undergone more change than was
// originally intended.  I don't think that even the original
// author would recognise it now.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Filmic look";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Cgrade  : RenderColorTarget;
texture Clipped : RenderColorTarget;
texture Halo    : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler colSampler = sampler_state
{
   Texture = <Cgrade>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler clpSampler = sampler_state
{
   Texture   = <Clipped>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler gloSampler = sampler_state
{
   Texture   = <Halo>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetRange
<
   string Description = "Video range";
   string Enum = "Legal BT.709,Full gamut (sRGB)";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float ColTemp
<
   string Description = "Colour temp";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Curve
<
   string Description = "Curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Vibrance
<
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.25;

float Halation
<
   string Description = "Halation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI 3.1415927

#define E_SCALE  0.25

#define B_POINT  0.0627451
#define W_SCALE  1.1643836
#define W_RANGE  0.8588235

#define LUMACONV float3(0.2989, 0.5866, 0.1145)
#define COLDER   float3(0.0, 0.8, 1.0)
#define WARMER   float3(1.0, 0.5, 0.0)

float _OutputWidth;
float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_colourgrade (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (InpSampler, uv);

   // Apply the colour temperature shift.  Luminance values are
   // maintained reasonably well, with just a slight droop.

   float luma  = dot (retval.rgb, LUMACONV);
   float range = abs (ColTemp * 0.2);

   float3 retRGB = (ColTemp >= 0.0) ? lerp (retval.rgb, WARMER * luma, range)
                                    : lerp (retval.rgb, COLDER * luma, range);

   // Apply the S-curve adjustment to the modified video.

   float3 vidY = 1.0.xxx - abs ((2.0 * retRGB) - 1.0.xxx);

   float Scurve = 1.0 + (4.0 * min (Curve * E_SCALE, 1.0));

   range = (SetRange == 1) ? 1.0 : W_RANGE;
   range = lerp (1.0, range, Curve);
   vidY  = (1.0.xxx - pow (vidY, Scurve)) * range * 0.5;

   retRGB.r = (retRGB.r > 0.5) ? 0.5 + vidY.r : 0.5 - vidY.r;
   retRGB.g = (retRGB.g > 0.5) ? 0.5 + vidY.g : 0.5 - vidY.g;
   retRGB.b = (retRGB.b > 0.5) ? 0.5 + vidY.b : 0.5 - vidY.b;

   // Adjust the saturation of the modified video.

   luma   = dot (retRGB, LUMACONV);
   retRGB = lerp (luma.xxx, retRGB + retRGB - luma, (Saturation + 1.0) / 2.0);

   // Finally calculate and apply the vibrance correction.

   float vibval = (retRGB.r + retRGB.g + retRGB.b) / 3.0;
   float maxval = max (retRGB.r, max (retRGB.g, retRGB.b));

   vibval = 3.0 * Vibrance * (vibval - maxval);

   return float4 (lerp (retRGB, maxval.xxx, vibval), retval.a);
}

float4 ps_clip_it (float2 uv : TEXCOORD1) : COLOR
{
   // This section creates a clipped version of the
   // colourgraded video for use later in creating
   // the halation effect.

   float4 retval = tex2D (colSampler, uv);

   float luma = dot (retval.rgb, LUMACONV);

   if (luma >= 0.9) return retval;

   if (luma < 0.70) return float4 (0.0.xxx, retval.a);

   return float4 ((retval.rgb *= (luma - 0.7) * 5.0), retval.a);
}

float4 ps_part_blur (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (clpSampler, uv);

   if (Halation <= 0.0) return retval;    // No halation, quit

   // This is a simple box blur applied to the clipped
   // video.  This section produces the horizontal blur.

   float2 xy = uv;
   float2 offset = float2 (1.0 / _OutputWidth, 0.0);

   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);
   xy += offset; retval += tex2D (clpSampler, xy);

   xy = uv - offset;
   retval += tex2D (clpSampler, xy);

   xy -= offset; retval += tex2D (clpSampler, xy);
   xy -= offset; retval += tex2D (clpSampler, xy);
   xy -= offset; retval += tex2D (clpSampler, xy);
   xy -= offset; retval += tex2D (clpSampler, xy);
   xy -= offset; retval += tex2D (clpSampler, xy);
   xy -= offset; retval += tex2D (clpSampler, xy);

   return retval / 15.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (colSampler, uv);

   float alpha  = retval.a;
   float amount = max (Amount, 0.0);

   retval = lerp (tex2D (InpSampler, uv), retval, amount);

   if (amount == 0.0) return retval;      // No changes, quit

   // Proceed with the box blur.  This section
   // produces the vertical component of the blur.

   amount *= log10 ((Halation * 4.0) + 1.0);

   float2 xy = uv;
   float2 offset = float2 (0.0, _OutputAspectRatio / _OutputWidth);

   float4 gloVal = tex2D (gloSampler, xy);

   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);
   xy += offset; gloVal += tex2D (gloSampler, xy);

   xy = uv - offset;
   gloVal += tex2D (gloSampler, xy);

   xy -= offset; gloVal += tex2D (gloSampler, xy);
   xy -= offset; gloVal += tex2D (gloSampler, xy);
   xy -= offset; gloVal += tex2D (gloSampler, xy);
   xy -= offset; gloVal += tex2D (gloSampler, xy);
   xy -= offset; gloVal += tex2D (gloSampler, xy);
   xy -= offset; gloVal += tex2D (gloSampler, xy);

   // Apply the blur to the graded image to simulate halation.

   gloVal = saturate (retval + (gloVal / 15.0));
   gloVal.a = alpha;

   return lerp (retval, gloVal, amount);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique FilmicLook
{
   pass P_1
   < string Script = "RenderColorTarget0 = Cgrade;"; >
   { PixelShader = compile PROFILE ps_colourgrade (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Clipped;"; >
   { PixelShader = compile PROFILE ps_clip_it (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Halo;"; >
   { PixelShader = compile PROFILE ps_part_blur (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

