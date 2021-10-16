// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Chinagraph_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Chinagraph.mp4

/**
 This "dissolve" simulates the chinagraph marks used by film editors to mark up optical
 effects on film rushes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect Chinagraph_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chinagraph pencil";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Simulates the chinagraph marks used by film editors to mark up optical effects on film rushes";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SIZE    0.00436
#define RAND_1  12.9898
#define RAND_2  78.233
#define RAND_3  43758.5453

#define TEX     0.5
#define WIDTH   0.0109
#define DISP    0.00218
#define TILT    0.1

#define L_R     0
#define R_L     1

#define LOOP    12
#define RADIUS  0.003333
#define ANGLE   0.261799
#define DIVISOR 25

#define OFFSET  0.002

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Target, s_Target);
DefineTarget (Overlay, s_Overlay);
DefineTarget (China, s_Chinagraph);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int MarkType
<
   string Description = "Overlay type";
   string Enum = "Left to right,Right to left,Crossover";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Tilt
<
   string Description = "Angle";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Texture
<
   string Group = "Texture";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Depth
<
   string Group = "Texture";
   string Description = "Depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Radius
<
   string Group = "Texture";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_bgnd (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   return (Amount < 0.5) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
}

float4 ps_ovly (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   return (Amount < 0.5) ? GetPixel (s_Background, uv2) : GetPixel (s_Foreground, uv1);
}

float4 ps_markup (float2 uv : TEXCOORD3) : COLOR
{
   float2 grain = float2 (1.0, _OutputAspectRatio) * SIZE;
   float2 xy1 = round ((uv - 0.5) / grain) * grain;
   float2 xy2 = frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + _Progress) * RAND_3);

   float4 china = float2 (frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + xy2.x) * RAND_3), 1.0).xxxy;
   float4 retval = 0.0.xxxx;

   china = lerp (retval, china, Texture * TEX);
   china = min (china + Depth, 1.0.xxxx);

   xy1 = ((uv - 0.5) / 4.0) + 0.5; xy2 = 1.0 - xy1;

   xy1.x  = uv.x + uv.y + WIDTH;
   xy2.x  = uv.x + uv.y - WIDTH;

   float4 offs_1 = tex2D (s_Target, xy1);
   float4 offs_2 = tex2D (s_Target, xy2);
   float4 offs_3 = tex2D (s_Overlay, 1.0 - xy1);
   float4 offs_4 = tex2D (s_Overlay, 1.0 - xy2);

   float slope  = Amount + (uv.y * Tilt * TILT);
   float prog_0 = uv.x;
   float prog_1 = ((offs_1.r + offs_1.g + offs_1.b + offs_3.r + offs_3.g + offs_3.b) * DISP) + WIDTH;
   float prog_2 = ((offs_2.r + offs_2.g + offs_2.b + offs_4.r + offs_4.g + offs_4.b) * DISP) + WIDTH;

   prog_1 = max (slope - prog_1, 0.0);
   prog_2 = min (slope + prog_2, 1.0);

   if ((MarkType != R_L) && (prog_0 > prog_1) && (prog_0 < prog_2))
      retval = float4 (china.rgb, 1.0);

   if ((MarkType != L_R) && (prog_0 > 1.0 - prog_2) && (prog_0 < 1.0 - prog_1))
      retval = float4 (china.rgb, 1.0);

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Target, uv);
   float4 china  = tex2D (s_Chinagraph, uv);

   if ((Amount != 0.0) && (Radius != 0.0)) {

      float angle = 0.0;

      float2 xy, radius = float2 (1.0 - china.b, china.r + china.g) * Radius * RADIUS;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         china += tex2D (s_Chinagraph, uv + xy);
         china += tex2D (s_Chinagraph, uv - xy);
         angle += ANGLE;
      }

      china /= DIVISOR;
   }

   return lerp (retval, china, china.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Chinagraph_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Target;"; > ExecuteShader (ps_bgnd)
   pass P_2 < string Script = "RenderColorTarget0 = Overlay;"; > ExecuteShader (ps_ovly)
   pass P_3 < string Script = "RenderColorTarget0 = China;"; > ExecuteShader (ps_markup)
   pass P_4 ExecuteShader (ps_main)
}
