// @Maintainer jwrl
// @Released 2021-08-30
// @Author schrauber
// @Created 2016-03-16
// @see https://www.lwks.com/media/kunena/attachments/6375/bulge-2018_640.png
// @see https://www.youtube.com/watch?v=IZToP0MrbZM

/**
 Bulge 2018 allows a variable area of the frame to have a concave or convex bulge applied.
 Optionally the background can have a radial distortion applied at the same time, or can
 be made black or transparent black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BulgeFx.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// My apologies for the code reformatting, schrauber.  I have always had trouble reading
// other people's code.  The problem is mine, not yours.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bulge 2018";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "This effect allows a variable area of the frame to have a concave or convex bulge applied";
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

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _InputWidthNormalised;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and shaders
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

SetTargetMode (FixInp, FgSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Zoom
<
   string Description = "Zoom";
   float MinVal = -3.0;
   float MaxVal = 3.0;
> = 1.0;

float Bulge_size
<
   string Group ="Bulge";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.25;

float AspectRatio
<
   string Group ="Bulge";
   string Description = "Aspect Ratio";
   float MinVal = 0.1;
   float MaxVal = 10.0;
> = 1.0;

float Angle
<
   string Group = "Bulge";
   string Description = "Angle";
   float MinVal = -3600.0;
   float MaxVal = 3600;
> = 0.0;

int Rotation
<
   string Description = "Rotation mode";
   string Enum = "Shape (Aspect ratio should not be 1),Only the bulge content,Bulge,Input texture";
> = 2;

int Mode
<
   string Description = "Environment of bulge";
   string Enum = "Original, Distorted, Black alpha 0, Black alpha 1";
> = 0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float Tsin, Tcos;     // Sine and cosine of the set angle.

   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 vcenter = uv - centre;    // Vector between Center and Texel

   // ------ Rotation of bulge dimensions. --------

   float angle = radians (-Angle);

   vcenter = float2 (vcenter.x * _OutputAspectRatio, vcenter.y);

   sincos (angle, Tsin , Tcos);

   // Correction Vector for recalculation of objects Dimensions.

   float2 Spin = float2 ((vcenter.x * Tcos - vcenter.y * Tsin), (vcenter.x * Tsin + vcenter.y * Tcos));

   Spin = float2 (Spin.x / _OutputAspectRatio, Spin.y );

   // SpinPixel is the rotated Texel position.

   float2 SpinPixel = Spin + centre;

   // ------ Bulge --------

   vcenter = centre - uv;

   if (Rotation == 1) Spin = vcenter;

   // Get corrected object radius.

   float corRadius = length (float2 (Spin.x / AspectRatio, (Spin.y / _OutputAspectRatio) * AspectRatio));
   float bulgeSize = Bulge_size * _InputWidthNormalised;    // Corrects Bulge_size scale - jwrl

   corRadius /= _InputWidthNormalised;    // Corrects corRadius scale - jwrl

   bool bulge = corRadius < bulgeSize;    // Saves on recalculation - jwrl

   if ((Mode == 3) && !bulge) return float4 (0.0.xxx, 1.0);
   if ((Mode == 2) && !bulge) return (0.0).xxxx;

   float distortion = ((Mode == 1) || bulge) ? Zoom * sqrt (sin (abs(bulgeSize - corRadius))) : 0.0;

   float2 xy = ((Rotation == 3) || ((Rotation == 2) && bulge) || ((Rotation == 1) && bulge))
             ? SpinPixel : uv;

   return GetPixel (FgSampler, (distortion * (centre - xy)) + xy);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Bulge
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (ps_main)
}

