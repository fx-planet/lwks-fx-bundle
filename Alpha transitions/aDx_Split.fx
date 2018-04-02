// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// User effect aDx_Split.fx
// Created by jwrl 26 October 2017.
// @Author: jwrl
// @CreationDate: "26 October 2017"
//
// This is really the classic barn door effect, but since a
// wipe with that name already exists in Lightworks another
// name had to be found.  This version has also been altered
// to support alpha channels.  It moves the separated image
// halves apart.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha split";
   string Category    = "Mix";
   string SubCategory = "Alpha";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp_1;
texture Inp_2;
texture Inp_3;

texture In_1 : RenderColorTarget;
texture In_2 : RenderColorTarget;

texture Bgd : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define HORIZ 0

#define EMPTY (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetMode
<
   string Description = "Transition type";
   string Enum = "Horizontal split,Vertical split";
> = HORIZ;

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

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

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

   float Amt = Amount * 0.5;
   float amt = Amt - 0.5;
   float AMT = 1.0 - Amt;

   if (SetMode == HORIZ) {
      xy1 = float2 (uv.x + amt, uv.y);
      xy2 = float2 (uv.x - amt, uv.y);
      Fgd = (uv.x > AMT) ? tex2D (Fg1Sampler, xy1)
          : (uv.x < Amt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }
   else {
      xy1 = float2 (uv.x, uv.y + amt);
      xy2 = float2 (uv.x, uv.y - amt);
      Fgd = (uv.y > AMT) ? tex2D (Fg1Sampler, xy1)
          : (uv.y < Amt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_I + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

float4 ps_wipe_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd;

   float2 xy1, xy2;;

   float amt = Amount * 0.5;
   float Amt = 0.5 - amt;
   float AMT = 0.5 + amt;

   if (SetMode == HORIZ) {
      xy1 = float2 (uv.x - amt, uv.y);
      xy2 = float2 (uv.x + amt, uv.y);
      Fgd = (uv.x > AMT) ? tex2D (Fg1Sampler, xy1)
          : (uv.x < Amt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }
   else {
      xy1 = float2 (uv.x, uv.y - amt);
      xy2 = float2 (uv.x, uv.y + amt);
      Fgd = (uv.y > AMT) ? tex2D (Fg1Sampler, xy1)
          : (uv.y < Amt) ? tex2D (Fg1Sampler, xy2) : EMPTY;
   }

   if (Boost_On) Fgd.a = pow (Fgd.a, 1.0 / max (1.0, Boost_O + 1.0));

   return lerp (tex2D (BgdSampler, uv), Fgd, Fgd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

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

