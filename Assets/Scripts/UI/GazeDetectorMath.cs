using UnityEngine;

public class GazeDetectorMath : MonoBehaviour
{
    public Transform vrCamera;
    
    // How precise the look needs to be. 
    // 1.0 = looking exactly at the dead center.
    // 0.95 = a little bit of leeway (standard).
    public float focusThreshold = 0.95f; 
    
    private bool _isFocused = false;

    void Update()
    {
        if (vrCamera == null) return;

        // 1. Get the direction from the camera to this Canvas
        Vector3 directionToCanvas = (transform.position - vrCamera.position).normalized;

        // 2. Compare it to the direction the camera is facing
        // Dot product returns 1 if looking exactly at it, -1 if looking away
        float lookAccuracy = Vector3.Dot(vrCamera.forward, directionToCanvas);

        // 3. Check if it passes our threshold
        if (lookAccuracy >= focusThreshold)
        {
            if (!_isFocused)
            {
                _isFocused = true;
                Debug.Log("Player is looking at the Canvas!");
                // Do visual effect here
            }
        }
        else
        {
            if (_isFocused)
            {
                _isFocused = false;
                Debug.Log("Player looked away.");
            }
        }
    }
}