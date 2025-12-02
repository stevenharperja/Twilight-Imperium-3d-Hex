Shader "Custom/BasicParallax"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Sprite", 2D) = "white" {}
        _ParallaxTwo("Parallax Depth 2", Range(0,10)) = 0.0
        _MainTexBrightness("Main Texture Brightness", Range(0,2)) = 1.0
        // _OtherBrightness("Other Textures Brightness", Range(0,2)) = 1.0
        _BackTexBrightness("Back Texture Brightness", Range(0,2)) = 1.0
        _ForegroundTexBrightness("Foreground Texture Brightness", Range(0,2)) = 1.0
        _BackTex ("Back Sprite", 2D) = "white" {}
        _SpriteScale ("Sprite Scale", Float) = 1.0
            _BackSpriteScale ("Back Sprite Scale", Float) = 1.0
            _BackOpacity ("Back Opacity", Range(0,1)) = 1.0
            _BackParallax ("Back Parallax", Range(0,10)) = 0.0
        _ForegroundTex ("Foreground Sprite", 2D) = "white" {}
            _ForegroundSpriteScale ("Foreground Sprite Scale", Float) = 1.0
            _ForegroundOpacity ("Foreground Opacity", Range(0,1)) = 1.0
            _ForegroundParallax ("Foreground Parallax", Range(0,10)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_DepthMap("DepthMap", 2D) = "grey" {}
		_Normal("Normal", 2D) = "bump" {}
		_Parallax("Parallax Depth", Range(0,10)) = 0.0
        
    }
    SubShader
    {
        // Change to Transparent render queue + type so back image composites correctly
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // Surface shader with alpha blending so we can composite a background texture
        #pragma surface surf Standard fullforwardshadows alpha:fade

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float _SpriteScale;
        sampler2D _BackTex;
        float _BackSpriteScale;
        float _BackOpacity;
        sampler2D _ForegroundTex;
        float _ForegroundSpriteScale;
        float _ForegroundOpacity;

        float _MainTexBrightness;
        // float _OtherBrightness;
        float _BackTexBrightness;
        float _ForegroundTexBrightness;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BackTex;
            float2 uv_ForegroundTex;
			float2 uv_Normal;
			float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Parallax;
        float _ParallaxTwo;
        // Parallax amount for the back texture, can be smaller or larger depending on desired depth
        float _BackParallax;
        float _ForegroundParallax;
		sampler2D _DepthMap, _Normal;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // Composite foreground (top) over front (middle) over back (base), with control over top/back opacities.
        fixed4 CompositeColors(fixed4 myImage, fixed4 backCol, float backOpacity, fixed4 foreCol, float foreOpacity)
        {
            // Respect the provided opacity sliders and texture alpha channels
            float backA = backCol.a * backOpacity;
            float frontA = myImage.a;
            float foreA = foreCol.a * foreOpacity;

            // Composite front over back
            float midA = frontA + backA * (1 - frontA);
            float3 midRGB = float3(0,0,0);
            if (midA > 0.0001)
            {
                midRGB = (myImage.rgb * frontA + backCol.rgb * backA * (1 - frontA)) / midA;
            }

            // Composite fore over the result
            float outA = foreA + midA * (1 - foreA);
            float3 outRGB = float3(0,0,0);
            if (outA > 0.0001)
            {
                outRGB = (foreCol.rgb * foreA + midRGB * midA * (1 - foreA)) / outA;
            }

            return fixed4(outRGB, outA);
        }
        float4 BooleanIntersect(float4 colorA, float4 colorB)
        {
            float alphaA = colorA.a;
            float alphaB = colorB.a;
            float outA = alphaA * alphaB;
            float3 outRGB = float3(0,0,0);
            if (outA > 0.0001)
            {
                outRGB = (colorA.rgb * alphaA * colorB.rgb * alphaB) / outA;
            }
            return float4(outRGB, outA);
        }
        fixed4 waveEffect(fixed4 image, float time, float3 viewDir)
        {
            // float wave = sin(dot(viewDir, float3(0,0,1))*5 );//+ time * 5);
            float wave = sin(viewDir.x * 10 + time * 5);
            fixed4 result = image;
            result.r += wave * 0.1;
            return result;
        }
        fixed4 holographicEffect(fixed4 image, Input IN)
        {
            // float rainbow = 
            fixed4 result = image;
            // result.r += rainbow * 0.1;
            return result;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// depth map for parallax	
			// float d = tex2D(_DepthMap, IN.uv_MainTex).r;
            float d = 0;

			float2 parallax = ParallaxOffset(d, _Parallax, IN.viewDir);
            
			// o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
            o.Normal = normalize(float3(0, 0, 1));
            // Albedo comes from a texture tinted by color
            float2 parallaxtwo = ParallaxOffset(d, _ParallaxTwo, IN.viewDir);
            fixed4 myImage = tex2D (_MainTex, IN.uv_MainTex*_SpriteScale + parallaxtwo) * _Color;

            // Back texture parallax and sample
            float2 parallaxBack = ParallaxOffset(d, _BackParallax, IN.viewDir);
            fixed4 backCol = tex2D(_BackTex, IN.uv_BackTex * _BackSpriteScale + parallaxBack);

            // Foreground texture parallax and sample
            float2 parallaxFore = ParallaxOffset(d, _ForegroundParallax, IN.viewDir);
            fixed4 foreCol = tex2D(_ForegroundTex, IN.uv_ForegroundTex * _ForegroundSpriteScale + parallaxFore);

            // Composite fore (top) over front over back using opacities and alphas
            fixed4 result = CompositeColors(myImage, backCol, _BackOpacity, foreCol, _ForegroundOpacity);

            o.Albedo = holographicEffect(result, IN).rgb;
            // vec3 myImageEmission = myImage.rgb * myImage.a * _MainTexBrightness;
            // vec3 backEmission = min(backCol.rgb * backCol.a * _BackTexBrightness, myImageEmission);
            // vec3 foreEmission = foreCol.rgb * foreCol.a * _ForegroundTexBrightness, backEmission;
            o.Emission = myImage.rgb * myImage.a * _MainTexBrightness;
            // o.Emission += min(backCol.rgb * backCol.a * _BackTexBrightness, o.Emission);
            o.Emission.r = max(o.Emission.r, backCol.r * backCol.a * _BackTexBrightness); //This is scuffed, please fix later.
            o.Emission.g = max(o.Emission.g, backCol.g * backCol.a * _BackTexBrightness);
            o.Emission.b = max(o.Emission.b, backCol.b * backCol.a * _BackTexBrightness);
            o.Emission += foreCol.rgb * foreCol.a * _ForegroundTexBrightness; 
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = result.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}