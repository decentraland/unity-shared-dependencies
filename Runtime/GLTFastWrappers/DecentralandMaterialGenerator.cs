using DCL.Helpers;
using DCL.Shaders;
using GLTFast;
using GLTFast.Materials;
using GLTFast.Schema;
using UnityEngine;
using UnityEngine.Rendering;
using GLTFastMaterial = GLTFast.Schema.Material;
using Material = UnityEngine.Material;

namespace DCL.GLTFast.Wrappers
{
    public class DecentralandMaterialGenerator : MaterialGenerator
    {
        // Historically we have no data on why we have this intensity
        private const float EMISSIVE_HDR_INTENSITY = 5f;

        private Material material;
        private readonly Shader shader;

        public DecentralandMaterialGenerator(string shaderName) { shader = Shader.Find(shaderName); }
        public override Material GetDefaultMaterial() { return new Material(shader); }
        
        /// <summary>
        /// Here we convert a GLTFMaterial into our Material using our shaders
        /// </summary>
        /// <param name="gltfMaterial"></param>
        /// <param name="gltf"></param>
        /// <returns></returns>
        public override Material GenerateMaterial(GLTFastMaterial gltfMaterial, IGltfReadable gltf)
        {
            material = GetDefaultMaterial();
            material.name = gltfMaterial.name;

            if (gltfMaterial.extensions?.KHR_materials_pbrSpecularGlossiness != null)
            {
                var specGloss = gltfMaterial.extensions.KHR_materials_pbrSpecularGlossiness;

                SetColor(specGloss.diffuseColor);
                SetSpecularColor(specGloss.specularColor);
                SetGlossiness(specGloss.glossinessFactor);
                SetBaseMapTexture(specGloss.diffuseTexture, gltf);
                SetSpecularMapTexture(specGloss.specularGlossinessTexture, gltf);
            }
            // If there's a specular-glossiness extension, ignore metallic-roughness
            // (according to extension specification)
            else
            {
                PbrMetallicRoughness roughness = gltfMaterial.pbrMetallicRoughness;

                if (roughness != null)
                {
                    SetColor(roughness.baseColor);
                    SetBaseMapTexture(roughness.baseColorTexture, gltf);
                    SetMetallic(roughness.metallicFactor);
                    SetMetallicRoughnessTexture( gltf, roughness.metallicRoughnessTexture, roughness.roughnessFactor);
                }
            }

            SetBumpMapTexture( gltfMaterial.normalTexture, gltf);
            SetOcclusionTexture(  gltfMaterial.occlusionTexture, gltf);
            SetEmissiveColor( gltfMaterial.emissive);
            SetEmissiveTexture(  gltfMaterial.emissiveTexture, gltf);

            SetAlphaMode(gltfMaterial.alphaModeEnum, gltfMaterial.alphaCutoff);
            SetDoubleSided(gltfMaterial.doubleSided);
            
            SRPBatchingHelper.OptimizeMaterial(material);
            
            return material;
        }
        
        private void SetEmissiveColor( Color gltfMaterialEmissive)
        {
            if (gltfMaterialEmissive != Color.black)
            {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
                material.SetColor(ShaderUtils.EmissionColor, gltfMaterialEmissive * EMISSIVE_HDR_INTENSITY);
                material.EnableKeyword(ShaderUtils.KEYWORD_EMISSION);
            }
        }
        
        private void SetEmissiveTexture(TextureInfo emissiveTexture, IGltfReadable gltf)
        {
            if (TrySetTexture(
                    emissiveTexture,
                    material,
                    gltf,
                    ShaderUtils.EmissionMap,
                    ShaderUtils.EmissionMapRotation,
                    ShaderUtils.EmissionMapScaleTransform,
                    ShaderUtils.EmissionMapUVChannel
                ))
            {
                material.SetInt(ShaderUtils.EmissiveMapUVs, emissiveTexture.texCoord);
                material.EnableKeyword(ShaderUtils.KEYWORD_EMISSION);
            }
        }
        
        private void SetOcclusionTexture(OcclusionTextureInfo occlusionTexture, IGltfReadable gltf)
        {
            if (TrySetTexture(
                    occlusionTexture,
                    material,
                    gltf,
                    ShaderUtils.OcclusionMap,
                    ShaderUtils.OcclusionMapRotation,
                    ShaderUtils.OcclusionMapScaleTransform,
                    ShaderUtils.OcclusionMapUVChannel
                ))
            {
                material.EnableKeyword(ShaderUtils.KEYWORD_OCCLUSION);
                material.SetFloat(ShaderUtils.OcclusionStrength, occlusionTexture.strength);
            }
        }
        
        private void SetBumpMapTexture(NormalTextureInfo textureInfo, IGltfReadable gltf)
        {
            if (TrySetTexture(
                    textureInfo,
                    material,
                    gltf, 
                    ShaderUtils.BumpMap,
                    ShaderUtils.BumpMapScaleTransformPropId,
                    ShaderUtils.BumpMapRotationPropId,
                    ShaderUtils.BumpMapUVChannelPropId
                ))
            {
                material.SetInt(ShaderUtils.NormalMapUVs, textureInfo.texCoord);
                material.SetFloat(ShaderUtils.BumpScale, textureInfo.scale);
                material.EnableKeyword(ShaderUtils.KEYWORD_NORMALMAP);
            }
        }

        private void SetMetallicRoughnessTexture(IGltfReadable gltf, TextureInfo textureInfo, float roughnessFactor)
        {
            if (TrySetTexture(
                    textureInfo,
                    material,
                    gltf,
                    ShaderUtils.MetallicRoughnessMapPropId,
                    ShaderUtils.MetallicRoughnessMapScaleTransformPropId,
                    ShaderUtils.MetallicRoughnessMapRotationPropId,
                    ShaderUtils.MetallicRoughnessMapUVChannelPropId
                ))
            {
                SetSmoothness(1);
                material.SetInt(ShaderUtils.MetallicMapUVs, textureInfo.texCoord);
                material.EnableKeyword(ShaderUtils.KEYWORD_METALLICSPECGLOSSMAP);
            }
            else
            {
                SetSmoothness(1 - roughnessFactor);
            }
        }

        private void SetSmoothness(float roughnessFactor) { material.SetFloat(ShaderUtils.Smoothness, roughnessFactor); }

        private void SetMetallic(float metallicFactor) { material.SetFloat(ShaderUtils.Metallic, metallicFactor); }

        private void SetSpecularMapTexture(TextureInfo textureInfo, IGltfReadable gltf)
        {
            if(TrySetTexture(
                textureInfo,
                material,
                gltf,
                ShaderUtils.SpecGlossMap,
                ShaderUtils.SpecGlossMapScaleTransform,
                ShaderUtils.SpecGlossMapRotation,
                ShaderUtils.SpecGlossMapUVChannelPropId))
            {
                material.SetFloat(ShaderUtils.SmoothnessTextureChannel, 0);
                material.EnableKeyword(ShaderUtils.KEYWORD_SPECGLOSSMAP);
            }
        }

        private void SetBaseMapTexture(TextureInfo textureInfo, IGltfReadable gltf)
        {
            TrySetTexture(
                textureInfo,
                material,
                gltf,
                ShaderUtils.BaseMap,
                ShaderUtils.BaseMapRotation,
                ShaderUtils.BaseMapScaleTransform,
                ShaderUtils.BaseMapUVs
            );
        }

        private void SetSpecularColor(Color color) { material.SetVector(ShaderUtils.SpecColor, color); }

        private void SetGlossiness(float glossiness)
        {
            material.SetFloat(ShaderUtils.GlossMapScale, glossiness);
            material.SetFloat(ShaderUtils.Glossiness, glossiness);
        }

        private void SetColor(Color color) { material.SetColor(ShaderUtils.BaseColor, color); }

        private void SetAlphaMode(GLTFastMaterial.AlphaMode alphaMode, float alphaCutoff)
        {
            switch (alphaMode)
            {
                case GLTFastMaterial.AlphaMode.MASK:
                    material.SetOverrideTag(ShaderUtils.RENDERER_TYPE, "TransparentCutout");
                    material.SetInt(ShaderUtils.SrcBlend, (int)BlendMode.One);
                    material.SetInt(ShaderUtils.DstBlend, (int)BlendMode.Zero);
                    material.SetInt(ShaderUtils.ZWrite, 1);
                    material.SetFloat(ShaderUtils.AlphaClip, 1);
                    material.EnableKeyword(ShaderUtils.KEYWORD_ALPHA_TEST);
                    material.DisableKeyword(ShaderUtils.KEYWORD_ALPHA_PREMULTIPLY);
                    material.renderQueue = (int)RenderQueue.AlphaTest;

                    if (material.HasProperty(ShaderUtils.Cutoff))
                        material.SetFloat(ShaderUtils.Cutoff, alphaCutoff);

                    break;

                case GLTFastMaterial.AlphaMode.BLEND:
                    material.SetOverrideTag(ShaderUtils.RENDERER_TYPE, "Transparent");
                    material.SetInt(ShaderUtils.SrcBlend, (int)BlendMode.SrcAlpha);
                    material.SetInt(ShaderUtils.DstBlend, (int)BlendMode.OneMinusSrcAlpha);
                    material.SetInt(ShaderUtils.ZWrite, 0);
                    material.DisableKeyword(ShaderUtils.KEYWORD_ALPHA_TEST);
                    material.DisableKeyword(ShaderUtils.KEYWORD_ALPHA_PREMULTIPLY);
                    material.renderQueue = (int)RenderQueue.Transparent;
                    material.SetFloat(ShaderUtils.Cutoff, 0);
                    break;
                default:
                    material.SetOverrideTag(ShaderUtils.RENDERER_TYPE, "Opaque");
                    material.SetInt(ShaderUtils.SrcBlend, (int)BlendMode.One);
                    material.SetInt(ShaderUtils.DstBlend, (int)BlendMode.Zero);
                    material.SetInt(ShaderUtils.ZWrite, 1);
                    material.DisableKeyword(ShaderUtils.KEYWORD_ALPHA_TEST);
                    material.DisableKeyword(ShaderUtils.KEYWORD_ALPHA_PREMULTIPLY);
                    material.renderQueue = (int)RenderQueue.Geometry;
                    material.SetFloat(ShaderUtils.Cutoff, 0);
                    break;
            }
        }

        private void SetDoubleSided(bool doubleSided)
        {
            if (doubleSided)
            {
                material.SetInt(ShaderUtils.Cull, (int)CullMode.Off);
            }
            else
            {
                material.SetInt(ShaderUtils.Cull, (int)CullMode.Back);
            }

            material.doubleSidedGI = doubleSided;
        }
    }
}