#1.1.12
- DCL_Toon: declared `_MetallicGlossMapArr` and `_MatCap_SamplerArr` in the Properties block (they existed only in HLSL), so the texture-array path can actually bind the stylized-metallic mask + matcap arrays via `material.SetTexture` (texture-array consumers like unity-explorer)

#1.1.11
- DCL_Toon: promoted `_MatCapColor` and `_BlurLevelMatcap` from compile-time constants to runtime per-material properties, so matcap tint and blur can be driven per material (e.g. from `MatcapPresets`)

#1.1.10
- DCL_Toon: added `MatcapPresets` ScriptableObject + bundled matcap library as the shared source of truth for stylized-metallic matcaps (consumed by aang-renderer, unity-explorer and future repos)

#1.1.9
- DCL_Toon: added normal map support (base/high-color/rim shading + DepthNormals for SSAO)
- DCL_Toon: added stylized metallic via matcap, driven by per-renderer `_IsStylizedMetallic` and an optional `_MetallicGlossMap` mask

#1.1.8
- Reverted gltfast version to 5.0.0

#1.1.7
- Updated gltfast to 6.16.1

#1.1.5
- Updated gltfast to 5.0.0

#1.1.4
- Changed dependency name as the package name was rolled back 

#1.1.3
- Pulled changes from https://github.com/decentraland/unity-renderer/pull/3667

#1.1.2
- Changed the gltfast dependency repository

#1.1.1
- Updated gltFast version and fixed compile errors

#1.1.0
- Updated to unity 2021.3.14f1