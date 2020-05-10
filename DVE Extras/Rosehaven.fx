// @Maintainer jwrl
// @Released 2020-05-10
// @Author jwrl
// @Created 2020-05-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Rosehaven_640.png

/**
 Rosehaven creates mirrored halves of the frame for title sequences and similar uses.
 The mirroring can be vertical or horizontal, and the mirror point/wipe centre can be
 moved to vary the effect.  The image can also be scaled, positioned, flipped and
 rotated to control the area mirrored.  There is a simpler version of this effect
 called Mirrors available, which lacks the ability to flip and rotate the image.

 Any black areas visible outside the active picture area are transparent, and can be
 blended with other effects to add complexity.

 The name of this effect comes from an Australian television series that I saw several
 years ago.  An effect similar to this was used in its opening title sequence.  Well,
 I had to call it something!
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rosehaven.fx
//
// This started life as a very simple effect called Mirrors.fx with just three lines of
// active code.  Adding the ability to rotate and flip the image changed that though!
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rosehaven";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Creates mirrored top/bottom or left/right images.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Img : RenderColorTarget;
texture Otd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Oriented = sampler_state
{
   Texture   = <Otd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

int Mode
<
   string Group = "Mirror settings";
   string Description = "Orientation";
   string Enum = "Horizontal,Vertical";
> = 1;

float Centre
<
   string Group = "Mirror settings";
   string Description = "Axis position";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Input image";
   string Description = "Orientation";
   string Enum = "Normal,Flipped,Flopped,Flipped / flopped,Rotated,Flip / rotate,Flop / rotate,Flip-flop / rotate";
> = 0;

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
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float PosY
<
   string Group = "Input image";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  0.0.xxxx

float _OutputAspectRatio;

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

float4 ps_input_0 (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Input, uv);
}

float4 ps_input_1 (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Input, float2 (uv.x, 1.0 - uv.y));
}

float4 ps_input_2 (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Input, float2 (1.0 - uv.x, uv.y));
}

float4 ps_input_3 (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Input, 1.0.xx - uv);
}

float4 ps_scale_N (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = float2 (uv.x - PosX, uv.y + PosY);

   if (Mode == 0) {
      xy = float2 (xy.x, xy.y - 0.5) / max (0.25, Scale);
      xy.y += 0.5;
   }
   else {
      xy = float2 (xy.x - 0.5, xy.y) / max (0.25, Scale);
      xy.x += 0.5;
   }

   return fn_tex2D (s_Oriented, xy);
}

float4 ps_scale_R (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;

   if (Mode == 0) {
      xy = float2 (uv.x + PosX, 1.0 - uv.y - PosY);
      xy = float2 (xy.x * _OutputAspectRatio, (xy.y - 0.5) / _OutputAspectRatio);
      xy = xy / max (0.25, Scale);
      xy = float2 (xy.y + 0.5, xy.x);
   }
   else {
      xy = float2 (1.0 - uv.x + PosX, uv.y - PosY);
      xy = float2 ((xy.x - 0.5) * _OutputAspectRatio, xy.y / _OutputAspectRatio);
      xy = xy / max (0.25, Scale);
      xy = float2 (xy.y, xy.x + 0.5);
   }

   return fn_tex2D (s_Oriented, xy);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (Mode == 0) ? uv - float2 (Centre, 0.0) : uv + float2 (0.0, Centre - 1.0);

   return tex2D (s_Image, xy);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Rosehaven_0
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_0 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_N (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_1
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_1 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_N (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_2
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_2 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_N (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_3
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_3 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_N (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_4
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_0 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_R (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_5
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_1 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_R (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_6
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_2 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_R (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

technique Rosehaven_7
{
   pass P_0 < string Script = "RenderColorTarget0 = Otd;"; >
   { PixelShader = compile PROFILE ps_input_3 (); }

   pass P_1 < string Script = "RenderColorTarget0 = Img;"; >
   { PixelShader = compile PROFILE ps_scale_R (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

