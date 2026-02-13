using UnityEngine;
using UnityEngine.InputSystem;

public class JoystickInputs : MonoBehaviour
{
    public float speed = 3.0f;
    private Vector2 moveInput;

    // This function is called AUTOMATICALLY by the Player Input component
    // purely based on the Action name "OnMove"
    public void OnMove(InputValue value)
    {
        moveInput = value.Get<Vector2>();
    }

    public void OnFire(InputValue value)
    {
        if(value.isPressed)
        {
            Debug.Log("Pew Pew!");
            // Add shooting logic here
        }
    }

    void Update()
    {
        // Apply movement relative to where the HEAD is looking
        // This is standard "FPS/VR" movement
        Vector3 direction = transform.forward * moveInput.y + transform.right * moveInput.x;
        
        // Keep us on the ground (ignore Y up/down)
        direction.y = 0; 
        
        transform.position += direction.normalized * speed * Time.deltaTime;
    }
}
