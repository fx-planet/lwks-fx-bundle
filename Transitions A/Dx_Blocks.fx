// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user Dx_Blocks.fx
//
// Written by LW user jwrl January 2016
// @Author jwrl
// @CreationDate "January 2016"
//
// This effect starts off by building blocks from the outgoing
// image for the first third of the effect, then dissolves to
// the new image for the next third, then loses the blocks over
// the remainder of the effect.
//
// It's based on Editshare's mosaic and mix effects, but some
// parameters have been modified.  It has been written to be
// compatible with both compiler versions used to compile
// Lightworks effects.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl - renamed from block_mix.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Block dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture BlockInput : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{ 
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BlocksSampler = sampler_state
{
   Texture = <BlockInput>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float blockSize
<
   string Description = "Block size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.10;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;

#define HALF_PI 1.57079633

//--------------------------------------------------------------//
//  Shaders
//--------------------------------------------------------------//

float4 ps_mix (float2 uv : TEXCOORD1) : COLOR
{
   float4 FgdPix = tex2D (FgdSampler, uv);
   float4 BgdPix = tex2D (BgdSampler, uv);

   float  level = saturate ((Amount * 3.0) - 1.0);

   return lerp (FgdPix, BgdPix, level);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   if (blockSize <= 0.0) return tex2D (BlocksSampler, uv);

   float amt   = max (0.0, (abs (((Amount + 0.00001) * 2.5) - 1.25) - 0.25));
   float Xsize = blockSize * cos (amt * HALF_PI);
   float Ysize = Xsize * _OutputAspectRatio;

   float2 xy;

   xy.x = (floor ((uv.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy.y = (floor ((uv.y - 0.5) / Ysize) * Ysize) + 0.5;

   return tex2D (BlocksSampler, xy);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique blockDissolve
{
   pass P_1
   < string Script = "RenderColorTarget0 = BlockInput;"; >
   { PixelShader = compile PROFILE ps_mix (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
