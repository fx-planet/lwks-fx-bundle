// @Maintainer jwrl
// @Released 2020-02-29
// @Author jwrl
// @Created 2020-02-29
// @see https://www.lwks.com/media/kunena/attachments/6375/BooleanBlendPlus_640.png

/**
 This is an extension of Boolean blend, which is the analogue equivalent of a digital
 logic gate.  AND, OR, NAND, NOR and XOR have been implemented while the analogue levels
 of the alpha channel have been maintained.  The video is always just OR-ed while the
 logic is fully implemented only in the alpha channel.

 As with Boolean blend, the default is to premultiply the RGB by the alpha channel, which
 is done to ensure that transparency displays as black as far as the gating is concerned.
 However in this effect RGB can also be simply set to zero when alpha is zero.  This can
 be done independently for each channel.  As with the earlier effect the levels of the A
 and B inputs can also be independently adjusted.  Unlike Boolean blend, the final video
 output is blanked to zero wherever the output alpha is zero.

 There is also a new mode called "Mask B with A".  This will work off the A video's alpha
 channel if "Premultiply RGB/mask uses alpha" is chosen, but will otherwise use the A
 video's RGB.  In this mode the B video's "Premultiply RGB/alpha from mask" uses the mask
 value as the alpha output for possible use in further blending, otherwise the unmodified
 B video's alpha channel is used.

 In "Mask B with A" the A channel's "Amount" setting can be used to fade the masked video
 out to reveal the full B video.  In this mode the B channel's "Amount" setting is used to
 fade the image to black, whether masked or not.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BooleanBlendPlus.fx
//
// Of the logic shaders only the AND shader is fully commented, since there is so much
// similarity with the other four booleans.  The mask shader is fully commented.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Boolean blend plus";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Combines two images having transparency using an equivalent of boolean logic.  Can also mask B with A.";
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
   string Description = "Blend mode";
   string Enum = "AND,OR,NAND,NOR,XOR,Mask B with A"; 
> = 0;

float Amount_A
<
   string Group = "A video";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool Transparency_A
<
   string Group = "A video";
   string Description = "Premultiply RGB/mask uses alpha"; 
> = true;

float Amount_B
<
   string Group = "B video";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool Transparency_B
<
   string Group = "B video";
   string Description = "Premultiply RGB/alpha from mask"; 
> = true;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_AND (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   // In the boolean modes if transparency is not set to multiply with alpha the RGB
   // values are instead replaced with zero (absolute black).

   if (Transparency_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Transparency_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   // In all boolean modes the video is effectively initially OR-ed.  This is so that
   // whatever is subsequently done to the alpha channel, appropriate video is output.

   float4 retval = max (vidA, vidB);

   retval.a = min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;   // Blanks the video where necessary

   return retval;
}

float4 ps_OR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   if (Transparency_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Transparency_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   // Because everything is already OR-ed no additional masking is needed.

   return max (vidA, vidB);
}

float4 ps_NAND (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   if (Transparency_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Transparency_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_NOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   if (Transparency_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Transparency_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - retval.a;

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_XOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1) * Amount_A;
   float4 vidB = tex2D (Sampler_B, xy2) * Amount_B;

   if (Transparency_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Transparency_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   float4 retval = max (vidA, vidB);

   retval.a *= 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_mask (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   // In this mode if transparency is not set to multiply with alpha on the A channel
   // the alpha channel is instead filled with the maximum value found in the R, G and
   // B channels.

   if (!Transparency_A) vidA.a = max (vidA.r, max (vidA.g, vidA.b));

   // The A's alpha channel is now transferred to its RGB channels.  This allows us to
   // use the minimum value to generate the mask.  This should be simpler than using
   // a linear interpolation (lerp()).

   vidA.rgb = vidA.aaa;

   float4 retval = min (vidA, vidB * Amount_B);

   // If transparency is set to multiply with alpha on the B channel the mask video will
   // be used as the alpha channel, otherwise the unmodified B channel alpha is used.

   retval.a = Transparency_B ? vidA.a : vidB.a;

   return lerp (vidB, retval, Amount_A);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AND  { pass P_1 { PixelShader = compile PROFILE ps_AND (); } }
technique OR   { pass P_1 { PixelShader = compile PROFILE ps_OR (); } }
technique NAND { pass P_1 { PixelShader = compile PROFILE ps_NAND (); } }
technique NOR  { pass P_1 { PixelShader = compile PROFILE ps_NOR (); } }
technique XOR  { pass P_1 { PixelShader = compile PROFILE ps_XOR (); } }
technique Mask { pass P_1 { PixelShader = compile PROFILE ps_mask (); } }

