// @Maintainer jwrl
// @Released 2021-10-07
// @Author khaver
// @Created 2013-12-04
// @see https://www.lwks.com/media/kunena/attachments/6375/WarpedStretch_640.png

/**
 This effect applies distortion to a region of the frame, and is intended for use as a means
 of helping handle mixed aspect ratio media.  It was designed to do the 4:3 to 16:9 warped
 stretch we all hate having to do.  You can set the range of the inner area that is not warped
 and set the outer limits at the edges of the crop.

 It defaults to a 4:3 image in a 16:9 frame, but since a "Strength" slider is provided it can
 be used for other purposes as well.  Note that because of its intended purpose of correcting
 aspect ratios it destroys resolution independence.  What leaves the effect is the size and
 aspect ratio of the sequence that it's used in.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WarpedStretch.fx
//
// Version history:
//
// Update 2021-10-07 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Corrected creation date.
// Changed subcategory.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.  This effect now functions correctly when used with all
// current and previous Lightworks versions.
//
// Added subcategory for LW14 - jwrl Feb 18 2017.
//
// Cross platform conversion by jwrl May 1 2016.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Warped Stretch";
   string Category    = "DVE";
   string SubCategory = "Repair tools";
   string Notes       = "This effect is intended for use as a means of helping handle mixed aspect ratio media";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, InputSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Grid
<
   string Description = "Show grid";
> = true;

bool Stretch
<
   string Description = "Stretch";
> = false;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ILX
<
   string Description = "Inner Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.42;

float ILY
<
   string Description = "Inner Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float IRX
<
   string Description = "Inner Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.58;

float IRY
<
   string Description = "Inner Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OLX
<
   string Description = "Outer Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float OLY
<
   string Description = "Outer Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ORX
<
   string Description = "Outer Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.875;

float ORY
<
   string Description = "Outer Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 main1 (float2 uv : TEXCOORD2) : COLOR
{
   float4 color;

   if (!Stretch) color = tex2D (InputSampler, uv);
   else {
      float delt, fact, stretchr = 1.0 - IRX;
      float sourcel = ILX - OLX;
      float sourcer = (ORX - IRX) / stretchr;

      float2 xy = uv;
      float2 norm = uv;
      float2 outp = uv;

      if (uv.x >= IRX) {
         norm.x =  IRX + ((uv.x - IRX) * sourcer);
         delt = (uv.x - IRX) / stretchr;
         fact = cos (radians (delt * 90.0));
         xy.x = ORX - ((1.0 - uv.x) * fact * sourcer);
      }

      if (uv.x <= ILX) {
         norm.x = xy.x = ILX - ((ILX - uv.x) * sourcel / ILX);
         delt = (ILX - uv.x) / ILX;
         fact = cos (radians (delt * 90.0));
         xy.x = OLX + (uv.x * fact * sourcel / ILX);
      }
   
      outp.x = lerp (norm.x, xy.x, Strength);

      color = Overflow (outp) ? BLACK : tex2D (InputSampler, outp);
   }

   if (Grid
   && ((uv.x >= ILX - 0.0008 && uv.x <= ILX + 0.0008)
   ||  (uv.x >= IRX - 0.0008 && uv.x <= IRX + 0.0008)
   ||  (uv.x >= OLX - 0.0008 && uv.x <= OLX + 0.0008)
   ||  (uv.x >= ORX - 0.0008 && uv.x <= ORX + 0.0008))) color = float4 (1.0, 0.0, 0.0, color.a);

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique NoStretchTechnique
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (main1)
}

