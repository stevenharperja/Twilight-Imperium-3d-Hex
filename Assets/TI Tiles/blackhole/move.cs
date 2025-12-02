using System.Collections; //wowie written by chatgpt!
using System.Collections.Generic; //wowie written by chatgpt!
using UnityEngine; //wowie written by chatgpt!

public class move : MonoBehaviour //wowie written by chatgpt!
{ //wowie written by chatgpt!
    public float speed = 5f; //wowie written by chatgpt!

    void Update() //wowie written by chatgpt!
    { //wowie written by chatgpt!
        Vector3 direction = Vector3.zero; //wowie written by chatgpt!

        if (Input.GetKey(KeyCode.W)) //wowie written by chatgpt!
            direction += Vector3.forward; //wowie written by chatgpt!
        if (Input.GetKey(KeyCode.S)) //wowie written by chatgpt!
            direction += Vector3.back; //wowie written by chatgpt!
        if (Input.GetKey(KeyCode.A)) //wowie written by chatgpt!
            direction += Vector3.left; //wowie written by chatgpt!
        if (Input.GetKey(KeyCode.D)) //wowie written by chatgpt!
            direction += Vector3.right; //wowie written by chatgpt!
        if (Input.GetKey(KeyCode.Space)) //wowie written by chatgpt!
            direction += Vector3.up; //wowie written by chatgpt!
        if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift)) //wowie written by chatgpt!
            direction += Vector3.down; //wowie written by chatgpt!

        transform.Translate(direction.normalized * speed * Time.deltaTime); //wowie written by chatgpt!
    } //wowie written by chatgpt!
} //wowie written by chatgpt!
