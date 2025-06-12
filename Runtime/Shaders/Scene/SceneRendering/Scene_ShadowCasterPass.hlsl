#ifndef SCENE_SHADOW_CASTER_PASS_INCLUDED
#define SCENE_SHADOW_CASTER_PASS_INCLUDED

#include "Scene_Dither.hlsl"
#include "Scene_Core.hlsl"
#include "Scene_Shadows.hlsl"
#include "Scene_PlaneClipping.hlsl"
#if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

#ifdef _GPU_INSTANCER_BATCHER
#define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
#include "UnityIndirect.cginc"
#endif

// Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
// For Directional lights, _LightDirection is used when applying shadow Normal Bias.
// For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
float3 _LightDirection;
float3 _LightPosition;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float3 positionWS   : TEXCOORD0;
    float2 uv           : TEXCOORD1;
    float4 tintColour   : TEXCOORD2;
    uint nDither        : TEXCOORD3;
};

float4 GetShadowPositionHClip(Attributes input, uint _svInstanceID)
{
    float3 positionWS = TransformObjectToWorld_Scene(input.positionOS.xyz, _svInstanceID);
    float3 normalWS = TransformObjectToWorldNormal_Scene(input.normalOS, _svInstanceID);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input, uint svInstanceID : SV_InstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    InitIndirectDrawArgs(0);
    #endif
    
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    #ifdef _GPU_INSTANCER_BATCHER
    uint instanceID = GetIndirectInstanceID_Base(svInstanceID);
    output.tintColour = _PerInstanceBuffer[_PerInstanceLookUpAndDitherBuffer[instanceID].instanceID].instColourTint;
    output.nDither = _PerInstanceLookUpAndDitherBuffer[instanceID].ditherLevel;
    #else
    output.tintColour = float4(1.0f, 1.0f, 1.0f, 1.0f);
    output.nDither = 0;
    #endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = GetShadowPositionHClip(input, svInstanceID);
    output.positionWS = TransformObjectToWorld_Scene(input.positionOS.xyz, svInstanceID);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    Dithering( input.positionCS, input.nDither);

    ClipFragmentViaPlaneTests(input.positionWS, _PlaneClipping.x, _PlaneClipping.y, _PlaneClipping.z, _PlaneClipping.w, _VerticalClipping.x, _VerticalClipping.y);

    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor * input.tintColour, _Cutoff);

#ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
#endif

    return 0;
}

#endif
