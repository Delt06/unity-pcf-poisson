Shader "Custom/Lit Poisson Sampling"
{
	Properties
	{
	    [MainColor]
		_BaseColor ("Albedo", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
		LOD 300

		Pass
		{
		    Name "ForwardLitPoissonSampling"
            Tags{"LightMode" = "UniversalForward"}
		    
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			struct appdata
			{
				float4 position_os : POSITION;
			    
				half2 uv : TEXCOORD0;
			    half3 normal_os : NORMAL;
			};

			struct v2f
			{
			    float4 position_cs : SV_POSITION;

                half2 uv : TEXCOORD0;
                half3 normal_ws : NORMAL;
                float3 position_ws : POSITION_WS;
            };

			CBUFFER_START(UnityPerMaterial)
			half4 _BaseColor;
			CBUFFER_END
			
			v2f vert (const appdata v)
			{
				v2f o;
                const float3 position_ws = TransformObjectToWorld(v.position_os.xyz);
				o.position_cs = TransformWorldToHClip(position_ws);
				o.uv = v.uv;
			    o.normal_ws = TransformObjectToWorldNormal(v.normal_os);
			    o.position_ws = position_ws;
				return o;
			}
			
			half4 frag (const v2f i) : SV_Target
			{
                const float4 shadow_coord = TransformWorldToShadowCoord(i.position_ws);
			    const Light light = GetMainLight(shadow_coord);
			    const half n_dot_l = saturate(dot(i.normal_ws, light.direction));

			    const half3 albedo = _BaseColor.rgb;
			    const half3 diffuse = albedo * n_dot_l * light.shadowAttenuation;
			    const half3 ambient = albedo * SampleSH(i.normal_ws);
			    
				return half4(diffuse + ambient, 1);
			}
			ENDHLSL
		}
	    
	    Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM

            #pragma vertex shadow_vert
            #pragma fragment shadow_frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;

            struct Attributes
            {
                float4 position_os   : POSITION;
                float3 normal_os     : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 position_cs   : SV_POSITION;
            };

            float4 get_shadow_position_h_clip(Attributes input)
            {
                const float3 position_ws = TransformObjectToWorld(input.position_os.xyz);
                const float3 normal_ws = TransformObjectToWorldNormal(input.normal_os);
                const float3 light_direction_ws = _LightDirection;
                float4 position_cs = TransformWorldToHClip(ApplyShadowBias(position_ws, normal_ws, light_direction_ws));

            #if UNITY_REVERSED_Z
                position_cs.z = min(position_cs.z, UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(position_cs.z, UNITY_NEAR_CLIP_VALUE);
            #endif

                return position_cs;
            }

            Varyings shadow_vert(const Attributes input)
            {
                Varyings output;

                output.uv = input.uv;
                output.position_cs = get_shadow_position_h_clip(input);
                return output;
            }

            half4 shadow_frag() : SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
        }
	}
}