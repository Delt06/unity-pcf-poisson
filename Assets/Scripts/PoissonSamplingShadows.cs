﻿using UnityEngine;
using UnityEngine.Rendering.Universal;

public class PoissonSamplingShadows : ScriptableRendererFeature
{
    public enum PoissonSamplesCount
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

    public PoissonSamplingMode Mode = PoissonSamplingMode.PoissonSampling;
    [Min(0.1f)]
    public float Spread = 700f;
    [HideInInspector]
    public Texture3D RotationSamplingTexture;

    public PoissonSamplesCount SamplesCount = PoissonSamplesCount._16;

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
            SamplesCount = SamplesCount,
            RotationSamplingTexture = RotationSamplingTexture,
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}