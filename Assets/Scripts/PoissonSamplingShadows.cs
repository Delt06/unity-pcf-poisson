using UnityEngine;
using UnityEngine.Rendering.Universal;

public class PoissonSamplingShadows : ScriptableRendererFeature
{
    public enum PoissonDiskSize
    {
        _4,
        _16,
    }

    public enum PoissonSamplingMode
    {
        Disabled,
        PoissonSampling,
        PoissonSamplingStratified,
        PoissonSamplingRotated,
    }

    [Min(0.1f)]
    public float Spread = 700f;
    public PoissonSamplingMode Mode = PoissonSamplingMode.PoissonSampling;
    [HideInInspector]
    public Texture3D RotationSamplingTexture;

    public PoissonDiskSize DiskSize = PoissonDiskSize._16;

    private PoissonSamplingRendererPass _pass;

    private void OnDestroy()
    {
        _pass.Dispose();
    }

    public override void Create()
    {
        _pass = new PoissonSamplingRendererPass
        {
            Mode = Mode,
            Spread = Spread,
            DiskSize = DiskSize,
            RotationSamplingTexture = RotationSamplingTexture,
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}