// @Maintainer jwrl
// @Released 2020-09-28
// @Author khaver
// @Created 2011-12-05
// @see https://www.lwks.com/media/kunena/attachments/6375/ColorBars_640.png

/**
 This version of colorbars provides a SMPTE alternative to the Lightworks-supplied EBU
 version.  It installs into the custom category "User", subcategory "Technical".
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colorbars.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified by LW user jwrl 6 December 2018.
// Added creation date.
// Changed subcategory.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bugfix 14 July 2017 by jwrl.
// Corrected an issue with Linux/Mac versions of the Lightworks effects compiler that
// caused the bars not to display on those platforms.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Color bars";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Provides SMPTE-standard colour bars as an alternative to the Lightworks-supplied EBU version";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

// No input required.

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Aspect Ratio";
   string Enum = "HD,SD";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
