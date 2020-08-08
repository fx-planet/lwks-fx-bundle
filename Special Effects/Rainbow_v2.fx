// @Maintainer jwrl
// @Released 2020-08-08
// @Author jwrl
// @Created 2020-08-08
// @see https://www.lwks.com/media/kunena/attachments/6375/RainbowV2_640.png

/**
 This is a special effect that generates single and double rainbows.  The blue end of the
 spectrum has adjustable falloff to give a fade out that is more like what happens in
 nature.   The rainbow is blended with the background image using a modified screen blend
 that varies in strength according to the inverse of the background brightness.  It can
 also be varied in intensity.  The default crop settings will produce a 90 degree arc
 (plus and minus 45 degrees), but can be adjusted to whatever angle you need over a 180
 degree range.

 The secondary rainbow is inverted and inherits Amount, Radius, Width, Falloff and Origin
 from the primary rainbow.  The master Amount is modified by the secondary rainbow Amount,
 and master Radius and Width are modified by the secondary rainbow Offset.  The secondary
 rainbow's crop angle and feathering are independent of the master rainbow settings.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow_v2.fx
//
// This effect was built after experience with the earlier rainbow effect, which tried to
// be all things to all people, and in my opinion, failed dismally.  This was written with
// a new user interface and re-engineered mask generation.  The previous version produced
// unexpected hard edges under the right conditions as the masks were rotated.  This uses
// a more brute force method of generating the masks.
//
// However this means that the now pointless extra pass used to generate a second mask for
// the double rainbow could be dropped.  Another side effect was that providing independent
// mask softness adjustment for the outer rainbow was possible.  Because the moondog effect
// was dropped it is now possible to specify the crop angles in degrees because we were no
// longer sharing glow parameters with crop angles.  Finally, we have improved the mask edge
// softness and opacity falloff over brighter backgrounds.
//
// Version history:
//
// Built jwrl 2020-08-08.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rainbow v2";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Red and yellow and pink and green, purple and orange and blue ...";
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
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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
> = 0.5;

float Radius
<
   string Description = "Radius";
   float MinVal = 0.1;
   float MaxVal = 2.0;
> = 0.5;

float Width
<
   string Description = "Width";
   float MinVal = 0.05;
   float MaxVal = 0.4;
> = 0.125;

float Falloff
<
   string Description = "Falloff";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_X
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_Y
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float L_angle
<
   string Group = "Primary rainbow cropping";
   string Description = "Left angle";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float L_soft
<
   string Group = "Primary rainbow cropping";
   string Description = "Left softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float R_angle
<
   string Group = "Primary rainbow cropping";
   string Description = "Right angle";
   float MinVal = -180.0;
   float MaxVal = 0.0;
> = -45.0;

float R_soft
<
   string Group = "Primary rainbow cropping";
   string Description = "Right softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float Amount_2
<
   string Group = "Secondary rainbow offsets";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Offset
<
   string Group = "Secondary rainbow offsets";
   string Description = "Displacement";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float L_angle_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Left angle";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float L_soft_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Left softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

float R_angle_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Right angle";
   float MinVal = -180.0;
   float MaxVal = 0.0;
> = -45.0;

float R_soft_2
<
   string Group = "Secondary rainbow cropping";
   string Description = "Right softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.175;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define INNER      true
#define OUTER      false

#define CIRCLE     0.7927904259
#define RADIUS     1.6666666667

#define EMPTY      0.0.xxxx

#define HUE        float3(1.0, 2.0 / 3.0, 1.0 / 3.0)
#define LUMA       float3(0.2989, 0.5866, 0.1145)

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if (max (xy.x, xy.y) > 0.5) return EMPTY;

   return tex2D (s_Sampler, uv);
}

float fn_get_mask (float2 xy, bool inner)
{
   if (xy.y >= 1.0 - Pos_Y) return 0.0;

   float c, l, r, s, L, R;

   if (inner) {
      L = -L_angle;
      R = -R_angle;
      l = L_soft;
      r = -R_soft;
   }
   else {
      L = -L_angle_2;
      R = -R_angle_2;
      l = L_soft_2;
      r = -R_soft_2;
   }

   float a = radians (L);
   float b = radians (R - 180.0);

   float2 uv  = float2 (xy.x - Pos_X, xy.y + Pos_Y - 1.0);
   float2 xy1 = float2 (uv.x, (uv.y + (l * L / 450.0)) / _OutputAspectRatio) * 0.25;
   float2 xy2 = float2 (uv.x, (uv.y + (r * R / 450.0)) / _OutputAspectRatio) * 0.25;

   sincos (a, s, c);
   xy1 = mul (float2x2 (c, -s, s, c), xy1);
   sincos (b, s, c);
   xy2 = mul (float2x2 (-c, s, -s, -c), xy2);

   xy1.x += 0.5;
   xy2.x += 0.5;
   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   return inner ? 1.0 - max (fn_tex2D (s_Mask, xy1).g, fn_tex2D (s_Mask, xy2).a)
                : 1.0 - max (fn_tex2D (s_Mask, xy1).r, fn_tex2D (s_Mask, xy2).b);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mask (float2 uv : TEXCOORD0) : COLOR
{
   float Ls = L_soft * 0.1;
   float Ld = max (1e-10, Ls);
   float Rs = R_soft * 0.1;
   float Rd = max (1e-10, Rs);

   float4 retval = (uv.y >= Ls) ? 1.0.xxxx : uv.yyyy / Ld;

   retval.a = (uv.y >= Rs) ? 1.0 : uv.y / Rd;

   Ls = L_soft_2 * 0.1;
   Ld = max (1e-10, Ls);
   Rs = R_soft_2 * 0.1;
   Rd = max (1e-10, Rs);

   retval.r = (uv.y >= Ls) ? 1.0 : uv.y / Ld;
   retval.b = (uv.y >= Rs) ? 1.0 : uv.y / Rd;

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Input, uv);

   float2 xy = float2 (Pos_X - uv.x, 1.0 - uv.y - Pos_Y);

   float radius = max (1.0e-6, Radius);
   float width  = Width * radius;
   float inner  = radius * CIRCLE;
   float outer  = length (float2 (xy.x, xy.y / _OutputAspectRatio)) * RADIUS;
   float rainbw = saturate ((outer - inner) / width);
   float alpha  = saturate (2.0 - abs ((rainbw * 4.0) - 2.0));

   float4 Fgnd = saturate (((1.0 - rainbw) * 4.0 / 3.0) - 1.0 / 6.0).xxxx;

   Fgnd.rgb = saturate (abs (frac (saturate (Fgnd.g - 0.1).xxx + HUE) * 6.0 - 3.0) - 1.0.xxx);
   Fgnd.a   = lerp (alpha, alpha * rainbw, Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);
   Fgnd.a  -= 1.5 * dot (Bgnd.rgb, LUMA);

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount);
   Bgnd = lerp (Bgnd, Fgnd, fn_get_mask (uv, INNER));

   if (Amount_2 <= 0.0) return Bgnd;

   radius = (Offset * 0.8) + 1.2;
   width *= radius;
   inner *= radius;

   rainbw = saturate ((outer - inner) / width);
   alpha  = saturate (2.0 - abs ((rainbw * 4.0) - 2.0));

   Fgnd = saturate ((rainbw * 4.0 / 3.0) - 1.0 / 6.0).xxxx;

   Fgnd.rgb = saturate (abs (frac (saturate (Fgnd.g - 0.1).xxx + HUE) * 6.0 - 3.0) - 1.0.xxx);
   Fgnd.a   = lerp (alpha, alpha * (1.0 - rainbw), Falloff);
   Fgnd.rgb = Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb);
   Fgnd.a  -= 1.5 * dot (Bgnd.rgb, LUMA);

   Fgnd = saturate (Fgnd);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amount * Amount_2);

   return lerp (Bgnd, Fgnd, fn_get_mask (uv, OUTER));
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Rainbow_v2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Msk;"; > 
   { PixelShader = compile PROFILE ps_mask (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}

