// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Bugfix by jwrl 14 July 2017 to correct an issue with Linux/
// Mac versions of the Lightworks effects compiler that caused
// the bars not to display on those platforms.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Color Bars";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

int SetTechnique
<
   string Description = "Aspect Ratio";
   string Enum = "HD,SD";
> = 0;

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


float4 PS_BarsHD( float2 uv : TEXCOORD0 ) : COLOR
{
	float v1 = 7.0f / 12.0f;
	float v2 = 2.0f / 3.0f;
	float v3 = 3.0f / 4.0f;
	float hd01 = 0.125;
	float hd17 = 0.75 / 7.0f;
	float hdb1 = hd17 * (3.0f/2.0f);
	float hdb2 = hd17 * 2.0f;
	float hdb3 = hd17 * (5.0f/6.0f);
	float hdb4 = hd17 * (1.0f/3.0f);
	if (uv.y > v1) {
		if (uv.y > v2) {
			if (uv.y > v3) {
				if (uv.x > hd01) {
					if (uv.x > hd01 + hdb1) {
						if (uv.x > hd01 + hdb1 + hdb2) {
							if (uv.x > hd01 + hdb1 + hdb2 + hdb3) {
								if (uv.x > 1.0f - hd01 - hd17 - (hdb4*4.0f)) {
									if (uv.x > 1.0f - hd01 - hd17 - (hdb4*3.0f)) {
										if (uv.x > 1.0f - hd01 - hd17 - (hdb4*2.0f)) {
											if (uv.x > 1.0f - hd01 - hd17 - hdb4) {
												if (uv.x > 1.0f - hd01 - hd17) {
													if (uv.x > 1.0f - hd01) {
														return float4(0.15,0.15,0.15,1);
													}
													return float4(0,0,0,1);
												}
												return float4(0.04,0.04,0.04,1);
											}
											return float4(0,0,0,1);
										}
										return float4(0.02,0.02,0.02,1);
									}
									return float4(0,0,0,1);
								}
								return float4(-0.02,-0.02,-0.02,1);
							}
							return float4(0,0,0,1);
						}
						return float4(1,1,1,1);
					}
					return float4(0,0,0,1);
				}
				return float4(0.15,0.15,0.15,1);			
			}
			if (uv.x > hd01) {
				if (uv.x > 1.0f - hd01) {
					return float4(1,0,0,1);
				}
				float color = (uv.x - hd01) * (1.0f / (0.875f-hd01));
				return float4(color,color,color,1);
			}
			return float4(1,1,0,1);
		}
		if (uv.x > hd01) {
			if (uv.x > hd01 + hd17) {
				if (uv.x > 1.0f - hd01) {
					return float4(0,0,1,1);
				}
				return float4(0.75,0.75,0.75,1);
			}
			return float4(0.75,0.75,0.75,1);
		}
		return float4(0,1,1,1);
	}
	if (uv.x > hd01) {
		if (uv.x > hd01 + hd17) {
			if (uv.x > hd01 + (hd17*2.0f)) {
				if (uv.x > hd01 + (hd17*3.0f)) {
					if (uv.x > hd01 + (hd17*4.0f)) {
						if (uv.x > hd01 + (hd17*5.0f)) {
							if (uv.x > hd01 + (hd17*6.0f)) {
								if (uv.x > 1.0f - hd01) {
									return float4(0.4,0.4,0.4,1);
								}
								return float4(0,0,0.75,1);
							}
							return float4(0.75,0,0,1);
						}
						return float4(0.75,0,0.75,1);
					}
					return float4(0,0.75,0,1);
				}
				return float4(0,0.75,0.75,1);
			}
			return float4(0.75,0.75,0,1);
		}
		return float4(0.75,0.75,0.75,1);
	}
	return float4(0.4,0.4,0.4,1);
}


float4 PS_BarsSD( float2 uv : TEXCOORD0 ) : COLOR
{
	float v1 = 7.0f / 12.0f;
	float v2 = 2.0f / 3.0f;
	float v3 = 3.0f / 4.0f;
	float sd17 = 1.0f / 7.0f;
	float sdb1 = sd17 * (3.0f/2.0f);
	float sdb2 = sd17 * 2.0f;
	float sdb3 = sd17 * (5.0f/6.0f);
	float sdb4 = sd17 * (1.0f/3.0f);
	if (uv.y > v1) {
		if (uv.y > v2) {
			if (uv.y > v3) {
				if (uv.x > sdb1) {
					if (uv.x > sdb1 + sdb2) {
						if (uv.x > sdb1 + sdb2 + sdb3) {
							if (uv.x > 1.0f - sd17 - (sdb4*4.0f)) {
								if (uv.x > 1.0f - sd17 - (sdb4*3.0f)) {
									if (uv.x > 1.0f - sd17 - (sdb4*2.0f)) {
										if (uv.x > 1.0f - sd17 - sdb4) {
											if (uv.x > 1.0f - sd17) {
												return float4(0,0,0,1);
											}
											return float4(0.04,0.04,0.04,1);
										}
										return float4(0,0,0,1);
									}
									return float4(0.02,0.02,0.02,1);
								}
								return float4(0,0,0,1);
							}
							return float4(-0.02,-0.02,-0.02,1);
						}
						return float4(0,0,0,1);
					}
					return float4(1,1,1,1);
				}
				return float4(0,0,0,1);
			}
			if (uv.x >= 0.0f) {
				float color = uv.x;
				return float4(color,color,color,1);
			}
		}
		if (uv.x > sd17) {
			return float4(0.75,0.75,0.75,1);
		}
		return float4(0.75,0.75,0.75,1);
	}
	if (uv.x > sd17) {
		if (uv.x > (sd17*2.0f)) {
			if (uv.x > (sd17*3.0f)) {
				if (uv.x > (sd17*4.0f)) {
					if (uv.x > (sd17*5.0f)) {
						if (uv.x > (sd17*6.0f)) {
							return float4(0,0,0.75,1);
						}
						return float4(0.75,0,0,1);
					}
					return float4(0.75,0,0.75,1);
				}
				return float4(0,0.75,0,1);
			}
			return float4(0,0.75,0.75,1);
		}
		return float4(0.75,0.75,0,1);
	}
	return float4(0.75,0.75,0.75,1);
}



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------

technique HD
{
   pass Pass1
   {
      PixelShader = compile PROFILE PS_BarsHD();
   }
}

technique SD
{
   pass Pass1
   {
      PixelShader = compile PROFILE PS_BarsSD();
   }
}

