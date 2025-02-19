﻿#ifndef DCL_SCENE_DITHER_INCLUDED
#define DCL_SCENE_DITHER_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

void Dithering( float4 positionCS, uint nDither)
{
    return;
    float4 ndc = positionCS * 0.5f;
    float4 positionNDC; // Homogeneous normalized device coordinates
    positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    positionNDC.zw = positionCS.zw;


    uint twofivefive = 255;
    float hideAmount = nDither / twofivefive;
    
    // Screen-door transparency: Discard pixel if below threshold.
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    
    float2 uv = positionNDC.xy / positionNDC.w;
    uv *= _ScreenParams.xy; // pixel position
    uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
    if((hideAmount - DITHER_THRESHOLDS[index]) <= 0.0)
        clip(-1);
}

#endif // DCL_SCENE_DITHER_INCLUDED