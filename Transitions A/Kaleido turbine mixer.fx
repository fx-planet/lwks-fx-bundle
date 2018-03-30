//--------------------------------------------------------------
// From Schrauber revised for transitions.
// The transition effect is based on baopao's (and/or nouanda?)  "Kaleido".
// In  "Kaleido" - file were the following listed:
// Quote: ...................
// Kaleido   http://www.alessandrodallafontana.com/ 
// based on the pixel shader of: http://pixelshaders.com/ 
// corrected for HLSL by Lightworks user nouanda
// ..........................
//--------------------------------------------------------------
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido turbine mixer";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------
texture FG;
texture BG;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//


sampler FGSampler = sampler_state
{
   Texture = <FG>;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
   MAGFILTER = LINEAR;
   ADDRESSU  = MIRROR;
   ADDRESSV  = MIRROR;
};

sampler BGSampler = sampler_state
{
   Texture = <BG>;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
   MAGFILTER = LINEAR;
   ADDRESSU  = MIRROR;
   ADDRESSV  = MIRROR;

};



//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------

float amount
<
	string Description = "Amount";
	float MinVal = 0.0;
	float MaxVal = 1.0;
        float KF0    = 0.0;
        float KF1    = 1.0;
> = 0.5;

float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 2.00;
> = 1.0;

float PosX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float PosY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool fan
<
	string Description = "Fan";
> = true;

#pragma warning ( disable : 3571 )


//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------

// This function added to mimic the GLSL mod() function

float mod(float x, float y)
{
  return x - y * floor(x/y);
}


float4 main( float2 xy1 : TEXCOORD1 ) : COLOR 
{

     float4 color;                 // to output
     float scale = 1 - (1.8 * amount); 						// Phase 2, kaleido, tube (Z), strengthen
     float2 PosXY = float2 (PosX, 1.0 - PosY);
     float2 p = xy1-PosXY;
     float r = length(p);
     float a = atan2(p.y, p.x);  						// Changed from GLSL version - float a = atan(p.y, p.x)
     float amount_b = (amount - 0.4) *5; 

     float kaleido = amount * 50 + 0.1;						// Phase 1, kaleido,rotation, strengthen
     if (amount > 0.5 ) kaleido = 50.1 - (amount * 50);				// Phase 2, kaleido, rotation, weaken
     if (amount > 0.5 ) scale =  1.8 * (amount -0.5) + 0.1 ; 			// Phase 2, kaleido, tube (Z),  weaken

     float tau = 2.0 * 3.1416;
     a = mod(a, tau / kaleido);
     a = abs(a - tau / kaleido / 2);

 
     p = r * float2(cos(a), sin(a));  



     if(amount < 0.5) color = tex2D(FGSampler, (p/Zoom + PosXY)/scale);				// Kaleido phase 1a
     if((amount < 0.5) && (r <= amount_b)) color = tex2D(BGSampler, (p/Zoom + PosXY)/scale);	// Kaleido phase 1b (FB outside & BG inside)

     if(amount >= 0.5) color = tex2D(BGSampler, (p/Zoom + PosXY)/scale);			// Kaleido phase 2b
     if((amount >= 0.5) && (r > amount_b)) color = tex2D(FGSampler, (p/Zoom + PosXY)/scale);	// Kaleido phase 2a (FB outside & BG inside)

     if((a > amount) && (amount < 0.5) && (fan)) color = tex2D(FGSampler, xy1);			// Fan phase 1
     if((a > 1 - amount) && (amount > 0.5) && (fan)) color = tex2D(BGSampler, xy1);		// Fan phase 2
     return color;
}

technique SimpleTechnique
{
pass MainPass

   {
      PixelShader = compile PROFILE main();
   }

}




