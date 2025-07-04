Shader "DCL/DCL_Toon"
{
    Properties
    {
        [HideInInspector] [PerRendererData] _HighlightObjectOffset ("Highlight Object Offset", Vector) = (0.0, 100.0, 0.0, 0.0)
        [HideInInspector] [PerRendererData] _HighlightColour ("Highlight Colour", Color) = (1,0,0,1)
        [HideInInspector] [PerRendererData] _HighlightWidth ("Highlight Width", Float) = 1.0
        
        [HideInInspector] [PerRendererData] _MainTexArr_ID ("MainTex Array ID", Integer) = -1
        [HideInInspector] [PerRendererData] _NormalMapArr_ID ("Normal Map Array ID", Integer) = -1
        [HideInInspector] [PerRendererData] _MatCap_SamplerArr_ID ("MatCap Array ID", Integer) = -1
        [HideInInspector] [PerRendererData] _Emissive_TexArr_ID ("Emissive Array ID", Integer) = -1
        [HideInInspector] [PerRendererData] _MetallicGlossMapArr_ID ("MetallicGlossMap Array ID", Integer) = -1

        [HideInInspector] [PerRendererData] _lastWearableVertCount ("Last wearable Vert Count", Integer) = -1
        [HideInInspector] [PerRendererData] _lastAvatarVertCount ("Last avatar vert count", Integer) = -1
        
        [HideInInspector] [PerRendererData] _EndFadeDistance ("EndFadeDistance", Float) = 0
        [HideInInspector] [PerRendererData] _StartFadeDistance ("StartFadeDistance", Float) = 0
        [HideInInspector] [PerRendererData] _FadeDistance ("FadeDistance", Float) = 1
        
        [HideInInspector] _MainTexArr ("Main Texture Array", 2DArray) = "white" {}
        [HideInInspector] _NormalMapArr ("Normal Texture Array", 2DArray) = "bump" {}
        [HideInInspector] _Emissive_TexArr ("Emissive Texture Array", 2DArray) = "black" {}
        
        [HideInInspector] _simpleUI ("SimpleUI", Int ) = 0

        [Enum(OFF, 0, StencilOut, 1, StencilMask, 2)] _StencilMode("StencilMode", int) = 0
        // these are set in UniversalToonGUI.cs in accordance with _StencilMode
        _StencilComp("Stencil Comparison", Float) = 8
        _StencilNo("Stencil No", Float) = 1
        _StencilOpPass("Stencil Operation", Float) = 0
        _StencilOpFail("Stencil Operation", Float) = 0
        [Enum(OFF, 0, ON, 1)] _TransparentEnabled("Transparent Mode", int) = 0

        // DoubleShadeWithFeather
        // 0:_IS_CLIPPING_OFF      1:_IS_CLIPPING_MODE    2:_IS_CLIPPING_TRANSMODE
        // ShadingGradeMap
        // 0:_IS_TRANSCLIPPING_OFF 1:_IS_TRANSCLIPPING_ON
        [Enum(OFF, 0, ON, 1, TRANSMODE, 2)] _ClippingMode("CliippingMode", int) = 0

 
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode("Cull Mode", int) = 2  //OFF/FRONT/BACK
        [Enum(OFF, 0, ON, 1)]	_ZWriteMode("ZWrite Mode", int) = 1  //OFF/ON
        [Enum(OFF, 0, ON, 1)]	_ZOverDrawMode("ZOver Draw Mode", Float) = 0  //OFF/ON
        _SPRDefaultUnlitColorMask("SPRDefaultUnlit Path Color Mask", int) = 15
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _SRPDefaultUnlitColMode("SPRDefaultUnlit  Cull Mode", int) = 1  //OFF/FRONT/BACK
        // ClippingMask paramaters from Here.
        _ClippingMask("ClippingMask", 2D) = "white" {}

        [Toggle(_)] _Inverse_Clipping("Inverse_Clipping", Float) = 0
        _Clipping_Level("Clipping_Level", Range(0, 1)) = 0
        _Tweak_transparency("Tweak_transparency", Range(-1, 1)) = 0
        // ClippingMask paramaters to Here.
        
        _MainTex ("BaseMap", 2D) = "white" {}
        _BaseMap ("BaseMap", 2D) = "white" {}
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        //v.2.0.5 : Clipping/TransClipping for SSAO Problems in PostProcessing Stack.
        //If you want to go back the former SSAO results, comment out the below line.
        _Color ("Color", Color) = (1,1,1,1)
        
        [Toggle(_)] _Is_LightColor_Base ("Is_LightColor_Base", Float ) = 1
        _1st_ShadeMap ("1st_ShadeMap", 2D) = "white" {}
        //v.2.0.5
        [Toggle(_)] _Use_BaseAs1st ("Use BaseMap as 1st_ShadeMap", Float ) = 0
        _1st_ShadeColor ("1st_ShadeColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_LightColor_1st_Shade ("Is_LightColor_1st_Shade", Float ) = 1
        _2nd_ShadeMap ("2nd_ShadeMap", 2D) = "white" {}
        //v.2.0.5
        [Toggle(_)] _Use_1stAs2nd ("Use 1st_ShadeMap as 2nd_ShadeMap", Float ) = 0
        _2nd_ShadeColor ("2nd_ShadeColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_LightColor_2nd_Shade ("Is_LightColor_2nd_Shade", Float ) = 1
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 1)) = 1
        [Toggle(_)] _Is_NormalMapToBase ("Is_NormalMapToBase", Float ) = 0
        //v.2.0.4.4
        [Toggle(_)] _Set_SystemShadowsToBase ("Set_SystemShadowsToBase", Float ) = 1
        _Tweak_SystemShadowsLevel ("Tweak_SystemShadowsLevel", Range(-0.5, 0.5)) = 0
        //v.2.0.6
        _BaseColor_Step ("BaseColor_Step", Range(0, 1)) = 0.5
        _BaseShade_Feather ("Base/Shade_Feather", Range(0.0001, 1)) = 0.0001
        _ShadeColor_Step ("ShadeColor_Step", Range(0, 1)) = 0
        _1st2nd_Shades_Feather ("1st/2nd_Shades_Feather", Range(0.0001, 1)) = 0.0001
        _1st_ShadeColor_Step ("1st_ShadeColor_Step", Range(0, 1)) = 0.5
        _1st_ShadeColor_Feather ("1st_ShadeColor_Feather", Range(0.0001, 1)) = 0.0001
        _2nd_ShadeColor_Step ("2nd_ShadeColor_Step", Range(0, 1)) = 0
        _2nd_ShadeColor_Feather ("2nd_ShadeColor_Feather", Range(0.0001, 1)) = 0.0001
        //v.2.0.5
        _StepOffset ("Step_Offset (ForwardAdd Only)", Range(-0.5, 0.5)) = 0
        [Toggle(_)] _Is_Filter_HiCutPointLightColor ("PointLights HiCut_Filter (ForwardAdd Only)", Float ) = 1
        //
        _Set_1st_ShadePosition ("Set_1st_ShadePosition", 2D) = "white" {}
        _Set_2nd_ShadePosition ("Set_2nd_ShadePosition", 2D) = "white" {}
        _ShadingGradeMap("ShadingGradeMap", 2D) = "white" {}
        //v.2.0.6
        _Tweak_ShadingGradeMapLevel("Tweak_ShadingGradeMapLevel", Range(-0.5, 0.5)) = 0
        _BlurLevelSGM("Blur Level of ShadingGradeMap", Range(0, 10)) = 0
        //
        _HighColor ("HighColor", Color) = (0,0,0,1)
//v.2.0.4 HighColor_Tex
        _HighColor_Tex ("HighColor_Tex", 2D) = "white" {}
        [Toggle(_)] _Is_LightColor_HighColor ("Is_LightColor_HighColor", Float ) = 1
        [Toggle(_)] _Is_NormalMapToHighColor ("Is_NormalMapToHighColor", Float ) = 0
        _HighColor_Power ("HighColor_Power", Range(0, 1)) = 0
        [Toggle(_)] _Is_SpecularToHighColor ("Is_SpecularToHighColor", Float ) = 0
        [Toggle(_)] _Is_BlendAddToHiColor ("Is_BlendAddToHiColor", Float ) = 0
        [Toggle(_)] _Is_UseTweakHighColorOnShadow ("Is_UseTweakHighColorOnShadow", Float ) = 0
        _TweakHighColorOnShadow ("TweakHighColorOnShadow", Range(0, 1)) = 0
//HiColorMask
        _Set_HighColorMask ("Set_HighColorMask", 2D) = "white" {}
        _Tweak_HighColorMaskLevel ("Tweak_HighColorMaskLevel", Range(-1, 1)) = 0
        [Toggle(_)] _RimLight ("RimLight", Float ) = 0
        _RimLightColor ("RimLightColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_LightColor_RimLight ("Is_LightColor_RimLight", Float ) = 1
        [Toggle(_)] _Is_NormalMapToRimLight ("Is_NormalMapToRimLight", Float ) = 0
        _RimLight_Power ("RimLight_Power", Range(0, 1)) = 0.1
        _RimLight_InsideMask ("RimLight_InsideMask", Range(0.0001, 1)) = 0.0001
        [Toggle(_)] _RimLight_FeatherOff ("RimLight_FeatherOff", Float ) = 0
//RimLight
        [Toggle(_)] _LightDirection_MaskOn ("LightDirection_MaskOn", Float ) = 0
        _Tweak_LightDirection_MaskLevel ("Tweak_LightDirection_MaskLevel", Range(0, 0.5)) = 0
        [Toggle(_)] _Add_Antipodean_RimLight ("Add_Antipodean_RimLight", Float ) = 0
        _Ap_RimLightColor ("Ap_RimLightColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_LightColor_Ap_RimLight ("Is_LightColor_Ap_RimLight", Float ) = 1
        _Ap_RimLight_Power ("Ap_RimLight_Power", Range(0, 1)) = 0.1
        [Toggle(_)] _Ap_RimLight_FeatherOff ("Ap_RimLight_FeatherOff", Float ) = 0
//RimLightMask
        _Set_RimLightMask ("Set_RimLightMask", 2D) = "white" {}
        _Tweak_RimLightMaskLevel ("Tweak_RimLightMaskLevel", Range(-1, 1)) = 0
//
        [Toggle(_)] _MatCap ("MatCap", Float ) = 0
        _MatCap_Sampler ("MatCap_Sampler", 2D) = "black" {}
        //v.2.0.6
        _BlurLevelMatcap ("Blur Level of MatCap_Sampler", Range(0, 10)) = 0
        _MatCapColor ("MatCapColor", Color) = (1,1,1,1)
        [Toggle(_)] _Is_LightColor_MatCap ("Is_LightColor_MatCap", Float ) = 1
        [Toggle(_)] _Is_BlendAddToMatCap ("Is_BlendAddToMatCap", Float ) = 1
        _Tweak_MatCapUV ("Tweak_MatCapUV", Range(-0.5, 0.5)) = 0
        _Rotate_MatCapUV ("Rotate_MatCapUV", Range(-1, 1)) = 0
        //v.2.0.6
        [Toggle(_)] _CameraRolling_Stabilizer ("Activate CameraRolling_Stabilizer", Float ) = 0
        [Toggle(_)] _Is_NormalMapForMatCap ("Is_NormalMapForMatCap", Float ) = 0
        _NormalMapForMatCap ("NormalMapForMatCap", 2D) = "bump" {}
        _BumpScaleMatcap ("Scale for NormalMapforMatCap", Range(0, 1)) = 1
        _Rotate_NormalMapForMatCapUV ("Rotate_NormalMapForMatCapUV", Range(-1, 1)) = 0
        [Toggle(_)] _Is_UseTweakMatCapOnShadow ("Is_UseTweakMatCapOnShadow", Float ) = 0
        _TweakMatCapOnShadow ("TweakMatCapOnShadow", Range(0, 1)) = 0
//MatcapMask
        _Set_MatcapMask ("Set_MatcapMask", 2D) = "white" {}
        _Tweak_MatcapMaskLevel ("Tweak_MatcapMaskLevel", Range(-1, 1)) = 0
        [Toggle(_)] _Inverse_MatcapMask ("Inverse_MatcapMask", Float ) = 0
        //v.2.0.5
        [Toggle(_)] _Is_Ortho ("Orthographic Projection for MatCap", Float ) = 0
        [Toggle(_)] _IsEmissive ("Is Emissive", Float) = 0
        _Emissive_Tex ("Emissive_Tex", 2D) = "white" {}
        [HDR]_Emissive_Color ("Emissive_Color", Color) = (0,0,0,1)

//Outline
        [KeywordEnum(NML,POS)] _OUTLINE("OUTLINE MODE", Float) = 0
        _Outline_Width ("Outline_Width", Float ) = 0
        _Farthest_Distance ("Farthest_Distance", Float ) = 100
        _Nearest_Distance ("Nearest_Distance", Float ) = 0.5
        _Outline_Sampler ("Outline_Sampler", 2D) = "white" {}
        _Outline_Color ("Outline_Color", Color) = (0.5,0.5,0.5,1)
        [Toggle(_)] _Is_BlendBaseColor ("Is_BlendBaseColor", Float ) = 0
        [Toggle(_)] _Is_LightColor_Outline ("Is_LightColor_Outline", Float ) = 1
        //v.2.0.4
        [Toggle(_)] _Is_OutlineTex ("Is_OutlineTex", Float ) = 0
        _OutlineTex ("OutlineTex", 2D) = "white" {}
        //Offset parameter
        _Offset_Z ("Offset_Camera_Z", Float) = 0
        //v.2.0.4.3 Baked Normal Texture for Outline
        [Toggle(_)] _Is_BakedNormal ("Is_BakedNormal", Float ) = 0
        _BakedNormal ("Baked Normal for Outline", 2D) = "white" {}
        //GI Intensity
        _GI_Intensity ("GI_Intensity", Range(0, 1)) = 0
        //For VR Chat under No effective light objects
        _Unlit_Intensity ("Unlit_Intensity", Range(0, 4)) = 0
        //v.2.0.5 
        [Toggle(_)] _Is_Filter_LightColor ("VRChat : SceneLights HiCut_Filter", Float ) = 1
        //Built-in Light Direction
        [Toggle(_)] _Is_BLD ("Advanced : Activate Built-in Light Direction", Float ) = 0
        _Offset_X_Axis_BLD (" Offset X-Axis (Built-in Light Direction)", Range(-1, 1)) = -0.05
        _Offset_Y_Axis_BLD (" Offset Y-Axis (Built-in Light Direction)", Range(-1, 1)) = 0.09
        [Toggle(_)] _Inverse_Z_Axis_BLD (" Inverse Z-Axis (Built-in Light Direction)", Float ) = 1
        
        _Metallic("_Metallic", Range(0.0, 1.0)) = 0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        // Caution: C# code in BaseLitUI.cs call LightmapEmissionFlagsProperty() which assume that there is an existing "_EmissionColor"
        // value that exist to identify if the GI emission need to be enabled.
        // In our case we don't use such a mechanism but need to keep the code quiet. We declare the value and always enable it.
        // TODO: Fix the code in legacy unity so we can customize the beahvior for GI
        _EmissionColor("Color", Color) = (1, 1, 1)

        // HACK: GI Baking system relies on some properties existing in the shader ("_MainTex", "_Cutoff" and "_Color") for opacity handling, so we need to store our version of those parameters in the hard-coded name the GI baking system recognizes.
        //////////// _MainTex("BaseMap", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
    }
    
    SubShader 
    {
        PackageRequirements
        {
             "com.unity.render-pipelines.universal": "10.5.0"
        }
        
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Pass
        {
            Name "Outline"
            Tags {
                "LightMode" = "Outline"
            }
            Cull Front
            //ColorMask [_SPRDefaultUnlitColorMask]
            //Blend SrcAlpha OneMinusSrcAlpha
//            Stencil
//            {
//                Ref[_StencilNo]
//                Comp[_StencilComp]
//                Pass[_StencilOpPass]
//                Fail[_StencilOpFail]
//            }

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag
            //#pragma enable_d3d11_debug_symbols

            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS
            
            //V.2.0.4
            #pragma multi_compile _IS_OUTLINE_CLIPPING_NO _IS_OUTLINE_CLIPPING_YES
            #pragma multi_compile _OUTLINE_NML _OUTLINE_POS
            //#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            // Outline is implemented in UniversalToonOutline.hlsl.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#ifdef UNIVERSAL_PIPELINE_CORE_INCLUDED
            #include "../DCL_AvatarDither.hlsl"
            #include "DCL_ToonInput.hlsl"
            #include "DCL_ToonHead.hlsl"
            #include "DCL_ToonOutline.hlsl"
#endif
            ENDHLSL
        }

        Pass
        {
            Name "Highlight"
            Tags {
                "LightMode" = "Highlight"
            }
            ZWrite Off
            Cull [_SRPDefaultUnlitColMode]
            ColorMask [_SPRDefaultUnlitColorMask]
            //Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref[_StencilNo]
                Comp[_StencilComp]
                Pass[_StencilOpPass]
                Fail[_StencilOpFail]

            }

            HLSLPROGRAM
            //#pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma vertex vert_highlight
            #pragma fragment frag_highlight
            //#pragma enable_d3d11_debug_symbols

            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS
            
            //V.2.0.4
            #pragma multi_compile _IS_OUTLINE_CLIPPING_NO _IS_OUTLINE_CLIPPING_YES
            #pragma multi_compile _OUTLINE_NML _OUTLINE_POS
            //#pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            // Outline is implemented in UniversalToonOutline.hlsl.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#ifdef UNIVERSAL_PIPELINE_CORE_INCLUDED
            #include "../DCL_AvatarDither.hlsl"
            #include "DCL_ToonInput.hlsl"
            #include "DCL_ToonHead.hlsl"
            #include "DCL_ToonHighlight.hlsl"
#endif
            ENDHLSL
        }
        
        Pass {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            ZWrite[_ZWriteMode]
            Cull[_CullMode]
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil {

                Ref[_StencilNo]

                Comp[_StencilComp]
                Pass[_StencilOpPass]
                Fail[_StencilOpFail]

            }

            HLSLPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            //#pragma enable_d3d11_debug_symbols
            
            // -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _FORWARD_PLUS

            //#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            // -------------------------------------
            // Unity defined keywords
            // #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            // #pragma multi_compile _ SHADOWS_SHADOWMASK
            // #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            // #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog

            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            //#define _IS_PASS_FWDBASE
            // DoubleShadeWithFeather and ShadingGradeMap use different fragment shader.  
            //#pragma shader_feature_local _ _SHADINGGRADEMAP
            
            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS

            // used in ShadingGradeMap
            //#pragma shader_feature _IS_TRANSCLIPPING_OFF _IS_TRANSCLIPPING_ON
            //#pragma shader_feature _IS_ANGELRING_OFF _IS_ANGELRING_ON

            // used in Shadow calculation 
            //#pragma shader_feature_local _ UTS_USE_RAYTRACING_SHADOW
            // used in DoubleShadeWithFeather
            #pragma dynamic_branch _IS_CLIPPING_OFF _IS_CLIPPING_MODE _IS_CLIPPING_TRANSMODE

            #define _EMISSIVE_SIMPLE
            //#pragma shader_feature _EMISSIVE_SIMPLE// _EMISSIVE_ANIMATION
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#ifdef UNIVERSAL_PIPELINE_CORE_INCLUDED
            #include "../DCL_AvatarDither.hlsl"
            #include "DCL_ToonInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
            #include "DCL_ToonHead.hlsl"
            #include "DCL_ToonBody.hlsl"
#endif
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 5.0
	    
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing
            //#pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            //#pragma enable_d3d11_debug_symbols

            #include "DCL_ToonInput.hlsl"
            #include "DCL_ToonShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 5.0
            
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            //#pragma enable_d3d11_debug_symbols

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS
            
            #include "DCL_ToonInput.hlsl"
            #include "../DCL_AvatarDither.hlsl"
            #include "DCL_ToonDepthOnlyPass.hlsl"
            ENDHLSL
        }
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_CullMode]

            HLSLPROGRAM
            #pragma target 5.0	    
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"

            
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            //#pragma enable_d3d11_debug_symbols

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #pragma shader_feature_local _DCL_COMPUTE_SKINNING
            #pragma shader_feature_local _DCL_TEXTURE_ARRAYS
            
            #include "DCL_ToonInput.hlsl"
            #include "../DCL_AvatarDither.hlsl"
            #include "DCL_ToonDepthNormalsPass.hlsl"

            ENDHLSL
        }
    }
    
    CustomEditor "UnityEditor.Rendering.DCL_Toon.DCL_Toon_GUI"
}