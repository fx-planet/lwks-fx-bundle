// @Maintainer jwrl
// @Released 2018-12-27
// @Author jwrl
// @Created 2018-09-09
// @see https://www.lwks.com/media/kunena/attachments/6375/DoubleVis_640.png

/**
Double vision gives a blurry double vision effect suitable for removing glasses or drunken
or head punch effects.  The blur adjustment is scaled by the displacement amount, so that
when the amount reaches zero the blur does also.  The displacement is produced by scaling
the video slightly in the X direction, ensuring that no edge artefacts are visible.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DoubleVision.fx
//
// Modified 5 Dec 2018 by user jwrl:
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Double vision";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Gives a blurry double vision effect suitable for impaired vision POVs";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Vblur : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blurry = sampler_state { Texture = <Vblur>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blur
<
   string Description = "Blurriness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP   12
#define DIVIDE 49

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_blur (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if (Amount > 0.0) {

      float2 xy = 0.0.xx;
      float2 spread = float2 (Amount * Blur * 0.00075, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         retval += tex2D (s_Input, uv + xy);
         retval += tex2D (s_Input, uv - xy);
         xy += spread;
         retval += tex2D (s_Input, uv + xy);
         retval += tex2D (s_Input, uv - xy);
      }

      retval /= DIVIDE;
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   if (Amount <= 0.0) { return tex2D (s_Input, uv); }

   float split = (0.05 * Amount) + 1.0;

   float2 xy1 = uv;
   float2 xy2 = uv;

   xy1.x = uv.x / split;
   xy2.x = 1.0 - ((1.0 - uv.x) / split);

   return lerp (tex2D (s_Blurry, xy1), tex2D (s_Blurry, xy2), 0.5);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DoubleVision
{
   pass P_1
   < string Script = "RenderColorTarget0 = Vblur;"; > 
   { PixelShader = compile PROFILE ps_blur (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

