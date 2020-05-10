// @Maintainer jwrl
// @Released 2020-05-10
// @Author jwrl
// @Created 2020-05-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Mirrors_640.png

/**
 Mirrors creates mirrored halves of the frame for title sequences.  The mirroring can be
 vertical or horizontal, and the mirror point/wipe centre can be moved to vary the effect.
 The image can also be scaled and positioned to control the area mirrored.

 Any black areas visible outside the active picture area are transparent, and can be
 blended with other effects to add complexity.

 There is a more complex version of this effect available, which adds the ability to rotate
 and flip the image. It's called Rosehaven.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Mirrors.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Mirrors";
   string Category    = "DVE";
   string SubCategory = "Simple tools";
   string Notes       = "Creates mirrored top/bottom or left/right images.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Img : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_Image = sampler_state
{
   Texture   = <Img>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Group = "Mirror settings";
   string Description = "Orientation";
   string Enum = "Horizontal,Vertical";
> = 1;

float Centre
<
   string Group = "Mirror settings";
   string Description = "Axis position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float Scale
<
   string Group = "Input image";
   string Description = "Scale";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.25;
   float MaxVal = 4.0;
> = 1.0;

float PosX
<
   string Group = "Input image";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Group = "Input image";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler S, float2 s)
{
   return (s.x < 0.0) || (s.y < 0.0) || (s.x > 1.0) || (s.y > 1.0) ? EMPTY : tex2D (S, s);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_scale (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Input, (uv - float2 (PosX, 1.0 - PosY)) / max (0.25, Scale) + 0.5.xx);
}

float4 ps_main_H (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Image, uv - float2 (Centre, 0.0));
}

float4 ps_main_V (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Image, uv - float2 (0.0, Centre));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Mirrors_H
{
   pass P_1
   < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_H (); }
}

technique Mirrors_V
{
   pass P_1
   < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_V (); }
}

