// @Maintainer jwrl
// @Released 2018-09-27
// @Author jwrl
// @Created 2018-04-19
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmicLook2018_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmicLook2018.fx
//
// Based on the earlier FilmicLook.fx, this effect simulates a filmic curve with exposure
// adjustment and controllable halation and vibrance.  In this version there is now a new
// exposure setting, so there are now eight parameters.  The order of the parameters has
// been changed from the earlier version allowing two logical groups to be formed as well
// as the non-grouped range and amount settings.
//
// Video range : This allows the adjustment range to be set to BT.709 or full gamut.
// Amount      : Mixes the modified image with the original.
//
// Exposure    : Allows a plus or minus one stop exposure correction.
// S curve     : Adjusts the amount of S-curve correction.
// Halation    : Mimics the back layer light scatter of older film stocks.
//
// Colour temp : Swings colour temperature between warmer (red) and colder (blue)
// Saturation  : Increases or reduces master saturation.
// Vibrance    : Allows the midtone saturation to be increased.
//
// Exposure is adjusted before range limiting because we need the exposure fed to the
// main effect to be correct, and this parameter is meant as a correction adjustment.
// For the same reason colour temperature is also adjusted ahead of the range limit.
// The sense of that setting has been swapped so that the higher the colour temperature
// and the bluer the image the more positive the control now is.  There's also now no
// change in luminance as the colour temperature is adjusted.
//
// Both vibrance and halation are adjusted logarithmically.  By doing this we get a more
// natural feel to the adjustment.  The halation generation technique has been slightly
// altered from that used in the earlier effect for a result that more closely resembles
// the look of film.  Vibrance is very similar to the sort of effect you get with
// the Photoshop vibrance filter - thanks gr00by for the algorithm.
//
// Bugfix and enhancement 2018-05-29 - jwrl.
// Discovered a bug that affects Linux and Mac versions when setting colour temperature.
// Highlights would invert when setting higher colour temperatures.  While correcting
// that the way the function performed subjectively was also improved.
//
// Modified 2018-07-06 jwrl.
// Calculates halation based on frame size not pixel size.
//
// Modified 27 September 2018 jwrl.
// Added notes to header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Filmic look 2018";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
   string Notes       = "Simulates a filmic curve with exposure adjustment, halation and vibrance.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Cgrade  : RenderColorTarget;
texture Clipped : RenderColorTarget;
texture Halo    : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Input>; };
sampler s_Grade = sampler_state { Texture = <Cgrade>; };

sampler s_Clip = sampler_state
{
   Texture   = <Clipped>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Halo  = sampler_state
{
   Texture   = <Halo>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

float Exposure
<
   string Group = "Linearity";
   string Description = "Exposure";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Curve
<
   string Group = "Linearity";
   string Description = "S curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Halation
<
   string Group = "Linearity";
   string Description = "Halation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ColTemp
<
   string Group = "Colour";
   string Description = "Colour temp";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Group = "Colour";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vibrance
<
   string Group = "Colour";
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define E_SCALE  0.25
#define W_RANGE  0.07058825

#define LUMACONV float3(0.2989, 0.5866, 0.1145)

#define COOLTEMP float3(1.68861871, 0.844309355, 0.0)
#define WARMTEMP float3(0.0, 0.95712098, 3.82848392)

#define PIXEL    0.0005

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_colourgrade (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   // Set up the exposure for a plus or minus one stop adjustment if needed.

   if (Exposure != 0.0) {
      float exp_range = Exposure < 0.0 ? 1.0 - Exposure : 1.0 - (Exposure * 0.5);

      retval.rgb = pow (retval.rgb, exp_range);
   }

   // Apply the colour temperature shift.  This version ensures that the luminance
   // values no longer vary slightly over the adjustment range.

   float luma    = dot (retval.rgb, LUMACONV);
   float maxTemp = clamp (ColTemp, -1.0, 1.0) * 0.5;
   float minTemp = abs (min (0.0, maxTemp));

   float3 retRGB = lerp (retval.rgb, saturate (COOLTEMP * luma), minTemp);

   maxTemp = max (0.0, maxTemp);
   retRGB = lerp (retRGB, saturate (WARMTEMP * luma), maxTemp);

   // Apply the S-curve adjustment to the modified video.

   float3 vidY = 1.0.xxx - abs ((2.0 * retRGB) - 1.0.xxx);

   float Scurve = 1.0 + (4.0 * min (Curve * E_SCALE, 1.0));
   float range  = SetRange == 1 ? 0.5 : 0.5 - (Curve * W_RANGE);

   vidY  = (1.0.xxx - pow (vidY, Scurve)) * range;

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
   // This section creates a clipped version of the colourgraded video for use later in
   // creating the halation effect.

   float4 retval = tex2D (s_Grade, uv);

   float luma = dot (retval.rgb, LUMACONV);

   return luma >= 0.9 ? retval :
          luma < 0.70 ? float4 (0.0.xxx, retval.a) :
                        float4 ((retval.rgb *= (luma - 0.7) * 5.0), retval.a);
}

float4 ps_part_blur (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Clip, uv);

   if (Halation <= 0.0) return retval;    // No halation, quit

   // This is a simple box blur applied to the clipped video, horizontal blur first.

   float h_amt  = Halation * 4.0;

   float2 xy = uv;
   float2 offset = float2 (PIXEL, 0.0);

   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);
   xy += offset; retval += tex2D (s_Clip, xy);

   xy = uv - offset;
   retval += tex2D (s_Clip, xy);

   xy -= offset; retval += tex2D (s_Clip, xy);
   xy -= offset; retval += tex2D (s_Clip, xy);
   xy -= offset; retval += tex2D (s_Clip, xy);
   xy -= offset; retval += tex2D (s_Clip, xy);
   xy -= offset; retval += tex2D (s_Clip, xy);
   xy -= offset; retval += tex2D (s_Clip, xy);

   return retval / 15.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Grade, uv);

   float alpha  = retval.a;
   float amount = max (Amount, 0.0);

   retval = lerp (tex2D (s_Input, uv), retval, amount);

   if (amount == 0.0) return retval;      // No changes, quit

   // This section produces the vertical component of the box blur.

   amount *= log10 ((Halation * 4.0) + 1.0);

   float2 xy = uv;
   float2 offset = float2 (0.0, _OutputAspectRatio * PIXEL);

   float4 gloVal = tex2D (s_Halo, xy);

   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);
   xy += offset; gloVal += tex2D (s_Halo, xy);

   xy = uv - offset;
   gloVal += tex2D (s_Halo, xy);

   xy -= offset; gloVal += tex2D (s_Halo, xy);
   xy -= offset; gloVal += tex2D (s_Halo, xy);
   xy -= offset; gloVal += tex2D (s_Halo, xy);
   xy -= offset; gloVal += tex2D (s_Halo, xy);
   xy -= offset; gloVal += tex2D (s_Halo, xy);
   xy -= offset; gloVal += tex2D (s_Halo, xy);

   // Apply the blur to the graded image to simulate halation.

   gloVal = saturate (retval + (gloVal / 15.0));
   gloVal.a = alpha;

   return lerp (retval, gloVal, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
