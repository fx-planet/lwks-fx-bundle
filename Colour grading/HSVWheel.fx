// @Maintainer jwrl
// @ReleaseDate 2018-03-31
// @Author khaver
//--------------------------------------------------------------//
// HSVWheel.fx
//
// Original effect by khaver - Gary Hango
//
// Cross platform conversion by jwrl April 30 2016
//
// Bug fix 10 July 2017 by jwrl to correct modulo usage
// affecting Linux and Mac versions only.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "HSV Wheel";
   string Category    = "Colour";
   string SubCategory = "Analysis";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture submaster : RenderColorTarget;

texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSamp = sampler_state {
        Texture = <Input>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

sampler SubMr = sampler_state {
        Texture = <submaster>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

sampler Samp1 = sampler_state {
        Texture = <Tex1>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

sampler Samp2 = sampler_state {
        Texture = <Tex2>;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float Pix1Y
<
   string Description = "Pixel 1";
   string Group = "HSV 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float zoomit1
<
   string Description = "Zoom";
   string Group = "HSV 1";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Pan1X
<
   string Description = "Move 1";
   string Flags = "SpecifiesPointX";
   string Group = "HSV 1";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float Pan1Y
<
   string Description = "Move 1";
   string Flags = "SpecifiesPointY";
   string Group = "HSV 1";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.85;

float Pix2Y
<
   string Description = "Pixel 2";
   string Group = "HSV 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float zoomit2
<
   string Description = "Zoom";
   string Group = "HSV 2";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float Pan2X
<
   string Description = "Move 2";
   string Flags = "SpecifiesPointX";
   string Group = "HSV 2";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.85;

float Pan2Y
<
   string Description = "Move 2";
   string Flags = "SpecifiesPointY";
   string Group = "HSV 2";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 wheel1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 pixel = tex2D (InputSamp, float2 (Pix1X, 1.0 - Pix1Y));
   float4 color = 0.0;
   float3 hsv = rgb2hsv (pixel);
   float2 polar = Polar (uv);

   float hc = polar.x;
   float hl = polar.x / 360.0;
   float vang = 360.0 * hsv.b;
   float sl = 1.0 - polar.y;

   if (polar.y < 0.99) {
      color = float4 (hl, hl, hl, 1.0);

      if (vang > hc - 0.7 && vang <= hc) color = float4 (1.0, 0.0, 0.0, 1.0);

      if (vang < hc-0.7) color = float4 (0.0, 0.0, 0.0, 1.0);
   }

   if (polar.y <= 0.833333) {
      float Cr = Hue (hc - 90.0);
      float Cg = Hue (hc + 120.0 - 90.0);
      float Cb = Hue (hc - 120.0 - 90.0);

      color = lerp (float4 (Cr, Cg, Cb, 1.0), 1.0, sl);
   }

   return color;
}

float4 prebuild (float2 xy : TEXCOORD1) : COLOR
{
   float4 orig = tex2D (InputSamp, xy);

   if (!CW1) return orig;

   float4 Cout, wheel = 0.0;

   float pixX = 3.0 / _OutputWidth;
   float pixY = 3.0 * _OutputAspectRatio / _OutputWidth;
   float asp = _OutputAspectRatio;

   float4 pixel = tex2D (InputSamp, float2 (Pix1X, 1.0 - Pix1Y));
   float3 hsv = rgb2hsv (pixel);
   float2 xxyy = Cart (hsv.r, hsv.g, hsv.b);

   xxyy /= 1.2;
   xxyy += 0.5;

   float zoom = (zoomit1 == 0.0) ? 0.00001 : zoomit1;

   float z = zoom / asp;
   float X = ((xy.x - 0.5) / z) + 0.5;
   float XX = ((xxyy.x - 0.5) * z) + 0.5;
   float Y = ((xy.y - 0.5) / zoom) + 0.5;
   float YY = ((xxyy.y - 0.5) * zoom) + 0.5;

   X -= (Pan1X - 0.5) / z;
   Y += (Pan1Y - 0.5) / zoom;
   XX += Pan1X - 0.5;
   YY -= Pan1Y - 0.5;

   wheel = tex2D (Samp1, float2 (X, Y));

   if (X > 1.0 || X < 0.0) wheel = 0.0;

   if (Y > 1.0 || Y < 0.0) wheel = 0.0;

   if (xy.x >= XX - pixX && xy.x <= XX + pixX && xy.y >= YY - pixY && xy.y <= YY + pixY) {
      wheel = float4 (0.0, 0.0, 0.0, 1.0);
   }

   return lerp (orig, wheel, wheel.a);
}

float4 wheel2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 color = 0.0;
   float4 pixel = tex2D (InputSamp, float2 (Pix2X, 1.0 - Pix2Y));
   float3 hsv = rgb2hsv (pixel);
   float2 polar = Polar (uv);

   float hc = polar.x;
   float hl = polar.x / 360.0;
   float vang = 360.0 * hsv.b;
   float sl = 1.0 - polar.y;

   if (polar.y < 0.99) {
      color = float4 (hl, hl, hl, 1.0);

      if (vang > hc-0.7 && vang <= hc) color = float4 (1.0, 0.0, 0.0, 1.0);

      if (vang < hc-0.7) color = float4 (0.0, 0.0, 0.0, 1.0);
   }

   if (polar.y <= 0.833333) {
      float Cr = Hue (hc - 90.0);
      float Cg = Hue (hc + 120.0 - 90.0);
      float Cb = Hue (hc - 120.0 - 90.0);

      color = lerp (float4 (Cr, Cg, Cb, 1.0), 1.0, sl);
   }

   return color;
}

float4 combine (float2 xy : TEXCOORD1) : COLOR
{
   float4 orig = tex2D (SubMr, xy);

   if (!CW2) return orig;

   float pixX = 3.0 / _OutputWidth;
   float pixY = 3.0 * _OutputAspectRatio / _OutputWidth;
   float asp = _OutputAspectRatio;

   float4 Cout, wheel = 0.0;

   float4 pixel = tex2D (SubMr, float2 (Pix2X, 1.0 - Pix2Y));
   float3 hsv = rgb2hsv (pixel);
   float2 xxyy = Cart (hsv.r, hsv.g, hsv.b);

   xxyy /= 1.2;
   xxyy += 0.5;

   float zoom = (zoomit2 == 0.0) ? 0.00001 : zoomit2;

   float z = zoom / asp;
   float X = ((xy.x - 0.5) / z) + 0.5;
   float XX = ((xxyy.x - 0.5) * z) + 0.5;
   float Y = ((xy.y - 0.5) / zoom) + 0.5;
   float YY = ((xxyy.y - 0.5) * zoom) + 0.5;

   X -= (Pan2X - 0.5) / z;
   Y += (Pan2Y - 0.5) / zoom;
   XX += Pan2X - 0.5;
   YY -= Pan2Y - 0.5;

   wheel = tex2D (Samp2, float2 (X, Y));

   if (X > 1.0 || X < 0.0) wheel = 0.0;

   if (Y > 1.0 || Y < 0.0) wheel = 0.0;

   if (xy.x >= XX - pixX && xy.x <= XX + pixX && xy.y >= YY - pixY && xy.y <= YY + pixY) {
      wheel = float4 (0.0, 0.0, 0.0, 1.0);
   }

   return lerp (orig, wheel, wheel.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SampleFxTechnique
{
   
   pass Pass0
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE wheel1 ();
   }

   pass Pass1
   <
   string Script = "RenderColorTarget0 = submaster;";
   >
   {
      PixelShader = compile PROFILE prebuild ();
   }

   pass Pass2
   <
   string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile PROFILE wheel2 ();
   }

   pass Pass3
   {
      PixelShader = compile PROFILE combine ();
   }
}

