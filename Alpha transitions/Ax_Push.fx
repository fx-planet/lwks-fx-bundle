// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Push_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Push.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Push.fx
//
// This mimics the Lightworks push effect but supports alpha channel transitions.  Alpha
// levels can be boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Bars.fx, which also had the ability to
// transition between two titles.  That adds needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha push";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Pushes a title on or off screen horizontally or vertically";
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
   string Enum = "Push in,Push out";
> = 0;

int SetTechnique
<
   string Description = "Type";
   string Enum = "Push Right,Push Down,Push Left,Push Up";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define FX_OUT  1

#define HALF_PI 1.5707963268

#define EMPTY   0.0.xxxx

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

float4 ps_push_right (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (Ttype == FX_OUT) ? float2 (saturate (uv.x + cos (HALF_PI * Amount) - 1.0), uv.y)
                                 : float2 (saturate (uv.x - sin (HALF_PI * Amount) + 1.0), uv.y);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_push_left (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (Ttype == FX_OUT) ? float2 (saturate (uv.x - cos (HALF_PI * Amount) + 1.0), uv.y)
                                 : float2 (saturate (uv.x + sin (HALF_PI * Amount) - 1.0), uv.y);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_push_down (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (Ttype == FX_OUT) ? float2 (uv.x, saturate (uv.y + cos (HALF_PI * Amount) - 1.0))
                                 : float2 (uv.x, saturate (uv.y - sin (HALF_PI * Amount) + 1.0));

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_push_up (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = (Ttype == FX_OUT) ? float2 (uv.x, saturate (uv.y - cos (HALF_PI * Amount) + 1.0))
                                 : float2 (uv.x, saturate (uv.y + sin (HALF_PI * Amount) - 1.0));

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Push_right
{
   pass P_1
   { PixelShader = compile PROFILE ps_push_right (); }
}

technique Ax_Push_down
{
   pass P_1
   { PixelShader = compile PROFILE ps_push_down (); }
}

technique Ax_Push_left
{
   pass P_1
   { PixelShader = compile PROFILE ps_push_left (); }
}

technique Ax_Push_up
{
   pass P_1
   { PixelShader = compile PROFILE ps_push_up (); }
}
