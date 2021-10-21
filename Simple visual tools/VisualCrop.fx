// @Maintainer jwrl
// @Released 2021-10-21
// @Author gr00by
// @OriginalAuthor LWKS Software Ltd
// @Created 2016-11-26
// @see https://www.lwks.com/media/kunena/attachments/6375/vicrop_640.png

/**
 Based on the crop section of DVE.fx as created for Lightworks, this is a quick simple cropping
 tool that you can set up by dragging corner pins around on the screen.  In effects settings mode,
 move your mouse over your edit viewer and two diagonally opposing corner pins will appear.  Just
 click on them and drag and the crop will follow.  Done.  It's one of those "why did no-one think
 of this sooner" tools.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualCrop.fx
//
// Version history:
//
// Update 2021-10-21 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual crop";
   string Category    = "DVE";
   string SubCategory = "Simple visual tools";
   string Notes       = "This is a quick simple cropping tool that you can set up by dragging corner pins around on the screen";
   bool CanSize       = true;
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
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

float _OutputAspectRatio;

float _FgNormWidth = 1.0;
float _FgWidth  = 10.0;
float _FgHeight = 10.0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Description = "Top-Left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropTop
<
   string Description = "Top-Left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropRight
<
   string Description = "Bottom-Right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CropBottom
<
   string Description = "Bottom-Right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float croppedL = CropLeft;
   float croppedT = 1.0 - CropTop;
   float croppedR = CropRight;
   float croppedB = 1.0 - CropBottom;

   float4 Bgnd = tex2D (s_Background, uv);

   if ((uv.x < croppedL) || (uv.x > croppedR) || (uv.y < croppedT) || (uv.y > croppedB))
      return Bgnd;

   // Remember that the texCoords for Fg may overflow 0 -> 1 so we may have
   // transparency in our legally addressed s_Foreground.

   float4 Fgnd = tex2D (s_Foreground, uv);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VisualCrop
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 ExecuteShader (ps_main)
}

