Shader "Custom/RippleStepByStep"
{
    Properties
    {
        // 1. These are the variables you see in the Inspector
        _BaseColor ("Color", Color) = (1,1,1,1)
        
        _HitPosition ("Hit Position", Vector) = (0,0,0,0)
        _RippleStrength ("Ripple Strength", Float) = 0
        _WaveFrequency ("Wave Frequency", Float) = 5
    }

    SubShader
    {
        // 2. We tell Unity: "I am an Opaque object using URP"
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            // 3. This block contains the actual HLSL code
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Include URP core helper functions (like 'TransformObjectToHClip')
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Define our inputs
            struct Attributes
            {
                float4 positionOS : POSITION; // OS = Object Space (Local 3D position)
                float3 normalOS : NORMAL; // Object Space Normal
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // HCS = Homogeneous Clip Space (Screen position)
            };

            // Define our variable (Must match Properties exactly)
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _HitPosition;
                float _RippleStrength;
                float _WaveFrequency;
            CBUFFER_END

            // --- VERTEX SHADER: Runs once per Vertex (Corner) ---
            Varyings vert(Attributes input)
            {
                Varyings output;

                // 1. Get World Position
                // We need to know where this vertex is in the WORLD to compare it with the Ball's Hit Position.
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                // 2. Calculate Distance
                // distance() is a built-in HLSL function.
                float dist = distance(positionWS, _HitPosition.xyz);

                // 3. Create the Sine Wave
                // We use _Time.y (Unity's internal timer) to make it animate.
                // 'dist * frequency' makes rings.
                // '- _Time.y' makes the rings move OUTWARDS.
                float wave = sin(dist * _WaveFrequency - _Time.y * 10.0);

                // 4. Apply the Displacement
                // We take the ORIGINAL position (input.positionOS)
                // And add a push along the NORMAL vector.
                // We multiply by _RippleStrength so we can turn it off (0) or on (1).
                float3 displacedPosition = input.positionOS.xyz + (input.normalOS * wave * _RippleStrength);

                // 5. Convert to Screen Space
                output.positionHCS = TransformObjectToHClip(displacedPosition);

                return output;
            }

            // --- FRAGMENT SHADER: Runs once per Pixel ---
            half4 frag(Varyings input) : SV_Target
            {
                // Just return the color
                return _BaseColor;
            }
            ENDHLSL
        }
    }
}
