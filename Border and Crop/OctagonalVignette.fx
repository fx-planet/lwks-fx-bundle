// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/Octagonal_Vignette_640.png

/**
 Originally this started life as a test-bed for an octagonal crop effect, but subsequently
 ongoing development brought it to what we have now.  It can be used as a simple mask or
 vignette, or since it preserves the alpha channel, can be used in more complex effect
 structures.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OctagonalVignette.fx
//
// Version history:
//
// Rewrite 2021-08-31 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Octagonal vignette";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "Left/right/top/bottom and diagonal crops, each with rotation.  Border and drop shadow provided.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

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
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define ZOOM      5.0
#define AR_PLUS   4.0
#define AR_MINUS  0.9

#define WHITE      1.0.xxxx

#define LOOP       6
#define DIVIDE     49

#define RADIUS_1   4.0
#define RADIUS_2   10.0
#define RADIUS_3   20.0

#define ANGLE      0.2617993878

#define LOOP_1     12
#define RADIUS     0.0125
#define ANGLE_1    0.1427996661
#define OFFSET    -0.0475998887

#define W_BLUR     0.0005

#define PI         3.1415926536

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fgd, s_RawFg);
DefineInput (Bgd, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Buffer_1, s_Buffer_1);
DefineTarget (Buffer_2, s_Buffer_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropT
<
   string Group = "Square crop";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngT
<
   string Group = "Square crop";
   string Description = "Top angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Group = "Square crop";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngB
<
   string Group = "Square crop";
   string Description = "Bottom angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropL
<
   string Group = "Square crop";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngL
<
   string Group = "Square crop";
   string Description = "Left angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Group = "Square crop";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float AngR
<
   string Group = "Square crop";
   string Description = "Right angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTL
<
   string Group = "Diagonal crop";
   string Description = "Upper left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngTL
<
   string Group = "Diagonal crop";
   string Description = "UL angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTR
<
   string Group = "Diagonal crop";
   string Description = "Upper right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngTR
<
   string Group = "Diagonal crop";
   string Description = "UR angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropBL
<
   string Group = "Diagonal crop";
   string Description = "Lower left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngBL
<
   string Group = "Diagonal crop";
   string Description = "LL angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CropBR
<
   string Group = "Diagonal crop";
   string Description = "Lower right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float AngBR
<
   string Group = "Diagonal crop";
   string Description = "LR angle";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int Mode
<
   string Description = "Background";
   string Enum = "Black,Colour,Video";
> = 2;

bool Phase
<
   string Description = "Invert mask";
> = false;

float Border
<
   string Description = "Border";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Feather
<
   string Description = "Feathering";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Rotate
<
   string Description = "Rotation";
   float MinVal = -180;
   float MaxVal = 180;
> = 0.0;

float OffsX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsZ
<
   string Description = "Position";
   string Flags = "SpecifiesPointZ";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Border/background";
> = { 0.2, 0.1, 1.0, 0.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the foreground and background clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_mask (float2 uv : TEXCOORD0) : COLOR
{
   float2 aspectL, aspectR, cropBR, cropTL, xy = uv - 0.5.xx;

   cropBR.x = uv.x - CropR + (xy.y * AngR / _OutputAspectRatio);
   cropBR.y = uv.y - CropB + (xy.x * AngB * _OutputAspectRatio);
   cropTL.x = uv.x - CropL - (xy.y * AngL / _OutputAspectRatio);
   cropTL.y = uv.y - CropT - (xy.x * AngT * _OutputAspectRatio);

   aspectL.x = (AngTL < 0.0) ? AngTL * AR_MINUS : AngTL * AR_PLUS;
   aspectL.y = (AngBL < 0.0) ? AngBL * AR_MINUS : AngBL * AR_PLUS;
   aspectR.x = (AngTR < 0.0) ? AngTR * AR_MINUS : AngTR * AR_PLUS;
   aspectR.y = (AngBR < 0.0) ? AngBR * AR_MINUS : AngBR * AR_PLUS;

   aspectL++;
   aspectR++;

   aspectL *= _OutputAspectRatio;
   aspectR *= _OutputAspectRatio;

   float2 diagL = (aspectL * uv.x) + float2 (uv.y, 1.0 - uv.y);
   float2 diagR = (aspectR * uv.x) + float2 (1.0 - uv.y, uv.y);

   aspectL++;
   aspectR++;

   diagL -= float2 (CropTL, CropBL) * aspectL;
   diagR -= (1.0 - float2 (CropTR, CropBR)) * aspectR;

   return (any (diagL < 0.0) || any (cropTL < 0.0) || any (diagR > 0.0) || any (cropBR > 0.0)) ? EMPTY : WHITE;
}

float4 ps_rotate_scale (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy = uv - float2 (OffsX, 1.0 - OffsY);

   float O = xy.x * _OutputAspectRatio;
   float A = xy.y;
   float H = sqrt ((O * O) + (A * A));

   if ((Rotate != 0.0) && (H != 0.0)) {
      float angBas = (A > 0.0) ? asin (O / H) : PI + asin (-O / H);

      angBas += radians (Rotate);
      sincos (angBas, O, A);

      xy = float2 (O / _OutputAspectRatio, A) * H;
   }

   float Scale = (OffsZ > 0.0) ? 1.0 / (1.0 + (ZOOM * OffsZ)) : 1.0 - (ZOOM * OffsZ);

   xy = (xy * Scale) + 0.5;

   float4 retval = GetPixel (s_Buffer_1, xy);

   return float4 (Phase ? 1.0 - retval : retval);
}

float4 ps_border (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Buffer_2, uv);

   if (Border > 0.0) {
      float angle = OFFSET;
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Border * RADIUS;

      for (int i = 0; i < LOOP_1; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval.r = max (retval.r, tex2D (s_Buffer_2, uv + xy).r);
         retval.r = max (retval.r, tex2D (s_Buffer_2, uv - xy).r);
         xy.y = -xy.y;
         retval.r = max (retval.r, tex2D (s_Buffer_2, uv + xy).r);
         retval.r = max (retval.r, tex2D (s_Buffer_2, uv - xy).r);
         angle += ANGLE_1;
      }
   }

   return retval;
}

float4 ps_blur (float2 uv : TEXCOORD3, uniform sampler s_blur, uniform float blurAmt) : COLOR
{
   float4 retval = tex2D (s_blur, uv);

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * (Feather + 0.05) * blurAmt * W_BLUR;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (s_blur, uv + xy);
      retval += tex2D (s_blur, uv - xy);
      xy.y = -xy.y;
      retval += tex2D (s_blur, uv + xy);
      retval += tex2D (s_blur, uv - xy);
      xy += xy;
      retval += tex2D (s_blur, uv + xy);
      retval += tex2D (s_blur, uv - xy);
      xy.y = -xy.y;
      retval += tex2D (s_blur, uv + xy);
      retval += tex2D (s_blur, uv - xy);
   }

   return retval / DIVIDE;
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 Mask = GetPixel (s_Buffer_2, uv).xy;

   float4 Fgnd = GetPixel (s_Foreground, uv);
   float4 Bgnd = (Mode == 0) ? EMPTY :
                 (Mode == 1) ? float4 (Colour.rgb, 0.0) :
                 GetPixel (s_Background, uv);

   if (Border > 0.0) {
      Mask.x *= saturate (Border * 20.0);
      Bgnd = lerp (Bgnd, Colour, Mask.x);
      Bgnd.a = max (Bgnd.a, Mask.x);
   }

   return lerp (Bgnd, Fgnd, Mask.y);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique OctagonalVignette
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_1 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_mask)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_rotate_scale)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_border)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_2;"; > Execute2param (ps_blur, s_Buffer_1, RADIUS_1)
   pass P_5 < string Script = "RenderColorTarget0 = Buffer_1;"; > Execute2param (ps_blur, s_Buffer_2, RADIUS_2)
   pass P_6 < string Script = "RenderColorTarget0 = Buffer_2;"; > Execute2param (ps_blur, s_Buffer_1, RADIUS_3)
   pass P_7 ExecuteShader (ps_main)
}

