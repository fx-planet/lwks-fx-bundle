// @Maintainer jwrl
// @Released 2020-03-14
// @Author jwrl
// @Created 2020-02-29
// @see https://www.lwks.com/media/kunena/attachments/6375/BooleanBlendPlus_640.png

/**
 This is an extension of Boolean blend, which is the analogue equivalent of a digital
 logic gate.  AND, OR, NAND, NOR and XOR have been implemented while the analogue
 levels of the alpha channel have been maintained.  The video is always just OR-ed
 while the logic is fully implemented only in the alpha channel.  Also included is a
 means of masking B with A.  In that case the same operation as with AND is performed
 on the alpha channels, but the video is taken only from the B channel.

 In all modes the default is to premultiply the RGB by the alpha channel.  This is
 done to ensure that transparency displays as black as far as the gating is concerned.
 However in this effect RGB can also be simply set to zero when alpha is zero.  This
 can be done independently for each channel.

 The levels of the A and B inputs can also be adjusted independently.  In mask mode
 reducing the A level to zero will fade the mask, revealing the background video in
 its entirety.  In that mode reducing the B level to zero fades the effect to black.

 There is also a means of using the highest value of A and B video's RGB components
 to create an artificial alpha channel for each channel.  The alpha value, however it
 is produced, is output for possible use in further blending.  Where the final output
 alpha channel is zero the video is blanked.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BooleanBlendPlus.fx
//
// Of the logic shaders only the AND shader is fully commented, since there is so much
// similarity with the other four booleans.  The mask shader is commented where it's
// significantly different to the AND shader.
//
// Modified jwrl 2020-03-14:
// Added the ability to derive the alpha from the maximum of R, G or B.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Boolean blend plus";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Combines two images using an analogue equivalent of boolean logic.  Alternatively it can mask B with A.";
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

bool Opaque_A
<
   string Group = "A video";
   string Description = "Alpha from RGB"; 
> = false;

bool Premultiply_A
<
   string Group = "A video";
   string Description = "Premultiply RGB"; 
> = true;

float Amount_B
<
   string Group = "B video";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool Opaque_B
<
   string Group = "B video";
   string Description = "Alpha from RGB"; 
> = false;

bool Premultiply_B
<
   string Group = "B video";
   string Description = "Premultiply RGB"; 
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
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   // In the boolean modes if alpha is not available, RGB values are used instead.
   // This can be less effective and should only be regarded as a plan B solution.

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   // If transparency is not set to multiply with alpha the RGB values are instead
   // replaced with zero (absolute black).

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Premultiply_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   // In all boolean modes the video is effectively initially OR-ed.  This is so that
   // whatever is subsequently done to the alpha channel, appropriate video is output.

   float4 retval = max (vidA, vidB);

   retval.a = min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;   // Blanks the video where necessary

   return retval;
}

float4 ps_OR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Premultiply_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   // Because everything is already OR-ed no additional masking is needed.

   return max (vidA, vidB);
}

float4 ps_NAND (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Premultiply_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_NOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Premultiply_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   float4 retval = max (vidA, vidB);

   retval.a = 1.0 - retval.a;

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_XOR (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   if (Premultiply_B) { vidB.rgb *= vidB.a; }
   else if (vidB.a == 0.0) vidB = EMPTY;

   vidA *= Amount_A;
   vidB *= Amount_B;

   float4 retval = max (vidA, vidB);

   retval.a *= 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = EMPTY;

   return retval;
}

float4 ps_mask (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidA = tex2D (Sampler_A, xy1);
   float4 vidB = tex2D (Sampler_B, xy2);

   if (Opaque_A) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
      }

   if (Opaque_B) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
      }

   // Only the A premultiply is required at this stage.  B is taken care of later.

   if (Premultiply_A) { vidA.rgb *= vidA.a; }
   else if (vidA.a == 0.0) vidA = EMPTY;

   // Amount_A is not applied at this stage but is used later to fade the mask.

   vidB *= Amount_B;

   // The mask operation differs slightly from a simple AND operation, in that only
   // the B video will be displayed after the AND, rather than a mix of A and B.

   float4 retval = float4 (vidB.rgb, min (vidA.a, vidB.a));

   // The premultiply for B is done now to clean up the video after the mask operation.

   if (Premultiply_B) { retval.rgb *= retval.a; }
   else if (retval.a == 0.0) retval = EMPTY;

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
