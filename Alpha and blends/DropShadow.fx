// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2016-03-31
// @see https://www.lwks.com/media/kunena/attachments/6375/DropShadow_5.png
//-----------------------------------------------------------------------------------------//
// Lightworks effect DropShadow.fx
//
// This effect is a drop shadow and border generator.  It provides drop shadow blur and
// independent colour settings for border and shadow.  Two border generation modes and
// full border anti-aliassing are provided.  The border centering can also be adjusted
// (thanks Igor for the suggestion).
//
// The effect can also output the foreground, border and drop shadow alone, with the
// appropriate alpha channel.  When doing so any background input to the effect will not
// be displayed.  This allows it to be used with downstream alpha processing effects.
//
// LW 14+ version by jwrl 11 January 2017.
// Category changed from "Keying" to "Key", subcategory "Edge Effects" added.
//
// Bug fix 26 February 2017 by jwrl:
// Fixed a bug with Lightworks' handling of interlaced media.  The height parameter in
// Lightworks returns half the true frame height when interlaced media is stationary.
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which could cause the effect to not behave as
// expected on Linux and Mac systems.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow and border";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture brdrInp : RenderColorTarget;
texture aliased : RenderColorTarget;
texture brdrOut : RenderColorTarget;
texture fthr_in : RenderColorTarget;
texture shadOut : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b_inSampler = sampler_state {
   Texture = <brdrInp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler hardSampler = sampler_state {
   Texture   = <aliased>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler fthrSampler = sampler_state {
   Texture = <fthr_in>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler borderSampler = sampler_state {
   Texture = <brdrOut>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler shadowSampler = sampler_state {
   Texture = <shadOut>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.00;

int B_edge
<
   string Group = "Border";
   string Description = "Border mode";
   string Enum = "Fully sampled,Full no anti-alias,Square edged,Square no anti-alias";
> = 0;

bool Badjust
<
   string Group = "Border";
   string Description = "Lock height to width";
> = true;

float Bamount
<
   string Group = "Border";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.00;

float Bwidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Bheight
<
   string Group = "Border";
   string Description = "Height";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float BcentreX
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float BcentreY
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 Bcolour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = (0.4784, 0.3961, 1.0, 0.7);

float Samount
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float feather
<
   string Group = "Shadow";
   string Description = "Feather";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.3333;

float offsetX
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.20;

float offsetY
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = -0.20;

float4 Scolour
<
   string Group = "Shadow";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = (0.0, 0.0, 0.0, 0.0);

int SetTechnique
<
   string Description = "Output mode";
   string Enum = "Normal (no alpha),Foreground with alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define F_SCALE    2
#define B_SCALE    10
#define S_SCALE    1.75

#define OFFS_SCALE 0.04

float _OutputAspectRatio;
float _OutputWidth  = 1.0;

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

const float sin_0 [] = { 0.0, 0.2588, 0.5, 0.7071, 0.866, 0.9659, 1.0 };
const float cos_0 [] = { 1.0, 0.9659, 0.866, 0.7071, 0.5, 0.2588, 0.0 };

const float sin_1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
const float cos_1 [] = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

const float _pascal [] = { 0.00000006, 0.00000143, 0.00001645, 0.00012064,
                           0.00063336, 0.00253344, 0.00802255, 0.02062941,
                           0.04383749, 0.07793331, 0.11689997, 0.14878178,
                           0.16118026 };

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 border_A (float2 xy : TEXCOORD1) : COLOR
{
   if (Bamount == 0.0) return tex2D (FgSampler, xy);

   float edgeX, edgeY;

   if (B_edge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = B_SCALE * S_SCALE / _OutputWidth;
      edgeY = 0.0;
   }

   float2 offset;
   float2 refXY = xy + float2 (edgeX * (0.5 - BcentreX), edgeY * (BcentreY - 0.5)) * 2.0;

   float4 retval = tex2D (FgSampler, refXY);

   edgeX *= Bwidth;
   edgeY *= Badjust ? Bwidth : Bheight;

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * sin_0 [i];
      offset.y = edgeY * cos_0 [i];

      retval += tex2D (FgSampler, refXY + offset);
      retval += tex2D (FgSampler, refXY - offset);

      offset.y = -offset.y;

      retval += tex2D (FgSampler, refXY + offset);
      retval += tex2D (FgSampler, refXY - offset);
   }

   return saturate (retval);
}

float4 border_B (float2 xy : TEXCOORD1) : COLOR
{
   if (Bamount == 0.0) return tex2D (FgSampler, xy);

   float edgeX, edgeY;

   if (B_edge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = 0.0;
      edgeY = B_SCALE * S_SCALE * _OutputAspectRatio / _OutputWidth;
   }

   float2 offset;
   float2 refXY = xy + float2 (edgeX * (0.5 - BcentreX), edgeY * (BcentreY - 0.5)) * 2.0;

   float4 retval = tex2D (b_inSampler, refXY);

   edgeX *= Bwidth;
   edgeY *= Badjust ? Bwidth : Bheight;

   for (int i = 0; i < 6; i++) {
      offset.x = edgeX * sin_1 [i];
      offset.y = edgeY * cos_1 [i];

      retval += tex2D (b_inSampler, refXY + offset);
      retval += tex2D (b_inSampler, refXY - offset);

      offset.y = -offset.y;

      retval += tex2D (b_inSampler, refXY + offset);
      retval += tex2D (b_inSampler, refXY - offset);
   }

   return saturate (retval);
}

float4 border_C (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (hardSampler, xy);

   if (Bamount == 0.0) return retval;

   if ((B_edge == 0) || (B_edge == 2)) {
      float2 offset = max (_OutputPixelHeight * _OutputAspectRatio, _OutputPixelWidth).xx / (_OutputWidth * 2.0);

      retval += tex2D (hardSampler, xy + offset);
      retval += tex2D (hardSampler, xy - offset);

      offset.x = -offset.x;

      retval += tex2D (hardSampler, xy + offset);
      retval += tex2D (hardSampler, xy - offset);
      retval /= 5.0;
   }

   float4 fgnd = tex2D (FgSampler, xy);

   float alpha = max (fgnd.a, retval.a * Bamount);

   retval = lerp (Bcolour, fgnd, fgnd.a);

   return float4 (retval.rgb, alpha);
}

float4 makeShadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (offsetX / _OutputAspectRatio, -offsetY) * OFFS_SCALE;

   float4 retval = tex2D (borderSampler, xy);

   if ((Samount != 0.0) && (feather != 0.0)) {
      float offset = feather * F_SCALE / _OutputWidth;

      float pos_b = xy.x  + offset;
      float pos_a = pos_b + offset;
      float pos_9 = pos_a + offset;
      float pos_8 = pos_9 + offset;
      float pos_7 = pos_8 + offset;
      float pos_6 = pos_7 + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_b = xy.x  - offset;
      float neg_a = neg_b - offset;
      float neg_9 = neg_a - offset;
      float neg_8 = neg_9 - offset;
      float neg_7 = neg_8 - offset;
      float neg_6 = neg_7 - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [12];

      retval += tex2D (borderSampler, float2 (pos_b, xy.y)) * _pascal [11];
      retval += tex2D (borderSampler, float2 (pos_a, xy.y)) * _pascal [10];
      retval += tex2D (borderSampler, float2 (pos_9, xy.y)) * _pascal [9];
      retval += tex2D (borderSampler, float2 (pos_8, xy.y)) * _pascal [8];
      retval += tex2D (borderSampler, float2 (pos_7, xy.y)) * _pascal [7];
      retval += tex2D (borderSampler, float2 (pos_6, xy.y)) * _pascal [6];
      retval += tex2D (borderSampler, float2 (pos_5, xy.y)) * _pascal [5];
      retval += tex2D (borderSampler, float2 (pos_4, xy.y)) * _pascal [4];
      retval += tex2D (borderSampler, float2 (pos_3, xy.y)) * _pascal [3];
      retval += tex2D (borderSampler, float2 (pos_2, xy.y)) * _pascal [2];
      retval += tex2D (borderSampler, float2 (pos_1, xy.y)) * _pascal [1];
      retval += tex2D (borderSampler, float2 (pos_0, xy.y)) * _pascal [0];
      retval += tex2D (borderSampler, float2 (neg_b, xy.y)) * _pascal [11];
      retval += tex2D (borderSampler, float2 (neg_a, xy.y)) * _pascal [10];
      retval += tex2D (borderSampler, float2 (neg_9, xy.y)) * _pascal [9];
      retval += tex2D (borderSampler, float2 (neg_8, xy.y)) * _pascal [8];
      retval += tex2D (borderSampler, float2 (neg_7, xy.y)) * _pascal [7];
      retval += tex2D (borderSampler, float2 (neg_6, xy.y)) * _pascal [6];
      retval += tex2D (borderSampler, float2 (neg_5, xy.y)) * _pascal [5];
      retval += tex2D (borderSampler, float2 (neg_4, xy.y)) * _pascal [4];
      retval += tex2D (borderSampler, float2 (neg_3, xy.y)) * _pascal [3];
      retval += tex2D (borderSampler, float2 (neg_2, xy.y)) * _pascal [2];
      retval += tex2D (borderSampler, float2 (neg_1, xy.y)) * _pascal [1];
      retval += tex2D (borderSampler, float2 (neg_0, xy.y)) * _pascal [0];
   }

   return retval;
}

float4 feather_it (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (fthrSampler, xy);

   if ((Samount != 0.0) && (feather != 0.0)) {
      float offset = feather * F_SCALE * _OutputAspectRatio / _OutputWidth;

      float pos_b = xy.y  + offset;
      float pos_a = pos_b + offset;
      float pos_9 = pos_a + offset;
      float pos_8 = pos_9 + offset;
      float pos_7 = pos_8 + offset;
      float pos_6 = pos_7 + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_b = xy.y  - offset;
      float neg_a = neg_b - offset;
      float neg_9 = neg_a - offset;
      float neg_8 = neg_9 - offset;
      float neg_7 = neg_8 - offset;
      float neg_6 = neg_7 - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [12];

      retval += tex2D (fthrSampler, float2 (xy.x, pos_b)) * _pascal [11];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_a)) * _pascal [10];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_9)) * _pascal [9];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_8)) * _pascal [8];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_7)) * _pascal [7];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_6)) * _pascal [6];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_5)) * _pascal [5];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_4)) * _pascal [4];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_3)) * _pascal [3];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_2)) * _pascal [2];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_1)) * _pascal [1];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_0)) * _pascal [0];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_b)) * _pascal [11];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_a)) * _pascal [10];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_9)) * _pascal [9];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_8)) * _pascal [8];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_7)) * _pascal [7];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_6)) * _pascal [6];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_5)) * _pascal [5];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_4)) * _pascal [4];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_3)) * _pascal [3];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_2)) * _pascal [2];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_1)) * _pascal [1];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_0)) * _pascal [0];
   }

   float alpha = retval.a * Samount;

   retval = tex2D (borderSampler, xy);
   alpha  = max (alpha, retval.a);
   retval = lerp (Scolour, retval, retval.a);

   return float4 (retval.rgb, alpha);
}

float4 ps_normal (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_alpha (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (shadowSampler, xy);

   return float4 (retval.rgb, retval.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique normal
{
   pass P_1
   < string Script = "RenderColorTarget0 = brdrInp;"; >
   { PixelShader = compile PROFILE border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = aliased;"; >
   { PixelShader = compile PROFILE border_B (); }

   pass P_3
   < string Script = "RenderColorTarget0 = brdrOut;"; >
   { PixelShader = compile PROFILE border_C (); }

   pass P_4
   < string Script = "RenderColorTarget0 = fthr_in;"; >
   { PixelShader = compile PROFILE makeShadow (); }

   pass P_5
   < string Script = "RenderColorTarget0 = shadOut;"; >
   { PixelShader = compile PROFILE feather_it (); }

   pass P_6
   { PixelShader = compile PROFILE ps_normal (); }
}

technique alpha
{
   pass P_1
   < string Script = "RenderColorTarget0 = brdrInp;"; >
   { PixelShader = compile PROFILE border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = aliased;"; >
   { PixelShader = compile PROFILE border_B (); }

   pass P_3
   < string Script = "RenderColorTarget0 = brdrOut;"; >
   { PixelShader = compile PROFILE border_C (); }

   pass P_4
   < string Script = "RenderColorTarget0 = fthr_in;"; >
   { PixelShader = compile PROFILE makeShadow (); }

   pass P_5
   < string Script = "RenderColorTarget0 = shadOut;"; >
   { PixelShader = compile PROFILE feather_it (); }

   pass P_6
   { PixelShader = compile PROFILE ps_alpha (); }
}
