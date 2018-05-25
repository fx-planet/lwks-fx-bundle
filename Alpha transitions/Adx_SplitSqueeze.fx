// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2017-10-26
// @see https://www.lwks.com/media/kunena/attachments/6375/Adx_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaSplitSqz.mp4
//-----------------------------------------------------------------------------------------//
// User effect Adx_SplitSqueeze.fx
//
// This is similar to the split squeeze effect, customised to suit its use with alpha
// channels.  It moves the separated alpha image halves apart and squeezes them to the
// edge of screen or expands the halves from the edges.  It operates either vertically
// or horizontally depending on the user setting.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
// The boost technique uses gamma to adjust the alpha levels which visually matches the
// way that Lightworks handles titles quite closely.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha split squeeze";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp_1;
texture Inp_2;
texture Inp_3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler In1Sampler = sampler_state
{
   Texture = <Inp_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In2Sampler = sampler_state
{
   Texture = <Inp_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler In3Sampler = sampler_state { Texture = <Inp_3>; };

sampler Fg1Sampler = sampler_state
{
   Texture   = <In_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Fg2Sampler = sampler_state
{
   Texture   = <In_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state { Texture = <Bgd>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetMode
<
   string Description = "Transition type";
   string Enum = "Squeeze/expand horizontal,Squeeze/expand vertical";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

int SetTechnique
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Transition";
   string Enum = "Wipe in,Wipe out,Wipe FX1 > FX2,Wipe FX2 > FX1";
> = 0;

bool Boost_On
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Enable alpha boost";
> = false;

float Boost_O
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost outgoing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Boost_I
<
   string Group = "Boost alpha (key) strength - needed for Lightworks title effects";
   string Description = "Boost incoming";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HORIZ 0

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_inp_1 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In1Sampler, uv);
}

float4 ps_inp_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In2Sampler, uv);
}

float4 ps_inp_3 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (In3Sampler, uv);
}

float4 ps_fg_2 (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (Fg2Sampler, uv);
}

float4 ps_wipe_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd;
   float2 xy1, xy2;

   float altAmt = Amount - 1.0;
   float negAmt = Amount * 0.5;
   float posAmt = 1.0 - negAmt;

   if (SetMode == HORIZ) {
      xy1 = float2 ((uv.x + altAmt) / Amount, uv.y);
      xy2 = float2 (uv.x / Amount, uv.y);
      Fgd = (uv.x > posAmt) ? tex2D (Fg1Sampler, xy1)
          : (uv.x < negAmt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }
   else {
      xy1 = float2 (uv.x, (uv.y + altAmt) / Amount);
      xy2 = float2 (uv.x, uv.y / Amount);
      Fgd = (uv.y > posAmt) ? tex2D (Fg1Sampler, xy1)
          : (uv.y < negAmt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

float4 ps_wipe_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd;
   float2 xy1, xy2;

   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) * 0.5;

   if (SetMode == HORIZ) {
      xy1 = float2 ((uv.x - Amount) / negAmt, uv.y);
      xy2 = float2 (uv.x / negAmt, uv.y);
      negAmt /= 2.0;
      Fgd = (uv.x > posAmt) ? tex2D (Fg1Sampler, xy1)
          : (uv.x < negAmt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }
   else {
      xy1 = float2 (uv.x, (uv.y - Amount) / negAmt);
      xy2 = float2 (uv.x, uv.y / negAmt);
      negAmt /= 2.0;
      Fgd = (uv.y > posAmt) ? tex2D (Fg1Sampler, xy1)
          : (uv.y < negAmt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique wipeIn
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_wipe_in (); }
}

technique wipeOut
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_wipe_out (); }
}

technique wipe_FX1_FX2
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_wipe_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_wipe_in (); }
}

technique wipe_FX2_FX1
{
   pass P_1
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_2 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_inp_3 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = In_2;"; >
   { PixelShader = compile PROFILE ps_wipe_out (); }

   pass P_4
   < string Script = "RenderColorTarget0 = In_1;"; >
   { PixelShader = compile PROFILE ps_inp_1 (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_fg_2 (); }

   pass P_6
   { PixelShader = compile PROFILE ps_wipe_in (); }
}
