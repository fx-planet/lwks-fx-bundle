// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Added subcategory for LW14 - jwrl 18 February 2017.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Ripples (manual expansion)";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;



//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//


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


//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

float _OutputAspectRatio;
	
float _Progress;



#pragma warning ( disable : 3571 )




//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------


float4 universal (float2 xy : TEXCOORD1) : COLOR 
{ 

 float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
 float2 xy1 = XYc - xy;
 float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);
 float _distance = distance ((0.0).xx, pos_zoom);
 float expansion;
 float distortion;
 float duration;
 float damping;	
 float phase = 0;
 float zoom;
 float freq = Frequency;
 if ((pulsing) || (pulse_negative)) freq = Frequency /2;							// Frequency adjustment, when the waveform was changed. ___________German: Frequenzanpassung, wenn die Wellenfom geändert wurde.
 
 
 // ............ Effect without expansion rate...............

 if (!enable_timing) {
  zoom =0.05 * pow((zoom_lin * 2.4),3);  
  phase = (sin (phase_shift +  (_Progress * (speed*-1)) + (freq * _distance))) ;				// Create a wave.
  distortion = zoom * phase / _distance;									//  Wave height ____________ German: Wellenhöhe 
  distortion = distortion / (_distance + 2.86);									// Wellenhöhe distanzabhängige Einstellungen
  if (pulsing) distortion = sqrt(distortion) / 3;								// Edit waveform ___________German:  Wellenfom ändern (ggf. auch für Druckwelle geeignet?)
  if (pulse_negative) distortion = sqrt(distortion) / -3;							// Edit waveform ___________German:  Wellenfom ändern (ggf. auch für Druckwelle geeignet?)
 }else{


 // ............ Effect with expansion rate ...........
 
  damping = pow(expansionSetting * 3 , 3) + 0.696;		
  expansion = damping; 
                                                     
  zoom =pow((zoom_lin*0.001),2) / pow (expansion , 3.6); if (expansion < 0.7) zoom = 0;			//Optimize the zoom setting characteristic, and expansion characteristic of the wave. (partly determined by tests)
 									
  phase = (sin (phase_shift +  (_Progress * (speed*-1)) + (freq * _distance))) ;					// Create a wave.

	
  distortion = zoom * phase / (1 + _distance);								// Wave height  ___________German: Wellenhöhe 

  duration = pow(_distance , damping); 									// Time behavior of the wave ___________German: Zeitverhalten des Wellenlaufes
  distortion = distortion / (pow(duration,4) + 28561E-12);						//	  Wave height, time-dependent attenuation. (Mainly through experiments determined) ___________German:  Wellenhöhe, zeitabhängige Dämpfung. (überwiegend durch Versuche ermittelt)

  if (pulsing) distortion = sqrt(distortion) / 3;								// Edit waveform ___________German:  Wellenfom ändern (ggf. auch für Druckwelle geeignet?)
  if (pulse_negative) distortion = sqrt(distortion) / -3;							// Edit waveform ___________German:  Wellenfom ändern (ggf. auch für Druckwelle geeignet?)
 }

 // ..........................................................



 xy1 = distortion * xy1 + xy;



 if (!Flip_edge) {
  if ((xy1.x < 0.0) || (xy1.x > 1.0) || (xy1.y < 0.0) || (xy1.y > 1.0)) 
  return (0.0).xxxx;
 }

 return tex2D (FgSampler, xy1); 
} 

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE universal();
   }
}

