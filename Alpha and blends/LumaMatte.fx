// @Maintainer jwrl
// @Released 2018-06-08
// @Author jwrl
// @Created 2018-06-08
// @see https://www.lwks.com/media/kunena/attachments/6375/LumaMatte_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumaMatte.fx
//
// This effect is designed to generate a key from the foreground video and use that key
// to superimpose the foreground over the background or fill the foreground key shape
// with a flat matte colour.  It has been designed with text supers in mind.  The key
// can be produced from a white on black image or inverted.  Alternatively the alpha
// channel can be used instead of the video to provide the key.  The same controls apply
// to the alpha channel in this mode as do to the video.
//
// A coloured border can also be generated from the key.  Border opacity, width and
// colour are all adjustable.  A drop shadow with the same range of adjustments can also
// be produced, and the position of that shadow can be adjusted.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey and matte";
   string Category    = "Key";
   string SubCategory = "User Effects";
   string Notes       = "This will generate a lumakey from white on black video, fill it with a matte colour and generate a border and drop shadow for it.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture keyInp  : RenderColorTarget;
texture brdrInp : RenderColorTarget;
texture brdrOut : RenderColorTarget;
texture shadow  : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_KeyAlpha = sampler_state {
   Texture   = <keyInp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BorderIn = sampler_state {
   Texture = <brdrInp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_BorderOut = sampler_state {
   Texture = <brdrOut>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Shadow = sampler_state {
   Texture = <shadow>;
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
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.00;

bool KeyAlpha
<
   string Description = "Use foreground alpha channel";
> = false;

bool KeyInvert
<
   string Description = "Invert key";
> = false;

float KeyClip
<
   string Group = "Key";
   string Description = "Clip level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float KeySlope
<
   string Group = "Key";
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

int KeyFill
<
   string Group = "Key";
   string Description = "Fill key with:";
   string Enum = "Foreground,Matte colour";
> = 1;

float4 KeyMatte
<
   string Group = "Key";
   string Description = "Matte colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

float BorderOpacity
<
   string Group = "Border";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.00;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 BorderColour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 0.0 };

float ShadowOpacity
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float ShadowFeather
<
   string Group = "Shadow";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3333;

float Shadow_X
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.20;

float Shadow_Y
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.20;

float4 ShadowColour
<
   string Group = "Shadow";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 0.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

float _OutputPixelWidth;
float _OutputPixelHeight;

float _sin0 [] = { 0.0, 0.2588, 0.5, 0.7071, 0.866, 0.9659, 1.0 };

float _sin1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };

float _pascal [] = { 0.0002441, 0.0029297, 0.0161133, 0.0537109, 0.1208496, 0.1933594, 0.2255859 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_matte_gen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 retval = (KeyFill == 1) ? KeyMatte : Fgnd;

   float softRngBg = 1.0 - KeyClip;
   float softRngFg = softRngBg + KeySlope;
   float keyValue  = KeyAlpha ? Fgnd.a : max (Fgnd.r, max (Fgnd.g, Fgnd.b));

   if (KeyInvert) keyValue = 1.0 - keyValue;

   retval.a = (keyValue <= softRngBg) ? 0.0 :
              ((keyValue > softRngFg) ? 1.0 : (keyValue - softRngBg) / KeySlope);

   return retval;
}

float4 ps_border_A (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_KeyAlpha, uv);

   if (BorderOpacity == 0.0) return retval;

   float2 offset;
   float2 xy = float2 (1.0, _OutputAspectRatio) * 10.0 * BorderWidth / _OutputWidth;

   for (int i = 0; i < 7; i++) {
      offset = xy * float2 (_sin0 [i], _sin0 [6 - i]);

      retval += tex2D (s_KeyAlpha, uv + offset);
      retval += tex2D (s_KeyAlpha, uv - offset);

      offset.y = -offset.y;

      retval += tex2D (s_KeyAlpha, uv + offset);
      retval += tex2D (s_KeyAlpha, uv - offset);
   }

   return saturate (retval);
}

float4 ps_border_B (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_KeyAlpha, uv);

   if (BorderOpacity == 0.0) return Fgnd;

   float4 retval = tex2D (s_BorderIn, uv);

   float2 offset;
   float2 xy = float2 (1.0, _OutputAspectRatio) * 10.0 * BorderWidth / _OutputWidth;

   for (int i = 0; i < 6; i++) {
      offset = xy * float2 (_sin1 [i], _sin1 [5 - i]);

      retval += tex2D (s_BorderIn, uv + offset);
      retval += tex2D (s_BorderIn, uv - offset);

      offset.y = -offset.y;

      retval += tex2D (s_BorderIn, uv + offset);
      retval += tex2D (s_BorderIn, uv - offset);
   }

   retval = saturate (retval);

   float alpha = max (Fgnd.a, retval.a * BorderOpacity);

   retval = lerp (BorderColour, Fgnd, Fgnd.a);

   return float4 (retval.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (Shadow_X / _OutputAspectRatio, -Shadow_Y) * 0.04;

   float4 retval = tex2D (s_BorderOut, xy);

   if ((ShadowOpacity != 0.0) && (ShadowFeather != 0.0)) {
      float offset = ShadowFeather * 2.0 / _OutputWidth;

      float pos_6 = xy.x  + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_6 = xy.x  - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [6];

      retval += tex2D (s_BorderOut, float2 (pos_5, xy.y)) * _pascal [5];
      retval += tex2D (s_BorderOut, float2 (pos_4, xy.y)) * _pascal [4];
      retval += tex2D (s_BorderOut, float2 (pos_3, xy.y)) * _pascal [3];
      retval += tex2D (s_BorderOut, float2 (pos_2, xy.y)) * _pascal [2];
      retval += tex2D (s_BorderOut, float2 (pos_1, xy.y)) * _pascal [1];
      retval += tex2D (s_BorderOut, float2 (pos_0, xy.y)) * _pascal [0];

      retval += tex2D (s_BorderOut, float2 (neg_5, xy.y)) * _pascal [5];
      retval += tex2D (s_BorderOut, float2 (neg_4, xy.y)) * _pascal [4];
      retval += tex2D (s_BorderOut, float2 (neg_3, xy.y)) * _pascal [3];
      retval += tex2D (s_BorderOut, float2 (neg_2, xy.y)) * _pascal [2];
      retval += tex2D (s_BorderOut, float2 (neg_1, xy.y)) * _pascal [1];
      retval += tex2D (s_BorderOut, float2 (neg_0, xy.y)) * _pascal [0];
   }

   return retval;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Shadow, xy1);

   if ((ShadowOpacity != 0.0) && (ShadowFeather != 0.0)) {
      float offset = ShadowFeather * 2.0 * _OutputAspectRatio / _OutputWidth;

      float pos_6 = xy1.y + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_6 = xy1.y - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [6];

      retval += tex2D (s_Shadow, float2 (xy1.x, pos_5)) * _pascal [5];
      retval += tex2D (s_Shadow, float2 (xy1.x, pos_4)) * _pascal [4];
      retval += tex2D (s_Shadow, float2 (xy1.x, pos_3)) * _pascal [3];
      retval += tex2D (s_Shadow, float2 (xy1.x, pos_2)) * _pascal [2];
      retval += tex2D (s_Shadow, float2 (xy1.x, pos_1)) * _pascal [1];
      retval += tex2D (s_Shadow, float2 (xy1.x, pos_0)) * _pascal [0];

      retval += tex2D (s_Shadow, float2 (xy1.x, neg_5)) * _pascal [5];
      retval += tex2D (s_Shadow, float2 (xy1.x, neg_4)) * _pascal [4];
      retval += tex2D (s_Shadow, float2 (xy1.x, neg_3)) * _pascal [3];
      retval += tex2D (s_Shadow, float2 (xy1.x, neg_2)) * _pascal [2];
      retval += tex2D (s_Shadow, float2 (xy1.x, neg_1)) * _pascal [1];
      retval += tex2D (s_Shadow, float2 (xy1.x, neg_0)) * _pascal [0];
   }

   float alpha = retval.a * ShadowOpacity;

   retval = tex2D (s_BorderOut, xy1);
   alpha  = max (alpha, retval.a);
   retval = lerp (ShadowColour, retval, retval.a);

   float4 Bgnd = tex2D (s_Background, xy2);

   retval = lerp (Bgnd, retval, alpha * Amount);

   return float4 (retval.rgb, Bgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LumaMatte_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = keyInp;"; >
   { PixelShader = compile PROFILE ps_matte_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = brdrInp;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_3
   < string Script = "RenderColorTarget0 = brdrOut;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_4
   < string Script = "RenderColorTarget0 = shadow;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

