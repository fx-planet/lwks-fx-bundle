//--------------------------------------------------------------//
// Lightworks effect Dx_Chinagraph.fx
//
// Created by Lightworks user jwrl 1 March 2017.
// @Author: jwrl
// @CreationDate: "1 March 2017"
//
// This effect simulates the chinagraph marks used by film
// editors to mark up optical effects on film rushes.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl - renamed from Chinagraph.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chinagraph pencil";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture chinatex : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler texSampler = sampler_state
{
   Texture   = <chinatex>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int MarkType
<
   string Description = "Markup type";
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

//--------------------------------------------------------------//
// Definitions and constants
//--------------------------------------------------------------//

#define SIZE    8.0
#define RAND_1  12.9898
#define RAND_2  78.233
#define RAND_3  43758.5453

#define TEX     0.5
#define WIDTH   20.0
#define DISP    4.0
#define TILT    0.1

#define L_R     0
#define R_L     1

#define LOOP    12
#define RADIUS  0.003333
#define ANGLE   0.261799
#define DIVISOR 25

#define OFFSET  0.002

float _OutputWidth;
float _OutputAspectRatio;

float _Progress;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_markup (float2 uv : TEXCOORD1) : COLOR
{
   float2 grain = float2 (1.0, _OutputAspectRatio) * SIZE / _OutputWidth;
   float2 xy1 = round ((uv - 0.5) / grain) * grain;
   float2 xy2 = frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + _Progress) * RAND_3);

   float4 china = float2 (frac (sin (dot (xy1, float2 (RAND_1, RAND_2)) + xy2.x) * RAND_3), 1.0).xxxy;
   float4 offset, retval = 0.0.xxxx;

   china = lerp (retval, china, Texture * TEX);
   china = min (china + Depth, 1.0);

   xy1 = ((uv - 0.5) / 4.0) + 0.5; xy2 = 1.0 - xy1;

   float line_width = WIDTH / _OutputWidth;
   float prog_2, prog_1, prog_0 = uv.x;

   xy1.x  = uv.x + uv.y + line_width;
   xy2.x  = uv.x + uv.y - line_width;

   if (Amount < 0.5) {
      offset = tex2D (BgdSampler, xy1);

      prog_1 = offset.r + offset.g + offset.b;
      offset = tex2D (FgdSampler, 1.0 - xy1);
      prog_1 = DISP * (prog_1 + offset.r + offset.g + offset.b) / _OutputWidth;

      offset = tex2D (BgdSampler, xy2);
      prog_2 = offset.r + offset.g + offset.b;
      offset = tex2D (FgdSampler, 1.0 - xy2);
   }
   else {
      offset = tex2D (FgdSampler, xy1);

      prog_1 = offset.r + offset.g + offset.b;
      offset = tex2D (BgdSampler, 1.0 - xy1);
      prog_1 = DISP * (prog_1 + offset.r + offset.g + offset.b) / _OutputWidth;

      offset = tex2D (FgdSampler, xy2);
      prog_2 = offset.r + offset.g + offset.b;
      offset = tex2D (BgdSampler, 1.0 - xy2);
   }

   prog_1 = max (Amount - line_width - prog_1 + (uv.y * Tilt * TILT), 0.0);
   prog_2 = DISP * (prog_2 + offset.r + offset.g + offset.b) / _OutputWidth;
   prog_2 = min (Amount + line_width + prog_2 + (uv.y * Tilt * TILT), 1.0);

   if ((MarkType != R_L) && (prog_0 > prog_1) && (prog_0 < prog_2)) retval = float4 (china.rgb, 1.0);

   prog_1 = 1.0 - prog_1; prog_2 = 1.0 - prog_2;

   if ((MarkType != L_R) && (prog_0 > prog_2) && (prog_0 < prog_1)) retval = float4 (china.rgb, 1.0);

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 china  = tex2D (texSampler, uv);
   float4 retval = (Amount < 0.5) ? tex2D (FgdSampler, uv) : tex2D (BgdSampler, uv);

   if ((Amount != 0.0) && (Radius != 0.0)) {

      float2 xy, radius = float2 (1.0 - china.b, china.r + china.g) * Radius * RADIUS;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         china += tex2D (texSampler, uv + xy);
         china += tex2D (texSampler, uv - xy);
      }

      china /= DIVISOR;
   }

   return lerp (retval, china, china.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique chinagraph
{
   pass P_1
   < string Script = "RenderColorTarget0 = chinatex;"; >
   { PixelShader = compile PROFILE ps_markup (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

