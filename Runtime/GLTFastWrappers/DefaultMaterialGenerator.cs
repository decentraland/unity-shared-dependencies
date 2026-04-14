using GLTFast;
using GLTFast.Materials;
using GLTFast.Schema;
using System;
using UnityEngine;
using Material = UnityEngine.Material;

namespace DCL.GLTFast.Wrappers
{
    /// <summary>
    /// With this class we can override the material generation from GLTFast,
    /// in this case we are using the ShaderGraphMaterialGenerator that comes from GLTFast
    /// </summary>
    internal class DefaultMaterialGenerator : ShaderGraphMaterialGenerator
    {
        private const float CUSTOM_EMISSIVE_FACTOR = 5f;

        public override Material GenerateMaterial(MaterialBase gltfMaterial, IGltfReadable gltf, bool pointsSupport = false)
        {
            Material generatedMaterial = base.GenerateMaterial(gltfMaterial, gltf, pointsSupport);

            SetMaterialName(generatedMaterial, gltfMaterial);

            if (gltfMaterial.Emissive != Color.black) { generatedMaterial.SetColor(MaterialProperty.EmissiveFactor, gltfMaterial.Emissive * CUSTOM_EMISSIVE_FACTOR); }

            return generatedMaterial;

            // This step is important if we want to keep the functionality of skin and hair colouring
            void SetMaterialName(Material material, MaterialBase materialBase)
            {
                material.name = "material";

                if (materialBase.name.Contains("skin", StringComparison.InvariantCultureIgnoreCase))
                    material.name += "_skin";

                if (materialBase.name.Contains("hair", StringComparison.InvariantCultureIgnoreCase))
                    material.name += "_hair";
            }
        }
    }
}
