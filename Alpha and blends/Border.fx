// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Border Effect by rhinox202
// First Attempt - 11/21/2012
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which may have caused
// the effect not to behave as needed on Linux and Mac systems.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//
float4 BorderC
<
   string Description = "Color";
> = { 1.0, 1.0, 1.0, 0.0 };

float BorderM
<
   string Description = "Master";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 1.0;

float BorderT
<
   string Description = "Top";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderR
<
   string Description = "Right";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderB
<
   string Description = "Bottom";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float BorderL
<
   string Description = "Left";
   float MinVal = 0.00;
   float MaxVal = 5.0;
> = 0.5;

float _OutputAspectRatio; //The project aspect ratio

texture Input;

sampler2D TextureSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Code
//--------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1) : COLOR
{
   float4 ret = tex2D (TextureSampler, xy1);
   
   float Border_T = BorderM * BorderT / 10.0;
   float Border_R = 1.0 - (BorderM * BorderR / (_OutputAspectRatio * 10.0));
   float Border_B = 1.0 - (BorderM * BorderB / 10.0);
   float Border_L = BorderM * BorderL / (_OutputAspectRatio * 10.0);
   
   if ((xy1.y <= Border_T) || (xy1.x >= Border_R) || (xy1.y >=  Border_B) || (xy1.x <= Border_L))
   {
      return float4 (BorderC.rgb, 0.0);
   }
   
   return ret;
}

//--------------------------------------------------------------//
// Technique Section for Image Processing Effects
//--------------------------------------------------------------//
technique Border { pass Single_Pass { PixelShader = compile PROFILE ps_main (); } }
