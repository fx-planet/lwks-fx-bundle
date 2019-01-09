// @Maintainer jwrl
// @Released 2018-09-26
// @Author jwrl
// @Created 2016-01-23
// @see https://www.lwks.com/media/kunena/attachments/6375/SafeAreaAndXhatch_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Crosshatch.fx
//
// This safe area and cross hatch generator is entirely original work.  It has been
// generously commented so that anyone who wishes to do so may modify it as required.
// All "magic numbers" are defined immediately following the sampler declarations for
// easy access and adjustment.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Safe area and crosshatch";
   string Category    = "User";
   string SubCategory = "Broadcast";
   string Notes       = "This effect is probably now redundant, but is probably most useful for viewfinder simulations";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture safeArea  : RenderColorTarget;
texture gridLines : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler   = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler safeSampler = sampler_state {
   Texture = <safeArea>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler gridSampler = sampler_state {
   Texture = <gridLines>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_crosshatch (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;
   float pixVal, xLine_value, yLine_value, retval = 0.0;

   // Quit if the opacity is zero or we don't need to show the crosshatch pattern

   if (disableFgd || ((X_opacity == 0.0) && !disableBgd) || (showXhatch == DISABLED)) {
      return retval.xxxx;
   }

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

      pixVal = abs (xy.x - xLine_value);              // This is really the first part of a compare operation

      if (pixVal < Xval) { retval = 1.0; };           // If we fall inside the line width turn the pixel on

      // To get the y value we must allow for the aspect ratio.  This is a little complex because any scaling must be centred.

      yLine_value = (xLine_value - 0.5) * _OutputAspectRatio;
      yLine_value = clamp ((yLine_value + 0.5), 0.0, 1.0);

      // Repeat our line width boundary calculation from above.

      pixVal = abs (xy.y - yLine_value);

      if (pixVal < Yval) { retval = 1.0; };
   }

   return retval.xxxx;
}

float4 ps_safe_area (float2 uv : TEXCOORD1) : COLOR
{
   float4 i, o;
   float2 xy = uv;
   float4 retval = float2 (0.0, 1.0).xxxy;

   // Quit if the opacity is zero or the background is disabled

   if ((opacity == 0.0) && !disableBgd) return retval;

   float Yval = ((lineWeight * 5) + 1.0) * LN_SCALE_C;
   float Xval = Yval / _OutputAspectRatio;

   // Set this next test up here so that we don't need to repeatedly do it

   bool show4x3safe = show4x3 && !(_OutputAspectRatio < AR16x9) || (_OutputAspectRatio > AR16x9a);

   float Bot, L_L, L_R, R_L, R_R, Top;

   if (showAction) {

      // Skip this block if we don't need to show the centre 4x3 safe area

      if (safeMode == R95) { i = float4 (T_L_0_a, B_R_0_a, T_L_0, B_R_0); }
      else if (safeMode == RP218) { i = float4 (T_L_1_a, B_R_1_a, T_L_1, B_R_1); }
      else { i = float4 (T_L_2_a, B_R_2_a, T_L_2, B_R_2); }

      if (show4x3safe) {

         L_L = i.x - Xval;             // Left line outer edge
         L_R = i.x + Xval;             // Left line inner edge

         R_L = i.y - Xval;             // Right line inner edge
         R_R = i.y + Xval;             // Right line outer edge

         Top = i.z + Yval;             // Safe line upper end
         Bot = i.w - Yval;             // Safe line lower end

         // We show the 4x3 safe area as cyan.  Because it's done here this also
         // puts the 4x3 area behind the standard 16x9 display.

         if (((xy.x >= L_L) && (xy.x <= L_R)) || ((xy.x >= R_L) && (xy.x <= R_R))) {
            if ((xy.y >= Top) && (xy.y <= Bot)) { retval = float2 (0.5, 1.0).xyyy; }
         }
      }

      // Now we calculate the inner and outer rectangles for the real safe area.
      // After this i.x holds the leftmost inner edge, i.y the right, i.z the top,
      // and i.w the bottom.  The o parameter holds the outer edge equivalents.

      o.x = i.z - Xval;
      o.y = i.w + Xval;
      o.z = i.z - Yval;
      o.w = i.w + Yval;

      i.x = i.z + Xval;
      i.y = i.w - Xval;
      i.z += Yval;
      i.w -= Yval;

      // Work out what to display.  The line width is obtained by excluding the
      // i (inner) area from the o (outer) area.

      if (!(((xy.x >= i.x) && (xy.x <= i.y) && (xy.y >= i.z) && (xy.y <= i.w))
          || ((xy.x < o.x) || (xy.x > o.y) || (xy.y < o.z) || (xy.y > o.w)))) {

         if (xy.x < i.x) { retval = (1.0).xxxx; }
         else if (xy.x > i.y) { retval = (1.0).xxxx; }

         if (xy.y < i.z) { retval = (1.0).xxxx; }
         else if (xy.y > i.w) { retval = (1.0).xxxx; }
      }
   }

   if (showTitle) {

      // This is a duplicate of the routine used to show action safe, above.
      // These two aren't done as a function for reasons of speed of execution.

      if (safeMode == LEGACY) { i = float4 (T_L_3_a, B_R_3_a, T_L_3, B_R_3); }
      else { i = float4 (T_L_2_a, B_R_2_a, T_L_2, B_R_2); }

      if (show4x3safe) {

         L_L = i.x - Xval;
         L_R = i.x + Xval;
         R_L = i.y - Xval;
         R_R = i.y + Xval;
         Top = i.z + Yval;
         Bot = i.w - Yval;

         if (((xy.x >= L_L) && (xy.x <= L_R)) || ((xy.x >= R_L) && (xy.x <= R_R))) {
            if ((xy.y >= Top) && (xy.y <= Bot)) { retval = float2 (0.5, 1.0).xyyy; }
         }
      }

      o.x = i.z - Xval;
      o.y = i.w + Xval;
      o.z = i.z - Yval;
      o.w = i.w + Yval;
      i.x = i.z + Xval;
      i.y = i.w - Xval;
      i.z += Yval;
      i.w -= Yval;

      if (!(((xy.x >= i.x) && (xy.x <= i.y) && (xy.y >= i.z) && (xy.y <= i.w))
          || ((xy.x < o.x) || (xy.x > o.y) || (xy.y < o.z) || (xy.y > o.w)))) {

         if (xy.x < i.x) { retval = (1.0).xxxx; }
         else if (xy.x > i.y) { retval = (1.0).xxxx; }

         if (xy.y < i.z) { retval = (1.0).xxxx; }
         else if (xy.y > i.w) { retval = (1.0).xxxx; }
      }
   }

   // Now check to see if we show the centre cross

   if (showCentre) {

      float H_size  = SIZE_X / _OutputAspectRatio;       // Calculate the horizontal size

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

      if (((xy.x >= i.x) && (xy.x <= i.y) && (xy.y >= i.z) && (xy.y <= i.w)) ||
         ((xy.x >= o.x) && (xy.x <= o.y) && (xy.y >= o.z) && (xy.y <= o.w))) { retval = (1.0).xxxx; }
   }

   // Finally show the 4x3 frame boundary if needed.  This goes on top in red.

   if (show4x3safe) {

      L_L = L_4_3 - Xval;              // Left line outer edge
      L_R = L_4_3 + Xval;              // Left line inner edge
      R_L = R_4_3 - Xval;              // Right line inner edge
      R_R = R_4_3 + Xval;              // Right line outer edge

      if (((xy.x >= L_L) && (xy.x <= L_R)) || ((xy.x >= R_L) && (xy.x <= R_R))
         && (xy.y >= 0.0) && (xy.y <= 1.0)) retval = float2 (0.5, 1.0).yxxy;
      }

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 original, overlay_1, overlay_2;
   float2 xy = uv;
   float Slevel, Xlevel;

   // If the foreground is disabled we either show the background video or we show black.

   if (disableFgd) return disableBgd ? float2 (0.0, 1.0).xxxy : tex2D (FgSampler, xy);

   // If the background is disabled we show black or white, depending on the crosshatch polarity
   // Otherwise we get the background video and set the opacity values.

   if (disableBgd) {
      original = (showXhatch == SUBTRACT) ? 1.0 : 0.0;
      Slevel = 0.5;
      Xlevel = 1.0;
    }
   else {
      original = tex2D (FgSampler, xy);
      Slevel = opacity;
      Xlevel = X_opacity;
    }

   // Now we calculate the crosshatch overlay.  Only do this if opacity isn't zero and crosshatch isn't disabled.

   if ((Xlevel > 0.0) && (showXhatch != DISABLED)) {

      overlay_1 = tex2D (gridSampler, xy);                           // Recover the crosshatch pattern
      overlay_2  = lerp ((0.0).xxxx, overlay_1, Xlevel);             // The level setting is applied at this point

      // This produces the actual crosshatch submaster, whether add, subtract or difference

      if (showXhatch == DIFFERENCE) { original = abs (original - overlay_2); }
      else original = clamp (((showXhatch == SUBTRACT) ? original - overlay_2 : original + overlay_2), 0.0, 1.0);
   }

   // This is the safe area display routine.  Only do it if the safe area opacity isn't zero.

   if (Slevel > 0.0) {

      overlay_1  = tex2D (safeSampler, xy);                          // Recover the safe area display
      overlay_2  = lerp ((0.0).xxxx, overlay_1, Slevel);

      if (showSafeArea == DIFFERENCE) { original = abs (original - overlay_2); }
      else original = clamp (((showSafeArea == SUBTRACT) ? original - overlay_2 : original + overlay_2), 0.0, 1.0);
   }

   original.a = 1.0;                                                 // Ensure that the alpha channel isn't zero

   return original;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Crosshatch
{
   pass P_1
   < string Script = "RenderColorTarget0 = gridLines;"; >
   { PixelShader = compile PROFILE ps_crosshatch (); }

   pass P_2
   < string Script = "RenderColorTarget0 = safeArea;"; >
   { PixelShader = compile PROFILE ps_safe_area (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
