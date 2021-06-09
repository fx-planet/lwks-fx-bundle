// @Maintainer jwrl
// @Released 2021-06-09
// @Author jwrl
// @Created 2021-06-09
// @see https://www.lwks.com/media/kunena/attachments/6375/SafeAreaAndXhatch_640.png

/**
 This safe area and cross hatch generator can display EBU R 95, SMPTE RP 218, or legacy
 RP 218 safe area zones.  Now largely redundant with digital images, it is probably most
 useful for viewfinder simulations and the like.  Title safe, action safe and a centre
 cross can be selectively displayed, and center 4:3 can also be enabled if it is needed.

 Because the most likely use is as a viewfinder simulator this version has been rebuilt
 to ensure that the lines stay inside the active image area.  If it is necessary to lock
 the patterns to the sequence size and aspect ratio the frame lock effect (FrameLock.fx)
 should be applied first.

 The crosshatch pattern can be adjusted from 8 to 32 lines across the image width, and
 the line weight can be adjusted for best visibility.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SafeArea.fx
//
// This safe area and cross hatch generator is a rewrite of SafeAreaCrosshatch.fx to
// support resolution independence.  It has been generously commented so that anyone who
// wishes to do so may modify it as required.  All "magic numbers" are described for easy
// access and adjustment.
//
// Version history:
//
// Built 2021-06-09 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup    = "GenericPixelShader";
   string Description    = "Safe area and crosshatch";
   string Category       = "User";
   string SubCategory    = "Technical";
   string Notes          = "This effect is probably now redundant, but may be useful for viewfinder simulations";
   bool CanSize          = true;
   bool HasMinOutputSize = true;
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

#define EMPTY   0.0.xxxx
#define BLACK   float2(0.0, 1.0).xxxy
#define WHITE   1.0.xxxx

#define Illegal(XY) any(saturate (XY) - XY)
#define GetPixel(SHADER, XY) (Illegal (XY) ? EMPTY : tex2D (SHADER, XY))

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

#define DefineTarget(TEXTURE, SAMPLER) \
                                       \
 texture TEXTURE : RenderColorTarget;  \
                                       \
 sampler SAMPLER = sampler_state       \
 {                                     \
   Texture   = <TEXTURE>;              \
   AddressU  = ClampToEdge;            \
   AddressV  = ClampToEdge;            \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
}

#define CompileShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define SUBTRACT     1           // Subtract value used by showIt and showSafeArea
#define DIFFERENCE   2           // Difference value used by showIt and showSafeArea
#define DISABLED     3           // Disabled value used by showIt

#define MIN_LINES    8           // Minimum number of horizontal crosshatch lines
#define DFT_LINES    16          // Default number of horizontal crosshatch lines
#define MAX_LINES    32          // Maximum number of horizontal crosshatch lines

#define T_L_0        0.0325      // These two give an action safe area of 93.5%,
#define B_R_0        0.9675      // consistent with EBU R 95

#define T_L_1        0.035       // These two give an action safe area of 93%,
#define B_R_1        0.965       // consistent with SMPTE RP 218, 2007-2008

#define T_L_2        0.05        // These two give a title/action safe area of
#define B_R_2        0.95        // 90%, RP 218 - EBU R 95/legacy RP 218

#define T_L_3        0.1         // These two give a title safe area of 80%,
#define B_R_3        0.9         // consistent with legacy SMPTE RP 218

// The next group of definitions only used to produce the 4x3 equivalents

#define T_L_0_a      0.149375    // EBU R 95 action
#define B_R_0_a      0.850625

#define T_L_1_a      0.15125     // SMPTE RP 218 action
#define B_R_1_a      0.84875

#define T_L_2_a      0.1625      // Legacy action/SMPTE RP 218 title/EBU R 95 title
#define B_R_2_a      0.8375

#define T_L_3_a      0.2         // Legacy title
#define B_R_3_a      0.8

#define L_4_3        0.125       // These define the the edges of the 4:3
#define R_4_3        0.875       // area on a 16:9 frame

#define SIZE_X       0.075       // Boundary of centre cross - 15% of screen height

#define CENTRE_PT    0.5         // Centre point
#define LN_SCALE_C   0.000926    // Line weight scale factor - this has been arbitrarily chosen

#define R95          0
#define RP218        1
#define LEGACY       2

#define AR16x9       1.7         // 16x9 rounded down to give minimum identification
#define AR16x9a      1.8         // 16x9 rounded up to give maximum ID

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (Xhatch, s_Xhatch);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int safeMode
<
   string Group = "Safe area";
   string Description = "Standard";
   string Enum = "EBU R 95,SMPTE RP 218,Legacy RP 218";
> = RP218;

bool showCentre
<
   string Group = "Safe area";
   string Description = "Centre cross";
> = true;

bool showTitle
<
   string Group = "Safe area";
   string Description = "Title safe";
> = true;

bool showAction
<
   string Group = "Safe area";
   string Description = "Action safe";
> = true;

bool show4x3
<
   string Group = "Safe area";
   string Description = "Show central 4:3 zones (disabled if the aspect ratio is not 16:9)";
> = false;

int showSafeArea
<
   string Group = "Safe area";
   string Description = "Line display";
   string Enum = "Add,Subtract,Difference";
> = DIFFERENCE;

float opacity
<
   string Group = "Safe area";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float lineWeight
<
   string Group = "Safe area";
   string Description = "Line weight";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.20;

int showXhatch
<
   string Group = "Crosshatch";
   string Description = "Line display";
   string Enum = "Add,Subtract,Difference,Disabled";
> = DISABLED;

float X_opacity
<
   string Group = "Crosshatch";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float XhatchLines
<
   string Group = "Crosshatch";
   string Description = "Squares across";
   float MinVal = MIN_LINES;
   float MaxVal = MAX_LINES;
> = DFT_LINES;

float XhatchWeight
<
   string Group = "Crosshatch";
   string Description = "Line weight";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.20;

bool lockWeight
<
   string Group = "Crosshatch";
   string Description = "Control this line weight with the safe area line weight fader";
> = false;

bool disableFgd
<
   string Description = "Disable foreground";
> = false;

bool disableBgd
<
   string Description = "Disable background";
> = false;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_safe_area (float4 bgnd, float4 Bounds, float2 xy, float X, float Y, bool show4x3)
{
   float Bot, L_L, L_R, R_L, R_R, Top;

   float4 i, o, overlay = bgnd;

   if (show4x3) {

      L_L = Bounds.x - X;              // Left line outer edge
      L_R = Bounds.x + X;              // Left line inner edge

      R_L = Bounds.y - X;              // Right line inner edge
      R_R = Bounds.y + X;              // Right line outer edge

      Top = Bounds.z + Y;              // Safe line upper end
      Bot = Bounds.w - Y;              // Safe line lower end

      // We show the 4x3 safe area as cyan.  Because it's done here this also puts the
      // 4x3 area behind the standard 16x9 display.

      if (((xy.x >= L_L) && (xy.x <= L_R)) || ((xy.x >= R_L) && (xy.x <= R_R))) {
         if ((xy.y >= Top) && (xy.y <= Bot)) { overlay = float2 (0.5, 1.0).xyyy; }
      }
   }

   // Now we calculate the inner and outer rectangles for the real safe area.  After this
   // i.x holds the leftmost inner edge, i.y the right, i.z the top, and i.w the bottom.
   // The o parameter holds the outer edge equivalents.

   o.x = Bounds.z - X;
   o.y = Bounds.w + X;
   o.z = Bounds.z - Y;
   o.w = Bounds.w + Y;

   i.x = Bounds.z + X;
   i.y = Bounds.w - X;
   i.z = Bounds.z + Y;
   i.w = Bounds.w - Y;

   // Work out what to display.  The line width is obtained by excluding the i (inner)
   // area from the o (outer) area.

   if (!(((xy.x >= i.x) && (xy.x <= i.y) && (xy.y >= i.z) && (xy.y <= i.w))
       || ((xy.x < o.x) || (xy.x > o.y) || (xy.y < o.z) || (xy.y > o.w)))) {

      if (xy.x < i.x) { overlay = WHITE; }
      else if (xy.x > i.y) { overlay = WHITE; }

      if (xy.y < i.z) { overlay = WHITE; }
      else if (xy.y > i.w) { overlay = WHITE; }
   }

   return overlay;
}

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crosshatch (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float pixVal, xLine_value, yLine_value, xHatch = 0.0;
   float Xlevel;

   float4 retval, Bgnd = disableBgd ? BLACK : GetPixel (s_Input, uv1);

   // If the background is disabled we show black or white, depending on the crosshatch polarity
   // Otherwise we get the background video and set the opacity values.

   if (disableBgd) {
      Bgnd = (showXhatch == SUBTRACT) ? WHITE : EMPTY;
      Xlevel = 1.0;
    }
   else Xlevel = X_opacity;

   // Quit if the opacity is zero or we don't need to show the crosshatch pattern

   if (disableFgd || (X_opacity == 0.0) || (showXhatch == DISABLED)) return Bgnd;

   // Now we calculate the crosshatch overlay.  Only do this if opacity isn't zero and crosshatch isn't disabled.

   if ((Xlevel > 0.0) && (showXhatch != DISABLED)) {

      // Calculate the horizontal and vertical line weights

      float Yval = (((lockWeight ? lineWeight : XhatchWeight) * 5) + 1.0) * LN_SCALE_C;
      float Xval = Yval / _OutputAspectRatio;

      float xLines = ceil (XhatchLines);                 // Get the integer value of the number of lines
      float xLine_increment = 1.0 / xLines;              // Calculate the percentage increment to achieve that
      float halfInc = xLine_increment / 2;               // Use this to offset lines so they stay centred

      bool oddLines = (fmod (xLines, 2.0) > 0.25);       // We set up this boolean here so we don't calculate it inside the loop

      for (int i = 0; i <= MAX_LINES; i++) {             // The loop executes a fixed amount to resolve a Windows compatibility issue.
         xLine_value = xLine_increment * i;              // The alternative would have been to build a unique Windows-specific version.

         if (oddLines) {                                 // If there are an odd number of lines offset them by half the line spacing
            xLine_value = clamp ((xLine_value - halfInc), 0.0, 1.0);
         }

         pixVal = abs (uv0.x - xLine_value);             // This is really the first part of a compare operation

         if (pixVal < Xval) { xHatch = 1.0; };           // If we fall inside the line width turn the pixel on

         // To get the y value we must allow for the aspect ratio.  This is a little complex because any scaling must be centred.

         yLine_value = (xLine_value - 0.5) * _OutputAspectRatio;
         yLine_value = clamp ((yLine_value + 0.5), 0.0, 1.0);

         // Repeat our line width boundary calculation from above.

         pixVal = abs (uv0.y - yLine_value);

         if (pixVal < Yval) { xHatch = 1.0; };
      }

      float4 overlay_1 = xHatch.xxxx;                       // Recover the crosshatch pattern
      float4 overlay_2 = lerp (EMPTY, overlay_1, Xlevel);   // The level setting is applied at this point

      // This produces the actual crosshatch submaster, whether add, subtract or difference

      if (showXhatch == DIFFERENCE) { retval = abs (Bgnd - overlay_2); }
      else retval = clamp (((showXhatch == SUBTRACT) ? Bgnd - overlay_2 : Bgnd + overlay_2), 0.0, 1.0);
   }

   retval.a = Bgnd.a;

   return retval;
}

float4 ps_main (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Bgnd = GetPixel (s_Xhatch, uv2);

   float Slevel = (disableBgd) ? 0.5 : opacity;

   // This is the safe area display routine.  Only do it if the safe area opacity isn't zero.

   if (!disableFgd && (opacity > 0.0) && (Slevel > 0.0)) {

      float Yval = ((lineWeight * 5) + 1.0) * LN_SCALE_C;
      float Xval = Yval / _OutputAspectRatio;

      // Set this next test up here so that we don't need to do it repeatedly

      bool show4x3safe = show4x3 && !(_OutputAspectRatio < AR16x9) || (_OutputAspectRatio > AR16x9a);

      float L_L, L_R, R_L, R_R;

      float4 i, overlay = BLACK;

      if (showAction) {

         // Skip this block if we don't need to show the centre 4x3 safe area

         i = (safeMode == R95)   ? float4 (T_L_0_a, B_R_0_a, T_L_0, B_R_0)
           : (safeMode == RP218) ? float4 (T_L_1_a, B_R_1_a, T_L_1, B_R_1)
                                 : float4 (T_L_2_a, B_R_2_a, T_L_2, B_R_2);

         overlay = fn_safe_area (overlay, i, uv0, Xval, Yval, show4x3safe);
      }

      if (showTitle) {

         i = (safeMode == LEGACY) ? float4 (T_L_3_a, B_R_3_a, T_L_3, B_R_3)
                                  : float4 (T_L_2_a, B_R_2_a, T_L_2, B_R_2);

         overlay = fn_safe_area (overlay, i, uv0, Xval, Yval, show4x3safe);
      }

      // Now check to see if we show the centre cross

      if (showCentre) {

         float H_size  = SIZE_X / _OutputAspectRatio;    // Calculate the horizontal size

         float4 o;

         // Calculate the horizontal component

         i.x = CENTRE_PT - H_size;        // Left
         i.y = CENTRE_PT + H_size;        // Right
         i.z = CENTRE_PT - Yval;          // Top
         i.w = CENTRE_PT + Yval;          // Bottom

         // Calculate the vertical component

         o.x = CENTRE_PT - Xval;          // Left
         o.y = CENTRE_PT + Xval;          // Right
         o.z = CENTRE_PT - SIZE_X;        // Top
         o.w = CENTRE_PT + SIZE_X;        // Bottom

         if (((uv0.x >= i.x) && (uv0.x <= i.y) && (uv0.y >= i.z) && (uv0.y <= i.w)) ||
            ((uv0.x >= o.x) && (uv0.x <= o.y) && (uv0.y >= o.z) && (uv0.y <= o.w))) { overlay = WHITE; }
      }

      // Finally show the 4x3 frame boundary if needed.  This goes on top in red.

      if (show4x3safe) {

         L_L = L_4_3 - Xval;              // Left line outer edge
         L_R = L_4_3 + Xval;              // Left line inner edge
         R_L = R_4_3 - Xval;              // Right line inner edge
         R_R = R_4_3 + Xval;              // Right line outer edge

         if (((uv0.x >= L_L) && (uv0.x <= L_R)) || ((uv0.x >= R_L) && (uv0.x <= R_R))
            && (uv0.y >= 0.0) && (uv0.y <= 1.0)) overlay = float2 (0.5, 1.0).yxxy;
         }

      float4 retval = lerp (EMPTY, overlay, Slevel);  // Recover the safe area display

      if (showSafeArea == DIFFERENCE) { retval = abs (Bgnd - retval); }
      else retval = clamp (((showSafeArea == SUBTRACT) ? Bgnd - retval : Bgnd + retval), 0.0, 1.0);

      Bgnd.rgb = retval.rgb;              // Preserve the alpha channel
   }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SafeArea
{
   pass P_1 < string Script = "RenderColorTarget0 = Xhatch;"; > CompileShader (ps_crosshatch)
   pass P_2 CompileShader (ps_main)
}

