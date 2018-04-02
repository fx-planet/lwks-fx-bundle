// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Mix
//
// Copyright (c) EditShare EMEA.  All Rights Reserved
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "DissolveX";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//
int SetTechnique
<
   string Description = "Method";
   string Enum = "Default,Add,Subtract,Multiply,Screen,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Exclusion,Lighten,Darken,Average,Difference,Negation,Colour,Luminosity,Dodge,Color Burn,Linear Burn,Light Meld,Dark Meld,Reflect";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Ease
<
   string Description = "Timing";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

bool Swap
<
	string Description = "Swap layers";
> = false;

bool Bypass
<
	string Description = "Bypass";
> = false;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture fg;
texture bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{ 
   Texture   = <fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Pixel Shader
//--------------------------------------------------------------//
float BlendAddf(float base, float blend) {
	return min(base + blend, 1.0);
}
float BlendSubtractf(float base, float blend) {
	return max(base + blend - 1.0, 0.0);
}
float BlendLinearDodgef(float base, float blend) {
	return BlendAddf(base, blend);
}
float BlendLinearBurnf(float base, float blend) {
	return BlendSubtractf(base, blend);
}
float BlendLightenf(float base, float blend) {
	return max(blend, base);
}
float BlendDarkenf(float base, float blend) {
	return min(blend, base);
}
float BlendLinearLightf(float base, float blend) {
	return (blend < 0.5 ? BlendLinearBurnf(base, (2.0 * blend)) : BlendLinearDodgef(base, (2.0 * (blend - 0.5))));
}
float BlendScreenf(float base, float blend) {
	return 1.0 - ((1.0 - base) * (1.0 - blend));
}
float BlendOverlayf(float base, float blend) {
	return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
}
float BlendSoftLightf(float base, float blend) {
	return ((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)));
}
float BlendColorDodgef(float base, float blend) {
	return ((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0));
}
float  BlendColorBurnf(float base, float blend) {
	return ((blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0));
}
float BlendVividLightf(float base, float blend) {
	return ((blend < 0.5) ? BlendColorBurnf(base, (2.0 * blend)) : BlendColorDodgef(base, (2.0 * (blend - 0.5))));
}
float BlendPinLightf(float base, float blend) {
	return ((blend < 0.5) ? BlendDarkenf(base, (2.0 * blend)) : BlendLightenf(base, (2.0 *(blend - 0.5))));
}
float BlendHardMixf(float base, float blend) {
	return ((BlendVividLightf(base, blend) < 0.5) ? 0.0 : 1.0);
}
float BlendReflectf(float base, float blend) {
	return ((blend == 1.0) ? blend : min(base * base / (1.0 - blend), 1.0));
}

float EaseAmountf(float ease) {
   float amo, easy;
   if (Ease >= 0.0) {
	easy = (ease + 0.5) * 2.0;
	amo = pow(Amount,easy);
   }
   else {
	easy = abs(ease - 0.5) * 2.0;
	amo = 1.0-pow(1.0-Amount,easy);
   }
   return amo;
}

float4 Default_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
   if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
   
   return lerp( fg, bg, amo);
}
//--------------------------------------------------------------//
float4 Add_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
   
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = min(fg.r + bg.r, 1.0);
   ret.g = min(fg.g + bg.g, 1.0);
   ret.b = min(fg.b + bg.b, 1.0);
   ret.a = min(fg.a + bg.a, 1.0);
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Subtract_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
   
   ret.r = max(fg.r + bg.r - 1.0, 0.0);
   ret.g = max(fg.g + bg.g - 1.0, 0.0);
   ret.b = max(fg.b + bg.b - 1.0, 0.0);
   ret.a = max(fg.a + bg.a - 1.0, 0.0);
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Multiply_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   float4 ret = bg * fg;
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Screen_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = BlendScreenf(fg.r, bg.r);
   ret.g = BlendScreenf(fg.g, bg.g);
   ret.b = BlendScreenf(fg.b, bg.b);
   ret.a = BlendScreenf(fg.a, bg.a);
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Overlay_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }

   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendOverlayf(bg.r, fg.r);
	ret.g = BlendOverlayf(bg.g, fg.g);
	ret.b = BlendOverlayf(bg.b, fg.b);
	ret.a = BlendOverlayf(bg.a, fg.a);
   }
   else {
	ret.r = BlendOverlayf(fg.r, bg.r);
	ret.g = BlendOverlayf(fg.g, bg.g);
	ret.b = BlendOverlayf(fg.b, bg.b);
	ret.a = BlendOverlayf(fg.a, bg.a);
   }
      
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 SoftLight_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendSoftLightf(bg.r, fg.r);
	ret.g = BlendSoftLightf(bg.g, fg.g);
	ret.b = BlendSoftLightf(bg.b, fg.b);
	ret.a = BlendSoftLightf(bg.a, fg.a);
   }
   
   else {
	ret.r = BlendSoftLightf(fg.r, bg.r);
	ret.g = BlendSoftLightf(fg.g, bg.g);
	ret.b = BlendSoftLightf(fg.b, bg.b);
	ret.a = BlendSoftLightf(fg.a, bg.a);
   }

   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Hardlight_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }

   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendOverlayf(fg.r, bg.r);
	ret.g = BlendOverlayf(fg.g, bg.g);
	ret.b = BlendOverlayf(fg.b, bg.b);
	ret.a = BlendOverlayf(fg.a, bg.a);
   }
   else {
	ret.r = BlendOverlayf(bg.r, fg.r);
	ret.g = BlendOverlayf(bg.g, fg.g);
	ret.b = BlendOverlayf(bg.b, fg.b);
	ret.a = BlendOverlayf(bg.a, fg.a);
   }

   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Vividlight_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }

   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendVividLightf(bg.r, fg.r);
	ret.g = BlendVividLightf(bg.g, fg.g);
	ret.b = BlendVividLightf(bg.b, fg.b);
	ret.a = BlendVividLightf(bg.a, fg.a);
   }
   else {
	ret.r = BlendVividLightf(fg.r, bg.r);
	ret.g = BlendVividLightf(fg.g, bg.g);
	ret.b = BlendVividLightf(fg.b, bg.b);
	ret.a = BlendVividLightf(fg.a, bg.a);
   }

   ret = clamp(ret, 0.0, 1.0);
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Linearlight_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }

   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendLinearLightf(bg.r, fg.r);
	ret.g = BlendLinearLightf(bg.g, fg.g);
	ret.b = BlendLinearLightf(bg.b, fg.b);
	ret.a = BlendLinearLightf(bg.a, fg.a);
   }
   else {
	ret.r = BlendLinearLightf(fg.r, bg.r);
	ret.g = BlendLinearLightf(fg.g, bg.g);
	ret.b = BlendLinearLightf(fg.b, bg.b);
	ret.a = BlendLinearLightf(fg.a, bg.a);
   }
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Pinlight_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }

   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendPinLightf(bg.r, fg.r);
	ret.g = BlendPinLightf(bg.g, fg.g);
	ret.b = BlendPinLightf(bg.b, fg.b);
	ret.a = BlendPinLightf(bg.a, fg.a);
   }
   else {
	ret.r = BlendPinLightf(fg.r, bg.r);
	ret.g = BlendPinLightf(fg.g, bg.g);
	ret.b = BlendPinLightf(fg.b, bg.b);
	ret.a = BlendPinLightf(fg.a, bg.a);
   }
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Exclusion_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = fg.r + bg.r - (2.0 * fg.r * bg.r);
   ret.g = fg.g + bg.g - (2.0 * fg.g * bg.g);
   ret.b = fg.b + bg.b - (2.0 * fg.b * bg.b);
   ret.a = fg.a + bg.a - (2.0 * fg.a * bg.a);
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Lighten_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = BlendLightenf(fg.r, bg.r);
   ret.g = BlendLightenf(fg.g, bg.g);
   ret.b = BlendLightenf(fg.b, bg.b);
   ret.a = BlendLightenf(fg.a, bg.a);
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Darken_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = BlendDarkenf(fg.r, bg.r);
   ret.g = BlendDarkenf(fg.g, bg.g);
   ret.b = BlendDarkenf(fg.b, bg.b);
   ret.a = BlendDarkenf(fg.a, bg.a);
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Average_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret = ( fg + bg ) / 2.0;
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Difference_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = abs( fg.r - bg.r );
   ret.g = abs( fg.g - bg.g );
   ret.b = abs( fg.b - bg.b );
   ret.a = abs( fg.a - bg.a );
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Negation_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   ret.r = 1.0 - abs(1.0 - fg.r - bg.r );
   ret.g = 1.0 - abs(1.0 - fg.g - bg.g );
   ret.b = 1.0 - abs(1.0 - fg.b - bg.b );
   ret.a = 1.0 - abs(1.0 - fg.a - bg.a );
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Color_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 ret;
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   float dstY, srcCr, srcCb;

   // Calc source luminance but use dest colour..
   if (Swap) {
    dstY  = ( 0.257 * fg.r ) + ( 0.504 * fg.g ) + ( 0.098 * fg.b ) + 0.0625;
    srcCr = ( 0.439 * bg.r ) - ( 0.368 * bg.g ) - ( 0.071 * bg.b ) + 0.5;
    srcCb = ( -0.148 * bg.r ) -( 0.291 * bg.g ) + ( 0.439 * bg.b ) + 0.5;
   }
   else {
    dstY  = ( 0.257 * bg.r ) + ( 0.504 * bg.g ) + ( 0.098 * bg.b ) + 0.0625;
    srcCr = ( 0.439 * fg.r ) - ( 0.368 * fg.g ) - ( 0.071 * fg.b ) + 0.5;
    srcCb = ( -0.148 * fg.r ) -( 0.291 * fg.g ) + ( 0.439 * fg.b ) + 0.5;
   }

   // Convert to RGB..
   float YBit = 1.164 * ( dstY - 0.0625 );
   ret.r = ( YBit + 1.596*(srcCr - 0.5) );
   ret.g = ( YBit - 0.813*(srcCr - 0.5) - 0.391*(srcCb - 0.5) );
   ret.b = ( YBit + 2.018*(srcCb - 0.5) );
   ret.a = 1.0;

   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Luminosity_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 ret;
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   float srcY, dstCr, dstCb;

   // Calc source luminance but use dest colour..
   if (Swap) {
    srcY  = ( 0.257 * bg.r ) + ( 0.504 * bg.g ) + ( 0.098 * bg.b ) + 0.0625;
    dstCr = ( 0.439 * fg.r ) - ( 0.368 * fg.g ) - ( 0.071 * fg.b ) + 0.5;
    dstCb = ( -0.148 * fg.r ) -( 0.291 * fg.g ) + ( 0.439 * fg.b ) + 0.5;
   }
   else {
    srcY  = ( 0.257 * fg.r ) + ( 0.504 * fg.g ) + ( 0.098 * fg.b ) + 0.0625;
    dstCr = ( 0.439 * bg.r ) - ( 0.368 * bg.g ) - ( 0.071 * bg.b ) + 0.5;
    dstCb = ( -0.148 * bg.r ) -( 0.291 * bg.g ) + ( 0.439 * bg.b ) + 0.5;
   }

   // Convert to RGB..
   float YBit = 1.164 * (srcY - 0.0625);
   ret.r = ( YBit + 1.596*(dstCr - 0.5) );
   ret.g = ( YBit - 0.813*(dstCr - 0.5) - 0.391*(dstCb - 0.5) );
   ret.b = ( YBit + 2.018*(dstCb - 0.5) );
   ret.a = 1.0;

   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 Dodge_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   float srcY, dstCr, dstCb;

   if (Swap) {
	ret.r = BlendColorDodgef(bg.r, fg.r);
	ret.g = BlendColorDodgef(bg.g, fg.g);
	ret.b = BlendColorDodgef(bg.b, fg.b);
	ret.a = BlendColorDodgef(bg.a, fg.a);
   }
   else {
	ret.r = BlendColorDodgef(fg.r, bg.r);
	ret.g = BlendColorDodgef(fg.g, bg.g);
	ret.b = BlendColorDodgef(fg.b, bg.b);
	ret.a = BlendColorDodgef(fg.a, bg.a);
   }
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 CBurn_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
   if (Swap) {
	ret.r = BlendColorBurnf(bg.r, fg.r);
	ret.g = BlendColorBurnf(bg.g, fg.g);
	ret.b = BlendColorBurnf(bg.b, fg.b);
	ret.a = BlendColorBurnf(bg.a, fg.a);
   }
   else {
	ret.r = BlendColorBurnf(fg.r, bg.r);
	ret.g = BlendColorBurnf(fg.g, bg.g);
	ret.b = BlendColorBurnf(fg.b, bg.b);
	ret.a = BlendColorBurnf(fg.a, bg.a);
   }
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 LBurn_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
  
	ret.r = BlendSubtractf(fg.r, bg.r);
	ret.g = BlendSubtractf(fg.g, bg.g);
	ret.b = BlendSubtractf(fg.b, bg.b);
	ret.a = BlendSubtractf(fg.a, bg.a);
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}
//--------------------------------------------------------------//
float4 LMeld_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
   
   if (!Swap) {
	if (((fg.r + fg.g + fg.b)/3.0) + amo > 1.0) ret = bg;
	else ret = fg;
   }
   else {
	if (((bg.r + bg.g + bg.b)/3.0) + amo > 1.0) ret = bg;
	else ret = fg;
   }
   
   return ret;
}
//--------------------------------------------------------------//
float4 DMeld_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
   
   if (!Swap) {
	if (1.0-((fg.r + fg.g + fg.b)/3.0) + amo > 1.0) ret = bg;
	else ret = fg;
   }
   else {
	if (1.0-((bg.r + bg.g + bg.b)/3.0) + amo > 1.0) ret = bg;
	else ret = fg;
   }
   
   return ret;
}
//--------------------------------------------------------------//
float4 Reflect_main( float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2 ) : COLOR
{
   float4 fg = tex2D( FgSampler, xy1 );
   float4 bg = tex2D( BgSampler, xy2 );
    if (Bypass) {
      if (Amount < 0.5) return fg;
      else return bg;
   }
   float4 ret;
    
   float amo = Amount;
   float ease;
   
   if (amo == 0.0) return fg;
   if (amo == 1.0) return bg;
   amo = EaseAmountf(Ease);
   
   if (Swap) {
	ret.r = BlendReflectf(bg.r, fg.r);
	ret.g = BlendReflectf(bg.g, fg.g);
	ret.b = BlendReflectf(bg.b, fg.b);
	ret.a = BlendReflectf(bg.a, fg.a);
   }
   else {
	ret.r = BlendReflectf(fg.r, bg.r);
	ret.g = BlendReflectf(fg.g, bg.g);
	ret.b = BlendReflectf(fg.b, bg.b);
	ret.a = BlendReflectf(fg.a, bg.a);
   }
   
   float4 cout;
   if (amo <= 0.5)  cout =  lerp( fg, ret, amo * 2.0 );
   if (amo > 0.5) cout =  lerp(ret,bg,(amo-0.5)*2.0);
   return cout;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//
technique Default    { pass SinglePass { PixelShader = compile PROFILE Default_main(); } }
technique Add        { pass SinglePass { PixelShader = compile PROFILE Add_main(); } }
technique Subtract   { pass SinglePass { PixelShader = compile PROFILE Subtract_main(); } }
technique Multiply   { pass SinglePass { PixelShader = compile PROFILE Multiply_main(); } }
technique Screen     { pass SinglePass { PixelShader = compile PROFILE Screen_main(); } }
technique Overlay    { pass SinglePass { PixelShader = compile PROFILE Overlay_main(); } }
technique SoftLight  { pass SinglePass { PixelShader = compile PROFILE SoftLight_main(); } }
technique Hardlight  { pass SinglePass { PixelShader = compile PROFILE Hardlight_main(); } }
technique Vividlight { pass SinglePass { PixelShader = compile PROFILE Vividlight_main(); } }
technique Linearlight{ pass SinglePass { PixelShader = compile PROFILE Linearlight_main(); } }
technique Pinlight   { pass SinglePass { PixelShader = compile PROFILE Pinlight_main(); } }
technique Exclusion  { pass SinglePass { PixelShader = compile PROFILE Exclusion_main(); } }
technique Lighten    { pass SinglePass { PixelShader = compile PROFILE Lighten_main(); } }
technique Darken     { pass SinglePass { PixelShader = compile PROFILE Darken_main(); } }
technique Average    { pass SinglePass { PixelShader = compile PROFILE Average_main(); } }
technique Difference { pass SinglePass { PixelShader = compile PROFILE Difference_main(); } }
technique Negation { pass SinglePass { PixelShader = compile PROFILE Negation_main(); } }
technique Color      { pass SinglePass { PixelShader = compile PROFILE Color_main(); } }
technique Luminosity { pass SinglePass { PixelShader = compile PROFILE Luminosity_main(); } }
technique Dodge      { pass SinglePass { PixelShader = compile PROFILE Dodge_main(); } }
technique CBurn      { pass SinglePass { PixelShader = compile PROFILE CBurn_main(); } }
technique LBurn      { pass SinglePass { PixelShader = compile PROFILE LBurn_main(); } }
technique LMeld      { pass SinglePass { PixelShader = compile PROFILE LMeld_main(); } }
technique DMeld      { pass SinglePass { PixelShader = compile PROFILE DMeld_main(); } }
technique Reflect { pass SinglePass { PixelShader = compile PROFILE Reflect_main(); } }
