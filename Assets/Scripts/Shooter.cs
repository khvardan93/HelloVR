using System;
using UnityEngine;

public class Shooter : MonoBehaviour
{
    [SerializeField] private BulletPhysics _bulletPrefab;

    private void Start()
    {
        JoystickInputs.OnFireInput += FireActionHAndler;
    }

    private void OnDestroy()
    {
        JoystickInputs.OnFireInput -= FireActionHAndler;
    }

    private void FireActionHAndler()
    {
        var newBullet = Instantiate(_bulletPrefab,  transform.position, transform.rotation);
        newBullet.gameObject.SetActive(true);
    }
}
