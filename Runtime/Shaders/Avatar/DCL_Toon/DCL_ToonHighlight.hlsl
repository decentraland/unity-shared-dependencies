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
    float4 positionCS : TEXCOORD4;

    UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutput vert_highlight (VertexInput v)
{
    VertexOutput o = (VertexOutput)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );

    float3 normalDir;
    float3 tangentDir;
    float3 bitangentDir;

    #ifdef _DCL_COMPUTE_SKINNING
    normalDir = UnityObjectToWorldNormal(_GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].normal.xyz);
    float4 skinnedTangent = _GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].tangent;
    tangentDir = normalize( mul( unity_ObjectToWorld, float4( skinnedTangent.xyz, 0.0 ) ).xyz );
    bitangentDir = normalize(cross(normalDir, tangentDir) * skinnedTangent.w);
    #else
    normalDir = UnityObjectToWorldNormal(v.normal);
    tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    bitangentDir = normalize(cross(normalDir, tangentDir) * v.tangent.w);
    #endif
    
    float Set_Outline_Width = _Highlight_Width * 0.001f * smoothstep( _Highlight_Farthest_Distance, _Highlight_Nearest_Distance, distance(objPos.rgb,_WorldSpaceCameraPos));
    Set_Outline_Width *= (1.0f - _Highlight_ZOverDrawMode);

    float4 _ClipCameraPos = mul(UNITY_MATRIX_VP, float4(_WorldSpaceCameraPos.xyz, 1));
    
    #if defined(UNITY_REVERSED_Z)
        float fOffset_Z = _Highlight_Offset_Z * -0.01;
    #else
        float fOffset_Z = _Highlight_Offset_Z * 0.01;
    #endif
    
    Set_Outline_Width = Set_Outline_Width*50;
    float signVar = dot(normalize(v.vertex.xyz),normalize(v.normal))<0 ? -1 : 1;
    float4 vertOffset = _Highlight_ObjectOffset;
    #ifdef _DCL_COMPUTE_SKINNING
        float4 vVert = float4(_GlobalAvatarBuffer[_lastAvatarVertCount + _lastWearableVertCount + v.index].position.xyz, 1.0f);
        o.pos = UnityObjectToClipPos(float4(vVert.xyz + signVar*normalize(vVert - vertOffset)*Set_Outline_Width, 1));
    #else
        o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + signVar*normalize(v.vertex)*Set_Outline_Width, 1));
    #endif

    o.pos.z = o.pos.z + fOffset_Z * _ClipCameraPos.z;
    o.positionCS = TransformWorldToHClip(o.pos);
    return o;
}

float4 frag_highlight(VertexOutput i) : SV_Target
{
    Dithering(_FadeDistance, i.positionCS, _EndFadeDistance, _StartFadeDistance);
    return _Highlight_Colour;
}