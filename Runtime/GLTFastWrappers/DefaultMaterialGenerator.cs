using GLTFast;
using GLTFast.Materials;
using UnityEngine;

namespace DCL.GLTFast.Wrappers
{
    /// <summary>
    /// With this class we can override the material generation from GLTFast,
    /// in this case we are using the ShaderGraphMaterialGenerator that comes from GLTFast
    /// </summary>
    internal class DefaultMaterialGenerator : ShaderGraphMaterialGenerator
    {
        private const float CUSTOM_EMISSIVE_FACTOR = 5f;

        public override Material GenerateMaterial(global::GLTFast.Schema.Material gltfMaterial, IGltfReadable gltf, bool pointsSupport = false)
        {
            Material generatedMaterial = base.GenerateMaterial(gltfMaterial, gltf);

            if (gltfMaterial.emissive != Color.black) { generatedMaterial.SetColor(emissiveFactorPropId, gltfMaterial.emissive * CUSTOM_EMISSIVE_FACTOR); }

            return generatedMaterial;
        }
    }
}
