// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders.mp4

/**
An alpha transition that generates borders from the delta key then uses them to make the
image materialise from four directions or blow apart in four directions.  Each quadrant
is independently coloured.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Borders_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border transition (delta)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Separates foreground from background which materialises from four directions or spreads and fades in four directions";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture border_1 : RenderColorTarget;
texture border_2 : RenderColorTarget;

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

sampler s_Border_1 = sampler_state {
   Texture   = <border_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Border_2 = sampler_state {
   Texture   = <border_2>;
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
   float KF0 = 0.0;
   float KF1 = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

float Radius
<
   string Group = "Borders";
   string Description = "Radius";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Displace
<
   string Group = "Borders";
   string Description = "Displacement";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour_1
<
   string Group = "Colours";
   string Description = "Outline 1";
   bool SupportsAlpha = true;
> = { 0.6, 0.9, 1.0, 1.0 };

float4 Colour_2
<
   string Group = "Colours";
   string Description = "Outline 2";
   bool SupportsAlpha = true;
> = { 0.3, 0.6, 1.0, 1.0 };

float4 Colour_3
<
   string Group = "Colours";
   string Description = "Outline 3";
   bool SupportsAlpha = true;
> = { 0.9, 0.6, 1.0, 1.0 };

float4 Colour_4
<
   string Group = "Colours";
   string Description = "Outline 4";
   bool SupportsAlpha = true;
> = { 0.6, 0.3, 1.0, 1.0 };

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP_1   30
#define RADIUS_1 0.01
#define ANGLE_1  1.0471975512

#define LOOP_2   24
#define RADIUS_2 0.0066666667
#define ANGLE_2  0.1309

#define OFFSET   0.5
#define X_OFFSET 0.5625
#define Y_OFFSET 1.7777777778

#define HALF_PI  1.5707963268

#define EMPTY    (0.0).xxxx

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

float fn_alpha (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv).a;
}

bool fn_diff (float2 xy1, float2 xy2)
{
   return ((xy1.x != xy2.x) || (xy1.y != xy2.y));
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

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
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

float4 ps_border_I_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = EMPTY;

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
   float2 xy;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (s_Title, uv + xy));
      retval = max (retval, tex2D (s_Title, uv - xy));
   }

   return retval;
}

float4 ps_border_O_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = EMPTY;

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_1;
   float2 xy;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (s_Title, uv + xy));
      retval = max (retval, tex2D (s_Title, uv - xy));
   }

   return retval;
}

float4 ps_border_I_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Border_1, uv);

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);
   float alpha = saturate (tex2D (s_Title, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (s_Border_1, uv + xy));
      retval = max (retval, tex2D (s_Border_1, uv - xy));
   }

   return lerp (retval, EMPTY, alpha);
}

float4 ps_border_O_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Border_1, uv);

   if (Radius == 0.0) return retval;

   float radScale = sin (Amount * HALF_PI);
   float alpha = saturate (tex2D (s_Title, uv).a * 2.0);

   float2 radius = float2 (_OutputPixelWidth, _OutputPixelHeight) * Radius * radScale * RADIUS_2;
   float2 xy;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      xy *= radius;
      retval = max (retval, tex2D (s_Border_1, uv + xy));
      retval = max (retval, tex2D (s_Border_1, uv - xy));
   }

   return lerp (retval, EMPTY, alpha);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv1 - xy1;
   float2 xy4 = uv1 + xy1;

   xy1  = uv1 - xy2;
   xy2 += uv1;

   float4 Super  = fn_tex2D (s_Title, xy1);
   float4 retval = EMPTY;

   if (fn_diff (xy1, xy2)) {
      retval = fn_tex2D (s_Title, xy2); Super = lerp (Super, retval, retval.a);
      retval = fn_tex2D (s_Title, xy3); Super = lerp (Super, retval, retval.a);
      retval = fn_tex2D (s_Title, xy4); Super = lerp (Super, retval, retval.a);

      retval = Colour_1 * fn_alpha (s_Border_2, xy1);
      retval = lerp (retval, Colour_2, fn_alpha (s_Border_2, xy2));
      retval = lerp (retval, Colour_3, fn_alpha (s_Border_2, xy3));
      retval = lerp (retval, Colour_4, fn_alpha (s_Border_2, xy4));

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   float4 Bgnd = lerp (tex2D (s_Foreground, uv2), Super, Super.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float Offset = Amount * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (-_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv1 - xy1;
   float2 xy4 = uv1 + xy1;

   xy1  = uv1 - xy2;
   xy2 += uv1;

   float4 Super  = fn_tex2D (s_Title, xy1);
   float4 retval = EMPTY;

   if (fn_diff (xy1, xy2)) {
      retval = fn_tex2D (s_Title, xy2); Super = lerp (Super, retval, retval.a);
      retval = fn_tex2D (s_Title, xy3); Super = lerp (Super, retval, retval.a);
      retval = fn_tex2D (s_Title, xy4); Super = lerp (Super, retval, retval.a);

      retval = Colour_1 * fn_alpha (s_Border_2, xy1);
      retval = lerp (retval, Colour_2, fn_alpha (s_Border_2, xy2));
      retval = lerp (retval, Colour_3, fn_alpha (s_Border_2, xy3));
      retval = lerp (retval, Colour_4, fn_alpha (s_Border_2, xy4));

      sincos ((Amount * HALF_PI), Opacity, Outline);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   float4 Bgnd = lerp (tex2D (s_Background, uv2), Super, Super.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Borders_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_I_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_I_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_Borders_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_O_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_O_2 (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main_O (); }
}

