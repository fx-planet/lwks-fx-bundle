// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Dx_Spin.fx written by LW user jwrl 15 February 2016.
// @Author jwrl
// @Created "15 February 2016"
//
// This effect performs a transition between two sources,
// During the process it also applies a rotational blur, the
// direction, aspect ratio, centring and strength of which can
// be adjusted.
//
// The blur section is based on a rotational blur converted by
// Lightworks user windsturm from original code created by
// rakusan - http://kuramo.ch/webgl/videoeffects/
//
// This cross-platform version by jwrl 4 May 2016.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Update August 10 2017 by jwrl - renamed from SpinDissolve.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Spin dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Fgnd : RenderColorTarget;
texture Bgnd : RenderColorTarget;

texture Spn1 : RenderColorTarget;
texture Spn2 : RenderColorTarget;
texture Spn3 : RenderColorTarget;
texture Spn4 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Fg>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture = <Bg>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgndSampler = sampler_state
{
   Texture   = <Fgnd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgndSampler = sampler_state
{
   Texture   = <Bgnd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn1Sampler = sampler_state
{
   Texture   = <Spn1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn2Sampler = sampler_state
{
   Texture   = <Spn2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn3Sampler = sampler_state
{
   Texture   = <Spn3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Spn4Sampler = sampler_state
{
   Texture   = <Spn4>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int CW_CCW
<
   string Group = "Spin";
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

float blurLen
<
   string Group = "Spin";
   string Description = "Arc (degrees)";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 90.0;

float aspectRatio
<
   string Group = "Spin";
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float centreX
<
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float centreY
<
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

#define RANGE_1    24
#define RANGE_2    48
#define RANGE_3    72
#define RANGE_4    96
#define RANGE_5    120

#define SAMPLES    120
#define INC_OFFSET 0.0083333     // 1.0 / SAMPLES
#define RETSCALE   60.5          // (SAMPLES + 1) / 2

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_FgBlur (float2 uv : TEXCOORD1, uniform int base) : COLOR
{
   int range = base + RANGE_1;

   float blurAngle, Tcos, Tsin, mixAmt = Amount;
   float spinAmt  = (radians (blurLen * saturate (mixAmt + 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect   = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY     = float2 (centreX, 1.0 - centreY);
   float2 angleXY, xy  = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (FgSampler, uv);
   float4 image  = retval;

   mixAmt  = saturate (mixAmt * 8.0);
   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * base;

   for (int i = base; i < range; i++) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (FgSampler, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   retval /= RETSCALE;

   if (base == RANGE_4) {
      retval += tex2D (Spn1Sampler, uv) + tex2D (Spn2Sampler, uv);
      retval += tex2D (Spn3Sampler, uv) + tex2D (Spn4Sampler, uv);

      retval = lerp (image, retval, mixAmt);
   }

   return retval;
}

float4 ps_BgBlur (float2 uv : TEXCOORD1, uniform int base) : COLOR
{
   int range = base - RANGE_1;

   float blurAngle, Tcos, Tsin, mixAmt = 1.0 - Amount;
   float spinAmt  = (radians (blurLen * saturate (mixAmt - 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect   = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY     = float2 (centreX, 1.0 - centreY);
   float2 angleXY, xy  = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (BgSampler, uv);
   float4 image  = retval;

   mixAmt = saturate (mixAmt * 8.0);
   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * (1 - base);

   for (int i = base; i > range; i--) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (BgSampler, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   retval /= RETSCALE;

   if (base == RANGE_1) {
      retval += tex2D (Spn1Sampler, uv) + tex2D (Spn2Sampler, uv);
      retval += tex2D (Spn3Sampler, uv) + tex2D (Spn4Sampler, uv);

      retval = lerp (image, retval, mixAmt);
   }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 outgoing = tex2D (FgndSampler, uv);
   float4 incoming = tex2D (BgndSampler, uv);

   float mixAmt = (Amount > 0.5) ? Amount - 1.0 : Amount;

   mixAmt *= 2.0;
   mixAmt = (mixAmt < 0.0) ? 1.0 - ((mixAmt * mixAmt) / 2.0) : (mixAmt * mixAmt) / 2.0;

   return lerp (outgoing, incoming, mixAmt);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SpinDiss
{
   pass P_1
   < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_FgBlur (0); }

   pass P_2
   < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_FgBlur (RANGE_1); }

   pass P_3
   < string Script = "RenderColorTarget0 = Spn3;"; >
   { PixelShader = compile PROFILE ps_FgBlur (RANGE_2); }

   pass P_4
   < string Script = "RenderColorTarget0 = Spn4;"; >
   { PixelShader = compile PROFILE ps_FgBlur (RANGE_3); }

   pass P_5
   < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_FgBlur (RANGE_4); }

   pass P_6
   < string Script = "RenderColorTarget0 = Spn1;"; >
   { PixelShader = compile PROFILE ps_BgBlur (RANGE_5); }

   pass P_7
   < string Script = "RenderColorTarget0 = Spn2;"; >
   { PixelShader = compile PROFILE ps_BgBlur (RANGE_4); }

   pass P_8
   < string Script = "RenderColorTarget0 = Spn3;"; >
   { PixelShader = compile PROFILE ps_BgBlur (RANGE_3); }

   pass P_9
   < string Script = "RenderColorTarget0 = Spn4;"; >
   { PixelShader = compile PROFILE ps_BgBlur (RANGE_2); }

   pass P_a
   < string Script = "RenderColorTarget0 = Bgnd;"; >
   { PixelShader = compile PROFILE ps_BgBlur (RANGE_1); }

   pass P_b
   { PixelShader = compile PROFILE ps_main (); }
}

