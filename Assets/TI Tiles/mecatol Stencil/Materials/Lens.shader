Shader "Stencil/Invisible Mask"
{
    Properties {}
    SubShader
    {
        Tags {"Queue"="Geometry-1"}      
        LOD 100
        Pass
        {   
            Stencil
            {
                Ref 100
                Comp always
                Pass Replace               
            }
            
        }
        
    }
}
