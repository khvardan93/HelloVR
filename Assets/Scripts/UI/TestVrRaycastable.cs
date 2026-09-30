using UnityEngine;
using UnityEngine.UI;

public class TestVrRaycastable : BaseVrRaycastable
{
    [SerializeField] private Color _foused = Color.red;
    [SerializeField] private Color _unfoused = Color.gray;
    [SerializeField] private Image  _fousedImage;

    private void Awake()
    {
        _fousedImage.color = _unfoused;
    }

    public override void OnFocused()
    {
        _fousedImage.color = _foused;
        
        Debug.Log(gameObject.name + " is focused");
    }

    public override void OnUnfocused()
    {
        _fousedImage.color = _unfoused;
        
        Debug.Log(gameObject.name + " is unfocused");
    }
}
