using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class PoissonSamplingShadows : ScriptableRendererFeature
{
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
    private PoissonSamplingRendererPass _pass;

    public override void Create()
    {
        _pass = new PoissonSamplingRendererPass
        {
            Mode = Mode,
            Spread = Spread,
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }

    private void OnDestroy()
    {
        _pass.Dispose();
    }
}