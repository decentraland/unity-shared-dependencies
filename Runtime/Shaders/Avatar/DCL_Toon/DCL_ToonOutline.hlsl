uniform float4 _LightColor0; // this is not set in c# code ?

#ifdef _DCL_COMPUTE_SKINNING
// Skinning structure
struct VertexInfo
{
    float3 position;
    float3 normal;
    float4 tangent;
};
StructuredBuffer<VertexInfo> _GlobalAvatarBuffer;
#endif

struct VertexInput
{
    uint index : SV_VertexID;
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float3 normalDir : TEXCOORD1;
    float3 tangentDir : TEXCOORD2;
    float3 bitangentDir : TEXCOORD3;
    float4 positionCS : TEXCOORD4;

    UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutput vert (VertexInput v)
{
    VertexOutput o = (VertexOutput)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.uv0 = v.texcoord0;
    float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
    float2 Set_UV0 = o.uv0;

    #ifdef _DCL_COMPUTE_SKINNING
    o.normalDir = UnityObjectToWorldNormal(_GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].normal.xyz);
    float4 skinnedTangent = _GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].tangent;
    o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( skinnedTangent.xyz, 0.0 ) ).xyz );
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * skinnedTangent.w);
    #else
    o.normalDir = UnityObjectToWorldNormal(v.normal);
    o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    #endif
    
    float3x3 tangentTransform = float3x3( o.tangentDir, o.bitangentDir, o.normalDir);

    float Set_Outline_Width = _Outline_Width * 0.001f * smoothstep( _Farthest_Distance, _Nearest_Distance, distance(objPos.rgb,_WorldSpaceCameraPos));
    Set_Outline_Width *= (1.0f - _ZOverDrawMode);
    float4 _ClipCameraPos = mul(UNITY_MATRIX_VP, float4(_WorldSpaceCameraPos.xyz, 1));
    
    #if defined(UNITY_REVERSED_Z)
        float fOffset_Z = _Offset_Z * -0.01f;
    #else
        float fOffset_Z = _Offset_Z * 0.01f;
    #endif
    
    Set_Outline_Width = Set_Outline_Width * 2.0f;
    float signVar = dot(normalize(v.vertex.xyz),normalize(v.normal))<0 ? -1 : 1;
    o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + signVar*normalize(v.vertex)*Set_Outline_Width, 1));
    #ifdef _DCL_COMPUTE_SKINNING
        float3 positionWS = TransformObjectToWorld(_GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].position.xyz);
    #else
        float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
    #endif

    o.pos.z = o.pos.z + fOffset_Z * _ClipCameraPos.z;
    o.positionCS = TransformWorldToHClip(positionWS);
    return o;
}

float4 frag(VertexOutput i) : SV_Target
{
    Dithering(_FadeDistance, i.positionCS, _StartFadeDistance, _StartFadeDistance);
    //v.2.0.5
    // if (_ZOverDrawMode > 0.99f)
    // {
    //     return float4(1.0f, 1.0f, 1.0f, 1.0f);  // but nothing should be drawn except Z value as colormask is set to 0
    // }
    //_Color = _BaseColor;
    float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
    //v.2.0.9
    float3 envLightSource_GradientEquator = unity_AmbientEquator.rgb >0.05 ? unity_AmbientEquator.rgb : half3(0.05,0.05,0.05);
    float3 envLightSource_SkyboxIntensity = max(ShadeSH9(half4(0.0,0.0,0.0,1.0)),ShadeSH9(half4(0.0,-1.0,0.0,1.0))).rgb;
    float3 ambientSkyColor = envLightSource_SkyboxIntensity.rgb>0.0 ? envLightSource_SkyboxIntensity*_Unlit_Intensity : envLightSource_GradientEquator*_Unlit_Intensity;
    //
    float3 lightColor = _LightColor0.rgb >0.05 ? _LightColor0.rgb : ambientSkyColor.rgb;
    float lightColorIntensity = (0.299*lightColor.r + 0.587*lightColor.g + 0.114*lightColor.b);
    lightColor = lightColorIntensity<1 ? lightColor : lightColor/lightColorIntensity;
    lightColor = lerp(half3(1.0,1.0,1.0), lightColor, _Is_LightColor_Outline);
    float2 Set_UV0 = i.uv0;
    int nMainTexArrID = _MainTexArr_ID;
    float2 uv_maintex = TRANSFORM_TEX(Set_UV0, _MainTex);
    float4 _MainTex_var = SAMPLE_MAINTEX(uv_maintex,nMainTexArrID);
    //float4 _MainTex_var = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, TRANSFORM_TEX(Set_UV0, _MainTex));
    float3 Set_BaseColor = _BaseColor.rgb*_MainTex_var.rgb;
    float3 _Is_BlendBaseColor_var = lerp( _Outline_Color.rgb*lightColor, (_Outline_Color.rgb*Set_BaseColor*Set_BaseColor*lightColor), _Is_BlendBaseColor );
    //
    //float3 _OutlineTex_var = float3(1.0, 1.0, 1.0);//tex2D(_OutlineTex,TRANSFORM_TEX(Set_UV0, _OutlineTex)).rgb;
    //v.2.0.7.5

    //return float4(1.0, 0.0, 0.0 ,1.0);
    //#ifdef _IS_OUTLINE_CLIPPING_NO
        //float3 Set_Outline_Color = lerp(_Is_BlendBaseColor_var, _OutlineTex_var.rgb*_Outline_Color.rgb*lightColor, _Is_OutlineTex );
        //return float4(Set_Outline_Color,1.0);
    //#elif _IS_OUTLINE_CLIPPING_YES
        //float4 _ClippingMask_var = float4(1.0, 1.0, 1.0, 1.0);//SAMPLE_TEXTURE2D(_ClippingMask, sampler_MainTex, TRANSFORM_TEX(Set_UV0, _ClippingMask));
        float Set_MainTexAlpha = _MainTex_var.a;
        float _IsBaseMapAlphaAsClippingMask_var = Set_MainTexAlpha;//lerp( _ClippingMask_var.r, Set_MainTexAlpha, _IsBaseMapAlphaAsClippingMask );
        float _Inverse_Clipping_var = lerp( _IsBaseMapAlphaAsClippingMask_var, (1.0 - _IsBaseMapAlphaAsClippingMask_var), _Inverse_Clipping );
        float Set_Clipping = saturate((_Inverse_Clipping_var+_Clipping_Level));
        clip(Set_MainTexAlpha - 0.5);
        float4 Set_Outline_Color = float4(_Is_BlendBaseColor_var,Set_Clipping);//lerp( float4(_Is_BlendBaseColor_var,Set_Clipping), float4((_OutlineTex_var.rgb*_Outline_Color.rgb*lightColor),Set_Clipping), _Is_OutlineTex );
        return Set_Outline_Color;
    //#endif
}