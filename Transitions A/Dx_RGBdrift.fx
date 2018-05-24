// @Maintainer jwrl
// @Released 2018-04-14
// @Author jwrl
// @Created 2018-04-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_RGBdrifter.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_RGBdrift.fx
//
// This transitions between the two images using different curves for each of red, green
// and blue.  One colour and alpha is always linear, and the other two can be set using
// the colour profile selection.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB drifter";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Outgoing = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Incoming = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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
   string Description = "Select colour profile";
   string Enum = "Red to blue,Blue to red,Red to green,Green to red,Green to blue,Blue to green"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define CURVE   4.0

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_R_B (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

float4 ps_main_B_R (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ga = lerp (vidOut.ga, vidIn.ga, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

float4 ps_main_R_G (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_R = pow (1.0 - Amount, CURVE);
   float amt_G = pow (Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidIn.r, vidOut.r, amt_R);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);

   return retval;
}

float4 ps_main_G_R (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_R = pow (Amount, CURVE);
   float amt_G = pow (1.0 - Amount, CURVE);

   retval.ba = lerp (vidOut.ba, vidIn.ba, Amount);
   retval.r  = lerp (vidOut.r, vidIn.r, amt_R);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);

   return retval;
}

float4 ps_main_G_B (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_G = pow (1.0 - Amount, CURVE);
   float amt_B = pow (Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidIn.g, vidOut.g, amt_G);
   retval.b  = lerp (vidOut.b, vidIn.b, amt_B);

   return retval;
}

float4 ps_main_B_G (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 vidOut = tex2D (s_Outgoing, xy1);
   float4 vidIn  = tex2D (s_Incoming, xy2);
   float4 retval;

   float amt_G = pow (Amount, CURVE);
   float amt_B = pow (1.0 - Amount, CURVE);

   retval.ra = lerp (vidOut.ra, vidIn.ra, Amount);
   retval.g  = lerp (vidOut.g, vidIn.g, amt_G);
   retval.b  = lerp (vidIn.b, vidOut.b, amt_B);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBdrifter_R_B
{
   pass P_1 { PixelShader = compile PROFILE ps_main_R_B (); }
}

technique RGBdrifter_B_R
{
   pass P_1 { PixelShader = compile PROFILE ps_main_B_R (); }
}

technique RGBdrifter_R_G
{
   pass P_1 { PixelShader = compile PROFILE ps_main_R_G (); }
}

technique RGBdrifter_G_R
{
   pass P_1 { PixelShader = compile PROFILE ps_main_G_R (); }
}

technique RGBdrifter_G_B
{
   pass P_1 { PixelShader = compile PROFILE ps_main_G_B (); }
}

technique RGBdrifter_B_G
{
   pass P_1 { PixelShader = compile PROFILE ps_main_B_G (); }
}

