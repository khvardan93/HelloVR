Shader "Custom/RippleURP"
{
    // --- PROPERTIES ---
    // These are the variables exposed to the Unity Inspector and C# Scripts.
    Properties
    {
        // The base color of the wall (Tint)
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        
        // The texture of the wall (e.g., Bricks, Concrete)
        _MainTex ("Base Map", 2D) = "white" {}

        // --- CUSTOM RIPPLE PROPERTIES ---
        // The World Space position where the ball hit. 
        // Updated by C# script: material.SetVector("_HitPosition", point);
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)

        // The intensity of the wave. 0 = Flat, 1 = Huge Wave.
        // Updated by C# script: material.SetFloat("_RippleStrength", val);
        _RippleStrength ("Ripple Strength", Float) = 0

        // How fast the wave expands outward.
        _WaveSpeed ("Wave Speed", Float) = 10

        // How tight the rings are (Higher = more rings).
        _WaveFrequency ("Wave Frequency", Float) = 5
    }

    SubShader
    {
        // --- TAGS ---
        // "RenderPipeline" = "UniversalPipeline" tells Unity this is for URP only.
        // "RenderType" = "Opaque" tells Unity to draw this before transparent objects.
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // The "UniversalForward" tag tells URP this is the main lighting/drawing pass.
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            // Register our programmable stages
            #pragma vertex vert
            #pragma fragment frag

            // --- INCLUDES ---
            // This is the URP Core library. It contains essential helper functions
            // like TransformObjectToHClip, TransformObjectToWorld, etc.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // --- ATTRIBUTES (Input from Mesh) ---
            struct Attributes
            {
                float4 positionOS : POSITION; // Vertex Position in Object Space (Local)
                float2 uv : TEXCOORD0;        // Texture Coordinates
                float3 normalOS : NORMAL;     // Vertex Normal (Direction pointing "out")
            };

            // --- VARYINGS (Data passing from Vertex -> Fragment) ---
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Final Screen Position (Homogeneous Clip Space)
                float2 uv : TEXCOORD0;            // Texture Coordinates
                float waveDebug : TEXCOORD1;      // (Optional) Passing wave height to visualize it
            };

            // --- CBUFFER (Unity Per Material) ---
            // This wrap is REQUIRED for SRP Batcher compatibility (Performance).
            // The variable names must match the Properties block exactly.
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _MainTex_ST; // Needed for Tiling/Offset of texture
                float4 _HitPosition;
                float _RippleStrength;
                float _WaveSpeed;
                float _WaveFrequency;
            CBUFFER_END

            // Texture Samplers (Defined outside CBUFFER)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // --- VERTEX SHADER ---
            // Runs once for every vertex on the mesh.
            Varyings vert(Attributes input)
            {
                Varyings output;

                // 1. Convert Object Space (Local) to World Space
                // We need World Space to compare distance with the external "Hit Position".
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                // 2. Calculate Distance
                // How far is this specific vertex from the impact point?
                float dist = distance(positionWS, _HitPosition.xyz);

                // 3. Calculate Sine Wave
                // sin(Distance * Frequency - Time * Speed)
                // We subtract Time so the wave moves OUTWARDS (expands).
                // _Time.y is Unity's built-in time variable (seconds).
                float wave = sin(dist * _WaveFrequency - _Time.y * _WaveSpeed);

                // 4. Attenuation (Optional Polish)
                // This makes the wave get smaller the further it is from the center.
                // "+ 1.0" prevents division by zero.
                float decay = 1.0 / (dist + 1.0); 

                // 5. Apply Displacement
                // We move the vertex along its Normal vector.
                // We multiply by _RippleStrength to turn it On/Off from C#.
                // We multiply by 'decay' to make it fade out at the edges.
                float3 displacement = input.normalOS * wave * _RippleStrength * decay;
                
                // Add the displacement to the original local position
                float3 newPositionOS = input.positionOS.xyz + displacement;

                // 6. Final Conversion
                // Convert the modified position to Clip Space (Screen Coordinates)
                output.positionHCS = TransformObjectToHClip(newPositionOS);

                // Pass UVs and Debug Data
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.waveDebug = wave * _RippleStrength; // Pass wave height for coloring

                return output;
            }

            // --- FRAGMENT SHADER ---
            // Runs once for every pixel on the screen.
            half4 frag(Varyings input) : SV_Target
            {
                // 1. Sample the Texture
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                // 2. Add Tint
                float4 finalColor = texColor * _BaseColor;

                // 3. (Optional) Visualize the Ripple
                // This adds a slight blue tint to the "high" parts of the wave
                // and a red tint to the "low" parts, making it look 3D.
                // You can remove this line if you want the pure texture.
                finalColor.rgb += input.waveDebug * 0.2; 

                return finalColor;
            }
            ENDHLSL
        }
    }
}
