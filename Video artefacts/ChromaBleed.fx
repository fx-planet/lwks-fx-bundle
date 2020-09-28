// @Maintainer jwrl
// @Released 2020-09-28
// @Author jwrl
// @Created 2018-09-06
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromaSmear_640.png

/**
 This simulates the "colour under/pilot tone colour" of early helical scan recorders.
 It does this by blurring the image chroma and re-applying it to the luminance.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaBleed.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chroma bleed";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Gives the horizontal smeared colour look of early helical scan recorders";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Smr : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_Smear = sampler_state
{
   Texture   = <Smr>;
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
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 1.0;

float Smear
<
   string Description = "Smear";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP   12
#define DIVIDE 49

#define R_LUMA  0.2989
#define G_LUMA  0.5866
#define B_LUMA  0.1145

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_spread (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if ((Smear > 0.0) && (Amount > 0.0)) {

      float2 xy = 0.0.xx;
      float2 spread = float2 (Smear * 0.00075, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         retval = max (retval, tex2D (s_Input, uv + xy));
         retval = max (retval, tex2D (s_Input, uv - xy));
         xy += spread;
         retval = max (retval, tex2D (s_Input, uv + xy));
         retval = max (retval, tex2D (s_Input, uv - xy));
      }
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if ((Smear <= 0.0) || (Amount <= 0.0)) { return retval; }

   float4 chroma = tex2D (s_Smear, uv);

   float2 xy = 0.0.xx;
   float2 spread = float2 (Smear * 0.000375, 0.0);

   for (int i = 0; i < LOOP; i++) {
      xy += spread;
      chroma += tex2D (s_Input, uv + xy);
      chroma += tex2D (s_Input, uv - xy);
      xy += spread;
      chroma += tex2D (s_Input, uv + xy);
      chroma += tex2D (s_Input, uv - xy);
   }

   chroma /= DIVIDE;

   float3 Lval = float3 (R_LUMA, G_LUMA, B_LUMA);

   float luma = dot (chroma.rgb, Lval);

   chroma.rgb -= luma.xxx;
   luma = dot (retval.rgb, Lval);
   chroma.rgb += luma.xxx;

   return lerp (retval, chroma, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SuperBlur_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Smr;"; > 
   { PixelShader = compile PROFILE ps_main (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
