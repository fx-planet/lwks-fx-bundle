// @Maintainer jwrl
// @Released 2018-10-14
// @Author jwrl
// @Author Editshare
// @Created 2018-10-07
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_alpha_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect DVE_alpha.fx
//
// This 2D DVE was built to emulate the Editshare original but respect alpha channels
// in both foreground and background, as well any produced by the drop shadow.  The
// original plan was to buffer the foreground with a premultiply to clean up any non-
// black transparent areas of the frame.  That was then to feed the original 2D DVE
// effect, but the end section of the original shader was to be modified to return the
// combined alphas of Fg, Bg and the drop shadow.
//
// That version was built and worked, but it felt a little clunky using the first pass
// to do what was really just a buffering operation.  The premultiply also felt a little
// excessive for what had to be achieved.  So pass one had the crop moved into it as
// well, and instead of premultiplying the video to blank any fully transparent areas a
// simple check for zero alpha was implemented.
//
// This meant that a total rewrite of the main shader was required.  It was no longer
// necessary to have the half texel adjustments of the original, and scaling became a
// great deal simpler, as did the position calculations.  Pretty much the only things
// in this code resembling the original effect now are the inputs and the parameters.
//
// It still performs as the Editshare version does, but with some differences.  The
// first is the obvious one that Fg, Bg and drop shadow alphas are passed to the
// output.  This has the side effect that any transparent areas of the background
// must also be blanked.  The drop shadow is also different, and now scales along
// with the foreground.  Unlike the Bg blanking, this was a deliberate choice.  It
// was felt to be more logical when using the DVE to zoom an image up to full screen.
//
// Fixed in this version of the 2D DVE is the half texel offset error which can
// appear as a transparent boundary between the image and the drop shadow under the
// right conditions in the Editshare version.  Also fixed is the fact the shadow is
// calculated from Fg frame boundaries regardless of whether they are opaque or not.
// Finally, the presence of the drop shadow will not punch a transparent hole in
// the composite when used with downstream blend and DVE effects.
//
// PS:  The creation date is an absolute fiction.  I cannot recall when I first did
// this, and it's been through too many modifications for me to track it.  That date
// is when I cleaned the code up and commented the source.  The release date is when
// I fully debugged the cleanup.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE plus alpha";
   string Category    = "DVE";
   string SubCategory = "User Effects";
   string Notes       = "A 2D DVE that fully respects foreground, background and drop shadow transparency";
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

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler2D s_Background = sampler_state { Texture = <Bg>; };

sampler s_Input = sampler_state
{
   Texture = <Inp>;
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crop (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = 1.0.xx - uv;

   if ((uv.x < cropL) || (xy.x < cropR) || (uv.y < cropT) || (xy.y < cropB)) return EMPTY;

   float4 retval = tex2D (s_Foreground, uv);

   if (retval.a <= 0.0) return EMPTY;

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

   uv -= float2 (ShadowXOffset, ShadowYOffset) * SHADOW_SCALE;

   float alpha = ((uv.x < 0.0) || (uv.x > 1.0) || (uv.y < 0.0) || (uv.y > 1.0))
                 ? 0.0 : tex2D (s_Input, uv).a;

   // Mix the foreground alpha with the shadow alpha to produce the composite.

   retval.a = max (retval.a, alpha * (1.0 - ShadowTransparency));

   // The background layer is now obtained and if transparent, set to empty.

   float4 Bgnd = tex2D (s_Background, xy2);

   if (Bgnd.a <= 0.0) Bgnd = EMPTY;

   // The foreground is mixed into the background and we're done.

   return lerp (Bgnd, retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVE_alpha
{
   pass P_1
   < string Script = "RenderColorTarget0 = Inp;"; > 
   { PixelShader = compile PROFILE ps_crop (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
