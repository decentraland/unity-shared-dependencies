#ifndef SCENE_DEPTH_NORMALS_PASS_INCLUDED
#define SCENE_DEPTH_NORMALS_PASS_INCLUDED

#include "Scene_Dither.hlsl"
#include "Scene_Lighting.hlsl"
#include "Scene_PlaneClipping.hlsl"
#if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

#ifdef _GPU_INSTANCER_BATCHER
#define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
#include "UnityIndirect.cginc"
#endif

// GLES2 has limited amount of interpolators
//#if defined(_PARALLAXMAP)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
//#endif

//#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)))
//#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
//#endif

struct Attributes
{
    float4 positionOS     : POSITION;
    float4 tangentOS      : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float3 normal       : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD1;
    half3 normalWS     : TEXCOORD2;

    //#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    half4 tangentWS    : TEXCOORD4;    // xyz: tangent, w: sign
    //#endif

    half3 viewDirWS    : TEXCOORD5;

    //#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS     : TEXCOORD8;
    //#endif

    float3 positionWS   : TEXCOORD9;
    
    uint nDither        : TEXCOORD10;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthNormalsVertex(Attributes input, uint svInstanceID : SV_InstanceID)
{
    #ifdef _GPU_INSTANCER_BATCHER
    InitIndirectDrawArgs(0);
    #endif
    
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    #ifdef _GPU_INSTANCER_BATCHER
    uint instanceID = GetIndirectInstanceID_Base(svInstanceID);
    output.nDither = _PerInstanceLookUpAndDitherBuffer[instanceID].ditherLevel;
    #else
    output.nDither = 0;
    #endif

    output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = TransformObjectToHClip_Scene(input.positionOS.xyz, svInstanceID);
    output.positionWS = TransformObjectToWorld_Scene(input.positionOS.xyz, svInstanceID);

    VertexPositionInputs vertexInput = GetVertexPositionInputs_Scene(input.positionOS.xyz, svInstanceID);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    output.normalWS = half3(normalInput.normalWS);
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        float sign = input.tangentOS.w * float(GetOddNegativeScale());
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    #endif

    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
        output.tangentWS = tangentWS;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
        output.viewDirTS = viewDirTS;
    #endif

    return output;
}

void DepthNormalsFragment(Varyings input, out half4 outNormalWS : SV_Target0)
{
    Dithering( input.positionCS, input.nDither);

    ClipFragmentViaPlaneTests(input.positionWS, _PlaneClipping.x, _PlaneClipping.y, _PlaneClipping.z, _PlaneClipping.w, _VerticalClipping.x, _VerticalClipping.y);

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);

    #ifdef LOD_FADE_CROSSFADE
        LODFadeCrossFade(input.positionCS);
    #endif

    #if defined(_GBUFFER_NORMALS_OCT)
        float3 normalWS = normalize(input.normalWS);
        float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
        float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
        half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
        outNormalWS = half4(packedNormalWS, 0.0);
    #else
        float2 uv = input.uv;
        //#if defined(_PARALLAXMAP)
            //#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS = input.viewDirTS;
            // #else
            //     half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
            // #endif
            ApplyPerPixelDisplacement(viewDirTS, uv);
        //#endif

        //#if defined(_NORMALMAP) || defined(_DETAIL)
            float sgn = input.tangentWS.w;      // should be either +1 or -1
            float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
            float3 normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

            // #if defined(_DETAIL)
            //     half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
            //     float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
            //     normalTS = ApplyDetailNormal(detailUv, normalTS, detailMask);
            // #endif

            float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
        // #else
        //     float3 normalWS = input.normalWS;
        // #endif

        outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
    #endif

    #ifdef _WRITE_RENDERING_LAYERS
        uint renderingLayers = GetMeshRenderingLayer();
        outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}

#endif
