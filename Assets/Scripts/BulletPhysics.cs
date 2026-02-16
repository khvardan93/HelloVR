using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class BulletPhysics : MonoBehaviour
{
    public float speed = 50f;
    public float lifeTime = 3f;

    void Start()
    {
        // Unity 6: Use linearVelocity instead of velocity
        Rigidbody rb = GetComponent<Rigidbody>();
        
        // Shoot forward instantly
        rb.linearVelocity = transform.forward * speed;
        
        // Destroy after 3 seconds to save memory
        //Destroy(gameObject, lifeTime);
    }

    /*// Since we set Collider to "Is Trigger", we use OnTriggerEnter
    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Enemy"))
        {
            Debug.Log("Hit Enemy!");
            // other.GetComponent<EnemyHealth>().TakeDamage(10);
            Destroy(gameObject); // Delete bullet
        }
        else if (other.CompareTag("Environment")) // Walls, Floor
        {
            Destroy(gameObject);
        }
    }*/
}