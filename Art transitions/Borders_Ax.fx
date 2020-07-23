// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Borders.mp4

/**
 An alpha transition that generates borders from the title(s) then blows them apart in
 four directions.  Each quadrant can be individually coloured.

 Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Borders_Ax.fx
//
// This is a revision of an earlier effect, Adx_Borders.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-23 jwrl:
// Changed Transition to Transition position.
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code to avoid the function call
// overhead while building the border.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border transition (alpha)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Bordered and coloured text spreads in four directions";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;
texture border_1 : RenderColorTarget;
texture border_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
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

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
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

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (Vsample, uv);
}

bool fn_equals (float2 xy1, float2 xy2)
{
   return ((xy1.x == xy2.x) && (xy1.y == xy2.y));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
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
      retval = max (retval, tex2D (s_Key, uv + xy));
      retval = max (retval, tex2D (s_Key, uv - xy));
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
      retval = max (retval, tex2D (s_Key, uv + xy));
      retval = max (retval, tex2D (s_Key, uv - xy));
   }

   return retval;
}

float4 ps_border_I_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Border_1, uv);

   if (Radius == 0.0) return retval;

   float radScale = cos (Amount * HALF_PI);
   float alpha = saturate (tex2D (s_Key, uv).a * 2.0);

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
   float alpha = saturate (tex2D (s_Key, uv).a * 2.0);

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

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float Offset = (1.0 - Amount) * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv - xy1;
   float2 xy4 = uv + xy1;

   xy1  = uv - xy2;
   xy2 += uv;

   float4 Fgnd = fn_tex2D (s_Key, xy1);
   float4 retval = EMPTY;

   if (!fn_equals (xy1, xy2)) {
      retval = fn_tex2D (s_Key, xy2); Fgnd = lerp (Fgnd, retval, retval.a);
      retval = fn_tex2D (s_Key, xy3); Fgnd = lerp (Fgnd, retval, retval.a);
      retval = fn_tex2D (s_Key, xy4); Fgnd = lerp (Fgnd, retval, retval.a);

      retval = Colour_1 * fn_tex2D (s_Border_2, xy1).a;
      retval = lerp (retval, Colour_2, fn_tex2D (s_Border_2, xy2).a);
      retval = lerp (retval, Colour_3, fn_tex2D (s_Border_2, xy3).a);
      retval = lerp (retval, Colour_4, fn_tex2D (s_Border_2, xy4).a);

      sincos ((Amount * HALF_PI), Outline, Opacity);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   float4 Bgnd = lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float Offset = Amount * Displace * OFFSET;
   float Outline = 0.0, Opacity = 1.0;

   float2 xy1 = float2 (-_OutputPixelWidth, _OutputPixelHeight) * Offset;
   float2 xy2 = float2 (xy1.x * X_OFFSET, (-xy1.y) * Y_OFFSET);
   float2 xy3 = uv - xy1;
   float2 xy4 = uv + xy1;

   xy1  = uv - xy2;
   xy2 += uv;

   float4 Fgnd = fn_tex2D (s_Key, xy1);
   float4 retval = EMPTY;

   if (!fn_equals (xy1, xy2)) {
      retval = fn_tex2D (s_Key, xy2); Fgnd = lerp (Fgnd, retval, retval.a);
      retval = fn_tex2D (s_Key, xy3); Fgnd = lerp (Fgnd, retval, retval.a);
      retval = fn_tex2D (s_Key, xy4); Fgnd = lerp (Fgnd, retval, retval.a);

      retval = Colour_1 * fn_tex2D (s_Border_2, xy1).a;
      retval = lerp (retval, Colour_2, fn_tex2D (s_Border_2, xy2).a);
      retval = lerp (retval, Colour_3, fn_tex2D (s_Border_2, xy3).a);
      retval = lerp (retval, Colour_4, fn_tex2D (s_Border_2, xy4).a);

      sincos ((Amount * HALF_PI), Opacity, Outline);
      Opacity = 1.0 - sin (Opacity * HALF_PI);
   }

   float4 Bgnd = lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Opacity);

   return lerp (Bgnd, retval, retval.a * Outline);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Borders_in
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_I_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_I_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Ax_Borders_out
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = border_1;"; >
   { PixelShader = compile PROFILE ps_border_O_1 (); }

   pass P_2 < string Script = "RenderColorTarget0 = border_2;"; >
   { PixelShader = compile PROFILE ps_border_O_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}
