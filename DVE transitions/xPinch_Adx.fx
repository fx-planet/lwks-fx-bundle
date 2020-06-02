// @Maintainer jwrl
// @Released 2020-06-02
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX.mp4

/**
 This effect pinches the delta key to a point to clear the background shot, while
 zooming out of the pinched key.  It reverses the process to bring in the incoming
 title.  Trig functions have been used during the progress of the effect to make the
 acceleration smoother.

 While based on xPinch_Dx.fx, the direction swap has been made symmetrical, unlike that
 in xPinch_Dx.fx.  When used with titles and similar keys which by their nature don't
 occupy the full screen, subjectively this approach looked better.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect xPinch_Adx.fx
//
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "X-pinch (delta)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Separates foreground from background then pinches it to a point while zooming to either hide or reveal it";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture Pinch : RenderColorTarget;

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

sampler s_Pinch = sampler_state
{
   Texture   = <Pinch>;
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

bool Ftype
<
   string Description = "Folded effect";
> = true;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MID_PT     (0.5).xx

#define EMPTY      (0.0).xxxx

#define QUARTER_PI 0.7853981634

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
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return Ftype ? float4 (Bgd, smoothstep (0.0, KeyGain, kDiff))
                : float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
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

float4 ps_pinch_I (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin ((1.0 - Amount) * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_tex2D (s_Title, xy);
}

float4 ps_pinch_O (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin (Amount * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_tex2D (s_Title, xy);
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgnd = fn_tex2D (s_Pinch, xy);

   return Ftype ? lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a)
                : lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (sin (Amount * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 Fgnd = fn_tex2D (s_Pinch, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_xPinch_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_I (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_xPinch_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_O (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}
