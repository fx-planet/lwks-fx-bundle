// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// De-interlace.fx written by jwrl March 14 2017.
// @Author jwrl
// @Created "March 14 2017"
//
// A fourth try at a de-interlace tool, still doing it the way
// that avoids Lightworks' pixel height bug.  It provides seven
// modes of operation: odd field only, even field only, blended
// fields, odd field interpolated, even field interpolated and
// two blended interpolated modes.
//
// Depending on the mode chosen, this can require a maximum of
// three passes to execute.  On that basis it shouldn't place
// too much of a strain on any modern GPU.
//
// This version is designed to work only on interlaced media of
// the same resolution as the project, and to then export only
// at that resolution.  If this is not the case severe "combing"
// can result which may be impossible to remove.
//
// Because it relies on the capability of the GPU to do pixel
// interpolation some tests were felt necessary before release.
// It has been tested with an Nvidia Quadro K2200, an Nvidia
// GTX-970 G1 and an Nvidia GTX-960.  On those it was reliable
// in all the interpolated modes with 1080i media in a 1080p
// project.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "De-interlace";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp;

texture Odds  : RenderColorTarget;
texture Evens : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture   = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler OddSampler = sampler_state
{
   Texture   = <Odds>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler EvenSampler = sampler_state
{
   Texture   = <Evens>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "De-interlace method";
   string Enum = "Odd fields only,Even fields only,Field blending,Interpolate odd fields,Interpolate even fields,Blended interpolated A,Blended interpolated B";
> = 5;

//--------------------------------------------------------------//
// Declarations and definitions
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_odd_fields (float2 uv : TEXCOORD1) : COLOR
{
   float pix_y = _OutputAspectRatio / _OutputWidth;

   if (round (frac (uv.y / (pix_y * 2.0))) > 0.5)
      return tex2D (InpSampler, uv);

   float2 xy = float2 (uv.x, max (uv.y - pix_y, 0.0));

   return tex2D (InpSampler, xy);
}

float4 ps_even_fields (float2 uv : TEXCOORD1) : COLOR
{
   float pix_y = _OutputAspectRatio / _OutputWidth;

   if (round (frac (uv.y / (pix_y * 2.0))) < 0.5)
      return tex2D (InpSampler, uv);

   float2 xy = float2 (uv.x, min (uv.y + pix_y, 1.0));

   return tex2D (InpSampler, xy);
}

float4 ps_blend (float2 uv : TEXCOORD1) : COLOR
{
   return (tex2D (OddSampler, uv) + tex2D (EvenSampler, uv)) / 2.0;
}

float4 ps_interp_odd (float2 uv : TEXCOORD1) : COLOR
{
   float half_pix_y = _OutputAspectRatio / (2.0 * _OutputWidth);

   if (round (frac (uv.y / (half_pix_y * 4.0))) < 0.5) {    // Even fields
      return tex2D (EvenSampler, uv);
   }

   float2 xy = float2 (uv.x, max (uv.y - half_pix_y, 0.0));

   return tex2D (EvenSampler, xy);
}

float4 ps_interp_even (float2 uv : TEXCOORD1) : COLOR
{
   float half_pix_y = _OutputAspectRatio / (2.0 * _OutputWidth);

   if (round (frac (uv.y / (half_pix_y * 4.0))) >= 0.5) {   // Odd fields
      return tex2D (OddSampler, uv);
   }

   float2 xy = float2 (uv.x, min (uv.y + half_pix_y, 1.0));

   return tex2D (OddSampler, xy);
}

float4 ps_main_A (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy;
   float4 retval;

   float half_pix_y = _OutputAspectRatio / (2.0 * _OutputWidth);

   if (round (frac (uv.y / (half_pix_y * 4.0))) < 0.5) {    // Even fields
      xy = float2 (uv.x, min (uv.y + half_pix_y, 1.0));
      retval = tex2D (OddSampler, xy);
   }
   else {                                                   // Odd fields
      xy = float2 (uv.x, max (uv.y - half_pix_y, 0.0));
      retval = tex2D (EvenSampler, xy);
   }

   return (retval + tex2D (InpSampler, uv)) / 2.0;
}

float4 ps_main_B (float2 uv : TEXCOORD1) : COLOR
{
   float half_pix_y = _OutputAspectRatio / (2.0 * _OutputWidth);

   float2 xy1 = float2 (uv.x, max (uv.y - half_pix_y, 0.0));
   float2 xy2 = float2 (uv.x, min (uv.y + half_pix_y, 1.0));

   return (tex2D (OddSampler, xy1) + tex2D (EvenSampler, xy1) +
           tex2D (OddSampler, xy2) + tex2D (EvenSampler, xy2)) / 4.0;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique oddFields
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_odd_fields ();
   }
}

technique evenFields
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_even_fields ();
   }
}

technique blendFields
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Odds;";
   >
   {
      PixelShader = compile PROFILE ps_odd_fields ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Evens;";
   >
   {
      PixelShader = compile PROFILE ps_even_fields ();
   }

   pass pass_three
   {
      PixelShader = compile PROFILE ps_blend ();
   }
}

technique interpolateOdd
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Evens;";
   >
   {
      PixelShader = compile PROFILE ps_even_fields ();
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_interp_odd ();
   }
}

technique interpolateEven
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Odds;";
   >
   {
      PixelShader = compile PROFILE ps_odd_fields ();
   }

   pass pass_two
   {
      PixelShader = compile PROFILE ps_interp_even ();
   }
}

technique blendInterpolateA
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Odds;";
   >
   {
      PixelShader = compile PROFILE ps_odd_fields ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Evens;";
   >
   {
      PixelShader = compile PROFILE ps_even_fields ();
   }

   pass pass_three
   {
      PixelShader = compile PROFILE ps_main_A ();
   }
}

technique blendInterpolateB
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = Odds;";
   >
   {
      PixelShader = compile PROFILE ps_odd_fields ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = Evens;";
   >
   {
      PixelShader = compile PROFILE ps_even_fields ();
   }

   pass pass_three
   {
      PixelShader = compile PROFILE ps_main_B ();
   }
}

