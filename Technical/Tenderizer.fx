// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2016-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Tenderizer_640.png

/**
 This effect converts 8 bit video to 10 bit video by adding intermediate colors and luminance
 values using spline interpolation.  Set project to 10 bit or better and set source width and
 height for best results.

 Note: the alpha channel is not changed, but there may be some image softening.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Tenderizer.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to better support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tenderizer";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Converts 8 bit video to 10 bit video by adding intermediate levels using spline interpolation";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define GetAlpha(SHADER,XY) (Overflow(XY) ? 0.0 : tex2D(SHADER, XY).a)

float _OutputWidth = 1.0;
float _OutputHeight = 1.0;

float _idxX[8] = { 0.0, 720.0, 1280.0, 1440.0, 1920.0, 2048.0, 3840.0, 4096.0 };
float _idxY[6] = { 0.0, 480.0, 576.0, 720.0, 1080.0, 2160.0 };

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

DefineInput (V, VSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int ReX
<
   string Description = "Source Horizontal Resolution";
   string Enum = "Project,720,1280,1440,1920,2048,3840,4096";
> = 0;

int ReY
<
   string Description = "Source Vertical Resolution";
   string Enum = "Project,480,576,720,1080,2160";
> = 0;

bool Luma
<
   string Description = "Tenderize Luma";
> = true;

bool Chroma
<
   string Description = "Tenderize Chroma";
> = true;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hermite (float t, float4 A, float4 B, float4 C, float4 D)
{
   float t2 = t * t;

   float4 retval = ((((3.0 * (B - C)) - A + D) * t2) + (C - A)) * t;

   retval += ((2.0 * A) - (5.0 * B) + (4.0 * C) - D) * t2;

   return (retval / 2.0) + B;
}

float4 colorsep (sampler samp, float2 xy, float2 pix)
{
   float4 color = GetPixel (samp, xy + pix);

   float Cmin = min (color.r, min (color.g, color.b));

   color.rgb -= Cmin.xxx;
   color.a  = Cmin;

   return color;
}

float closest (float test, float orig, float bit)
{
   float t = abs (test - orig);

   return (t < (bit * 0.3333)) ? orig : (t < (bit * 0.6667)) ? test : (test + orig) / 2.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Tenderize (float2 xy : TEXCOORD1) : COLOR
{
   float2 pixel;

   pixel.x = (ReX == 0) ? _OutputWidth : _idxX [ReX];
   pixel.y = (ReY == 0) ? _OutputHeight : _idxY [ReY];

   pixel = 1.0 / max (1.0e-6, pixel);

   float4 seporg = colorsep (VSampler, xy, 0.0.xx);
   float4 samp2, samp3, samp4, samp5, samp6, samp7, samp8;

   float4 samp00 = colorsep (VSampler, xy, float2 (pixel.x * -2.0, 0.0));
   float4 samp01 = colorsep (VSampler, xy, float2 (-pixel.x, 0.0));
   float4 samp02 = colorsep (VSampler, xy, float2 (pixel.x, 0.0));
   float4 samp03 = colorsep (VSampler, xy, float2 (pixel.x * 2.0, 0.0));
   float4 samp1  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 ((pixel.x * -2.0), -pixel.y));
   samp01 = (colorsep (VSampler, xy, float2 (-pixel.x, 0)) + colorsep (VSampler, xy, float2 (-pixel.x, -pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, xy, float2 (pixel.x, 0)) + colorsep (VSampler, xy, float2 (pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, xy, float2 (pixel.x * 2.0, pixel.y));
   samp2  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (pixel.x * -2.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, xy, float2 (-pixel.x, -pixel.y));
   samp02 = colorsep (VSampler, xy, float2 (pixel.x, pixel.y));
   samp03 = colorsep (VSampler, xy, float2 (pixel.x * 2.0, pixel.y * 2.0));
   samp3  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (-pixel.x, pixel.y * -2.0));
   samp01 = (colorsep (VSampler, xy, float2 (-pixel.x, -pixel.y)) + colorsep (VSampler, xy, float2(0, -pixel.y))) / 2.0;
   samp02 = (colorsep(VSampler, xy, float2 (0.0, pixel.y)) + colorsep (VSampler, xy, float2 (pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, xy, float2 (pixel.x, pixel.y * 2.0));
   samp4  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (0.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, xy, float2 (0.0, -pixel.y));
   samp02 = colorsep (VSampler, xy, float2 (0.0, pixel.y));
   samp03 = colorsep (VSampler, xy, float2 (0.0, pixel.y * 2.0));
   samp5  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (pixel.x, pixel.y * -2.0));
   samp01 = (colorsep (VSampler, xy, float2 (pixel.x, -pixel.y)) + colorsep (VSampler, xy, float2 (0.0, -pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, xy, float2 (0.0, pixel.y)) + colorsep (VSampler, xy, float2 (-pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, xy, float2 (-pixel.x, pixel.y * 2.0));
   samp6  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (pixel.x * 2.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, xy, float2 (pixel.x, -pixel.y));
   samp02 = colorsep (VSampler, xy, float2 (-pixel.x, pixel.y));
   samp03 = colorsep (VSampler, xy, float2 (pixel.x * -2.0, pixel.y * 2.0));
   samp7  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, xy, float2 (pixel.x * -2.0, pixel.y));
   samp01 = (colorsep (VSampler, xy, float2 (-pixel.x, 0.0)) + colorsep (VSampler, xy, float2 (-pixel.x, pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, xy, float2 (pixel.x, 0.0)) + colorsep (VSampler, xy, float2 (pixel.x, -pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, xy, float2 (pixel.x * 2.0, -pixel.y));
   samp8  = Hermite (0.5, samp00, samp01, samp02, samp03);

   float cbit = 1.0 / 256.0;
   float R, G, B, L;

   if (Chroma) {
      R = (samp1.r + samp2.r + samp3.r + samp4.r + samp5.r + samp6.r + samp7.r + samp8.r) / 8.0;
      G = (samp1.g + samp2.g + samp3.g + samp4.g + samp5.g + samp6.g + samp7.g + samp8.g) / 8.0;
      B = (samp1.b + samp2.b + samp3.b + samp4.b + samp5.b + samp6.b + samp7.b + samp8.b) / 8.0;
      R = closest (R, seporg.r, cbit);
      G = closest (G, seporg.g, cbit);
      B = closest (B, seporg.b, cbit);
   }
   else {
      R = seporg.r;
      G = seporg.g;
      B = seporg.b;
   }
      
   if (Luma) {
      L = (samp1.a + samp2.a + samp3.a + samp4.a + samp5.a + samp6.a + samp7.a + samp8.a) / 8.0;
      L = closest (L, seporg.a, cbit);
   }
   else L = seporg.a;

   return float4 (R + L, G + L, B + L, GetAlpha (VSampler, xy));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Tenderizer { pass P_1 ExecuteShader (Tenderize) }

