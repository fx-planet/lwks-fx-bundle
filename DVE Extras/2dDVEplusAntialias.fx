// @Maintainer jwrl
// @Released 2020-04-12
// @Author schrauber
// @Author jwrl
// @Author Editshare
// @Created 2018-03-09
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_antialias_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_alpha_antialias.png
// @see https://www.lwks.com/media/kunena/attachments/6375/2D_DVE_antialias.mp4

/**
 This a 2D DVE that performs as the Editshare version does, but with some differences.
 The first is the obvious one that Fg, Bg and drop shadow alphas are passed through
 to the output.  The behaviour of the drop shadow is also different, and in this
 effect scales along with the foreground.  This is felt to be more logical behaviour
 when using the DVE to zoom an image up to full screen.

 Fixed in this version of the 2D DVE is the half texel offset error which can appear as
 a transparent one pixel boundary between the image and the drop shadow under the right
 conditions in the Editshare version.  Also fixed is the fact the shadow is calculated
 from Fg frame boundaries regardless of whether they are opaque or not.  Finally, the
 presence of the drop shadow will not punch a transparent hole in the composite when used
 with downstream blend and DVE effects as the Editshare version does.

 Added in this version is a means of smoothing edges, overcoming the aliasing and jitter
 caused by simple GPU processing of a zoom.  Because of the considerably increased GPU
 load this adds, the simple GPU setting bypasses all edge blurring, thus performing in
 the same way as the original effect.  The stronger the setting the heavier the GPU load.

 The antialias component is courtesy of schrauber, and is much appreciated.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVEplusAntialias.fx
//
// This 2D DVE was originally built to emulate the Editshare original but respect alpha
// channels in both foreground and background, as well any produced by the drop shadow.
// That effect was called "2D DVE plus alpha" and was highly successful.  It is still
// available in that form but will ultimately be withdrawn, since this effect at its
// simplest provides exactly the same functionality.
//
// The original effect was locked at 14 October 2018 and it is that version that forms
// the basis for this effect.  The creation date shown here is the date that schruaber
// first posted his initial amendment.  That version was considered by scrauber to be
// a prototype, and while posted on the Lightworks forums, was never actually released.
//
// Initial version schrauber 2020-03-09:
// Added proportional pre-blurring to "2D DVE plus alpha" to improve smoothness of zooms
// and slow position changes.  That blur only applied to scaling factors less than zero.
//
// Modified jwrl 2020-03-11:
// Modified ps_crop() to simplify the code slightly.
// Placed ps_crop() ahead of ps_blur() in the execution order so that any hard edges it
// produces will be processed by ps_blur().
// As a result, changed the mirror addressing of s_Foreground back to default.
//
// Modified jwrl 2020-03-12:
// Removed the necessity to explicitly pass the shader value to ps_blur().
// Added the ability to apply a non-linear proportional edge blur for zoom scaling factors
// greater than 1.
// Changed the layout of the parameters so that SetTechnique is ahead of the sacle factors.
// Finalised the labelling of the SetTechnique parameters.
// If both X and Y scale factors are unity we exit the blur routine immediately.
// Removed the redundant aspect ratio correction from the blur scale factor.  While it is
// necessary for a standard blur, it should not be necessary here.
//
// Modified jwrl 2020-04-12:
// Added linear filtering to s_Foreground to improve antialiasing.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE plus antialias";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A 2D DVE with antialiasing that fully respects foreground, background and drop shadow transparency";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Inp : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
   Texture   = <Fg>;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler2D s_Background = sampler_state { Texture = <Bg>; };

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Mirror;   // Mirror addressing deals with the edges of the frame better
   AddressV  = Mirror;   // when applying the pre-blur filtering to fix scaling issues.
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

int SetTechnique
<
   string Description = "Proportional smoothing/antialiasing";
   string Group = "Scale";
   string Enum = "None,Subtle,Medium,Strong";
> = 1;

float MasterScale
<
   string Description = "Master";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float cropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float cropT
<
   string Description = "Top";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float cropR
<
   string Description = "Right";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float cropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowTransparency
<
   string Description = "Transparency";
   string Group = "Shadow";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float ShadowXOffset
<
   string Description = "X Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowYOffset
<
   string Description = "Y Offset";
   string Group = "Shadow";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY        0.0.xxxx    // Transparent black
#define SHADOW_SCALE 0.2         // Carry over from Editshare original to match unity scaling

float _OutputAspectRatio;
float _OutputWidth;
float _OutputHeight;

// Blur definitions

#define POWER        0.375       // Changes blur profile when scaling up
#define TEXEL        float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight)
#define DIVIDE       9.0
#define DIAG_SCALE   0.707107    // Sine/cosine 45 degrees correction for diagonal blur

// A radius change factor of 1.71 between different passes for minimal blur

#define RADIUS_1a    0.5
#define RADIUS_2a    0.2924
#define RADIUS_3a    0.171
#define RADIUS_4a    0.1

// Similar to the above radius settings with the same factor (1.71), but the values
// are all scaled by 0.521 to reduce sampler interference during the pre-blur process

#define RADIUS_1b    0.2605
#define RADIUS_2b    0.1523
#define RADIUS_3b    0.0891
#define RADIUS_4b    0.0521

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   // This version of the crop is slightly simplified so that one less exit is taken
   // The penalty is that whether it's needed or not retval is loaded with Fg.  By
   // placing crop() ahead of the blur routine cropped edges will also be softened.

   float4 retval = tex2D (s_Foreground, uv);

   float2 xy = 1.0.xx - uv;

   if ((uv.x < cropL) || (xy.x < cropR) || (uv.y < cropT) || (xy.y < cropB) || (retval.a <= 0.0))
      return EMPTY;

   return retval;
}

float4 ps_blur (float2 uv : TEXCOORD1, uniform float passRadius) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   // Calculate the individual X and Y scale factors

   float2 scale = float2 (MasterScale * XScale, MasterScale * YScale);

   // If the scale factor is 1.0 in both X and Y we exit the blur routine

   if ((scale.x == 1.0) && (scale.y == 1.0)) return retval;

   // Set blur strength for X and Y depending on scaling settings.  When zooming
   // in blur is applied with a non-linear profile, which minimises the blur for
   // very slight changes in size.  It is also necessary to set X and Y values
   // independently because it's possible to change each individually.

   scale.x = (scale.x > 1.0) ? pow (scale.x, POWER) : 1.0 / clamp (scale.x, 1e-6 , 1.0);
   scale.y = (scale.y > 1.0) ? pow (scale.y, POWER) : 1.0 / clamp (scale.y, 1e-6 , 1.0);
   scale  -= 1.0.xx;

   // The scale factor now varies from zero for 1.0x to 1,000,000 for 0.0x.
   // That last figure will never be used because no image would ever be seen.

   float2 radius = TEXEL * scale * passRadius;

   // We now do a single step standard box blur, vertical blur first

   retval += tex2D (s_Input, float2 (uv.x, uv.y + radius.y));
   retval += tex2D (s_Input, float2 (uv.x, uv.y - radius.y));

   // Then the horizontal blur

   retval += tex2D (s_Input, float2 (uv.x + radius.x, uv.y));
   retval += tex2D (s_Input, float2 (uv.x - radius.x, uv.y));

   // The box blur is now repeated with the coordinates rotated by 45 degrees

   radius *= DIAG_SCALE;
   retval += tex2D (s_Input, uv + radius);
   retval += tex2D (s_Input, uv - radius);

   // Inverting the Y vector changes the rotation to -45 degrees from reference

   radius.y = -radius.y;
   retval += tex2D (s_Input, uv + radius);
   retval += tex2D (s_Input, uv - radius);

   retval /= DIVIDE;

   return retval;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   // First set up the scaling and position for the foreground.  This all done with
   // float2's for efficiency.  In Cg one float2 operation is better than 2 floats.

   float2 scale = float2 (XScale, YScale) * MasterScale;
   float2 pos = float2 (CentreX, 1.0 - CentreY) - (scale * 0.5);
   float2 uv = (xy1 - pos) / scale;

   // The modified and cropped foreground is now recovered.  Legal address ranges
   // must be checked to prevent unexpected cross-platform issues.

   float4 retval = ((uv.x < 0.0) || (uv.x > 1.0) || (uv.y < 0.0) || (uv.y > 1.0))
                 ? EMPTY : tex2D (s_Input, uv);

   // Now recover the scaled foreground alpha, offset by the shadow amount.  This
   // allows us to add the foreground drop shadow only where Fg alpha is present.

   uv -= float2 (ShadowXOffset, ShadowYOffset * _OutputAspectRatio) * SHADOW_SCALE;

   float alpha = ((uv.x < 0.0) || (uv.x > 1.0) || (uv.y < 0.0) || (uv.y > 1.0))
                 ? 0.0 : tex2D (s_Input, uv).a;

   // Mix the foreground alpha with the shadow alpha to produce the composite.

   retval.a = max (retval.a, alpha * (1.0 - ShadowTransparency));

   // The foreground is mixed into the background and we're done.

   return lerp (tex2D (s_Background, xy2), retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVEplusAntialias_0
{
   pass P_0 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_crop (); }

   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}


technique DVEplusAntialias_1
{
   pass P_0   < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_crop (); }

   pass P_1_1 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_2a); }
   pass P_1_2 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_1a); }

   pass P_2   { PixelShader = compile PROFILE ps_main (); }
}

technique DVEplusAntialias_2
{
   pass P_0   < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_crop (); }

   pass P_1_1 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_2b); }
   pass P_1_2 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_1b); }
   pass P_1_3 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_2a); }
   pass P_1_4 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_1a); }

   pass P_2   { PixelShader = compile PROFILE ps_main (); }
}


technique DVEplusAntialias_3
{
   pass P_0   < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_crop (); }

   pass P_1_1 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_4b); }
   pass P_1_2 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_3b); }
   pass P_1_3 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_2b); }
   pass P_1_4 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_1b); }
   pass P_1_5 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_4a); }
   pass P_1_6 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_3a); }
   pass P_1_7 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_2a); }
   pass P_1_8 < string Script = "RenderColorTarget0 = Inp;"; >
      { PixelShader = compile PROFILE ps_blur (RADIUS_1a); }

   pass P_2   { PixelShader = compile PROFILE ps_main (); }
}

