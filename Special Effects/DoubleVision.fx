// @Maintainer jwrl
// @Released 2021-10-22
// @Author jwrl
// @Created 2021-10-22
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
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Double vision";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Gives a blurry double vision effect suitable for impaired vision POVs";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LOOP   12
#define DIVIDE 49

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Vblur, s_Blurry);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_blur (float2 uv : TEXCOORD2) : COLOR
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

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   if (Amount <= 0.0) return tex2D (s_Input, uv);

   float split = (0.05 * Amount) + 1.0;

   float2 xy1 = float2 (uv.x / split, uv.y);
   float2 xy2 = float2 (1.0 - ((1.0 - uv.x) / split), uv.y);

   return lerp (tex2D (s_Blurry, xy1), tex2D (s_Blurry, xy2), 0.5);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DoubleVision
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Vblur;"; > ExecuteShader (ps_blur)
   pass P_3 ExecuteShader (ps_main)
}

