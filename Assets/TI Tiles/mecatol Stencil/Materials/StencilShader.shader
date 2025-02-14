Shader "Custom/Stencil"
{
    SubShader
    {
        
        Pass
        {
            ColorMask 0
            ZWrite Off

            Stencil
            {
                Ref 2
                Comp always
                Pass replace
            }
        }
    }
}
