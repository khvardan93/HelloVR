using UnityEngine;
using UnityEngine.EventSystems;

public class CanvasFocuseDetector : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler
{
    // This triggers the moment the XR Ray or Gaze hits this UI element
    public void OnPointerEnter(PointerEventData eventData)
    {
        Debug.Log("Canvas is in focus!");
    }

    // This triggers the moment the XR Ray or Gaze leaves this UI element
    public void OnPointerExit(PointerEventData eventData)
    {
        Debug.Log("Canvas lost focus!");
    }
}
