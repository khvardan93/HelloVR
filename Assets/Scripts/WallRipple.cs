using UnityEngine;

public class WallRipple : MonoBehaviour
{
    private Material _wallMaterial;
    private float _currentRippleStrength = 0f;

    void Start()
    {
        // We get the material from the Wall's Renderer so we can talk to the Shader
        _wallMaterial = GetComponent<Renderer>().material;
    }

    void Update()
    {
        // Decay the ripple over time so the wall settles down
        if (_currentRippleStrength > 0)
        {
            _currentRippleStrength -= Time.deltaTime * 2.0f; 
            _wallMaterial.SetFloat("_RippleStrength", _currentRippleStrength);
        }
    }

    // This function runs when the BALL hits the WALL
    private void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Ball"))
        {
            // 1. Get the exact point on the WALL where the ball hit
            Vector3 hitPoint = collision.contacts[0].point;

            // 2. Tell the Wall's shader: " The center of the ripple is HERE"
            _wallMaterial.SetVector("_HitPosition", hitPoint);

            // 3. Turn on the ripple effect
            _currentRippleStrength = 1.0f;
            _wallMaterial.SetFloat("_RippleStrength", _currentRippleStrength);
        }
    }
}