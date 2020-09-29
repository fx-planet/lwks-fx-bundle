// @Maintainer jwrl
// @Released 2020-09-29
// @Author hugly
// @Author schrauber
// @Created 2019-08-09
// @see https://www.lwks.com/media/kunena/attachments/6375/EasyOverlay_640a.png

/**
 'Easy overlay' is a luminance keyer for overlays which show luminance for transparency,
 i.e. full transparency appears as solid black in the overlay.  The keyer works also on
 overlays with an alpha channel.  It reveals transparency using a black&white mask created
 from the foreground.

 The presets should work for most material of that kind with good looking results. If
 adjustments should be necessary, start with 'MaskGain'.  'Fg Lift' influences overall
 brightness of the overlay while preserving highlights.  'Fg Opacity' is e.g. useful to
 dissolve from/to the overlay using keyframes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EasyOverlay.fx
//
// Version history:
//
// Update 2020-09-29 jwrl.
// Revised header block.
//
// Modified 2020-06-15 jwrl:
// Removed redundant TEXCOORD3 input to oa_main().
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<  string EffectGroup = "GenericPixelShader";
   string Description = "Easy overlay";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "For overlays where luminance represents transparency";
> = 0;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float MaskGain
<  string Description = "Mask Gain";
   float MinVal = 0.0;
   float MaxVal = 6.0;
> = 3;

float FgLift
<  string Description = "Fg Lift";
   float MinVal =  -1.0;
   float MaxVal =   1.0;
> = 0;

float FgOpacity
<  string Description = "Fg Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;

sampler FgSampler   = sampler_state { Texture = <fg>; };
sampler BgSampler   = sampler_state { Texture = <bg>; };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 setFgLift (float4 x, float lift)
{  lift *= 0.55;
   float3 gamma1 = 1.0 - pow ( 1.0 - x.rgb, 1.0 / max ((1.0 - lift), 1E-6));
   float3 gamma2 =       pow ( x.rgb , 1.0      / max (lift + 1.0, 1E-6));
   float3 gamma = (lift > 0) ? gamma1 : gamma2;
   gamma =  saturate (lerp ( gamma , (gamma1 + gamma2) / 2.0, 0.8));
   return float4 (gamma.rgb, x.a);
}

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

float4 oa_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
   float4 mask = fg;  

   fg = setFgLift (fg, FgLift);
   float alpha = mask.a * min ((( mask.r + mask.g + mask.b ) / 3.0) * MaskGain, 1.0);		

   float4 ret = lerp( bg, fg, alpha * FgOpacity);
   ret.a = 1.0;
   return ret;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ps { pass SinglePass { PixelShader = compile PROFILE oa_main(); } }
