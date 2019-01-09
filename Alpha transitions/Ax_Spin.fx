// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Spin.fx
//
// The effect applies a rotary blur to transition into or out of a title or between titles
// and is based on original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).
// The direction, aspect ratio, centring and strength of the blur can all be adjusted.
// It then composites the result over the background layer.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Spin.fx, which also had the ability to
// dissolve between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha spin dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Dissolves the title through a blurred spin";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Proc : RenderColorTarget;
texture Fgnd : RenderColorTarget;
texture Spin : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Overlay = sampler_state { Texture = <Sup>; };
sampler s_Video   = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Proc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Foreground = sampler_state {
   Texture   = <Fgnd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Spin = sampler_state {
   Texture   = <Spin>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
> = 0;

int CW_CCW
<
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

float blurAmount
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
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float centreY
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI   1.5707963268

#define REDUCE    0.009375

#define CCW       0
#define CW        1

float _OutputAspectRatio;

float blur_idx []  = { 0, 20, 40, 60, 80 };
float redux_idx [] = { 1.0, 0.8125, 0.625, 0.4375, 0.25 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fixAlpha (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Overlay, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_spinBlur_in (float2 uv : TEXCOORD1, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - sin (Amount * HALF_PI)) * blurAmount;

   if (blurLen == 0.0) return tex2D (s_Super, uv);

   float4 retval = (0.0).xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blurAspect = float2 (1.0, aspectRatio);
   float2 centre = float2 (centreX, 1.0 - centreY );
   float2 xy1, xy2 = (uv - centre) / outputAspect / blurAspect;

   float reduction = redux_idx [passNum];
   float amount = radians (blurLen) / 100.0;

   if (CW_CCW == CCW) amount = -amount;

   float Tcos, Tsin, ang = amount * blur_idx [passNum];

   for (int i = 0; i < 20; i++) {
      sincos (ang, Tsin, Tcos);
      xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                             (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
      retval = max (retval, (tex2D (s_Super, xy1) * reduction));
      reduction -= REDUCE;
      ang += amount;
   }

   if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Foreground, uv)); }
   else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv));

   return retval;
}

float4 ps_spinBlur_out (float2 uv : TEXCOORD1, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - cos (Amount * HALF_PI)) * blurAmount;

   if (blurLen == 0.0) return tex2D (s_Super, uv);

   float4 retval = (0.0).xxxx;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blurAspect = float2 (1.0, aspectRatio);
   float2 centre = float2 (centreX, 1.0 - centreY );
   float2 xy1, xy2 = (uv - centre) / outputAspect / blurAspect;

   float reduction = redux_idx [passNum];
   float amount = radians (blurLen) / 100.0;

   if (CW_CCW == CW) amount = -amount;

   float Tcos, Tsin, ang = amount * blur_idx [passNum];

   for (int i = 0; i < 20; i++) {
      sincos (ang, Tsin, Tcos);
      xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                             (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
      retval = max (retval, (tex2D (s_Super, xy1) * reduction));
      reduction -= REDUCE;
      ang += amount;
   }

   if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Foreground, uv)); }
   else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv));

   return retval;
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Spin_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Proc;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_in (0); }

   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_spinBlur_in (1); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_in (2); }

   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_spinBlur_in (3); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_in (4); }

   pass P_7
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Spin_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Proc;"; >
   { PixelShader = compile PROFILE ps_fixAlpha (); }

   pass P_2 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_out (0); }

   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_spinBlur_out (1); }

   pass P_4 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_out (2); }

   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; >
   { PixelShader = compile PROFILE ps_spinBlur_out (3); }

   pass P_6 < string Script = "RenderColorTarget0 = Fgnd;"; >
   { PixelShader = compile PROFILE ps_spinBlur_out (4); }

   pass P_7
   { PixelShader = compile PROFILE ps_main_out (); }
}

