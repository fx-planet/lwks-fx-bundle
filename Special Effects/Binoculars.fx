// @Maintainer jwrl
// @Released 2020-08-23
// @Author jwrl
// @Created 2020-08-23
// @see https://www.lwks.com/media/kunena/attachments/6375/Binoculars_640.png

/**
 This effect creates the classic binocular mask shape.  It can be adjusted from a simple
 circular or telescope-style effect, to separated circular masks.  The edge softness can
 be adjusted, and colour fringing can be applied to the edges as well.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Binoculars.fx
//
// Created jwrl 2020-08-23.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Binoculars";
   string Category    = "DVE";
   string SubCategory = "Special Effects";
   string Notes       = "Creates the classic binocular effect";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Msk : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

sampler s_Mask = sampler_state
{
   Texture   = <Msk>;
   AddressU  = Border;
   AddressV  = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Offset
<
   string Description = "L / R offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Softness
<
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Fringing
<
   string Description = "Edge fringing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define RADIUS  1.6666666667
#define FEATHER 0.05
#define FRINGE  0.0125
#define SIZE    2.5

#define CIRCLE  0.25

#define CENTRE  0.5.xx

#define WHITE   1.0.xxxx
#define EMPTY   0.0.xxxx

float _OutputAspectRatio; 

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_circle (float2 uv : TEXCOORD0) : COLOR
{
   float2 range = float2 (0.5 - uv.x - (Offset * 0.2), 0.5 - uv.y);

   float fthr   = max (0.02, Softness) * FEATHER;
   float edge   = CIRCLE - fthr;
   float radius = length (float2 (range.x, range.y / _OutputAspectRatio)) * RADIUS;

   fthr += fthr;

   return lerp (WHITE, EMPTY, saturate ((radius - edge) / fthr));
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = float2 (-abs (uv.x - 0.5), uv.y - 0.5) / (Size * SIZE);
   float2 xy2, xy3 = uv - CENTRE;
   float2 fringe = 1.0.xx - (float2 (1.0, _OutputAspectRatio) * Fringing * FRINGE);

   float offset = Offset * Size * 0.5;

   if (uv.x < 0.5) {
      xy3 = float2 ((xy3.x + offset) * fringe.x, xy3.y * fringe.y);
      xy2 = float2 (xy3.x * fringe.x, xy3.y * fringe.y);

      xy2.x -= offset;
      xy3.x -= offset;
   }
   else {
      xy3 = float2 ((xy3.x - offset) * fringe.x, xy3.y * fringe.y);
      xy2 = float2 (xy3.x * fringe.x, xy3.y * fringe.y);

      xy2.x += offset;
      xy3.x += offset;
   }

   xy1 += CENTRE;
   xy2 += CENTRE;
   xy3 += CENTRE;

   float Mask = tex2D (s_Mask, xy1).x;

   float2 RedGreen = float2 (tex2D (s_Input, xy2).r, tex2D (s_Input, xy3).g);

   float4 Fgnd = tex2D (s_Input, uv);

   Fgnd.rg = lerp (Fgnd.rg, RedGreen, saturate ((1.0 - Mask) * 4.0));

   return lerp (EMPTY, Fgnd, Mask);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Binoculars
{
   pass P_1
   < string Script = "RenderColorTarget0 = Msk;"; >
   {   PixelShader = compile PROFILE ps_circle (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

