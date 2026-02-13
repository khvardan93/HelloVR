using UnityEngine;
using UnityEngine.InputSystem; // Required for Unity 6 Input

public class VRCameraNewInput : MonoBehaviour
{
    // The container to offset the camera
    private Transform camParent; 

    void Start()
    {
        // 1. Create a parent to neutralize initial rotation offset
        camParent = new GameObject("CamParent").transform;
        camParent.position = transform.position;
        transform.SetParent(camParent);

        // 2. Enable the sensors explicitly!
        // In the new system, sensors are often disabled by default to save battery.
        if (AttitudeSensor.current != null)
            InputSystem.EnableDevice(AttitudeSensor.current);
        
        // 3. Fix the initial rotation (90 degree rotation for landscape)
        camParent.rotation = Quaternion.Euler(90, 0, 0);
    }

    void Update()
    {
        // Check if the sensor exists
        if (AttitudeSensor.current != null)
        {
            // Read the rotation directly
            Quaternion rot = AttitudeSensor.current.attitude.ReadValue();
            
            // Remap coordinates: Unity 6 Input System usually matches the screen orientation
            // better, but we often still need to re-orient for VR landscape.
            // This specific remapping depends on if you locked the screen to Landscape Left.
            transform.localRotation = new Quaternion(rot.x, rot.y, -rot.z, -rot.w);
        }
    }
}