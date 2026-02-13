using UnityEngine;

public class GyroControl : MonoBehaviour
{
    private GameObject cameraContainer;
    private Quaternion rotationFix;

    void Start()
    {
        // 1. Create a parent object to hold the camera transform
        // This helps neutralize the initial phone rotation offset
        cameraContainer = new GameObject("Camera Container");
        cameraContainer.transform.position = transform.position;
        transform.SetParent(cameraContainer.transform);

        // 2. Enable the Gyroscope
        if (SystemInfo.supportsGyroscope)
        {
            Input.gyro.enabled = true;

            // 3. Fix the rotation difference between Unity (Left-handed) 
            // and Phone Gyro (Right-handed)
            cameraContainer.transform.rotation = Quaternion.Euler(90f, 90f, 0f);
            rotationFix = new Quaternion(0, 0, 1, 0);
        }
    }

    void Update()
    {
        if (SystemInfo.supportsGyroscope)
        {
            // Read the gyro attitude
            Quaternion gyroAttitude = Input.gyro.attitude;
            
            // Remap coordinates for Unity
            // We swap Y and Z and invert types to match Unity's coordinate system
            transform.localRotation = gyroAttitude * rotationFix;
        }
    }
}