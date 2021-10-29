// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2011-04-17
// @see https://www.lwks.com/media/kunena/attachments/6375/Grain_640.png

/**
 This is a simple means of applying a video noise style of grain.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Grain_Effect.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain effect";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "This is a simple means of applying a video noise style of grain";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Strength
<
   string Description = "Strength";
   string Group = "Master";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand (float2 co, float seed)
{
   return frac ((dot (co.xy, float2 (co.x + 123.0, co.y + 13.0))) * seed + _Progress);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = GetPixel (s_Input, uv);

   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float x = sin (xy.x) + cos (xy.y) + _rand (xy, ((source.g + 1.0) * xy.x)) * 1000.0;
   float grain = frac (fmod (x, 13.0) * fmod (x, 123.0)) - 0.5;

   source.rgb = saturate (source.rgb + (grain * (Strength / 50.0)).xxx);
  
   return source;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Grain
{
   pass P_1 ExecuteShader (ps_main)
}

