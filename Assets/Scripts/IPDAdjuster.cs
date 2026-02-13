using UnityEngine;

public class IPDAdjuster : MonoBehaviour
{
    public Transform leftEye;
    public Transform rightEye;
    
    // Range from 0 to 0.1 (0cm to 10cm)
    [Range(0f, 0.1f)] 
    public float ipd = 0.064f; // Standard human IPD is ~64mm

    void Update()
    {
        // Apply half the distance to each eye
        float halfIPD = ipd / 2f;
        
        if(leftEye)
            leftEye.localPosition = new Vector3(-halfIPD, 0, 0);
            
        if(rightEye)
            rightEye.localPosition = new Vector3(halfIPD, 0, 0);
    }

    public void Test(float value)
    {
        ipd = value;
    }
}