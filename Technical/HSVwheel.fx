// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2013-03-15
// @see https://www.lwks.com/media/kunena/attachments/6375/HSVWheel_640.png

/**
 HSV Wheel is a colour analysis tool.  It shows one or optionally two pixel reference points
 mapped onto the HSV wheel(s).  Select the pixels with the on-screen cross-hairs and move
 and zoom the HSV wheels to wherever you need.  The small dot in each wheel shows the hue
 and saturation of its associated reference point.  The outer ring displays the brightness
 value.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect HSVwheel.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "HSV wheel";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "A colour analysis tool which shows one or two pixel reference points mapped onto HSV wheels";
   bool CanSize       = false;
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
#define BLACK float2(0.0,1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define RED float2(0.0,1.0).yxxy

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (submaster, SubMr);
DefineTarget (Tex1, Samp1);
DefineTarget (Tex2, Samp2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool CW1
<
   string Description = "Show";
   string Group = "HSV 1";
> = true;

float Pix1X
<
   string Description = "Pixel 1";
   string Group = "HSV 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Pix1Y
<
   string Description = "Pixel 1";
   string Group = "HSV 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float zoomit1
<
   string Description = "Zoom";
   string Group = "HSV 1";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Pan1X
<
   string Description = "Move 1";
   string Flags = "SpecifiesPointX";
   string Group = "HSV 1";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Pan1Y
<
   string Description = "Move 1";
   string Flags = "SpecifiesPointY";
   string Group = "HSV 1";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

bool CW2
<
   string Description = "Show";
   string Group = "HSV 2";
> = false;

float Pix2X
<
   string Description = "Pixel 2";
   string Group = "HSV 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.85;

float Pix2Y
<
   string Description = "Pixel 2";
   string Group = "HSV 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float zoomit2
<
   string Description = "Zoom";
   string Group = "HSV 2";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Pan2X
<
   string Description = "Move 2";
   string Flags = "SpecifiesPointX";
   string Group = "HSV 2";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.85;

float Pan2Y
<
   string Description = "Move 2";
   string Flags = "SpecifiesPointY";
   string Group = "HSV 2";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float Hue (float angle)
{
   if (angle > 360.0) angle -= 360.0;

   if (angle < 0.0) angle += 360.0;

   if (angle >= 60.0 && angle < 120.0) return (120.0 - angle) / 60.0;

   if (angle >= 240.0 && angle < 300.0) return 1.0 - ((300.0 - angle) / 60.0);

   if (angle >= 120.0 && angle < 240.0) return 0.0;

   return 1.0;
}

float2 Polar (float2 xy)
{
   float x = (xy.x - 0.5);
   float y = (xy.y - 0.5);
   float angle = degrees (atan2 (x, -y));

   if (angle < 0.0) angle += 360.0;

   float dist = distance (float2 (0.0, 0.0), float2 (x, y));

   return float2 (angle, dist * 2.0);
}

float2 Cart (float h, float s, float v)
{
   float x = s * cos (radians (h)) / 2.0;
   float y = s * sin (radians (h)) / 2.0;

   return float2 (x, -y);
}

float3 rgb2hsv (float4 rgb)
{
   float rgb_min, rgb_max, Chroma;
   float H = 0.0;
   float S = 0.0;
   float V = 0.0;

   rgb_min = min (rgb.r, min (rgb.g, rgb.b));
   rgb_max = max (rgb.r, max (rgb.g, rgb.b));

   if (rgb_max != rgb_min) {

      if (rgb_max == rgb.r) H = fmod (60.0 * ((rgb.g - rgb.b) / (rgb_max - rgb_min)), 360.0);
      else if (rgb_max == rgb.g) H = 60.0 * ((rgb.b - rgb.r) / (rgb_max - rgb_min)) + 120.0;
      else if (rgb_max == rgb.b) H = 60.0 * ((rgb.r - rgb.g) / (rgb_max - rgb_min)) + 240.0;

      if (H < 0.0) H += 360.0;
   }

   V = rgb_max;

   if (rgb_max == 0.0) S = 0.0;
   else S = 1.0 - (rgb_min / rgb_max);

   return float3 (H, S, V);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 wheel1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 pixel = tex2D (s_Input, float2 (Pix1X, 1.0 - Pix1Y));
   float4 color = EMPTY;

   float3 hsv = rgb2hsv (pixel);

   float2 polar = Polar (uv);

   float hc = polar.x;
   float hl = polar.x / 360.0;
   float vang = 360.0 * hsv.b;
   float sl = 1.0 - polar.y;

   if (polar.y < 0.99) {
      color = float4 (hl.xxx, 1.0);

      if (vang > hc - 0.7 && vang <= hc) color = RED;

      if (vang < hc-0.7) color = BLACK;
   }

   if (polar.y <= 0.833333) {
      float Cr = Hue (hc - 90.0);
      float Cg = Hue (hc + 120.0 - 90.0);
      float Cb = Hue (hc - 120.0 - 90.0);

      color = lerp (float4 (Cr, Cg, Cb, 1.0), 1.0, sl);
   }

   return color;
}

float4 prebuild (float2 uv : TEXCOORD1) : COLOR
{
   float4 orig = GetPixel (s_Input, uv);

   if (!CW1) return orig;

   float pixX = 3.0 / _OutputWidth;
   float pixY = 3.0 * _OutputAspectRatio / _OutputWidth;
   float asp = _OutputAspectRatio;

   float4 pixel = GetPixel (s_Input, float2 (Pix1X, 1.0 - Pix1Y));

   float3 hsv = rgb2hsv (pixel);

   float2 xxyy = Cart (hsv.r, hsv.g, hsv.b);

   xxyy /= 1.2;
   xxyy += 0.5;

   float zoom = max (0.00001, zoomit1);

   float z = zoom / asp;
   float X = ((uv.x - Pan1X) / z) + 0.5;
   float XX = ((xxyy.x - 0.5) * z) + Pan1X;
   float Y = ((uv.y + Pan1Y - 1.0) / zoom) + 0.5;
   float YY = ((xxyy.y - 0.5) * zoom) - Pan1Y + 1.0;

   float4 wheel = GetPixel (Samp1, float2 (X, Y));

   if (uv.x >= XX - pixX && uv.x <= XX + pixX && uv.y >= YY - pixY && uv.y <= YY + pixY)
      wheel = BLACK;

   return lerp (orig, wheel, wheel.a);
}

float4 wheel2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 color = 0.0;
   float4 pixel = tex2D (s_Input, float2 (Pix2X, 1.0 - Pix2Y));
   float3 hsv = rgb2hsv (pixel);
   float2 polar = Polar (uv);

   float hc = polar.x;
   float hl = polar.x / 360.0;
   float vang = 360.0 * hsv.b;
   float sl = 1.0 - polar.y;

   if (polar.y < 0.99) {
      color = float4 (hl, hl, hl, 1.0);

      if (vang > hc-0.7 && vang <= hc) color = RED;

      if (vang < hc-0.7) color = BLACK;
   }

   if (polar.y <= 0.833333) {
      float Cr = Hue (hc - 90.0);
      float Cg = Hue (hc + 120.0 - 90.0);
      float Cb = Hue (hc - 120.0 - 90.0);

      color = lerp (float4 (Cr, Cg, Cb, 1.0), 1.0, sl);
   }

   return color;
}

float4 combine (float2 xy : TEXCOORD2) : COLOR
{
   float4 orig = tex2D (SubMr, xy);

   if (!CW2) return orig;

   float pixX = 3.0 / _OutputWidth;
   float pixY = 3.0 * _OutputAspectRatio / _OutputWidth;
   float asp = _OutputAspectRatio;

   float4 pixel = tex2D (SubMr, float2 (Pix2X, 1.0 - Pix2Y));

   float3 hsv = rgb2hsv (pixel);

   float2 xxyy = Cart (hsv.r, hsv.g, hsv.b);

   xxyy /= 1.2;
   xxyy += 0.5.xx;

   float zoom = (zoomit2 == 0.0) ? 0.00001 : zoomit2;

   float z = zoom / asp;
   float X = ((xy.x - Pan2X) / z) + 0.5;
   float XX = ((xxyy.x - 0.5) * z) + Pan2X;
   float Y = ((xy.y + Pan2Y - 1.0) / zoom) + 0.5;
   float YY = ((xxyy.y - 0.5) * zoom) - Pan2Y + 1.0;

   float4 wheel = GetPixel (Samp2, float2 (X, Y));

   if (xy.x >= XX - pixX && xy.x <= XX + pixX && xy.y >= YY - pixY && xy.y <= YY + pixY)
      wheel = BLACK;

   return lerp (orig, wheel, wheel.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = Tex1;"; > ExecuteShader (wheel1)
   pass P_2 < string Script = "RenderColorTarget0 = submaster;"; > ExecuteShader (prebuild)
   pass P_3 < string Script = "RenderColorTarget0 = Tex2;"; > ExecuteShader (wheel2)
   pass P_4 ExecuteShader (combine)
}

