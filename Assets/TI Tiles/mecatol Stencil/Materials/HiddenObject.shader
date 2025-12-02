Shader "Custom/HiddenObject"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _EmissionTex ("Emission Color(RGB)", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}

        [Enum(UnityEngine.Rendering.CompareFunction)]
        _StencilComp("Stencil Comp",Float) = 8
        [int] _StencilRef("Stencil Ref", Float) = 100
    }
    SubShader
    {
        ZWrite Off
        Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
        LOD 200

        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
        }

        Ztest Always

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _NormalMap;
        sampler2D _EmissionTex;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            fixed4 c2 = tex2D(_EmissionTex, IN.uv_MainTex)*0.5;
            c2.r = (c2.r + c2.g + c2.b) / 3;
            c2.g = c2.r;
            c2.b = c2.r;
            c2.r = c2.r * 1.1;
            o.Albedo = c.rgb + c2.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;


            

            fixed4 d;
            d.rgb = step(0.7, c.rgb);
            // o.Emission = step (0.2, o.Emission) * 0.1;

            o.Emission = o.Emission + d.rgb*0.07;

            // Use the normal map
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        ENDCG
    }
    FallBack "Diffuse"
}
