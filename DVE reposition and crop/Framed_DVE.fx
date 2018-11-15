// @Maintainer jwrl
// @Released 2018-11-15
// @Author jwrl
// @Created 2018-11-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Framed_DVE_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Framed_DVE.fx
//
// This is a combination of two 2D DVEs designed to provide a drop shadow and vignette
// effect while matching Editshare's 2D DVE parameters.  Because of the way that the
// DVEs are created and applied they have exactly the same quality impact on the final
// result as a single DVE would.  DVE adjusts the foreground, crop, frame and drop shadow.
// When the foreground is cropped it can be given a textured border to create a picture
// frame.  The border can be feathered, as can the drop shadow.  The second (hidden) DVE
// adjusts the size and position of the foreground inside the frame.
//
// There is actually a third DVE of sorts that adjusts the size and position of the frame
// texture.  This is extremely rudimentary though.
//
// TO DO LIST:
// Given that currently X and Y rotation kills the frame depth illusion they have been
// left out.  If a true depth component could be included though, immediately several
// things would become possible.  Apart from allowing convincing X-Y axes of rotation,
// directional edge illumination could be correctly supported and linked to drop shadow
// angle, for example.
//
// Unfortunately although modern GPUs all support working in 3D space, there seems to
// be no way to do that using Lightworks effects programming - well, no way that I can
// work out, anyway.  For example, sampler3D and tex3D() both compile but neither seem
// to do very much.  I suspect that this is fated to remain on the to-do list.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Framed DVE";
   string Category    = "DVE";
   string SubCategory = "User Effects";
   string Notes       = "Creates a textured frame around the foreground image and resizes and positions the result.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;
texture Tx;

texture Mask : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Texture = sampler_state
{
   Texture   = <Tx>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_CropMask = sampler_state
{
   Texture   = <Mask>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float DVE_Scale
<
   string Group = "DVE";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float DVE_Z_angle
<
   string Group = "DVE";
   string Description = "Z angle";
   float MinVal = -360.0;
   float MaxVal = 360.0;
> = 0.0;

float DVE_PosX
<
   string Group = "DVE";
   string Description = "X position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float DVE_PosY
<
   string Group = "DVE";
   string Description = "Y position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TLcropX
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float TLcropY
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BRcropX
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BRcropY
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float VideoScale
<
   string Group = "Video insert";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float VideoPosX
<
   string Group = "Video insert";
   string Description = "X position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float VideoPosY
<
   string Group = "Video insert";
   string Description = "Y position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BorderBevel
<
   string Group = "Border";
   string Description = "Bevel";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BorderSharpness
<
   string Group = "Border";
   string Description = "Bevel sharpness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float BorderOuter
<
   string Group = "Border";
   string Description = "Outer edge";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.6;

float BorderInner
<
   string Group = "Border";
   string Description = "Inner edge";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.4;

float TexScale
<
   string Group = "Border";
   string Description = "Texture scale";
   float MinVal = 0.5;
   float MaxVal = 2.0;
> = 1.0;

float TexPosX
<
   string Group = "Border";
   string Description = "Texture X";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TexPosY
<
   string Group = "Border";
   string Description = "Texture Y";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowOpacity
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float ShadowSoft
<
   string Group = "Shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float ShadowAngle
<
   string Group = "Shadow";
   string Description = "Angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

float ShadowOffset
<
   string Group = "Shadow";
   string Description = "Offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowDistance
<
   string Group = "Shadow";
   string Description = "Distance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI      1.5707963268
#define PI           3.1415926536

#define BEVEL_SCALE  0.04
#define BORDER_SCALE 0.05

#define SHADOW_DEPTH 0.1
#define SHADOW_SOFT  0.05

#define MINIMUM      0.0001.xx
#define MINSPIN      0.0000305176

#define SCALE        0.1725
#define OFFSET       1.15

#define CENTRE       0.5.xx

#define BLACK        float2(0.0, 1.0).xxxy
#define WHITE        1.0.xxxx
#define EMPTY        0.0.xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

float4 fn_blk2D (sampler s_Sampler, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return BLACK;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD0) : COLOR
{
/* Returned values: crop.w - master crop 
                    crop.x - master border (inside crop) 
                    crop.y - border shading
                    crop.z - drop shadow
*/
   float cropX = TLcropX < BRcropX ? TLcropX : BRcropX;
   float cropY = TLcropY > BRcropY ? TLcropY : BRcropY;

   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 xyCrop = float2 (cropX, 1.0 - cropY);
   float2 ccCrop = (xyCrop + float2 (BRcropX, 1.0 - BRcropY)) * 0.5;
   float2 uvCrop = abs (uv - ccCrop);

   xyCrop = abs (xyCrop - ccCrop);

   float2 border = max (0.0.xx, xyCrop - (aspect * BorderWidth * BORDER_SCALE));
   float2 shadow = max (0.0.xx, xyCrop - (aspect * ShadowSoft * SHADOW_SOFT));
   float2 edge_0 = aspect * BorderWidth * BorderBevel * BEVEL_SCALE;
   float2 edge_1 = max (0.0.xx, border + edge_0);

   float4 crop = ((uvCrop.x >= xyCrop.x) || (uvCrop.y >= xyCrop.y)) ? 0.0.xxxx : 1.0.xxxx;

   if ((uvCrop.x >= border.x) || (uvCrop.y >= border.y)) crop.x = 0.0;

   edge_0 = max (0.0.xx, xyCrop - edge_0);
   edge_0 = (smoothstep (edge_0, xyCrop, uvCrop) + smoothstep (border, edge_1, uvCrop)) - 1.0.xx;
   edge_0 = (clamp (edge_0 * (1.0 + (BorderSharpness * 9.0)), -1.0.xx, 1.0.xx) * 0.5) + 0.5.xx;
   shadow = smoothstep (shadow, xyCrop, uvCrop);
   crop.y = max (edge_0.x, edge_0.y);
   crop.z = (1.0 - shadow.x) * (1.0 - shadow.y);

   return crop;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float tmp, ShadowX, ShadowY, scale = DVE_Scale < 0.0001 ? 10000.0 : 1.0 / DVE_Scale;

   sincos (radians (ShadowAngle), ShadowY, ShadowX);

   float2 xy0, xy1 = (uv - CENTRE) * scale;
   float2 xy2 = float2 (ShadowX, ShadowY * _OutputAspectRatio) * ShadowOffset * SHADOW_DEPTH;

   sincos (radians (DVE_Z_angle), xy0.x, xy0.y);
   tmp  = (xy0.x * xy1.x * _OutputAspectRatio) - (xy0.y * xy1.y);
   xy1  = float2 ((xy0.x * xy1.y / _OutputAspectRatio) + (xy0.y * xy1.x), -tmp);

   xy1 += CENTRE - (float2 (DVE_PosX, -DVE_PosY) * 2.0);

   float shadow = ShadowDistance * 0.3333333333;

   xy2 += float2 (1.0, 1.0 / _OutputAspectRatio) * shadow * xy2 / max (xy2.x, xy2.y);
   tmp  = (xy0.x * xy2.x * _OutputAspectRatio) - (xy0.y * xy2.y);
   xy2  = float2 ((xy0.x * xy2.y / _OutputAspectRatio) + (xy0.y * xy2.x), -tmp);
   xy2  = ((xy1 - xy2 - CENTRE) * (1.0 + shadow)) + CENTRE;

   float2 xy3 = ((xy1 - float2 (TexPosX, -TexPosY) - CENTRE) / TexScale) + CENTRE;

   float4 Mask = fn_tex2D (s_CropMask, xy3);

   Mask.z = fn_tex2D (s_CropMask, xy2).z;

   scale = VideoScale < 0.0001 ? 10000.0 : 1.0 / VideoScale;
   xy1  = (CENTRE + ((xy1 - CENTRE) * scale)) - (float2 (VideoPosX, -VideoPosY) * 2.0);

   float4 Fgnd = fn_blk2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 frame = tex2D (s_Texture, xy3);
   float4 retval = lerp (Bgnd, BLACK, Mask.z * ShadowOpacity);

   float alpha_O = ((2.0 * Mask.y) - 1.0);
   float alpha_I = max (0.0, -alpha_O) * abs (BorderInner);

   alpha_O = max (0.0, alpha_O) * abs (BorderOuter);
   frame = BorderOuter > 0.0 ? lerp (frame, WHITE, alpha_O) : lerp (frame, BLACK, alpha_O);
   frame = BorderInner > 0.0 ? lerp (frame, WHITE, alpha_I) : lerp (frame, BLACK, alpha_I);
   retval = lerp (retval, frame, Mask.w);
   retval = lerp (retval, Fgnd, Mask.x);

   return lerp (Bgnd, retval, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Framed_DVE
{
   pass P_1
   < string Script = "RenderColorTarget0 = Mask;"; >
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
