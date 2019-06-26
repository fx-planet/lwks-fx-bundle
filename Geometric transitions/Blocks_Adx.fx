// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blocks_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blocks.mp4

/**
This effect is used to transition into or out of a delta (difference) key, and is useful
with titles.  The title fades in from blocks that progressively reduce in size or builds
into larger and larger blocks as it fades.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blocks_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Block dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Separates foreground from background and builds it into larger and larger blocks as it fades";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
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
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

float blockSize
<
   string Group = "Blocks";
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float AR
<
   string Group = "Blocks";
   string Description = "Aspect ratio";
   float MinVal = 0.25;
   float MaxVal = 4.00;
> = 1.0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLOCKS  0.1

#define HALF_PI 1.5707963268

#define EMPTY  (0.0).xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float2 xy = xy1;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = cos (Amount * HALF_PI);

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (tex2D (s_Foreground, xy2), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float2 xy = xy1;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = sin (Amount * HALF_PI);

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Bgnd = fn_tex2D (s_Title, xy);

   return lerp (tex2D (s_Background, xy2), Bgnd, Bgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Blocks_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_Blocks_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

