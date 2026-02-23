using UnityEngine;

public class CustomVRRaycaster : MonoBehaviour
{
    [SerializeField] private float _reachDistance = 10f;
    private GameObject _currentFocusedObject;
    private Transform _transform;
    
    private void Awake()
    {
        _transform = transform;
    }

    private void Update()
    {
        // 1. Shoot a ray forward from this object (Camera or Hand)
        var ray = new Ray(_transform.position, _transform.forward);

        // 2. Check if the ray hits a collider
        if (Physics.Raycast(ray, out var hit, _reachDistance, 1 << 3))
        {
            var hitObject = hit.collider.gameObject;

            // Did we hit a NEW canvas?
            if (hitObject != _currentFocusedObject)
            {
                TryToSetUnfocused();

                _currentFocusedObject = hitObject;
                Debug.Log("Gained focus on: " + _currentFocusedObject.name);
                
                // You can call a method on the canvas here
                 hitObject.GetComponent<BaseVrRaycastable>().OnFocused();
            }
        }
        else
        {
            TryToSetUnfocused();
        }
    }

    private void TryToSetUnfocused()
    {
        if (!_currentFocusedObject) return;
        _currentFocusedObject.GetComponent<BaseVrRaycastable>().OnUnfocused();
        Debug.Log("Lost focus on: " + _currentFocusedObject.name);
        _currentFocusedObject = null;
    }
}