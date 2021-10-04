// @Maintainer jwrl
// @Released 2021-10-02
// @Author msi
// @OriginalAuthor "Wojciech Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)"
// @Created 2011-05-27
// @License "CC BY-NC-SA"
// @see https://www.lwks.com/media/kunena/attachments/6375/vintagelook_640.png

/**
 Vintage look simulates what happens when the dye layers of old colour film stock start
 to fade.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VintageLook.fx
//
// 2011 msi [CC BY-NC-SA] - Uses Vintage Look routine by Wojciech
// Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)
//
// Version history:
//
// Update 2021-10-02 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2018-12-23:
// Various cross-platform upgrades.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Vintage look";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates what happens when the dye layers of old colour film stock start to fade.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 Yellow
<
	string Description = "Yellow";
	string Group       = "Balance";
> = { 0.9843f, 0.9490f, 0.6392f, 1.0f };

float4 Magenta
<
	string Description = "Magenta";
	string Group       = "Balance";
> = { 0.9098f, 0.3960f, 0.7019f, 1.0f };

float4 Cyan
<
	string Description = "Cyan";
	string Group       = "Balance";
> = { 0.0352f, 0.2862f, 0.9137f, 1.0f };

float YellowLevel
<
	string Description = "Yellow";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.59;

float MagentaLevel
<
	string Description = "Magenta";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.2;

float CyanLevel
<
	string Description = "Cyan";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.17;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 VintageLookFX (float2 uv: TEXCOORD1) : COLOR
{
   float4 source = GetPixel (s_Input, uv);

   // BEGIN Vintage Look routine by Wojciech Toman
   // (http://wtomandev.blogspot.com/2011/04/vintage-look.html)

   float4 corrected = lerp (source, source * Yellow, YellowLevel);

   corrected = lerp (corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Magenta))),  MagentaLevel);
   corrected = lerp (corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Cyan))), CyanLevel);

   // END Vintage Look routine by Wojciech Toman

   return corrected;	
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique VintageLookFXTechnique
{
   pass SinglePass ExecuteShader (VintageLookFX)
}

