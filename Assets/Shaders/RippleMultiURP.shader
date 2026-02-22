Shader "Custom/RippleMultiURP"
{
    Properties
    {
        _BaseColor ("Wall Color", Color) = (0.1, 0.1, 0.1, 1)
        _MainTex ("Wall Texture", 2D) = "white" {}
        [HDR] _RippleColor ("Ripple Color", Color) = (0, 1, 1, 1)
        
        _WaveSpeed ("Speed", Float) = 5
        _WaveFrequency ("Frequency", Float) = 10
        _MaxDistance ("Max Size", Float) = 5
        _Duration ("Duration", Float) = 1
        _GameTime ("Game Time", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define MAX_RIPPLES 100

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _MainTex_ST;
                float4 _RippleColor;
                float _WaveSpeed;
                float _WaveFrequency;
                float _MaxDistance;
                float _Duration;
                float _GameTime;

                // FIX: One single array. 
                // XYZ = Position, W = Start Time.
                // This prevents all GPU memory alignment bugs.
                float4 _HitData[MAX_RIPPLES]; 
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 finalColor = texColor.rgb * _BaseColor.rgb;

                float totalRippleMask = 0;

                for (int i = 0; i < MAX_RIPPLES; i++)
                {
                    // Unpack the data
                    float3 hitPos = _HitData[i].xyz;
                    float startTime = _HitData[i].w;

                    if (startTime <= 0) continue;

                    float timeAlive = _GameTime - startTime;
                    if (timeAlive < 0) continue;

                    float dist = distance(input.positionWS, hitPos);

                    if (dist < _MaxDistance)
                    {
                        float waveValue = sin(dist * _WaveFrequency - timeAlive * _WaveSpeed);
                        float mask = smoothstep(0.5, 1.0, waveValue);
                        float distFade = 1.0 - saturate(dist / _MaxDistance);
                        float timeFade = 1.0 - saturate(timeAlive / _Duration); // Fades out over 2 seconds

                        totalRippleMask += mask * distFade * timeFade;
                    }
                }

                totalRippleMask = saturate(totalRippleMask);
                finalColor = lerp(finalColor, _RippleColor.rgb, totalRippleMask);

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}