// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Slice.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Slice.fx
//
// This transition splits the title into strips which then move off either horizontally
// or vertically to reveal the incoming image.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha slice";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Splits the title into strips which move on or off horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
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
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

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
   string Description = "Transition";
   string Enum = "Move in,Move out";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = 1.0 - Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_top (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = (Ttype == 0) ? 1.0 - Amount : Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_bottom (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float strips   = max (2.0, round (StripNumber));

   if (Ttype == 0) {
      float amount_1 = (Ttype == 0) ? 1.0 - Amount : Amount;
      float amount_2 = (1.0 - pow (1.0 - amount_1, 3.0)) / (strips * 2.0);

      amount_1 = pow (amount_1, 3.0);
      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }
   else {
      float amount_1 = pow (Amount, 3.0);
      float amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                          : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Slice_Left
{
   pass P_1
   { PixelShader = compile PROFILE ps_left (); }
}

technique Ax_Slice_Right
{
   pass P_1
   { PixelShader = compile PROFILE ps_right (); }
}

technique Ax_Slice_Top
{
   pass P_1
   { PixelShader = compile PROFILE ps_top (); }
}

technique Ax_Slice_Bottom
{
   pass P_1
   { PixelShader = compile PROFILE ps_bottom (); }
}

