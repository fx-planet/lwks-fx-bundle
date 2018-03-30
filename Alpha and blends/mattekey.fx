//--------------------------------------------------------------//
// mattekey.fx
//
// Created by Lightworks user jwrl 29 February 2016
//
// This provides a means of matting a foreground image into a
// background using a white on black or black on white matte
// shape.  The matte can be feathered, or it can be blurred
// inside the effect prior to generating the key.
//
// It currently uses reasonably dumb box blurs on the matte
// shape.  That seems to work well enough for feathering.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Matte key";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float opacity
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.00;

bool matteAlpha
<
   string Description = "Use matte alpha channel";
> = false;

bool Invert
<
   string Description = "Invert matte";
> = false;

int SetTechnique
<
   string Description = "Matte feather range";
   string Enum = "Standard (best for anti-aliasing),Extended (best for wipes and masks)";
> = 0;

float preBlur
<
   string Group = "Matte";
   string Description = "Feather";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.10;

float clipLevel
<
   string Group = "Matte";
   string Description = "Clip level";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float Slope
<
   string Group = "Matte";
   string Description = "Tolerance";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

bool AlphaChan
<
   string Description = "Output foreground and alpha only";
> = false;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Matte;
texture Fg;
texture Bg;

texture blurIn1 : RenderColorTarget;
texture blurIn2 : RenderColorTarget;
texture blurIn3 : RenderColorTarget;
texture blurIn4 : RenderColorTarget;
texture keyInp  : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler matteSampler = sampler_state
{
   Texture   = <Matte>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler blur1Sampler = sampler_state
{
   Texture   = <blurIn1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler blur2Sampler = sampler_state
{
   Texture   = <blurIn2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler blur3Sampler = sampler_state
{
   Texture   = <blurIn3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler blur4Sampler = sampler_state
{
   Texture   = <blurIn4>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler keySampler = sampler_state
{
   Texture   = <keyInp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

#define R_VAL          0.2989
#define G_VAL          0.5866
#define B_VAL          0.1145

#define SAMPLE_1_2     16
#define SAMPLE_3_4     32

#define MAXSAMPLE_1_2  SAMPLE_1_2*4
#define MAXSAMPLE_3_4  SAMPLE_3_4*2

#define BLUR_SCALE_1_2 0.0009765625
#define BLUR_SCALE_3_4 0.00390625

#define BLUR_ROTATE    0.70710678

float _OutputAspectRatio;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 invertMatte (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (matteSampler, xy);

   if (matteAlpha) { retval = float4 (retval.aaa, 1.0); }
   else { retval = float2 ((retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL), 1.0).xxxy ;};

   return float4 (Invert ? retval : 1.0.xxxx - retval);
}

float4 boxBlur_1 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (blur1Sampler, xy);

   float4 retval = 0.0.xxxx;

   float B_R_Factor = preBlur * BLUR_SCALE_1_2 * BLUR_ROTATE;

   float2 offs_1 = float2 (B_R_Factor / _OutputAspectRatio, B_R_Factor);
   float2 offs_2 = float2 (offs_1.x, -B_R_Factor);

   float2 xy1, xy2;

   for (int i = 0; i < SAMPLE_1_2; i++) {
      xy1 = offs_1 * i;
      xy2 = offs_2 * i;
      retval += tex2D (blur1Sampler, xy - xy1);
      retval += tex2D (blur1Sampler, xy + xy1);
      retval += tex2D (blur1Sampler, xy - xy2);
      retval += tex2D (blur1Sampler, xy + xy2);
   }

   retval /= MAXSAMPLE_1_2;

   return retval;
}

float4 boxBlur_2 (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (blur2Sampler, xy);

   float4 retval = 0.0.xxxx;

   float2 offs_1, offs_2 = float2 (0.0, preBlur * BLUR_SCALE_1_2);
   offs_1.xy = float2 (offs_2 / _OutputAspectRatio).yx;

   float2 xy1, xy2;

   for (int i = 0; i < SAMPLE_1_2; i++) {
      xy1 = offs_1 * i;
      xy2 = offs_2 * i;
      retval += tex2D (blur2Sampler, xy - xy1);
      retval += tex2D (blur2Sampler, xy + xy1);
      retval += tex2D (blur2Sampler, xy - xy2);
      retval += tex2D (blur2Sampler, xy + xy2);
   }

   retval /= MAXSAMPLE_1_2;

   return retval;
}

float4 blur_X (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (blur3Sampler, xy);

   float4 retval = 0.0.xxxx;

   float2 offset = float2 (preBlur * BLUR_SCALE_3_4 / _OutputAspectRatio, 0.0);
   float2 xy1;

   for (int i = 0; i < SAMPLE_3_4; i++) {
      xy1 = offset * i;
      retval += tex2D (blur3Sampler, xy - xy1);
      retval += tex2D (blur3Sampler, xy + xy1);
   }

   retval /= MAXSAMPLE_3_4;

   return retval;
}

float4 blur_Y (float2 xy : TEXCOORD1) : COLOR
{
   if (preBlur == 0.0) return tex2D (blur4Sampler, xy);

   float4 retval = 0.0.xxxx;

   float2 offs_2 = float2 (0.0, preBlur * BLUR_SCALE_3_4);
   float2 xy2;

   for (int i = 0; i < SAMPLE_3_4; i++) {
      xy2 = offs_2 * i;
      retval += tex2D (blur4Sampler, xy - xy2);
      retval += tex2D (blur4Sampler, xy + xy2);
   }

   retval /= MAXSAMPLE_3_4;

   return retval;
}

float4 matte_gen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (FgSampler, xy1);
   float4 bgImg  = tex2D (BgSampler, xy2);
   float4 extKey = tex2D (keySampler, xy3);

   float softRngBg = 1.0 - clipLevel;
   float softRngFg = softRngBg + Slope;
   float keyValue  = 1.0 - extKey.x;

   float keyAlpha = (keyValue <= softRngBg) ? 0.0 :
                    ((keyValue > softRngFg) ? 1.0 : (keyValue - softRngBg) / Slope);

   if (AlphaChan) { retval.a = keyAlpha; }
   else {
      keyAlpha *= opacity;
      retval = lerp (bgImg, retval, keyAlpha);
      retval.a = 1.0;
   }

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique standardFeather
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurIn1;";
   >
   {
      PixelShader = compile PROFILE invertMatte ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = blurIn2;";
   >
   {
      PixelShader = compile PROFILE boxBlur_1 ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = keyInp;";
   >
   {
      PixelShader = compile PROFILE boxBlur_2 ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE matte_gen ();
   }
}

technique extendFeather
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurIn1;";
   >
   {
      PixelShader = compile PROFILE invertMatte ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = blurIn2;";
   >
   {
      PixelShader = compile PROFILE boxBlur_1 ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = blurIn3;";
   >
   {
      PixelShader = compile PROFILE boxBlur_2 ();
   }

   pass pass_four
   <
      string Script = "RenderColorTarget0 = blurIn4;";
   >
   {
      PixelShader = compile PROFILE blur_X ();
   }

   pass pass_five
   <
      string Script = "RenderColorTarget0 = keyInp;";
   >
   {
      PixelShader = compile PROFILE blur_Y ();
   }

   pass pass_six
   {
      PixelShader = compile PROFILE matte_gen ();
   }
}
