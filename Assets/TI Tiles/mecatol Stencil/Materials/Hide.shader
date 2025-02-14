Shader "Stencil/Invisible Mask"
{
    Properties {}
    SubShader
    {
        Tags {"Queue"="Geometry-1"}      
        LOD 100
        // Blend Zero One
        ZWrite off
        ColorMask 0
        Pass
        {   
            Blend Zero One
            ZWrite Off
        }
        Pass
        {   
            Stencil
            {
                Ref 1 
                Comp always
                Pass Replace               
            }
            
        }
        
    }
}

// Shader "Custom/InvisibleLens"
// {
//     SubShader
//     {
//         Tags { "Queue"="Geometry-1" "RenderType"="Opaque" }

//         // **Depth Masking Pass (Blocks everything behind the lens)**
//         Pass
//         {
//             ZWrite On      // Write to the depth buffer
//             ZTest LEqual   // Ensures depth is written correctly
//             ColorMask 0    // Don't render color (fully invisible)
//         }
//     }
//     SubShader
//     {
//         Tags { "Queue"="Geometry" "RenderType"="Translucent" }
//         // **Stencil Masking Pass (Marks the area for the special object)**
//         Pass
//         {
//             Blend Zero One // Don't render anything
//             ZWrite Off     // Don't modify depth
//             ColorMask 0    // Invisible, only updates stencil
//             Stencil
//             {
//                 Ref 1
//                 Comp Always
//                 Pass Replace
//             }
//         }
//     }
// }
