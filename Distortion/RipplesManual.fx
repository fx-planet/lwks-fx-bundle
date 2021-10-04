// @Maintainer jwrl
// @Released 2021-08-30
// @Author schrauber
// @Created 2016-03-25
// @see https://www.lwks.com/media/kunena/attachments/6375/RippleManual_640.png

/**
 There are two related effects, "Ripples (automatic expansion)" and this version
 "Ripples (manual expansion)".  This is the simple version, which is the one to use
 when you want to control the wave expansion via keyframes. 
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RipplesManual.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Ripples (manual expansion)";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "Radiating ripples are produced under full user control";
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
	
float _Progress;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

SetTargetMode (FixInp, FgSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool enable_timing
<
	string Description = "Enable expansion setting";
> = true;


float expansionSetting
<
	string Description = "Expansion";
	float MinVal = 0;
	float MaxVal = 1;
> = 0.4;


float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;


float zoom_lin
<
	string Group = "waveform";
	string Description = "Wave depth";
	float MinVal = 0;
	float MaxVal = 1;
> = 0.3;

float Frequency
<
	string Group = "waveform";
	string Description = "Frequency";
	float MinVal = 0;
	float MaxVal = 1000;
> = 100;



float phase_shift
<
	string Group = "waveform";
	string Description = "Phase";
	float MinVal = -12;
	float MaxVal = 12;
> = 0;


bool pulsing
<
	string Group = "waveform";
	string Description = "Pulsation on";
> = false;

bool pulse_negative
<	
	string Group = "waveform";
	string Description = "Invert pulses";
> = false;

float speed
<
	string Description = "Wave dynamics";
	float MinVal = -5000;
	float MaxVal = 5000;
> = 100;

bool Flip_edge
<
	string Description = "Flip edge";
> = true;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 universal (float2 uv : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR 
{ 
   if (Overflow (uv)) return EMPTY;    // If we fall outside the original limits we don't see anything, so processing empty media is pointless - jwrl.

 float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
 float2 xy1 = XYc - xy;
 float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);

 float _distance = distance ((0.0).xx, pos_zoom) / _InputWidthNormalised;    // Partially corrects distance scale - jwrl
 float freq = Frequency;
 float phase = 0;
 float damping, distortion, duration, expansion, zoom;

 if ((pulsing) || (pulse_negative)) freq = Frequency /2;							// Frequency adjustment, when the waveform was changed. ___________German: Frequenzanpassung, wenn die Wellenfom geÃ¤ndert wurde.
 
 
 // ............ Effect without expansion rate...............

 if (!enable_timing) {
  zoom =0.05 * pow((zoom_lin * 2.4),3);  
  phase = (sin (phase_shift +  (_Progress * (speed*-1)) + (freq * _distance))) ;				// Create a wave.
  distortion = zoom * phase / _distance;									//  Wave height ____________ German: WellenhÃ¶he 
  distortion = distortion / (_distance + 2.86);									// WellenhÃ¶he distanzabhÃ¤ngige Einstellungen
  if (pulsing) distortion = sqrt(distortion) / 3;								// Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
  if (pulse_negative) distortion = sqrt(distortion) / -3;							// Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
 }else{


 // ............ Effect with expansion rate ...........
 
  damping = pow(expansionSetting * 3 , 3) + 0.696;		
  expansion = damping; 
                                                     
  zoom =pow((zoom_lin*0.001),2) / pow (expansion , 3.6); if (expansion < 0.7) zoom = 0;			//Optimize the zoom setting characteristic, and expansion characteristic of the wave. (partly determined by tests)
 									
  phase = (sin (phase_shift +  (_Progress * (speed*-1)) + (freq * _distance))) ;					// Create a wave.

	
  distortion = zoom * phase / (1 + _distance);								// Wave height  ___________German: WellenhÃ¶he 

  duration = pow(_distance , damping); 									// Time behavior of the wave ___________German: Zeitverhalten des Wellenlaufes
  distortion = distortion / (pow(duration,4) + 28561E-12);						//	  Wave height, time-dependent attenuation. (Mainly through experiments determined) ___________German:  WellenhÃ¶he, zeitabhÃ¤ngige DÃ¤mpfung. (Ã¼berwiegend durch Versuche ermittelt)

  if (pulsing) distortion = sqrt(distortion) / 3;								// Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
  if (pulse_negative) distortion = sqrt(distortion) / -3;							// Edit waveform ___________German:  Wellenfom Ã¤ndern (ggf. auch fÃ¼r Druckwelle geeignet?)
 }

 // ..........................................................


 xy1 = distortion * xy1 + xy;


 if (!Flip_edge && Overflow (xy1)) return EMPTY;

 return tex2D (FgSampler, xy1); 
} 

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (universal)
}

