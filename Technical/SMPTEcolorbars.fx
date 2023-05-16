// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2011-12-05

/**
 This version of colorbars provides a SMPTE alternative to the Lightworks-supplied EBU
 version.  It installs into the custom category "User", subcategory "Technical".

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SMPTEcolorbars.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-05-05 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("SMPTE color bars", "User", "Technical", "Provides SMPTE-standard colour bars as an alternative to the Lightworks-supplied EBU version", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Aspect Ratio", kNoGroup, 0, "HD|SD");

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Colorbars_HD)
{
   float v1 = 7.0 / 12.0;
   float v2 = 2.0 / 3.0;
   float v3 = 3.0 / 4.0;
   float hd01 = 0.125;
   float hd17 = 0.75 / 7.0;
   float hdb1 = hd17 * (3.0/2.0);
   float hdb2 = hd17 * 2.0;
   float hdb3 = hd17 * (5.0/6.0);
   float hdb4 = hd17 * (1.0/3.0);
   if (uv0.y > v1) {
      if (uv0.y > v2) {
         if (uv0.y > v3) {
            if (uv0.x > hd01) {
               if (uv0.x > hd01 + hdb1) {
                  if (uv0.x > hd01 + hdb1 + hdb2) {
                     if (uv0.x > hd01 + hdb1 + hdb2 + hdb3) {
                        if (uv0.x > 1.0 - hd01 - hd17 - (hdb4*4.0)) {
                           if (uv0.x > 1.0 - hd01 - hd17 - (hdb4*3.0)) {
                              if (uv0.x > 1.0 - hd01 - hd17 - (hdb4*2.0)) {
                                 if (uv0.x > 1.0 - hd01 - hd17 - hdb4) {
                                    if (uv0.x > 1.0 - hd01 - hd17) {
                                       if (uv0.x > 1.0 - hd01) {
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
         if (uv0.x > hd01) {
            if (uv0.x > 1.0 - hd01) {
               return float4(1,0,0,1);
            }
            float color = (uv0.x - hd01) * (1.0 / (0.875f-hd01));
            return float4(color,color,color,1);
         }
         return float4(1,1,0,1);
      }
      if (uv0.x > hd01) {
         if (uv0.x > hd01 + hd17) {
            if (uv0.x > 1.0 - hd01) {
               return float4(0,0,1,1);
            }
            return float4(0.75,0.75,0.75,1);
         }
         return float4(0.75,0.75,0.75,1);
      }
      return float4(0,1,1,1);
   }
   if (uv0.x > hd01) {
      if (uv0.x > hd01 + hd17) {
         if (uv0.x > hd01 + (hd17*2.0)) {
            if (uv0.x > hd01 + (hd17*3.0)) {
               if (uv0.x > hd01 + (hd17*4.0)) {
                  if (uv0.x > hd01 + (hd17*5.0)) {
                     if (uv0.x > hd01 + (hd17*6.0)) {
                        if (uv0.x > 1.0 - hd01) {
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

DeclareEntryPoint (Colorbars_SD)
{
   float v1 = 7.0 / 12.0;
   float v2 = 2.0 / 3.0;
   float v3 = 3.0 / 4.0;
   float sd17 = 1.0 / 7.0;
   float sdb1 = sd17 * (3.0/2.0);
   float sdb2 = sd17 * 2.0;
   float sdb3 = sd17 * (5.0/6.0);
   float sdb4 = sd17 * (1.0/3.0);
   if (uv0.y > v1) {
      if (uv0.y > v2) {
         if (uv0.y > v3) {
            if (uv0.x > sdb1) {
               if (uv0.x > sdb1 + sdb2) {
                  if (uv0.x > sdb1 + sdb2 + sdb3) {
                     if (uv0.x > 1.0 - sd17 - (sdb4*4.0)) {
                        if (uv0.x > 1.0 - sd17 - (sdb4*3.0)) {
                           if (uv0.x > 1.0 - sd17 - (sdb4*2.0)) {
                              if (uv0.x > 1.0 - sd17 - sdb4) {
                                 if (uv0.x > 1.0 - sd17) {
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
         if (uv0.x >= 0.0) {
            float color = uv0.x;
            return float4(color,color,color,1);
         }
      }
      if (uv0.x > sd17) {
         return float4(0.75,0.75,0.75,1);
      }
      return float4(0.75,0.75,0.75,1);
   }
   if (uv0.x > sd17) {
      if (uv0.x > (sd17*2.0)) {
         if (uv0.x > (sd17*3.0)) {
            if (uv0.x > (sd17*4.0)) {
               if (uv0.x > (sd17*5.0)) {
                  if (uv0.x > (sd17*6.0)) {
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

