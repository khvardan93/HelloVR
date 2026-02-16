Shader "Custom/RippleWaterURP"
{
    Properties
    {
        _BaseColor ("Water Color", Color) = (0, 0.5, 1, 1)
        _Smoothness ("Glossiness", Range(0,1)) = 0.9
        
        // --- RIPPLE SETTINGS ---
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)
        _RippleStrength ("Wave Height", Float) = 0
        _WaveSpeed ("Travel Speed", Float) = 2
        _WaveFrequency ("Ring Density", Float) = 10
        _WaveFalloff ("Decay Rate", Float) = 2
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT; // Needed for recalculating normals
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Smoothness;
                float4 _HitPosition;
                float _RippleStrength;
                float _WaveSpeed;
                float _WaveFrequency;
                float _WaveFalloff;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                // 1. Get World Position
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
                // 2. Calculate Distance from Hit Point
                float dist = distance(positionWS, _HitPosition.xyz);

                // --- THE WATER MATH ---
                
                // A. The Wave Formula: sin(Distance - Time)
                // We subtract time so the rings move OUTWARD.
                float timeFactor = _Time.y * _WaveSpeed;
                float wavePhase = dist * _WaveFrequency - timeFactor;
                float baseWave = sin(wavePhase);

                // B. Decay (The "Splash" Effect)
                // Waves get smaller further away. 
                // We use 'exp' for a smooth natural fade.
                float decay = exp(-dist * _WaveFalloff);
                
                // C. Final Height
                float waveHeight = baseWave * _RippleStrength * decay;

                // D. Apply Height to Vertex
                // Move vertex UP/OUT along its normal
                float3 newPositionWS = positionWS + (TransformObjectToWorldNormal(input.normalOS) * waveHeight);


                // --- RECALCULATE NORMALS (The "Liquid" Look) ---
                // To make light bounce correctly, we must tilt the normal vector 
                // based on the steepness (derivative) of the wave.
                
                // Derivative of sin(x) is cos(x).
                float waveDerivative = cos(wavePhase) * _WaveFrequency * _RippleStrength * decay;
                
                // We dampen the derivative slightly by the decay to prevent sharp spikes far away
                // (Simplified math for performance)

                // Get the direction from the hit point to this vertex
                float3 rippleDir = normalize(positionWS - _HitPosition.xyz);
                
                // Tilt the normal towards the ripple direction based on slope
                float3 originalNormalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 newNormalWS = originalNormalWS - (rippleDir * waveDerivative);


                // --- FINAL OUTPUT ---
                output.positionHCS = TransformWorldToHClip(newPositionWS);
                output.positionWS = newPositionWS;
                output.normalWS = normalize(newNormalWS); // Normalize to keep lighting correct

                return output;
            }

            half4 frag1(Varyings input) : SV_Target
            {
                // Simple Blinn-Phong Specular Lighting (Shiny Water)
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(input.positionWS));
                float3 normal = normalize(input.normalWS);

                // Diffuse (Base Color)
                float NdotL = max(0, dot(normal, lightDir));
                float3 diffuse = NdotL * _BaseColor.rgb;

                // Specular (The Shine)
                float3 halfVector = normalize(lightDir + viewDir);
                float NdotH = max(0, dot(normal, halfVector));
                float specular = pow(NdotH, _Smoothness * 100) * _Smoothness;

                return half4(diffuse + specular, 1);
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // Simple Blinn-Phong Specular Lighting (Shiny Water)
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(input.positionWS));
                float3 normal = normalize(input.normalWS);

                // 2. Direct Lighting (The Sun)
                // This creates the bright side and the black side
                float NdotL = max(0, dot(normal, lightDir));
                float3 directDiffuse = NdotL * _BaseColor.rgb * mainLight.color;

                // 3. Ambient Lighting (The Shadows) - NEW STEP!
                // SampleSH grabs the color of your Skybox/Environment Lighting
                float3 ambient = SampleSH(normal); 
                // Multiply ambient by BaseColor so the shadow isn't grey, but dark blue
                float3 indirectDiffuse = ambient * _BaseColor.rgb;

                // 4. Specular (The Shine)
                float3 halfVector = normalize(lightDir + viewDir);
                float NdotH = max(0, dot(normal, halfVector));
                // Multiply by NdotL to prevent shine on the back side of waves
                float specular = pow(NdotH, _Smoothness * 100) * _Smoothness * NdotL;

                // 5. Combine: Direct + Indirect + Shine
                float3 finalColor = directDiffuse + indirectDiffuse + specular;

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}