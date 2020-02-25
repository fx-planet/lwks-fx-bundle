// @Maintainer jwrl
// @Released 2020-02-25
// @Author jwrl
// @Created 2020-02-25
// @see https://www.lwks.com/media/kunena/attachments/6375/BooleanBlend_640.png

/**
 This arose out of a need to combine two images with alpha channels using the analogue
 equivalent of a digital AND gate.  AND, OR, NAND, NOR and XOR have been implemented
 while the analogue levels of the alpha channel have been maintained.  The video is
 always just OR-ed while the logic is fully implemented only in the alpha channel.

 To ensure that transparency is shown as black as far as the gating is concerned, RGB
 is multiplied by alpha.  The levels of the A and B inputs can be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BooleanBlend.fx
//
// The date shown above is when I cleaned this effect up for posting.  The main changes
// from my private original are the addition of NOR logic and the definition of "Category",
// "Subcategory" and "Notes".  It was originally categorised as "User" with no subcategory
// or notes, since the latter two weren't supported when it was written.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Boolean blend";
   string Category    = "Mix";
   string SubCategory = "Simple tools";
   string Notes       = "Combines two images with transparency using boolean logic.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture A;
texture B;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler Sampler_A = sampler_state { Texture = <A>; };
sampler Sampler_B = sampler_state { Texture = <B>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Boolean expression";
   string Enum = "AND,OR,NAND,NOR,XOR"; 
> = 0;

float Amount_A
<
   string Description = "A amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount_B
<
   string Description = "B amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_AND (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = min (vidA.a, vidB.a);

   return retval;
}

float4 ps_OR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   return max (vidA, vidB);
}

float4 ps_NAND (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - min (vidA.a, vidB.a);

   return retval;
}

float4 ps_NOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - retval.a;

   return retval;
}

float4 ps_XOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   vidA.rgb *= vidA.a;
   vidB.rgb *= vidB.a;

   float4 retval = max (vidA, vidB);

   float alpha = 1.0 - min (vidA.a, vidB.a);

   return float4 (retval.rgb, retval.a * alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AND  { pass P_1 { PixelShader = compile PROFILE ps_AND (); } }
technique OR   { pass P_1 { PixelShader = compile PROFILE ps_OR (); } }
technique NAND { pass P_1 { PixelShader = compile PROFILE ps_NAND (); } }
technique NOR  { pass P_1 { PixelShader = compile PROFILE ps_NOR (); } }
technique XOR  { pass P_1 { PixelShader = compile PROFILE ps_XOR (); } }

