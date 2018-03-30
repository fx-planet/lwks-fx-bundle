//--------------------------------------------------------------//
// Lightworks user effect Extrusion_matte.fx
//
// Created by LW user jwrl 2 April 2016.
//  LW 14+ version by jwrl 11 January 2017
//  Subcategory "Edge Effects" added.
//
// This effect, as the name suggests, extrudes a foreground
// image either linearly or radially towards a centre point.
// The extruded section can either be shaded by the foreground,
// image, colour shaded, or flat colour filled.
//
// The edge shading can be inverted if desired.  It is also
// possible to export the alpha channel for use in downstream
// effects.
//
// Lightworks effect modified by user jwrl 6 May 2016.
// Extrusion anti-ailasing added.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  It returns only half the actual frame
// height when interlaced media is playing and only when it
// is playing.  This fix will be reliable even if the LW bug
// is fixed.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for
// undefined samplers they have now been explicitly declared.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Extrusion matte";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Edge type";
   string Enum = "Radial,Radial shaded,Radial coloured,Linear,Linear shaded,Linear coloured";
> = 0;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 colour
<
   string Group = "Colour setup";
   string Description = "Edge colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.3804, 1.0, 0.0 };

bool invShade
<
   string Description = "Invert shading";
> = false;

bool expAlpha
<
   string Description = "Export alpha channel";
> = false;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture blurPre  : RenderColorTarget;
texture colorPre : RenderColorTarget;
texture blurProc : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
        Texture   = <Fg>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

sampler BgSampler = sampler_state {
        Texture   = <Bg>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

sampler BlurSampler = sampler_state {
        Texture   = <blurPre>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

sampler Col_Sampler = sampler_state {
        Texture   = <colorPre>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

sampler ProcSampler = sampler_state {
        Texture   = <blurProc>;
        AddressU  = Clamp;
        AddressV  = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};

//--------------------------------------------------------------//
// Common
//--------------------------------------------------------------//

#define SAMPLE   80
#define HALFWAY  40              // SAMPLE / 2
#define SAMPLES  81              // SAMPLE + 1.0

#define DELTANG  25
#define ALIASFIX 50              // DELTANG * 2
#define ANGLE    0.125664        // 0.1309

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define COLOUR   true
#define MONO     false

#define LIN_OFFS 0.667333

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_radial (float2 xy : TEXCOORD1, uniform bool is_colour) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   if (zoomAmount == 0.0) return retval;

   float scale, depth = zoomAmount * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 uv = xy;
   float2 xy1 = depth * (xy - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      retval += tex2D (FgSampler, uv);
      uv += xy1;
   }

   retval.a = saturate (retval.a);

   if (is_colour) { retval.rgb = colour.rgb; }
   else {
      retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

      if (!invShade) retval.rgb = 1.0.xxx - retval.rgb;
   }

   return retval;
}

float4 ps_linear (float2 xy : TEXCOORD1, uniform bool is_colour) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   float2 offset, uv = xy;

   offset.x = (0.498 - Xcentre) * LIN_OFFS;
   offset.y = (Ycentre - 0.505) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) return retval;

   float depth = zoomAmount * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (FgSampler, uv);
      uv += offset;
      }

   retval.a = saturate (retval.a);

   if (is_colour) { retval.rgb = colour.rgb; }
   else {
      retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

      if (!invShade) retval.rgb = 1.0.xxx - retval.rgb;
   }

   return retval;
}

float4 ps_shaded (float2 xy : TEXCOORD1) : COLOR
{
   float4 blurImg = tex2D (BlurSampler, xy);
   float4 colrImg = tex2D (Col_Sampler, xy);

   float alpha   = blurImg.a;
   float minColr = min (colrImg.r, min (colrImg.g, colrImg.b));
   float maxColr = max (colrImg.r, max (colrImg.g, colrImg.b));
   float delta   = maxColr - minColr;

   float3 hsv = 0.0.xxx;

   if (maxColr != 0.0) {
      hsv.y = 1.0 - (minColr / maxColr);
      hsv.x = (colrImg.r == maxColr) ? (colrImg.g - colrImg.b) / delta :
              (colrImg.g == maxColr) ? 2.0 + (colrImg.b - colrImg.r) / delta
                                     : 4.0 + (colrImg.r - colrImg.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   hsv.z = max (blurImg.r, max (blurImg.g, blurImg.b));

   if (hsv.y == 0.0) return float4 (hsv.zzz, alpha);

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float beta = hsv.x - (float) i;

   float4 retval = hsv.zzzz;

   retval.w *= (1.0 - hsv.y * (1.0 - beta));
   retval.y *= (1.0 - hsv.y);
   retval.z *= (1.0 - hsv.y * beta);

   if (i == 0) return float4 (retval.xwy, alpha);
   if (i == 1) return float4 (retval.zxy, alpha);
   if (i == 2) return float4 (retval.yxw, alpha);
   if (i == 3) return float4 (retval.yzx, alpha);
   if (i == 4) return float4 (retval.wyx, alpha);

   return float4 (retval.xyz, alpha);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 fgImage = tex2D (FgSampler, xy);
   float4 retval  = 0.0.xxxx;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      retval += tex2D (ProcSampler, xy + offset);
      retval += tex2D (ProcSampler, xy - offset);
      angle += ANGLE;
   }

   retval  /= ALIASFIX;
   retval   = lerp (0.0.xxxx, retval, retval.a);
   retval   = lerp (retval, fgImage, fgImage.a);
   retval.a = max (fgImage.a, retval.a * Amount);

   if (expAlpha) return retval;

   float4 bgImage = tex2D (BgSampler, xy);

   retval = lerp (bgImage, retval, retval.a);

   return lerp (bgImage, float4 (retval.rgb, bgImage.a), Opacity);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Radial
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_radial (MONO);
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique RadialShaded
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurPre;";
   >
   {
      PixelShader = compile PROFILE ps_radial (MONO);
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = colorPre;";
   >
   {
      PixelShader = compile PROFILE ps_radial (COLOUR);
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_shaded ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique RadialColour
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_radial (COLOUR);
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique Linear
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_linear (MONO);
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique LinearShaded
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurPre;";
   >
   {
      PixelShader = compile PROFILE ps_linear (MONO);
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = colorPre;";
   >
   {
      PixelShader = compile PROFILE ps_linear (COLOUR);
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_shaded ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

technique LinearColour
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurProc;";
   >
   {
      PixelShader = compile PROFILE ps_linear (COLOUR);
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

