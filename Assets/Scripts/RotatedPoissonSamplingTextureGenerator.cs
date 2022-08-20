#if UNITY_EDITOR
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

public class RotatedPoissonSamplingTextureGenerator : EditorWindow
{
    [SerializeField] [Min(1)]
    private int _size = 32;

    private void OnGUI()
    {
        _size = EditorGUILayout.IntField("Size", _size);

        if (GUILayout.Button("Generate"))
            Generate();
    }

    [MenuItem("Window/Rendering/Rotated Poisson Sampling Texture Generator")]
    public static void Open()
    {
        var window = CreateWindow<RotatedPoissonSamplingTextureGenerator>();
        window.titleContent = new GUIContent("Rotated Poisson Sampling Texture Generator");
        window.Show();
    }

    private void Generate()
    {
        var texture = new Texture3D(_size, _size, _size, TextureFormat.RG16, false);
        var pixels = texture.GetPixels();
        for (var i = 0; i < pixels.Length; i++)
        {
            var rotation = Random.value * Mathf.PI * 2;
            math.sincos(rotation, out var sin, out var cos);
            ref var pixel = ref pixels[i];

            static float Remap(float value) => (value + 1) * 0.5f;
            pixel.r = Remap(cos);
            pixel.g = Remap(sin);
        }

        texture.SetPixels(pixels);
        texture.Apply(false, true);

        var path = EditorUtility.SaveFilePanelInProject(
            "Save texture",
            "RotatedPoissonSamplingTexture",
            "asset",
            "Save texture"
        );

        if (path.Length == 0) return;

        AssetDatabase.CreateAsset(texture, path);
        AssetDatabase.SaveAssets();
    }
}

#endif