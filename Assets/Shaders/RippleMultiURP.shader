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
        _RippleWidth ("Ripple Width", Float) = 1
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

            // Define the maximum number of ripples we can handle at once
            #define MAX_RIPPLES 10

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
                float _RippleWidth;

                // --- ARRAYS ---
                // We cannot expose arrays to the Inspector properties, 
                // but we can set them via C# script.
                float4 _HitPositions[MAX_RIPPLES]; // Where did we hit?
                float _HitStartTimes[MAX_RIPPLES]; // When did we hit? (Time.time)
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

                // We will accumulate the "strength" of all ripples here
                float totalRippleMask = 0;

                // --- THE LOOP ---
                // Check all 10 possible ripple slots
                for (int i = 0; i < MAX_RIPPLES; i++)
                {
                    float3 hitPos = _HitPositions[i].xyz;
                    float startTime = _HitStartTimes[i];

                    // Optimization: If startTime is 0, this slot is empty/unused
                    if (startTime <= 0) continue;

                    // 1. Calculate how long this specific ripple has been alive
                    float timeAlive = _Time.y - startTime;

                    // If time is negative (future?) or too old, skip it
                    // (Optional: You can add a max duration check here)
                    if (timeAlive < 0) continue;

                    // 2. Distance from THIS hit point
                    float dist = distance(input.positionWS, hitPos);

                    // 3. Logic: Wave moves based on timeAlive
                    if (dist < _MaxDistance)
                    {
                        // The wave moves OUTWARD as time increases
                        float waveValue = sin(dist * _WaveFrequency - timeAlive * _WaveSpeed);

                        // Create the ring shape
                        float mask = smoothstep(0.5, 1.0, waveValue);
                        
                        // Decay over distance
                        float distFade = 1.0 - saturate(dist / _MaxDistance);
                        
                        // Decay over TIME (So they fade out after a few seconds)
                        // Let's say it lasts 2 seconds.
                        float timeFade = 1.0 - saturate(timeAlive / 2.0);

                        // Combine
                        totalRippleMask += mask * distFade * timeFade;
                    }
                }

                // Clamp the result so multiple ripples don't turn pure white instantly
                totalRippleMask = saturate(totalRippleMask);

                // Mix the Wall Color with the Ripple Color
                finalColor = lerp(finalColor, _RippleColor.rgb, totalRippleMask);

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}