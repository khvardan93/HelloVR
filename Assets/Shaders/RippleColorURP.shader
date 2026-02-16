Shader "Custom/RippleColorURP"
{
    Properties
    {
        // --- BASE APPEARANCE ---
        _BaseColor ("Wall Color", Color) = (0.5, 0.5, 0.5, 1)
        _MainTex ("Wall Texture", 2D) = "white" {}

        // --- RIPPLE APPEARANCE ---
        [HDR] _RippleColor ("Ripple Color", Color) = (0, 1, 1, 1) // Cyan (HDR for bloom)
        _RippleWidth ("Wave Thickness", Float) = 10
        
        // --- LOGIC ---
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)
        _WaveSpeed ("Speed", Float) = 5
        _WaveFrequency ("Frequency", Float) = 10
        _MaxDistance ("Max Size", Float) = 5 // How far the wave goes before disappearing
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
                float4 _HitPosition;
                float _RippleWidth;
                float _WaveSpeed;
                float _WaveFrequency;
                float _MaxDistance;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings vert(Attributes input)
            {
                Varyings output;
                // Standard setup - no vertex movement!
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 1. Base Wall Appearance
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 finalColor = texColor.rgb * _BaseColor.rgb;

                // 2. Calculate Ripple Logic
                float dist = distance(input.positionWS, _HitPosition.xyz);
                
                // Only calculate if within range (Optimization + Hard limit)
                if (dist < _MaxDistance)
                {
                    // Create the moving ring: sin(Distance - Time)
                    // We multiply by Frequency to control ring count
                    float waveValue = sin(dist * _WaveFrequency - _Time.y * _WaveSpeed);

                    // 3. Sharpen the Wave (Create the Gradient)
                    // Sine waves are -1 to 1. We want 0 to 1 (soft gradient) or sharper.
                    // smoothstep helps us control the "thickness" of the color band.
                    
                    // This logic makes a ring that is bright in the center and fades out
                    float rippleMask = smoothstep(0.5, 1.0, waveValue); 
                    
                    // 4. Fade out over distance (The "Splash" decay)
                    // 1.0 at center, 0.0 at MaxDistance
                    float distanceFade = 1.0 - saturate(dist / _MaxDistance);
                    
                    // Combine the wave shape with the distance fade
                    float finalAlpha = rippleMask * distanceFade * distanceFade; // Squared for nicer falloff

                    // 5. Mix the Colors!
                    // Lerp (Linear Interpolate) between Wall Color and Ripple Color
                    // If finalAlpha is 0, we see Wall. If 1, we see Ripple.
                    finalColor = lerp(finalColor, _RippleColor.rgb, finalAlpha);
                }

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}