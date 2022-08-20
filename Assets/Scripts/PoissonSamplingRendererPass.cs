using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PoissonSamplingRendererPass : ScriptableRenderPass
{
    private const string PoissonShadowsKeyword = "_POISSON_SHADOWS";
    private const string PoissonShadowsStratifiedKeyword = "_POISSON_SHADOWS_STRATIFIED";
    private const string PoissonShadowsRotatedKeyword = "_POISSON_SHADOWS_ROTATED";

    private static readonly int PoissonShadowsSpreadInvId = Shader.PropertyToID("_PoissonShadowsSpreadInv");

    public PoissonSamplingRendererPass() => renderPassEvent = RenderPassEvent.BeforeRendering;

    public PoissonSamplingShadows.PoissonSamplingMode Mode { get; set; }

    public float Spread { get; set; }

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

        cmd.SetGlobalFloat(PoissonShadowsSpreadInvId, 1f / Spread);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}