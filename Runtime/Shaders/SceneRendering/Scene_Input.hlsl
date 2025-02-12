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

#ifdef _GPU_INSTANCER_BATCHER
struct PerInstanceBuffer
{
    float4x4 instMatrix;
    float3 instColourTint;
};
StructuredBuffer<PerInstanceBuffer> _PerInstanceBuffer;

struct PerInstanceLookUpAndDither
{
    uint instanceID;
    uint ditherLevel;
};
StructuredBuffer<PerInstanceLookUpAndDither> _PerInstanceLookUpAndDitherBuffer;
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;
	if (_METALLICSPECGLOSSMAP)
	{
	    specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
	    //ARM Texture - Provides Height in R, Metallic in B and Roughness in G
	    specGloss.g = 1.0 - specGloss.g; //Conversion from RoughnessToSmoothness
	    specGloss.b *= _Metallic;
	}
    else // _METALLICSPECGLOSSMAP
    {
        specGloss.r = 0.0;
        specGloss.g = _Smoothness;
        specGloss.b = _Metallic;
        specGloss.a = 0.0;
    }

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
    if (_PARALLAXMAP) // using HRM texture, so RGB == Height, Roughness, Metallic
    {
        uv += ParallaxMapping(TEXTURE2D_ARGS(_MetallicGlossMap, sampler_MetallicGlossMap), viewDirTS, _Parallax, uv);
    }
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

#ifdef _GPU_INSTANCER_BATCHER
#define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
#include "UnityIndirect.cginc"
#endif

#ifdef _GPU_INSTANCER_BATCHER
float3 TransformObjectToWorld_PerInstance(float3 positionOS, uint _instanceID)
{
    #if defined(SHADER_STAGE_RAY_TRACING)
    return mul(ObjectToWorld3x4(), float4(positionOS, 1.0)).xyz;
    #else
    uint instID = _PerInstanceLookUpAndDitherBuffer[_instanceID].instanceID;
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

float4 TransformObjectToHClip_Scene(float3 _positionOS, uint _svInstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID_Base(_svInstanceID);
    uint instID = _PerInstanceLookUpAndDitherBuffer[instanceID].instanceID;
    return mul(GetWorldToHClipMatrix(), mul(_PerInstanceBuffer[instID].instMatrix, float4(_positionOS, 1.0)));
    #else
    return TransformObjectToHClip(_positionOS);
    #endif
}

float3 TransformObjectToWorld_Scene(float3 _positionOS, uint _svInstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID_Base(_svInstanceID);
    uint instID = _PerInstanceLookUpAndDitherBuffer[instanceID].instanceID;
    return mul(_PerInstanceBuffer[instID].instMatrix, float4(_positionOS, 1.0)).xyz;
    #else
    return TransformObjectToWorld(_positionOS);
    #endif
}

float3 TransformObjectToWorldDir_Scene(float3 dirOS, uint _svInstanceID, bool doNormalize = true)
{
    #ifdef _GPU_INSTANCER_BATCHER
        uint cmdID = GetCommandID(0);
        uint instanceID = GetIndirectInstanceID_Base(_svInstanceID);
        uint instID = _PerInstanceLookUpAndDitherBuffer[instanceID].instanceID;
        float4x4 ObjToWorldMatrix = _PerInstanceBuffer[instID].instMatrix;
        float3 dirWS = mul((float3x3)ObjToWorldMatrix, dirOS);
    #else
        #ifndef SHADER_STAGE_RAY_TRACING
            float3 dirWS = mul((float3x3)GetObjectToWorldMatrix(), dirOS);
        #else
            float3 dirWS = mul((float3x3)ObjectToWorld3x4(), dirOS);
        #endif
    #endif
    
    if (doNormalize)
        return SafeNormalize(dirWS);
    return dirWS;
}

float4x4 inverse(float4x4 m) {
    float n11 = m[0][0], n12 = m[1][0], n13 = m[2][0], n14 = m[3][0];
    float n21 = m[0][1], n22 = m[1][1], n23 = m[2][1], n24 = m[3][1];
    float n31 = m[0][2], n32 = m[1][2], n33 = m[2][2], n34 = m[3][2];
    float n41 = m[0][3], n42 = m[1][3], n43 = m[2][3], n44 = m[3][3];

    float t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
    float t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
    float t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
    float t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

    float det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
    float idet = 1.0f / det;

    float4x4 ret;

    ret[0][0] = t11 * idet;
    ret[0][1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * idet;
    ret[0][2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * idet;
    ret[0][3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * idet;

    ret[1][0] = t12 * idet;
    ret[1][1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * idet;
    ret[1][2] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * idet;
    ret[1][3] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * idet;

    ret[2][0] = t13 * idet;
    ret[2][1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * idet;
    ret[2][2] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * idet;
    ret[2][3] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * idet;

    ret[3][0] = t14 * idet;
    ret[3][1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * idet;
    ret[3][2] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * idet;
    ret[3][3] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * idet;

    return ret;
}


float3 TransformObjectToWorldNormal_Scene(float3 normalOS, uint _svInstanceID, bool doNormalize = true)
{
    #ifdef UNITY_ASSUME_UNIFORM_SCALING
        return TransformObjectToWorldDir_Scene(normalOS, doNormalize);
    #else
        // Normal need to be multiply by inverse transpose
        #ifdef _GPU_INSTANCER_BATCHER
            uint cmdID = GetCommandID(0);
            uint instanceID = GetIndirectInstanceID_Base(_svInstanceID);
            uint instID = _PerInstanceLookUpAndDitherBuffer[instanceID].instanceID;
            float4x4 ObjToWorldMatrix = _PerInstanceBuffer[instID].instMatrix;
            float3 normalWS = mul(normalOS, (float3x3)inverse(ObjToWorldMatrix));
        #else
            float3 normalWS = mul(normalOS, (float3x3)GetWorldToObjectMatrix());
        #endif
        if (doNormalize)
            return SafeNormalize(normalWS);

        return normalWS;
    #endif
}

VertexPositionInputs GetVertexPositionInputs_Scene(float3 _positionOS, uint _svInstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    uint cmdID = GetCommandID(0);
    uint instanceID = GetIndirectInstanceID_Base(_svInstanceID);
    VertexPositionInputs vertexInput = GetVertexPositionInputs_PerInstance(_positionOS, instanceID);
    return vertexInput;
    #else
    VertexPositionInputs vertexInput = GetVertexPositionInputs(_positionOS);
    return vertexInput;
    #endif
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
