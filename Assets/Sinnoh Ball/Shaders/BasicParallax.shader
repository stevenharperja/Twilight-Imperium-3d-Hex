Shader "Custom/BasicParallax"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Sprite", 2D) = "white" {}
        _BackTex ("Back Sprite", 2D) = "white" {}
        _SpriteScale ("Sprite Scale", Float) = 1.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_DepthMap("DepthMap", 2D) = "grey" {}
		_Normal("Normal", 2D) = "bump" {}
		_Parallax("Parallax Depth", Range(0,10)) = 0.0
        _ParallaxTwo("Parallax Depth 2", Range(0,10)) = 0.0
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows 

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float _SpriteScale;
        sampler2D _BackTex;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_Normal;
			float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		float _Parallax;
        float _ParallaxTwo;
		sampler2D _DepthMap, _Normal;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// depth map for parallax	
			float d = tex2D(_DepthMap, IN.uv_MainTex).r;
            // float d = 0;

			float2 parallax = ParallaxOffset(d, _Parallax, IN.viewDir);
            
			// o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
            o.Normal = normalize(float3(0, 0, 1));
            // Albedo comes from a texture tinted by color
            float2 parallaxtwo = ParallaxOffset(d, _ParallaxTwo, IN.viewDir);
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex*_SpriteScale+parallaxtwo) * _Color;
            // o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal + parallax));
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}