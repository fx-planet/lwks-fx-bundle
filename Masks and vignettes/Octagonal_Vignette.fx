// @Maintainer jwrl
// @Released 2018-07-07
// @Author jwrl
// @Created 2016-08-05
// @see https://www.lwks.com/media/kunena/attachments/6375/Octagonal_Vignette_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Octagonal_Vignette.fx
//
// Originally this started life as a test-bed for an octagonal crop effect, but has had
// other stuff thrown at it until we have what you see now.  It can be used as a simple
// mask or vignette, or because it preserves the alpha channel, can be used in other,
// more complex effect trees.
//
// Bug fix 2016-08-06 jwrl:
// X and Y position controls behaved unpredictably during effect rotation.  Fixed.
//
// Bug fix and enhancement 2016-08-17 jwrl:
// Boundary calculation added to stop diagonals showing during repositioning.  This has
// the added benefit of giving an extra four crop edges when scaling, allowing up to 12
// convex crops to be applied at once.  At this stage concave crops are not possible.
//
// LW 14+ modification 2017-02-11 jwrl:
// Category "Masks" is no longer defined in 14+, so category "DVEs" has been used with
// the subcategory "Crop Presets".
//
// Bug fix 2017-02-26 jwrl:
// Corrected for a bug in the way that Lightworks handles interlaced media.  When a height
// parameter is needed one can not reliably use _OutputHeight with interlaced media unless
// the media is in motion.  The output height is now obtained by dividing _OutputWidth by
// _OutputAspectRatio.  This fix has been fully tested, and appears reliable regardless of
// the pixel aspect ratio.
//
// Modification 2018-04-04 jwrl:
// Metadata header block added to better support GitHub repository.
//
// Modification 2018-07-07 jwrl:
// Made blur calculation resolution independent.  Bug fix 2017-02-26 no longer applies.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Octagonal vignette";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
   string Notes       = "Left/right/top/bottom and diagonal crops, each with rotation.  Border and drop shadow provided.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fgd>; };
sampler s_Background = sampler_state { Texture = <Bgd>; };

sampler s_Buffer_1 = sampler_state
{
   Texture   = <Buffer_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer_2 = sampler_state
{
   Texture   = <Buffer_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
> = 0;

bool Phase
<
   string Description = "Invert mask";
> = false;

float Border
<
   string Description = "Border";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.0;

float Feather
<
   string Description = "Feathering";
   float MinVal = 0.0;
   float MaxVal = 1.00;
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define ZOOM     5.0
#define AR_PLUS  4.0
#define AR_MINUS 0.9

#define BLACK    (0.0).xxxx
#define WHITE    (1.0).xxxx

#define LOOP     6
#define DIVIDE   49

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0

#define ANGLE    0.2617993878

#define LOOP_1   12
#define RADIUS   0.0125
#define ANGLE_1  0.1427996661
#define OFFSET  -0.0475998887

#define W_BLUR   0.0005

#define PI       3.1415926536

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD1) : COLOR
{
   float2 aspectL, aspectR, cropBR, cropTL, xy = uv - 0.5;

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

   return (any (diagL < 0.0) || any (cropTL < 0.0) || any (diagR > 0.0) || any (cropBR > 0.0)) ? BLACK : WHITE;
}

float4 ps_rotate_scale (float2 uv : TEXCOORD1) : COLOR
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

   float4 retval = (any (xy < 0.0) || any (xy > 1.0)) ? BLACK : tex2D (s_Buffer_1, xy);

   return float4 (Phase ? 1.0 - retval : retval);
}

float4 ps_border (float2 uv : TEXCOORD1) : COLOR
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

float4 ps_blur (float2 uv : TEXCOORD1, uniform sampler blurSampler, uniform float blurRadius) : COLOR
{
   float4 retval = tex2D (blurSampler, uv);

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * (Feather + 0.05) * blurRadius * W_BLUR;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (blurSampler, uv + xy);
      retval += tex2D (blurSampler, uv - xy);
      xy.y = -xy.y;
      retval += tex2D (blurSampler, uv + xy);
      retval += tex2D (blurSampler, uv - xy);
      xy += xy;
      retval += tex2D (blurSampler, uv + xy);
      retval += tex2D (blurSampler, uv - xy);
      xy.y = -xy.y;
      retval += tex2D (blurSampler, uv + xy);
      retval += tex2D (blurSampler, uv - xy);
   }

   return retval / DIVIDE;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 Mask = tex2D (s_Buffer_2, uv).xy;

   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = (Mode == 0) ? BLACK :
                 (Mode == 1) ? float4 (Colour.rgb, 0.0) :
                 tex2D (s_Background, uv);

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
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_mask (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_rotate_scale (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_border (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur (s_Buffer_1, RADIUS_1); }

   pass P_5
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_blur (s_Buffer_2, RADIUS_2); }

   pass P_6
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_blur (s_Buffer_1, RADIUS_3); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (); }
}
