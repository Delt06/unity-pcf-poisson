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
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _POISSON_SHADOWS _POISSON_SHADOWS_STRATIFIED _POISSON_SHADOWS_ROTATED
			#pragma multi_compile _ _POISSON_SHADOWS_DISK_4 _POISSON_SHADOWS_DISK_16

			#pragma shader_feature_local POISSON_SAMPLING_STRATIFIED
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			#if defined(_POISSON_SHADOWS) || defined(_POISSON_SHADOWS_STRATIFIED) || defined(_POISSON_SHADOWS_ROTATED)
			#define _POISSON_SHADOWS_ANY
			#endif

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

			float _PoissonShadowsSpreadInv;
			TEXTURE3D(_PoissonShadowsRotationTexture);
			SAMPLER(sampler_PoissonShadowsRotationTexture);

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

			#ifdef _POISSON_SHADOWS_DISK_4

			#define POISSON_DISK_SIZE 4

			static const float2 poisson_disk[] = {
              float2( -0.94201624, -0.39906216 ),
              float2( 0.94558609, -0.76890725 ),
              float2( -0.094184101, -0.92938870 ),
              float2( 0.34495938, 0.29387760 )
            };
			#elif defined(_POISSON_SHADOWS_DISK_16)

			#define POISSON_DISK_SIZE 16

			static const float2 poisson_disk[] = {
               float2( -0.94201624, -0.39906216 ), 
               float2( 0.94558609, -0.76890725 ), 
               float2( -0.094184101, -0.92938870 ), 
               float2( 0.34495938, 0.29387760 ), 
               float2( -0.91588581, 0.45771432 ), 
               float2( -0.81544232, -0.87912464 ), 
               float2( -0.38277543, 0.27676845 ), 
               float2( 0.97484398, 0.75648379 ), 
               float2( 0.44323325, -0.97511554 ), 
               float2( 0.53742981, -0.47373420 ), 
               float2( -0.26496911, -0.41893023 ), 
               float2( 0.79197514, 0.19090188 ), 
               float2( -0.24188840, 0.99706507 ), 
               float2( -0.81409955, 0.91437590 ), 
               float2( 0.19984126, 0.78641367 ), 
               float2( 0.14383161, -0.14100790 ) 
            };

			#else

			#define POISSON_DISK_SIZE 0

			static const float2 poisson_disk[1];

			#endif

			float random_value(const float4 seed4)
			{
                const float dot_product = dot(seed4, float4(12.9898,78.233,45.164,94.673));
                return frac(sin(dot_product) * 43758.5453);
			}

			real sample_shadowmap_poisson(TEXTURE2D_SHADOW_PARAM(shadow_map, sampler_shadow_map), float4 shadow_coord, half4 shadow_params, float3 position_ws, const bool is_perspective_projection = true)
            {
                // Compiler will optimize this branch away as long as isPerspectiveProjection is known at compile time
                if (is_perspective_projection)
                    shadow_coord.xyz /= shadow_coord.w;

			    real attenuation = 0;

			    #ifdef _POISSON_SHADOWS_ROTATED
			    float2 rotation = SAMPLE_TEXTURE3D(_PoissonShadowsRotationTexture, sampler_PoissonShadowsRotationTexture, position_ws.xyz * 100).xy;
			    rotation = rotation * 2 - 1;
			    #endif

			    UNITY_UNROLL
			    for (int i=0;i<POISSON_DISK_SIZE;i++)
			    {
			        float2 poisson_disk_sample;
			        
			        #ifdef _POISSON_SHADOWS_STRATIFIED
			        const uint index = uint(POISSON_DISK_SIZE * random_value(float4(position_ws, i))) % POISSON_DISK_SIZE;
			        poisson_disk_sample = poisson_disk[index];
			        #elif defined(_POISSON_SHADOWS_ROTATED)
			        poisson_disk_sample = poisson_disk[i];
			        poisson_disk_sample = float2(
                        rotation.x * poisson_disk_sample.x - rotation.y * poisson_disk_sample.y,
                        rotation.y * poisson_disk_sample.x + rotation.x * poisson_disk_sample.y
                        );
			        #else
                    poisson_disk_sample = poisson_disk[i];
			        #endif
			        
			        float3 sample_shadow_coord = shadow_coord.xyz;
			        sample_shadow_coord += float3(poisson_disk_sample * _PoissonShadowsSpreadInv, 0);
			        attenuation += SAMPLE_TEXTURE2D_SHADOW(shadow_map, sampler_shadow_map, sample_shadow_coord) / POISSON_DISK_SIZE;
                }

                const real shadow_strength = shadow_params.x;

                attenuation = LerpWhiteTo(attenuation, shadow_strength);

                // Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
                // TODO: We could use branch here to save some perf on some platforms.
                return BEYOND_SHADOW_FAR(shadow_coord) ? 1.0 : attenuation;
            }

			Light get_main_light_poisson(const float4 shadow_coord, const float3 position_ws)
			{
			    #ifdef _POISSON_SHADOWS_ANY
			    Light light = GetMainLight();
                const half4 shadow_params = GetMainLightShadowParams();
			    light.shadowAttenuation = sample_shadowmap_poisson(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadow_coord, shadow_params, position_ws, false);
			    #else
			    Light light = GetMainLight(shadow_coord);
			    #endif

			    light.shadowAttenuation = lerp(light.shadowAttenuation, 1, GetMainLightShadowFade(position_ws));

			    return light;
			}
			
			half4 frag (const v2f i) : SV_Target
			{
                const float4 shadow_coord = TransformWorldToShadowCoord(i.position_ws);
			    const Light light = get_main_light_poisson(shadow_coord, i.position_ws);
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