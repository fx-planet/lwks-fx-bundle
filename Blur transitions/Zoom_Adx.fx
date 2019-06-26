// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom.mp4

/**
IMPORTANT NOTE:  WHEN USED WITH THE MICROSOFT WINDOWS OPERATING SYSTEM THIS EFFECT IS
ONLY SUITABLE FOR LIGHTWORKS VERSION 14.5 AND BETTER.

This effect is a user-selectable zoom in or zoom out that transitions into or out of
a delta key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Separates foreground from background then performs a zoom in or out to establish or remove it";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Super = sampler_state
{
   Texture   = <Super>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

int Ttype
<
   string Description = "Direction";
   string Enum = "Zoom out,Zoom in";
> = 0;

float zoomAmount
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Xcentre
<
   string Group = "Zoom";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Group = "Zoom";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLE  61
#define DIVISOR 61.0    // Sorts out float issues with Linux

#define EMPTY   (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Bgd = tex2D (s_Foreground, xy1).rgb;
   float3 Fgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_zoom_I (float2 uv : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s_Super, uv);

   float scale, zoomStrength;

   if (Ttype == 0) {
      zoomStrength = zoomAmount * (1.0 - Amount);
      scale = 1.0 - zoomStrength;
      zoomStrength /= SAMPLE;
   }
   else {
      zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
      scale = 1.0;
   }

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += fn_tex2D (s_Super, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_O (float2 uv : TEXCOORD1) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s_Super, uv);

   float scale, zoomStrength;

   if (Ttype == 0) {
      zoomStrength = zoomAmount * Amount / SAMPLE;
      scale = 1.0;
   }
   else {
      zoomStrength = zoomAmount * Amount;
      scale = 1.0 - zoomStrength;
      zoomStrength /= SAMPLE;
   }

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += fn_tex2D (s_Super, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval;

   if (zoomAmount == 0.0) { retval = tex2D (s_Background, uv); }
   else {
      float scale, zoomStrength;

      if (Ttype == 0) {
         zoomStrength = zoomAmount * (1.0 - Amount);
         scale = 1.0 - zoomStrength;
         zoomStrength /= SAMPLE;
      }
      else {
         zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
         scale = 1.0;
      }

      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy = uv - zoomCentre;

      retval = EMPTY;

      for (int i = 0; i < SAMPLE; i++) {
         retval += fn_tex2D (s_Title, xy * scale + zoomCentre);
         scale += zoomStrength;
      }

      retval /= DIVISOR;
   }

   return lerp (tex2D (s_Foreground, uv), retval, retval.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval;

   if (zoomAmount == 0.0) { retval = tex2D (s_Foreground, uv); }
   else {
      float scale, zoomStrength;

      if (Ttype == 0) {
         zoomStrength = zoomAmount * Amount / SAMPLE;
         scale = 1.0;
      }
      else {
         zoomStrength = zoomAmount * Amount;
         scale = 1.0 - zoomStrength;
         zoomStrength /= SAMPLE;
      }

      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy = uv - zoomCentre;

      retval = EMPTY;

      for (int i = 0; i < SAMPLE; i++) {
         retval += fn_tex2D (s_Title, xy * scale + zoomCentre);
         scale += zoomStrength;
      }

      retval /= DIVISOR;
   }

   return lerp (tex2D (s_Background, uv), retval, retval.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Zoom_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_zoom_I (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_Zoom_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_zoom_O (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}

