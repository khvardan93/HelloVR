using UnityEngine;

public class WallRipple : MonoBehaviour
{
    private Material _material;
    private static int MAX_COUNT = 100;

    // Fixed size arrays to match the Shader
    private Vector4[] _hitData = new Vector4[MAX_COUNT];
    
    // Tracks which slot (0-9) to use next
    private int _currentIndex = 0;

    private void Start()
    {
        _material = GetComponent<Renderer>().material;

        // Initialize arrays so the shader doesn't get garbage data
        // (Though C# defaults to 0, it's good practice)
        for (int i = 0; i < MAX_COUNT; i++)
        {
            _hitData[i] = new Vector4(0, 0, 0, -100f); // 0 means "inactive" in our shader logic
        }
    }
    
    private void Update()
    {
        // Keep the clock synced!
        _material.SetFloat("_GameTime", Time.time);
    }
    
    // This function runs when the BALL hits the WALL
    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ball"))
        {
            Vector3 hitPoint = collision.contacts[0].point;

            // PACK THE DATA: X, Y, Z = Position. W = Time.
            _hitData[_currentIndex] = new Vector4(hitPoint.x, hitPoint.y, hitPoint.z, Time.time);

            // Send the single array to the shader
            _material.SetVectorArray("_HitData", _hitData);

            // Increment and loop
            _currentIndex = (_currentIndex + 1) % 10;
            
            Destroy(collision.gameObject);
        }
    }
}