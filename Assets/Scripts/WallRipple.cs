using UnityEngine;

public class WallRipple : MonoBehaviour
{
    private Material _material;

    // Fixed size arrays to match the Shader
    private Vector4[] _hitPositions = new Vector4[1000];
    private float[] _hitStartTimes = new float[1000];
    
    // Tracks which slot (0-9) to use next
    private int _currentIndex = 0;

    private void Start()
    {
        _material = GetComponent<Renderer>().material;

        // Initialize arrays so the shader doesn't get garbage data
        // (Though C# defaults to 0, it's good practice)
        for (int i = 0; i < 1000; i++)
        {
            _hitStartTimes[i] = 0; // 0 means "inactive" in our shader logic
        }
    }
    
    // This function runs when the BALL hits the WALL
    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ball"))
        {
            Vector3 hitPoint = collision.contacts[0].point;

            // 1. Record the Hit
            _hitPositions[_currentIndex] = hitPoint;
            
            // 2. Record the Time (Unity's Time.timeSinceLevelLoad matches _Time.y)
            _hitStartTimes[_currentIndex] = Time.timeSinceLevelLoad;

            // 3. Send Arrays to Shader
            // Note: We send the WHOLE array every time. This is fast enough.
            _material.SetVectorArray("_HitPositions", _hitPositions);
            _material.SetFloatArray("_HitStartTimes", _hitStartTimes);

            // 4. Increment Index (Loop back to 0 if we hit 10)
            _currentIndex++;
            if (_currentIndex >= 10)
            {
                _currentIndex = 0;
            }
        }
    }
}