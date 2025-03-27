#ifndef SCENE_INPUT_INCLUDED
#define SCENE_INPUT_INCLUDED

#include "../Scene_Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "../../URP/Constants.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Scene_SurfaceInput_TexArray.hlsl"

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
UNITY_DEFINE_INSTANCED_PROP(int, _BaseMapArr_ID)
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
#define _BaseMapArr_ID          UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMapArr_ID)

#define _DCL_TEXTURE_ARRAYS

#ifdef _DCL_TEXTURE_ARRAYS
    #define DCL_DECLARE_TEX2DARRAY(tex) Texture2DArray tex; SamplerState sampler##tex
    #define DCL_SAMPLE_TEX2DARRAY(tex,coord) tex.Sample (sampler##tex,coord)

    DCL_DECLARE_TEX2DARRAY(_BaseMapArr);
    #define SAMPLE_BASEMAP(uv, texArrayID)                  DCL_SAMPLE_TEX2DARRAY(_BaseMapArr, float3(uv, texArrayID))
#else
    TEXTURE2D(_BaseMap);
    SAMPLER(sampler_BaseMap);
    #define SAMPLE_BASEMAP(uv,texArrayID)                   SAMPLE_TEXTURE2D(_BaseMap,                  sampler_BaseMap, uv)
#endif

half4 SampleAlbedoAlpha(float2 uv)
{
    int nBaseMapArrID = _BaseMapArr_ID;
    return half4(SAMPLE_BASEMAP(uv,nBaseMapArrID));
}

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);

#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;
    #ifdef _METALLICSPECGLOSSMAP
        specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
        //ARM Texture - Provides Height in R, Metallic in B and Roughness in G
        specGloss.a = 1.0 - specGloss.g; //Conversion from RoughnessToSmoothness
        specGloss.rgb = specGloss.rgb;
    #else // _METALLICSPECGLOSSMAP
        specGloss.rgb = _Metallic.rrr;
        specGloss.a = _Smoothness;
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
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

inline void InitializeStandardLitSurfaceData_Scene(float2 uv, float4 _PerInstanceColour, out SurfaceData_Scene outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv);
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor * _PerInstanceColour, _Cutoff);
    outSurfaceData.albedo = AlphaModulate(albedoAlpha.rgb * _BaseColor.rgb * _PerInstanceColour.rgb, outSurfaceData.alpha);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.metallic = specGloss.b;
    outSurfaceData.smoothness = specGloss.a;
    
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
    outSurfaceData.height = specGloss.r;
}

#ifdef _GPU_INSTANCER_BATCHER
float3 TransformObjectToWorld_PerInstance(float3 positionOS, uint _instanceID)
{
    #if defined(SHADER_STAGE_RAY_TRACING)
    return mul(ObjectToWorld3x4(), float4(positionOS, 1.0)).xyz;
    #else
    uint instID = _PerInstanceLookUpAndDitherBuffer[instanceID].instanceID;
    return mul(_PerInstanceBuffer[instID].instMatrix, float4(positionOS, 1.0)).xyz;
    #endif
}

VertexPositionInputs GetVertexPositionInputs_PerInstance(float3 positionOS, uint _instanceID)
{
    VertexPositionInputs input;
    input.positionWS = TransformObjectToWorld_PerInstance(positionOS, _instanceID);
    input.positionVS = TransformWorldToView(input.positionWS);
    input.positionCS = TransformWorldToHClip(input.positionWS);

    float4 ndc = input.positionCS * 0.5f;
    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    input.positionNDC.zw = input.positionCS.zw;

    return input;
}
#endif

VertexPositionInputs GetVertexPositionInputs_Scene(float3 _positionOS, uint _svInstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID(_svInstanceID);
    VertexPositionInputs vertexInput = GetVertexPositionInputs_PerInstance(_positionOS, instanceID);
    return vertexInput;
    #else
    VertexPositionInputs vertexInput = GetVertexPositionInputs(_positionOS);
    return vertexInput;
    #endif
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
