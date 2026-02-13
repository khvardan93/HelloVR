using UnityEngine;
using UnityEngine.InputSystem; // Required for Unity 6 Input

public class VRCameraNewInput : MonoBehaviour
{
    [SerializeField] private float _rotSpeed = 10f;
    
    // The container to offset the camera
    private Transform _camParent;
    private Transform _transform;

    private void Start()
    {
        _transform = transform;
        
        // 1. Create a parent to neutralize initial rotation offset
        _camParent = new GameObject("CamParent").transform;
        _camParent.position = _transform.position;
        _transform.SetParent(_camParent);

        // 2. Enable the sensors explicitly!
        // In the new system, sensors are often disabled by default to save battery.
        if (AttitudeSensor.current != null)
            InputSystem.EnableDevice(AttitudeSensor.current);
        
        // 3. Fix the initial rotation (90 degree rotation for landscape)
        _camParent.rotation = Quaternion.Euler(90, 0, 0);
    }

    private void Update()
    {
        // Check if the sensor exists
        if (AttitudeSensor.current == null) return;
        
        // Read the rotation directly
        var rot = AttitudeSensor.current.attitude.ReadValue();
            
        // Remap coordinates: Unity 6 Input System usually matches the screen orientation
        // better, but we often still need to re-orient for VR landscape.
        // This specific remapping depends on if you locked the screen to Landscape Left.
        var newRot = new Quaternion(rot.x, rot.y, -rot.z, -rot.w);
        _transform.localRotation = Quaternion.Lerp(_transform.localRotation, newRot, Time.deltaTime * _rotSpeed);
    }
}