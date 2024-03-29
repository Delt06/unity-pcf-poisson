﻿using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PoissonSamplingRendererPass : ScriptableRenderPass, IDisposable
{
    private const string PoissonShadowsKeyword = "_POISSON_SHADOWS";
    private const string PoissonShadowsStratifiedKeyword = "_POISSON_SHADOWS_STRATIFIED";
    private const string PoissonShadowsRotatedKeyword = "_POISSON_SHADOWS_ROTATED";

    private const string PoissonShadowsDisk4Keyword = "_POISSON_SHADOWS_DISK_4";
    private const string PoissonShadowsDisk16Keyword = "_POISSON_SHADOWS_DISK_16";


    private static readonly int PoissonShadowsSpreadInvId = Shader.PropertyToID("_PoissonShadowsSpreadInv");
    private static readonly int PoissonShadowsRotationTextureId = Shader.PropertyToID("_PoissonShadowsRotationTexture");

    public PoissonSamplingRendererPass() => renderPassEvent = RenderPassEvent.BeforeRendering;

    public PoissonSamplingShadows.PoissonSamplingMode Mode { get; set; }

    public float Spread { get; set; }

    public PoissonSamplingShadows.PoissonSamplesCount SamplesCount { get; set; }

    public Texture3D RotationSamplingTexture { get; set; }


    public void Dispose()
    {
        Shader.DisableKeyword(PoissonShadowsKeyword);
        Shader.DisableKeyword(PoissonShadowsStratifiedKeyword);
        Shader.DisableKeyword(PoissonShadowsRotatedKeyword);

        Shader.DisableKeyword(PoissonShadowsDisk4Keyword);
        Shader.DisableKeyword(PoissonShadowsDisk16Keyword);

        Shader.SetGlobalTexture(PoissonShadowsRotationTextureId, null);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get();

        switch (Mode)
        {
            case PoissonSamplingShadows.PoissonSamplingMode.Disabled:
                cmd.DisableShaderKeyword(PoissonShadowsKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsStratifiedKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsRotatedKeyword);
                break;
            case PoissonSamplingShadows.PoissonSamplingMode.PoissonSampling:
                cmd.EnableShaderKeyword(PoissonShadowsKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsStratifiedKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsRotatedKeyword);
                break;
            case PoissonSamplingShadows.PoissonSamplingMode.PoissonSamplingStratified:
                cmd.DisableShaderKeyword(PoissonShadowsKeyword);
                cmd.EnableShaderKeyword(PoissonShadowsStratifiedKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsRotatedKeyword);
                break;
            case PoissonSamplingShadows.PoissonSamplingMode.PoissonSamplingRotated:
                cmd.DisableShaderKeyword(PoissonShadowsKeyword);
                cmd.DisableShaderKeyword(PoissonShadowsStratifiedKeyword);
                cmd.EnableShaderKeyword(PoissonShadowsRotatedKeyword);
                break;
            default:
                throw new ArgumentOutOfRangeException();
        }

        if (Mode != PoissonSamplingShadows.PoissonSamplingMode.Disabled)
        {
            switch (SamplesCount)
            {
                case PoissonSamplingShadows.PoissonSamplesCount._4:
                    cmd.EnableShaderKeyword(PoissonShadowsDisk4Keyword);
                    cmd.DisableShaderKeyword(PoissonShadowsDisk16Keyword);
                    break;
                case PoissonSamplingShadows.PoissonSamplesCount._16:
                    cmd.DisableShaderKeyword(PoissonShadowsDisk4Keyword);
                    cmd.EnableShaderKeyword(PoissonShadowsDisk16Keyword);
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
        else
        {
            cmd.DisableShaderKeyword(PoissonShadowsDisk4Keyword);
            cmd.DisableShaderKeyword(PoissonShadowsDisk16Keyword);
        }

        cmd.SetGlobalTexture(PoissonShadowsRotationTextureId,
            Mode == PoissonSamplingShadows.PoissonSamplingMode.PoissonSamplingRotated
                ? RotationSamplingTexture
                : Texture2D.blackTexture
        );


        cmd.SetGlobalFloat(PoissonShadowsSpreadInvId, 1f / Spread);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}