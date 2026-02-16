using System;
using UnityEngine;
using UnityEngine.InputSystem;

public class JoystickInputs : MonoBehaviour
{
    [SerializeField] private float _speed = 3.0f;
    private Vector2 _moveInput;
    private Transform _transform;
    
    public static event Action OnFireInput;
    public static event Action<bool> OnRightInput;
    public static event Action<bool> OnLeftInput;
    public static event Action<bool> OnUpInput;
    public static event Action<bool> OnDownInput;

    private void Start()
    {
        _transform = transform;
    }

    // This function is called AUTOMATICALLY by the Player Input component
    // purely based on the Action name "OnMove"
    public void OnMove(InputValue value)
    {
        _moveInput = value.Get<Vector2>();
    }

    public void OnFire(InputValue value)
    {
        if(value.isPressed)
        {
            OnFireInput?.Invoke();
        }
    }

    public void OnRight(InputValue value)
    {
        OnRightInput?.Invoke(value.isPressed);
    }
    
    public void OnLeft(InputValue value)
    {
        OnLeftInput?.Invoke(value.isPressed);
    }
    
    public void OnDown(InputValue value)
    {
        OnDownInput?.Invoke(value.isPressed);
    }
    
    public void OnUp(InputValue value)
    {
        OnUpInput?.Invoke(value.isPressed);
    }

    private void Update()
    {
        // Apply movement relative to where the HEAD is looking
        // This is standard "FPS/VR" movement
        Vector3 direction = _transform.forward * _moveInput.y + _transform.right * _moveInput.x;
        
        // Keep us on the ground (ignore Y up/down)
        direction.y = 0; 
        
        _transform.position += direction.normalized * _speed * Time.deltaTime;
    }
}
