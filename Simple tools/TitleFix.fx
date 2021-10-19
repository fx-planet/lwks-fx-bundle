// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/TitleFix_640.png

/**
 This effect enhances the blending of a title, roll or crawl when used with external blending
 or DVE effects.  Because it has been developed empirically with no knowledge of how Lightworks
 does it internally, it only claims to be subjectively close to the Lightworks effect.

 To use it, disconnect the title input, apply this effect to the title then apply the blend or
 DVE effect that you need.  You will get a result very similar to that obtained with a standard
 title effect.

 It also has the ability to smooth and antialias text produced by any Lightworks text effect.
 This can be particularly useful when moving or zooming on a title.  A suggested start point
 setting of 10% is completely subjective, and will almost certainly vary depending on text
 size and style.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TitleFix.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Title blend fix";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Enhances Lightworks titles when they are used with DVEs and other effects";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375,
                      0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (RawInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Smoothing
<
   string Description = "Smooth edges";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   if (Smoothing > 0.0) {
      float2 xy1 = float2 (1.0, _OutputAspectRatio) * Smoothing * STRENGTH;
      float2 xy2 = uv + xy1;

      retval *= _gaussian [0];
      retval += tex2D (s_Input, xy2) * _gaussian [1]; xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [2]; xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [3]; xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [4]; xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [5]; xy2 += xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [6];

      xy2 = uv - xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [1]; xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [2]; xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [3]; xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [4]; xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [5]; xy2 -= xy1;
      retval += tex2D (s_Input, xy2) * _gaussian [6];
   }

   retval.a = pow (retval.a, 0.5);
   retval.rgb /= retval.a;

   return (Overflow (uv)) ? EMPTY : retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TitleFix
{
   pass P_1 < string Script = "RenderColorTarget0 = RawInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main)
}

