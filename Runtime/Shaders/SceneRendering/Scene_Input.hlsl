#ifndef SCENE_INPUT_INCLUDED
#define SCENE_INPUT_INCLUDED

#include "Scene_Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "../URP/Constants.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Scene_SurfaceInput.hlsl"

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(half4, _SpecColor)
UNITY_DEFINE_INSTANCED_PROP(half4, _EmissionColor)
UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(half, _Smoothness)
UNITY_DEFINE_INSTANCED_PROP(half, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(half, _BumpScale)
UNITY_DEFINE_INSTANCED_PROP(half, _Parallax)
UNITY_DEFINE_INSTANCED_PROP(half, _OcclusionStrength)
UNITY_DEFINE_INSTANCED_PROP(half, _Surface)
UNITY_DEFINE_INSTANCED_PROP(float4, _PlaneClipping)
UNITY_DEFINE_INSTANCED_PROP(float4, _VerticalClipping)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

#define _BaseMap_ST             UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST)
#define _BaseColor              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor)
#define _SpecColor              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecColor)
#define _EmissionColor          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor)
#define _Cutoff                 UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff)
#define _Smoothness             UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness)
#define _Metallic               UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic)
#define _BumpScale              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BumpScale)
#define _Parallax               UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Parallax)
#define _OcclusionStrength      UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _OcclusionStrength)
#define _Surface                UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Surface)
#define _PlaneClipping          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _PlaneClipping)
#define _VerticalClipping       UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _VerticalClipping)

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
//TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);

#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;
	#ifdef _METALLICSPECGLOSSMAP
        specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
        //ARM Texture - Provides Height in R, Metallic in B and Roughness in G
        specGloss.g = 1.0 - specGloss.g; //Conversion from RoughnessToSmoothness
        specGloss.b *= _Metallic;
	#else // _METALLICSPECGLOSSMAP
        specGloss.r = 0.0;
        specGloss.g = _Smoothness;
        specGloss.b = _Metallic;
        specGloss.a = 0.0;
	#endif
    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        return LerpWhiteTo(occ, _OcclusionStrength);
    #else
        return half(1.0);
    #endif
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_METALLICSPECGLOSSMAP) // using HRM texture, so RGB == Height, Roughness, Metallic
    uv += ParallaxMapping(TEXTURE2D_ARGS(_MetallicGlossMap, sampler_MetallicGlossMap), viewDirTS, _Parallax, uv);
#endif
}

inline void InitializeStandardLitSurfaceData_Scene(float2 uv, out SurfaceData_Scene outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    outSurfaceData.albedo = AlphaModulate(albedoAlpha.rgb * _BaseColor.rgb, outSurfaceData.alpha);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.metallic = specGloss.b;
    outSurfaceData.smoothness = specGloss.g;
    
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
    outSurfaceData.height = specGloss.r;
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
