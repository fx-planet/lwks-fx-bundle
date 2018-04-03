// @Maintainer jwrl
// @Released 2018-03-31
// @Author baopao
//--------------------------------------------------------------//
// CC_RGBCMY - a colorgrade tool based on individual red, green,
// blue, cyan, magentan and yellow parameters.  This is a
// "Color_NOT_Channel" correction based filter created for Mac
// and Linux systems by user baopao.  Feedback should be to
// http://www.alessandrodallafontana.com/ 
//
// Cross platform compatibility check 31 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.  In the process
// the original version has been rewritten to make it more
// modular and to provide Windows support.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "CC_RGBCMY";
   string Category    = "Colour";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture RGBout : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler   = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler rgbSampler = sampler_state
{
   Texture   = <RGBout>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

// RED_P

float4 R_TintColour
<
   string Description = "TintColour";
   string Group = "RED";
> = { 1.0, 1.0, 1.0, 1.0 };

float R_TintAmount
<
   string Description = "TintAmount";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float R_Saturate
<
   string Description = "Saturate";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float R_Gamma
<
   string Description = "Gamma";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Contrast
<
   string Description = "Contrast";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Gain
<
   string Description = "Gain";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Brightness
<
   string Description = "Brightness";
   string Group = "RED";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// GREEN_P

float4 G_TintColour
<
   string Description = "TintColour";
   string Group = "GREEN";
> = { 1.0, 1.0, 1.0, 1.0 };

float G_TintAmount
<
   string Description = "TintAmount";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float G_Saturate
<
   string Description = "Saturate";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float G_Gamma
<
   string Description = "Gamma";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Contrast
<
   string Description = "Contrast";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Gain
<
   string Description = "Gain";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Brightness
<
   string Description = "Brightness";
   string Group = "GREEN";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// BLUE_P

float4 B_TintColour
<
   string Description = "TintColour";
   string Group = "BLUE";
> = { 1.0, 1.0, 1.0, 1.0 };

float B_TintAmount
<
   string Description = "TintAmount";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float B_Saturate
<
   string Description = "Saturate";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float B_Gamma
<
   string Description = "Gamma";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Contrast
<
   string Description = "Contrast";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Gain
<
   string Description = "Gain";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Brightness
<
   string Description = "Brightness";
   string Group = "BLUE";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// CYAN_P

float4 C_TintColour
<
   string Description = "TintColour";
   string Group = "CYAN";
> = { 1.0, 1.0, 1.0, 1.0 };

float C_TintAmount
<
   string Description = "TintAmount";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float C_Saturate
<
   string Description = "Saturate";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float C_Gamma
<
   string Description = "Gamma";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Contrast
<
   string Description = "Contrast";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Gain
<
   string Description = "Gain";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Brightness
<
   string Description = "Brightness";
   string Group = "CYAN";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// MAGENTA_P

float4 M_TintColour
<
   string Description = "TintColour";
   string Group = "MAGENTA";
> = { 1.0, 1.0, 1.0, 1.0 };

float M_TintAmount
<
   string Description = "TintAmount";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float M_Saturate
<
   string Description = "Saturate";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float M_Gamma
<
   string Description = "Gamma";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Contrast
<
   string Description = "Contrast";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Gain
<
   string Description = "Gain";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Brightness
<
   string Description = "Brightness";
   string Group = "MAGENTA";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// YELLOW_P

float4 Y_TintColour
<
   string Description = "TintColour";
   string Group = "YELLOW";
> = { 1.0, 1.0, 1.0, 1.0 };

float Y_TintAmount
<
   string Description = "TintAmount";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Y_Saturate
<
   string Description = "Saturate";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Y_Gamma
<
   string Description = "Gamma";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Contrast
<
   string Description = "Contrast";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Gain
<
   string Description = "Gain";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Brightness
<
   string Description = "Brightness";
   string Group = "YELLOW";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_RGB (float2 xy : TEXCOORD1) : COLOR
{
   float3 Fix_CC, RGBsCx;
   float3 RGBs = tex2D (FgSampler, xy).rgb;

   float lum   = dot (RGBs, float3 (0.3, 0.59, 0.11));
   float red   = RGBs.r - max (RGBs.g, RGBs.b);
   float green = RGBs.g - max (RGBs.b, RGBs.r);
   float blue  = RGBs.b - max (RGBs.r, RGBs.g);
   float Ydiff = lum - 0.5;

// RED

   Fix_CC = R_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, R_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * R_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / R_Gamma) * R_Gain) + R_Brightness.xxx - 0.5.xxx) * R_Contrast) + 0.5.xxx;

   RGBsCx = lerp (RGBs, Fix_CC, saturate (red - max (green, blue)));

// GREEN

   Fix_CC = G_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, G_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * G_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / G_Gamma) * G_Gain) + G_Brightness.xxx - 0.5.xxx) * G_Contrast) + 0.5.xxx;

   RGBsCx = lerp (RGBsCx, Fix_CC, saturate (green - max (red, blue)));

// BLUE

   Fix_CC = B_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, B_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * B_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / B_Gamma) * B_Gain) + B_Brightness.xxx - 0.5.xxx) * B_Contrast) + 0.5.xxx;

   return float4 (lerp (RGBsCx, Fix_CC, saturate (blue - max (green, red))), 1.0);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float3 RGBs   = tex2D (FgSampler, xy).rgb;
   float3 RGBsCx = tex2D (rgbSampler, xy).rgb;
   float3 Fix_CC = 1.0.xxx - RGBs;

   float lum     = dot (RGBs, float3 (0.3, 0.59, 0.11));
   float cyan    = Fix_CC.r - max (Fix_CC.g, Fix_CC.b);
   float magenta = Fix_CC.g - max (Fix_CC.b, Fix_CC.r);
   float yellow  = Fix_CC.b - max (Fix_CC.r, Fix_CC.g);
   float Ydiff   = lum - 0.5;

   float RGBa = tex2D (FgSampler, xy).a;

// CYAN

   Fix_CC = C_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, C_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * C_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / C_Gamma) * C_Gain) + C_Brightness.xxx - 0.5.xxx) * C_Contrast) + 0.5.xxx;

   RGBsCx = lerp (RGBsCx, Fix_CC, saturate (cyan - max (yellow, magenta)));

// MAGENTA

   Fix_CC = M_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, M_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * M_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / M_Gamma) * M_Gain) + M_Brightness.xxx - 0.5.xxx) * M_Contrast) + 0.5.xxx;

   RGBsCx = lerp (RGBsCx, Fix_CC, saturate (magenta - max (cyan, yellow)));

// YELLOW

   Fix_CC = Y_TintColour.rgb + Ydiff.xxx;
   Fix_CC = lerp (RGBs, Fix_CC, Y_TintAmount);
   Fix_CC = saturate (lum.xxx + ((Fix_CC - lum.xxx) * Y_Saturate));
   Fix_CC = (((pow (Fix_CC, 1.0 / Y_Gamma) * Y_Gain) + Y_Brightness.xxx - 0.5.xxx) * Y_Contrast) + 0.5.xxx;

   return float4 (lerp (RGBsCx, Fix_CC, saturate (yellow - max (magenta, cyan))), RGBa);
}

//--------------------------------------------------------------//
//  Technique
//--------------------------------------------------------------//

technique CC_RGBCMY
{
   pass P_1
   < string Script = "RenderColorTarget0 = RGBout;"; >
   { PixelShader = compile PROFILE ps_RGB (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

