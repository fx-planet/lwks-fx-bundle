// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Dx_Granular.fx was created by Lightworks user jwrl to
// provide a granular noise driven dissolve, February 8 2016.
// It is fully cross-platform compatible.  This version to
// fix a transition linearity issued February 10 2016.
//
// The noise component is based on work by users khaver and
// windsturm.  The radial gradient generator is from an
// effect created by Editshare.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  When a height parameter is needed one
// cannot use _OutputHeight because it returns only half the
// actual frame height when interlaced media is playing.  In
// this effect the output height is obtained by dividing
// _OutputWidth by _OutputAspectRatio.  This is reliable
// regardless of the pixel aspect ratio or interlace mode.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Update August 10 2017 by jwrl - renamed from Gran_mix.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture Buffer_0 : RenderColorTarget;
texture Buffer_1 : RenderColorTarget;
texture Buffer_2 : RenderColorTarget;
texture Buffer_3 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler Outgo_S = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Incom_S = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_0_S = sampler_state
{
   Texture   = <Buffer_0>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_1_S = sampler_state
{
   Texture   = <Buffer_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_2_S = sampler_state
{
   Texture   = <Buffer_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Buffer_3_S = sampler_state
{
   Texture   = <Buffer_3>;
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

float gWidth
<
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool TransDir
<
   string Description = "Invert transition direction";
> = false;

float pSize
<
   string Group       = "Particles";
   string Description = "Size";
   float MinVal = 1.00;
   float MaxVal = 10.0;
> = 5.5;

float pSoftness
<
   string Group       = "Particles";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group       = "Particles";
   string Description = "Type";
   string Enum = "Top to bottom,Left to right,Radial,No gradient";
> = 0;

bool TransVar
<
   string Group       = "Particles";
   string Description = "Static particle pattern";
> = false;

bool Sparkles
<
   string Group       = "Particles";
   string Description = "Sparkle";
> = false;

float4 starColour
<
   string Group       = "Particles";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.9, 0.75, 0.0, 1.0 };

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_vert_grad (float2 xy : TEXCOORD1) : COLOR
{
   float retval = lerp (0.0, 1.0, xy.y);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_horiz_grad (float2 xy : TEXCOORD1) : COLOR
{
   float retval = lerp (0.0, 1.0, xy.x);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_radial_grad (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float progress = abs (distance (xy1, float2 (0.5, 0.5))) * 1.414;
   float4 pixel = tex2D (Outgo_S, xy2);

   float colOneAmt = 1.0 - progress;
   float colTwoAmt = progress;

   float retval = (lerp (pixel, 0.0, 1.0) * colOneAmt) +
                  (lerp (pixel, 1.0, 1.0) * colTwoAmt) +
                  (pixel * (1.0 - (colOneAmt + colTwoAmt)));

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

float4 ps_noise (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = (0.0).xxxx;

   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;

   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000.0;

   return saturate (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0).xxxx;
}

float4 ps_soft_1 (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval   = tex2D (Buffer_1_S, xy);

   float2 offset_X1 = float2 (pSoftness / _OutputWidth, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (Buffer_1_S, xy + offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, xy - offset_X1) * BLUR_1;
   retval += tex2D (Buffer_1_S, xy + offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, xy - offset_X2) * BLUR_2;
   retval += tex2D (Buffer_1_S, xy + offset_X3) * BLUR_3;
   retval += tex2D (Buffer_1_S, xy - offset_X3) * BLUR_3;

   return retval;
}

float4 ps_soft_2 (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval   = tex2D (Buffer_2_S, xy);

   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio / _OutputWidth);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (Buffer_2_S, xy + offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, xy - offset_Y1) * BLUR_1;
   retval += tex2D (Buffer_2_S, xy + offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, xy - offset_Y2) * BLUR_2;
   retval += tex2D (Buffer_2_S, xy + offset_Y3) * BLUR_3;
   retval += tex2D (Buffer_2_S, xy - offset_Y3) * BLUR_3;

   return retval;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd  = tex2D (Outgo_S, xy1);
   float4 Bgnd  = tex2D (Incom_S, xy2);

   float4 grad  = tex2D (Buffer_0_S, xy1);
   float4 noise = tex2D (Buffer_3_S, ((xy1 - 0.5) / pSize) + 0.5);

   float level  = saturate (((0.5 - grad.x) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3) * 4) + level);

   return lerp (retval, starColour, stars);
}

float4 ps_flat (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd  = tex2D (Outgo_S, xy1);
   float4 Bgnd  = tex2D (Incom_S, xy2);

   float4 noise = tex2D (Buffer_3_S, ((xy1 - 0.5) / pSize) + 0.5);

   float level  = saturate (((Amount - 0.5) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3) * 4) + level);

   return lerp (retval, starColour, stars);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique TopToBottom
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE ps_vert_grad (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_soft_1 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE ps_soft_2 (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique LeftToRight
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE ps_horiz_grad (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_soft_1 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE ps_soft_2 (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique Radial
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_0;"; >
   { PixelShader = compile PROFILE ps_radial_grad (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_soft_1 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE ps_soft_2 (); }

   pass P_5
   { PixelShader = compile PROFILE ps_main (); }
}

technique Flat
{
   pass P_1
   < string Script = "RenderColorTarget0 = Buffer_1;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Buffer_2;"; >
   { PixelShader = compile PROFILE ps_soft_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Buffer_3;"; >
   { PixelShader = compile PROFILE ps_soft_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_flat (); }
}

