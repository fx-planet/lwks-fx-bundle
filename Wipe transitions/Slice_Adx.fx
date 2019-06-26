// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice.mp4

/**
This transition splits a delta key into strips which then move off either horizontally
or vertically to reveal the incoming image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Slice_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Slice transition (delta)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates foreground from background then splits it into strips which move on or off horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

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

int Ttype
<
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

int SetTechnique
<
   string Description = "Strip direction";
   string Enum = "Right to left,Left to right,Top to bottom,Bottom to top";
> = 1;

int Mode
<
   string Description = "Strip type";
   string Enum = "Mode A,Mode B";
> = 0;

float StripNumber
<
   string Description = "Strip number";
   float MinVal = 10.0;
   float MaxVal = 50.0;
> = 20.0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

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

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd;
   float3 Bgd;

   if (Ttype == 0) {
      Fgd = tex2D (s_Foreground, xy1).rgb;
      Bgd = tex2D (s_Background, xy2).rgb;
   }
   else {
      Fgd = tex2D (s_Background, xy2).rgb;
      Bgd = tex2D (s_Foreground, xy1).rgb;
   }

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_left (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Foreground, uv);
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_right (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Foreground, uv);
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_top (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = (Ttype == 0) ? 1.0 - Amount : Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Foreground, uv);
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_bottom (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd;

   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = (Ttype == 0) ? 1.0 - Amount : Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Foreground, uv);
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
      Bgnd = tex2D (s_Background, uv);
   }

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Slice_Adx_Left
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_left (); }
}

technique Slice_Adx_Right
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_right (); }
}

technique Slice_Adx_Top
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_top (); }
}

technique Slice_Adx_Bottom
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_bottom (); }
}

