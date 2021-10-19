// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-08-02
// @see https://www.lwks.com/media/kunena/attachments/6375/TruerSepia_640.png

/**
 Why TRUER sepia tone?  Because there are an awful lot of so-called sepia tone
 effects that create a rough and ready black and white image then colour that so
 that the lightest areas of the image are at least as strongly coloured as the
 darkest, and often even more so.  THAT IS NOT THE WAY THAT SEPIA TONING WORKS!

 Sepia toning is a chemical change to the silver molecules that we see as black
 in a photographic image, so obviously the lighter parts of an image cannot be
 as strongly coloured as the darker parts.  This effect is a very determined
 attempt to get as near as it's humanly possible to provide the look of a true
 film based sepia tone.  At it's strongest you will notice that the lighter
 areas appear almost white - which they should do.

 Secondly, sepia toning affects the less dense areas of the image first, so that
 the lighter tones will colour before the darker ones do.   For that reason, in
 this effect as the sepia tone is increased the effect converts the image
 progressively, starting with the whiter (lightest silver density) areas first.

 Thirdly, sepia is definitely not red-brown!!!!  Silver sulphide (silver sulfide
 if you're American) is a yellow-brown colour.  If you've ever changed a baby's
 nappy (diaper if you're American) you'll know exactly the colour that I mean.
 Silver sulphide is the chemical that gives you sepia toning.  The colour of the
 sepia tone has been visually matched with old photographic prints to be as close
 as it's possible to get.  No baby's nappies were checked.

 Four different black and white conversion profiles have been supplied.  There
 is the standard video luminance conversion, a modified RGB average, and two
 that mimic panchromatic and orthochromatic black and white filmstocks.  Each
 profile can have its exposure adjusted by plus or minus one stop so that you
 can finesse the look to your satisfaction.

 There is one final characteristic which I have chosen not to directly provide.
 The silver sulphide molecule is larger than the metallic silver one: this has
 the effect of increasing the contrast in a sepia toned image somewhat.  This
 means that as sepia toning increases the contrast should also increase up to
 the point where the toned image begins to fade with age.  I have chosen not to
 provide that.  There should be enough range in the exposure setting to cover
 it should you need it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TruerSepia.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Truer sepia";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "This produces an adjustable sepia tone that matches the process in real filmstocks";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define SEPIA   float3(0.732, 0.899, 1.0)

#define LUMA    float3(0.299, 0.587, 0.114)
#define AVERAGE (1.0 / 3.0).xxx
#define PANCHRO float3(0.217, 0.265, 0.518)
#define ORTHO   float3(0.025, 0.463, 0.512)

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Greyscale profile";
   string Enum = "Luminance,RGB averaging,Panchromatic film,Orthochromatic film";
> = 2;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Exposure
<
   string Group = "Sepia settings";
   string Description = "Exposure";
   string Flags = "DisplayAsLiteral";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float SepiaTone
<
   string Group = "Sepia settings";
   string Description = "Sepia tone";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_L (float2 uv : TEXCOORD1) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 retval = tex2D (s_Input, uv);

   float print = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 sepia = pow (retval.rgb, print);

   float luma = 1.0 - dot (sepia, LUMA);

   sepia = 1.0.xxx - (SEPIA * luma);

   float SepiaMix = min (1.0, pow (2.0 * (SepiaTone + sepia.b), 4.0) * min (1.0, SepiaTone * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaTone - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Amount), retval.a);
}

float4 ps_main_A (float2 uv : TEXCOORD1) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 retval = tex2D (s_Input, uv);

   float print = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 sepia = pow (retval.rgb, print);

   float luma = pow (1.0 - pow (dot (sepia, AVERAGE), 1.2), 1.3);

   sepia = 1.0.xxx - (SEPIA * luma);

   float SepiaMix = min (1.0, pow (2.0 * (SepiaTone + sepia.b), 4.0) * min (1.0, SepiaTone * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaTone - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Amount), retval.a);
}

float4 ps_main_P (float2 uv : TEXCOORD1) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 retval = tex2D (s_Input, uv);

   float print = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 sepia = pow (retval.rgb, print);

   sepia.r = pow (sepia.r, 0.7);
   sepia.b = pow (sepia.b, 1.5);

   float luma = pow (1.0 - pow (dot (sepia, PANCHRO), 1.375), 2.8);

   sepia = 1.0.xxx - (SEPIA * luma);

   float SepiaMix = min (1.0, pow (2.0 * (SepiaTone + sepia.b), 4.0) * min (1.0, SepiaTone * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaTone - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Amount), retval.a);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 retval = tex2D (s_Input, uv);

   float print = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 sepia = pow (retval.rgb, print);

   sepia.r = pow (sepia.r, 5.0);
   sepia.g = pow (sepia.g, 2.5);
   sepia.b = pow (sepia.b, 0.6);

   float luma = pow (1.0 - dot (sepia, ORTHO), 1.7);

   sepia = 1.0.xxx - (SEPIA * luma);

   float SepiaMix = min (1.0, pow (2.0 * (SepiaTone + sepia.b), 4.0) * min (1.0, SepiaTone * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaTone - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Amount), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TrueSepia_0 { pass P_1 ExecuteShader (ps_main_L) }
technique TrueSepia_1 { pass P_1 ExecuteShader (ps_main_A) }
technique TrueSepia_2 { pass P_1 ExecuteShader (ps_main_P) }
technique TrueSepia_3 { pass P_1 ExecuteShader (ps_main_O) }

