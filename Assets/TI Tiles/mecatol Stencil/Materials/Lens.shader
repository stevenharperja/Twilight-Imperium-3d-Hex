Shader "Stencil/Invisible Mask"
{
    Properties {
        _StencilRef("Stencil Ref", Float) = 100
    }
    SubShader
    {
        Tags {"Queue"="Geometry-3"}      
        LOD 100
        Pass
        {   
            Stencil
            {
                Ref [_StencilRef]
                Comp always
                Pass Replace               
            }
            
        }
        
    }
}
