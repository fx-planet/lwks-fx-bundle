// @Maintainer jwrl
// @Released 2021-10-28
// @Author khaver
// @Created 2013-02-14
// @see https://www.lwks.com/media/kunena/attachments/6375/CCHelper2_640.png

/**
 CC Helper (Colour Correction Helper) is designed to provide up to six user selected
 reference colour patches.  Individual colour patches can be turned off if you need
 fewer than six and you can change the colour patches to gradients if you wish.  The
 colour value range of the patches can be switched to 100% meaning that the selected
 colour will be scaled so that the highest of the RGB channels will become 100%.  You
 can also slide the bars up and down over the video to clear areas that you need to
 see, and optional RGB level meters can be laid over individual colour patches.

 Add the effect to a clip, select the pixels you want to check and select "Display
 Bars".  When using the colour picker, you can click and drag to select a rectangular
 region.  The resultant colour will be the average of the selected pixels.  Then add
 a Colour Correction effect to the chain and adjust using CC Helper to assist.

 NOTE:  This effect "works with" resolution independence in that it overrides it.  If
 that is not it can become impossible to accurately position the sample points.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CChelper.fx
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to work with LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "CC Helper";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Provides up to six user selectable reference colour patches";
   bool CanSize       = false;
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define ONE_SIXTH   0.1667
#define TWO_SIXTH   0.3333
#define THREE_SIXTH 0.5
#define FOUR_SIXTH  0.6667
#define FIVE_SIXTH  0.8333

#define CONST_00    0.755
#define CONST_01    0.75
#define CONST_02    0.25
#define CONST_03    0.245

#define CONST_11    0.1128    // ONE_SIXTH - (ONE_SIXTH * 0.3233)
#define CONST_12    0.0539    // ONE_SIXTH - (ONE_SIXTH * 0.6767)
#define CONST_13    0.0741    // ONE_SIXTH - (ONE_SIXTH * 0.5556)
#define CONST_14    0.0556    // ONE_SIXTH - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_15    0.0926    // ONE_SIXTH - (ONE_SIXTH * 0.4444)
#define CONST_16    0.1111    // ONE_SIXTH - (ONE_SIXTH * TWO_SIXTH)

#define CONST_21    0.2794    // TWO_SIXTH - (ONE_SIXTH * 0.3233)
#define CONST_22    0.2206    // TWO_SIXTH - (ONE_SIXTH * 0.6767)
#define CONST_23    0.2407    // TWO_SIXTH - (ONE_SIXTH * 0.5556)
#define CONST_24    0.2222    // TWO_SIXTH - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_25    0.2593    // TWO_SIXTH - (ONE_SIXTH * 0.4444)
#define CONST_26    0.2778    // TWO_SIXTH - (ONE_SIXTH * TWO_SIXTH)

#define CONST_31    0.4461    // THREE_SIXTH - (ONE_SIXTH * 0.3233)
#define CONST_32    0.3872    // THREE_SIXTH - (ONE_SIXTH * 0.6767)
#define CONST_33    0.4074    // THREE_SIXTH - (ONE_SIXTH * 0.5556)
#define CONST_34    0.3889    // THREE_SIXTH - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_35    0.4259    // THREE_SIXTH - (ONE_SIXTH * 0.4444)
#define CONST_36    0.4444    // THREE_SIXTH - (ONE_SIXTH * TWO_SIXTH)

#define CONST_41    0.6128    // FOUR_SIXTH - (ONE_SIXTH * 0.3233)
#define CONST_42    0.5539    // FOUR_SIXTH - (ONE_SIXTH * 0.6767)
#define CONST_43    0.5741    // FOUR_SIXTH - (ONE_SIXTH * 0.5556)
#define CONST_44    0.5556    // FOUR_SIXTH - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_45    0.5926    // FOUR_SIXTH - (ONE_SIXTH * 0.4444)
#define CONST_46    0.6111    // FOUR_SIXTH - (ONE_SIXTH * TWO_SIXTH)

#define CONST_51    0.7794    // FIVE_SIXTH - (ONE_SIXTH * 0.3233)
#define CONST_52    0.7206    // FIVE_SIXTH - (ONE_SIXTH * 0.6767)
#define CONST_53    0.7407    // FIVE_SIXTH - (ONE_SIXTH * 0.5556)
#define CONST_54    0.7222    // FIVE_SIXTH - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_55    0.7593    // FIVE_SIXTH - (ONE_SIXTH * 0.4444)
#define CONST_56    0.7778    // FIVE_SIXTH - (ONE_SIXTH * TWO_SIXTH)

#define CONST_61    0.9461    // 1.0 - (ONE_SIXTH * 0.3233)
#define CONST_62    0.8872    // 1.0 - (ONE_SIXTH * 0.6767)
#define CONST_63    0.9074    // 1.0 - (ONE_SIXTH * 0.5556)
#define CONST_64    0.8889    // 1.0 - (ONE_SIXTH * FOUR_SIXTH)
#define CONST_65    0.9259    // 1.0 - (ONE_SIXTH * 0.4444)
#define CONST_66    0.9444    // 1.0 - (ONE_SIXTH * TWO_SIXTH)

#define RED   float2(0.0, 1.0).yxxy
#define GREEN float2(0.0, 1.0).xyxy
#define BLUE  float2(0.0, 1.0).xxyy
#define BLACK float2(0.0, 1.0).xxxy

#define WHITE 1.0.xxxx

#define comax(COLOUR) (1.0 / max (max (COLOUR.r, COLOUR.g), COLOUR.b))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

DefineTarget (Bars1, BarSampler1);
DefineTarget (Bars2, BarSampler2);
DefineTarget (Bars3, BarSampler3);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Graph
<
   string Description = "Display Bars";
> = true;

bool Grad
<
   string Description = "Add Gradient";
> = false;

bool Full
<
   string Description = "100% Colors";
> = false;

float Slide
<
   string Description = "Move Bars";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.75;

bool bC1
<
   string Description = "Show";
   string Group = "Color 1";
> = true;

bool Lvl1
<
   string Description = "Display RGB Levels";
   string Group = "Color 1";
> = false;

float C1X
<
   string Description = "C1";
   string Group = "Color 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.08333;

float C1Y
<
   string Description = "C1";
   string Group = "Color 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

bool bC2
<
   string Description = "Show";
   string Group = "Color 2";
> = false;

bool Lvl2
<
   string Description = "Display RGB Levels";
   string Group = "Color 2";
> = false;

float C2X
<
   string Description = "C2";
   string Group = "Color 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float C2Y
<
   string Description = "C2";
   string Group = "Color 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

bool bC3
<
   string Description = "Show";
   string Group = "Color 3";
> = false;

bool Lvl3
<
   string Description = "Display RGB Levels";
   string Group = "Color 3";
> = false;

float C3X
<
   string Description = "C3";
   string Group = "Color 3";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.41667;

float C3Y
<
   string Description = "C3";
   string Group = "Color 3";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

bool bC4
<
   string Description = "Show";
   string Group = "Color 4";
> = false;

bool Lvl4
<
   string Description = "Display RGB Levels";
   string Group = "Color 4";
> = false;

float C4X
<
   string Description = "C4";
   string Group = "Color 4";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.58333;

float C4Y
<
   string Description = "C4";
   string Group = "Color 4";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

bool bC5
<
   string Description = "Show";
   string Group = "Color 5";
> = false;

bool Lvl5
<
   string Description = "Display RGB Levels";
   string Group = "Color 5";
> = false;

float C5X
<
   string Description = "C5";
   string Group = "Color 5";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float C5Y
<
   string Description = "C5";
   string Group = "Color 5";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

bool bC6
<
   string Description = "Show";
   string Group = "Color 6";
> = false;

bool Lvl6
<
   string Description = "Display RGB Levels";
   string Group = "Color 6";
> = false;

float C6X
<
   string Description = "C6";
   string Group = "Color 6";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.91667;

float C6Y
<
   string Description = "C6";
   string Group = "Color 6";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main1a (float2 uv : TEXCOORD2) : COLOR
{
   float4 cc5 = tex2D (s_Input, float2 (C5X, 1.0 - C5Y));
   float4 cc6 = tex2D (s_Input, float2 (C6X, 1.0 - C6Y));
   float4 graph = EMPTY;

   if (Full) {
      cc5 *= comax (cc5);
      cc6 *= comax (cc6);
   }

   if (bC6) {
      if (uv.x > FIVE_SIXTH) {
         graph = cc6;

         if (Grad) graph *= (uv.x - FIVE_SIXTH) / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl6) {
         if (uv.x <= CONST_61 && uv.x >= CONST_62 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;
         if (uv.x <= CONST_63 && uv.x >= CONST_64 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y) <= (cc6.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_65 && uv.x >= CONST_63 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc6.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_66 && uv.x >= CONST_65 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc6.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   if (bC5) {
      if (uv.x <= FIVE_SIXTH && uv.x > FOUR_SIXTH) {
         graph = cc5;

         if (Grad) graph *= (uv.x - FOUR_SIXTH) / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl5) {
         if (uv.x <= CONST_51 && uv.x >= CONST_52 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;
         if (uv.x <= CONST_53 && uv.x >= CONST_54 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc5.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_55 && uv.x >= CONST_53 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc5.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_56 && uv.x >= CONST_55 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc5.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   return graph;
}

float4 main1b (float2 uv : TEXCOORD2) : COLOR
{
   float4 cc3 = tex2D (s_Input, float2 (C3X, 1.0 - C3Y));
   float4 cc4 = tex2D (s_Input, float2 (C4X, 1.0 - C4Y));
   float4 graph = EMPTY;

   if (Full) {
      cc3 *= comax (cc3);
      cc4 *= comax (cc4);
   }

   if (bC4) {
      if (uv.x <= FOUR_SIXTH && uv.x > THREE_SIXTH) {
         graph = cc4;

         if (Grad) graph *= (uv.x - THREE_SIXTH) / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl4) {
         if (uv.x <= CONST_41 && uv.x >= CONST_42 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;
         if (uv.x <= CONST_43 && uv.x >= CONST_44 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc4.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_45 && uv.x >= CONST_43 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph =  (1.0 - uv.y <= cc4.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_46 && uv.x >= CONST_45 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc4.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   if (bC3) {

      if (uv.x <= THREE_SIXTH && uv.x > TWO_SIXTH) {
         graph = cc3;

         if (Grad) graph *= (uv.x - TWO_SIXTH) / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl3) {

         if (uv.x <= CONST_31 && uv.x >= CONST_32 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;

         if (uv.x <= CONST_33 && uv.x >= CONST_34 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc3.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_35 && uv.x >= CONST_33 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc3.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_36 && uv.x >= CONST_35 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc3.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   return graph;
}

float4 main1c (float2 uv : TEXCOORD2) : COLOR
{
   float4 cc1 = tex2D (s_Input, float2 (C1X, 1.0 - C1Y));
   float4 cc2 = tex2D (s_Input, float2 (C2X, 1.0 - C2Y));
   float4 graph = EMPTY;

   if (Full) {
      cc1 *= comax (cc1);
      cc2 *= comax (cc2);
   }

   if (bC2) {
      if (uv.x <= TWO_SIXTH && uv.x > ONE_SIXTH) {
         graph = cc2;

         if (Grad) graph *= (uv.x - 0.1667) / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl2) {
         if (uv.x <= CONST_21 && uv.x >= CONST_22 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;
         if (uv.x <= CONST_23 && uv.x >= CONST_24 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc2.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_25 && uv.x >= CONST_23 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc2.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_26 && uv.x >= CONST_25 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc2.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   if (bC1) {

      if (uv.x <= ONE_SIXTH) {
         graph = cc1;

         if (Grad) graph *= uv.x / ONE_SIXTH;

         graph.a = 1.0;
      }

      if (Lvl1) {
         if (uv.x <= CONST_11 && uv.x >= CONST_12 && uv.y <= CONST_00 && uv.y >= CONST_03) graph = BLACK;
         if (uv.x <= CONST_13 && uv.x >= CONST_14 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc1.r / 2.0 + CONST_03) ? RED : WHITE;
         }

         if (uv.x <= CONST_15 && uv.x >= CONST_13 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc1.g / 2.0 + CONST_03) ? GREEN : WHITE;
         }

         if (uv.x <= CONST_16 && uv.x >= CONST_15 && uv.y <= CONST_01 && uv.y >= CONST_02) {
            graph = (1.0 - uv.y <= cc1.b / 2.0 + CONST_03) ? BLUE : WHITE;
         }
      }
   }

   return graph;
}

float4 main2 (float2 uv : TEXCOORD2) : COLOR
{
   float4 orig = tex2D (s_Input, uv);
   float4 graph;

   float yy = uv.y;

   float2 xy;

   if (Graph) {
      if (Slide < 0.0) {
         yy = 1.0 - ((1.0 - uv.y) / (1.0 + Slide));
         xy = float2 (uv.x, yy);
         graph = tex2D (BarSampler1, xy) + tex2D (BarSampler2, xy) + tex2D (BarSampler3, xy);

         if (uv.y > abs (Slide) && graph.a >= 1.0) return graph;
      }
      else if (Slide > 0.0) {
         yy = uv.y / (1.0 - Slide);
         xy = float2 (uv.x, yy);
         graph = tex2D (BarSampler1, xy) + tex2D (BarSampler2, xy) + tex2D (BarSampler3, xy);

         if (uv.y < 1.0 - abs (Slide) && graph.a >= 1.0) return graph;
      }
      else {
         xy = float2 (uv.x, yy);
         graph = tex2D (BarSampler1, xy) + tex2D (BarSampler2, xy) + tex2D (BarSampler3, xy);

         if (graph.a >= 1.0) return graph;
      }
   }

   return orig;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CCHelper
{
   pass P_1 < string Script = "RenderColorTarget0 = Bars1;"; > ExecuteShader (main1a)
   pass P_2 < string Script = "RenderColorTarget0 = Bars2;"; > ExecuteShader (main1b)
   pass P_3 < string Script = "RenderColorTarget0 = Bars3;"; > ExecuteShader (main1c)
   pass P_4 ExecuteShader (main2)
}

