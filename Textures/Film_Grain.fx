// @Maintainer jwrl
// @Released 2021-10-29
// @Author khaver
// @Created 2013-06-07
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmGrain_640.png

/**
 This effect adds grain to an image either as film-style grain or as random noise.
 The grain can be applied to the luminance, chroma, luminance and chroma, or RGB.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Film_Grain.fx
//
// Version history:
//
// Update 2021-10-29 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film Grain";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Adds grain to an image either as film-style grain or as random noise";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Grain, s_Grain);
DefineTarget (Blur, s_Blur);
DefineTarget (Emboss, s_Emboss);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int show
<
   string Description = "Grain Type";
   string Enum = "Bypass,Plain,Blurred,Film";
> = 3;

int gtype
<
   string Description = "Applied to";
   string Enum = "Luma,Chroma,Luma+Chroma,RGB";
> = 0;

float Mstrength
<
   string Description = "Master Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Lstrength
<
   string Description = "Luma Strength";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Cstrength
<
   string Description = "Chroma Strength";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float zoomit
<
   string Description = "Grain Size";
   float MinVal = 0.05;
   float MaxVal = 5.0;
> = 1.0;

float Xbias
<
   string Description = "X";
   float MinVal = -3.0;
   float MaxVal = 3.0;
   string Group = "Film Grain Bias";
> = -1.0;

float Ybias
<
   string Description = "Y";
   float MinVal = -3.0;
   float MaxVal = 3.0;
   string Group = "Film Grain Bias";
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

//---------------- rand function by Windsturm ------------------

float rand (float2 uv, float seed)
{
   float rn = frac (sin (dot (uv, float2 (12.9898, 78.233)) + seed) * (43758.5453)) - 0.5;

   return clamp (rn, -0.5, 0.5);
}
 
//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

//---------------------- Generate grain ------------------------

float4 Graintex (float2 xy : TEXCOORD0) : COLOR
{
   float Prog = _Progress + 0.5;
   float Crand = rand (xy, Prog * xy.y);
   float Rrand = 0.5 + (Crand * (Mstrength * Lstrength));

   Crand = rand (xy, Prog * xy.x);

   float Grand = 0.5 + (Crand * (Mstrength * Cstrength));

   Crand = rand (xy, Prog * (1.0 - xy.x));

   float Brand = 0.5 + (Crand * (Mstrength * Cstrength));

   return float4 (Rrand, Grand, Brand, 1.0);
}

//---------------------- Blur the grain ------------------------

float4 Blurtex (float2 xy : TEXCOORD2) : COLOR
{
   float2 _pixel = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

   float4 bout = tex2D (s_Grain, xy);

   bout += tex2D (s_Grain, xy + (_pixel * float2 (-1.0, -1.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (0.0, -1.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (1.0, -1.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (-1.0, 0.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (1.0, 0.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (-1.0, 1.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (0.0, 1.0)));
   bout += tex2D (s_Grain, xy + (_pixel * float2 (1.0, 1.0)));

   return bout / 9.0;
}

//---------------------- Emboss the grain -----------------------

float4 Embosstex (float2 xy : TEXCOORD2) : COLOR
{
   float2 _pixel = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

   float r22 = tex2D (s_Blur, xy).r;
   float r11 = tex2D (s_Blur, xy - (_pixel * float2 (Xbias, Ybias))).r * -1.5;
   float r33 = tex2D (s_Blur, xy + (_pixel * float2 (Xbias, Ybias))).r * 1.5;
   
   float g22 = tex2D (s_Blur, xy).g;
   float g11 = tex2D (s_Blur, xy - (_pixel * float2 (Xbias, Ybias))).g * 1.5;
   float g33 = tex2D (s_Blur, xy + (_pixel * float2 (Xbias, Ybias))).g * -1.5;

   float b22 = tex2D (s_Blur, xy).b;
   float b11 = tex2D (s_Blur, xy - (_pixel * float2 (Xbias, Ybias))).b * -1.5;
   float b33 = tex2D (s_Blur, xy + (_pixel * float2 (Xbias, Ybias))).b * 1.5;
   
   return float4 (r11 + r22 + r33, g11 + g22 + g33, b11 + b22 + b33, 1.0);
}

//---------------------- Select the grain -----------------------

float4 Combine (float2 uv : TEXCOORD2) : COLOR
{
  float R, G, B;

  //------------Zoom the grain------------

  float2 xy = uv - 0.5;

  xy = (xy / zoomit) + 0.5;

  if (xy.x > 0.99) xy.x = frac (xy.x);
  if (xy.y > 0.99) xy.y = frac (xy.y);
  if (xy.x < 0.01) xy.x = abs (frac (xy.x));
  if (xy.y < 0.01) xy.y = abs (frac (xy.y));
  
  if (show == 0) return tex2D (s_Input, uv);       //------Bypass-----
  
  if (show == 1) {                                 //------Plain Grain-------
     R = tex2D (s_Grain, xy).r - 0.5;
     G = tex2D (s_Grain, xy).g - 0.5;
     B = tex2D (s_Grain, xy).b - 0.5;
  }
  
  if (show == 2) {                                 //-----Blurred Grain------
     R = tex2D (s_Blur, xy).r - 0.5;
     G = tex2D (s_Blur, xy).g - 0.5;
     B = tex2D (s_Blur, xy).b - 0.5;
  }
  
  if (show == 3) {                                 //-----Embossed Grain-----
     R = tex2D (s_Emboss, xy).r - 0.5;
     G = tex2D (s_Emboss, xy).g - 0.5;
     B = tex2D (s_Emboss, xy).b - 0.5;
  }
  
  float4 orig = tex2D (s_Input, uv);
  
  //----------------Convert RGB to YUV--------------

  float Y = (0.299 * orig.r) + (0.587 * orig.g) + (0.114 * orig.b);
  float Cb = ((0.5 * orig.b) - (0.168736 * orig.r) - (0.331264 * orig.g)) + 0.5;
  float Cr = ((0.5 * orig.r) - (0.418688 * orig.g) - (0.081312 * orig.b)) + 0.5;

  //--Adjust grain strength according to luma level - Black>Grey>White = 0.0>1.0>0.0

  float Ydelta = 1.0 - abs ((Y - 0.5) * 2.0);

  if (gtype == 0 || gtype == 2) Y += (R * Ydelta); //-----Luma & Luma+Chroma

  if (gtype == 1 || gtype == 2) {                  //-----Chroma & Luma+Chroma
      Cb += (G * Ydelta);
      Cr += (B * Ydelta);
   }
  
  //----------------Convert YUV to RGB--------------   

  float4 cout = float4 (Y.xxx, 1.0);

  Cb -= 0.5;
  Cr -= 0.5;

  cout.r += 1.402 * Cr;
  cout.g -= (0.34414 * Cb) + (0.71414 * Cr);
  cout.b += 1.772 * Cb;

  if (gtype == 3) {                                //-----RGB
      cout.r += (B * Ydelta);
      cout.g += (R * Ydelta);
      cout.b += (G * Ydelta);
   }

  return cout;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FilmGrain
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 < string Script = "RenderColorTarget0 = Grain;"; > ExecuteShader (Graintex)
   pass P_3 < string Script = "RenderColorTarget0 = Blur;"; > ExecuteShader (Blurtex)
   pass P_4 < string Script = "RenderColorTarget0 = Emboss;"; > ExecuteShader (Embosstex)
   pass P_5 ExecuteShader (Combine)
}

