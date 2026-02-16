Shader "Custom/RippleVisualURP"
{
    Properties
    {
        _BaseColor ("Water Color", Color) = (0, 0.5, 1, 1)
        _Smoothness ("Glossiness", Range(0,1)) = 0.95
        
        // --- RIPPLE SETTINGS ---
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)
        _RippleStrength ("Wave Height", Float) = 1
        _WaveSpeed ("Travel Speed", Float) = 3
        _WaveFrequency ("Ring Density", Float) = 20
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
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
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
                
                // 1. Standard Vertex Transform (No Deformation!)
                // We just pass the flat mesh data to the pixel shader.
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // --- PER-PIXEL RIPPLE LOGIC ---
                // Since we are in the Fragment Shader, this runs for every tiny dot on the screen.
                // This means we can draw a round circle even on a square mesh!

                // 1. Calculate Distance from Hit Point to this specific PIXEL
                float dist = distance(input.positionWS, _HitPosition.xyz);

                // 2. Ripple Math (Same as before)
                float timeFactor = _Time.y * _WaveSpeed;
                float wavePhase = dist * _WaveFrequency - timeFactor;
                
                // 3. Calculate "Slope" (Derivative)
                // We don't care about height (sin) anymore, only the ANGLE (cos).
                // This tells light which way to bounce.
                float decay = exp(-dist * _WaveFalloff);
                float waveSlope = cos(wavePhase) * _RippleStrength * decay;

                // 4. Create the "Fake" Normal
                // Get the direction from the center of the ripple to this pixel
                float3 rippleDir = normalize(input.positionWS - _HitPosition.xyz);

                // Start with the flat wall normal
                float3 baseNormal = normalize(input.normalWS);
                
                // "Tilt" the normal based on the wave slope
                // We subtract the direction * slope to angle it away from the center
                float3 finalNormal = normalize(baseNormal - (rippleDir * waveSlope));


                // --- LIGHTING CALCULATION ---
                // Now we use the FAKE normal (finalNormal) to calculate light.
                // The light thinks the surface is curvy, but the mesh is actually flat.

                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(input.positionWS));

                // Ambient (Shadows)
                float3 ambient = SampleSH(finalNormal);

                // Diffuse (Sun)
                float NdotL = max(0, dot(finalNormal, lightDir));
                float3 diffuse = NdotL * mainLight.color * _BaseColor.rgb;

                // Specular (Shine)
                // This is where the effect really pops!
                float3 halfVector = normalize(lightDir + viewDir);
                float NdotH = max(0, dot(finalNormal, halfVector));
                float specular = pow(NdotH, _Smoothness * 500) * _Smoothness; // Sharper highlight

                // Combine
                float3 color = (diffuse + (ambient * _BaseColor.rgb)) + specular;
                
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}