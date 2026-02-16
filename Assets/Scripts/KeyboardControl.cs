using UnityEngine;

public class KeyboardControl : MonoBehaviour
{
    [SerializeField] private float _rotSpeed = 10f;
    
    // The container to offset the camera
    private Transform _camParent;
    private Transform _transform;
    private bool _right;
    private bool _left;
    private bool _up;
    private bool _down;

    private void Start()
    {
        _transform = transform;
        
        // 1. Create a parent to neutralize initial rotation offset
        _camParent = new GameObject("CamParent").transform;
        _camParent.position = _transform.position;
        _transform.SetParent(_camParent);

        JoystickInputs.OnRightInput += OnRight;
        JoystickInputs.OnLeftInput += OnLeft;
        JoystickInputs.OnUpInput += OnUp;
        JoystickInputs.OnDownInput += OnDown;
    }

    private void OnDestroy()
    {
        JoystickInputs.OnRightInput -= OnRight;
        JoystickInputs.OnLeftInput -= OnLeft;
        JoystickInputs.OnUpInput -= OnUp;
        JoystickInputs.OnDownInput -= OnDown;
    }

    public void OnRight(bool value)
    {
        _right = value;
    }
    
    public void OnLeft(bool value)
    {
        _left = value;
    }
    
    public void OnUp(bool value)
    {
        _up = value;
    }
    
    public void OnDown(bool value)
    {
        _down = value;
    }

    private void Update()
    {
        if (_right || _left) _transform.RotateAround(Vector3.up, (_right ? _rotSpeed : -_rotSpeed) * Time.deltaTime);
        if (_up || _down) _transform.RotateAround(-_transform.right, (_up ? _rotSpeed : -_rotSpeed) * Time.deltaTime);
    }
}
