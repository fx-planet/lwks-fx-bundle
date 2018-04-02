// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Cx_Pinch.fx
// Created by LW user jwrl 8 September 2017.
// @Author jwrl
// @CreationDate "8 September 2017"
//
// This effect pinches the outgoing video to a user-defined
// point to reveal the incoming shot.  It can also reverse the
// process to bring in the incoming video.  It's the triple
// layer version of Wx_Pinch.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Composite Pinch";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture V1;
texture V2;
texture V3;

texture Fg : RenderColorTarget;
texture Bg : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler V1sampler = sampler_state
{
   Texture   = <V1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V3sampler = sampler_state
{
   Texture   = <V3>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgdSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler V2sampler = sampler_state
{
   Texture   = <V2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool Swapped
<
   string Description = "Make V3 and not V1 the outgoing image";
> = false;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float centreX
<
   string Description = "End point";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Description = "End point";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define EMPTY   (0.0).xxxx

#define HALF_PI 1.5707963

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_swap_V1 (float2 uv : TEXCOORD1) : COLOR
{
   if (Swapped) return tex2D (V3sampler, uv);

   float4 retval = tex2D (V1sampler, uv);

   retval.a = max (retval.a, tex2D (V2sampler, uv).a);

   return retval;
}

float4 ps_swap_V3 (float2 uv : TEXCOORD1) : COLOR
{
   if (!Swapped) return tex2D (V3sampler, uv);

   float4 retval = tex2D (V1sampler, uv);

   retval.a = max (retval.a, tex2D (V2sampler, uv).a);

   return retval;
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -sin (Amount * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 outgoing = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);

   return lerp (tex2D (BgdSampler, uv), outgoing, outgoing.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy = (uv - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -cos ((Amount + 0.01) * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 incoming = fn_illegal (xy) ? EMPTY : tex2D (BgdSampler, xy);

   return lerp (tex2D (FgdSampler, uv), incoming, incoming.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Pinch_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_swap_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_swap_V3 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Pinch_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fg;"; >
   { PixelShader = compile PROFILE ps_swap_V1 (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Bg;"; >
   { PixelShader = compile PROFILE ps_swap_V3 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_2 (); }
}

