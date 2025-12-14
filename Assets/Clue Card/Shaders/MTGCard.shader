Shader "Custom/BasicParallax"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex("Front Image", 2D) = "white" {}
        _FrontImageBrightness("Front Image Brightness", Range(-2,2)) = 1.0
        _Subject ("Sprite", 2D) = "white" {}
        _ParallaxTwo("Parallax Depth 2", Range(0,10)) = 0.0
        _SubjectBrightness("Main Texture Brightness", Range(-2,2)) = 1.0
        // _OtherBrightness("Other Textures Brightness", Range(0,2)) = 1.0
        _BackTexBrightness("Back Texture Brightness", Range(-2,2)) = 1.0
        _ForegroundTexBrightness("Foreground Texture Brightness", Range(-2,2)) = 1.0
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
        _DepthEffectScale("Depth Effect Scale", Range(-2,2)) = 1
        _DepthSpriteScale("Depth Sprite Scale", Float) = 1.0
		_Normal("Normal", 2D) = "bump" {}
        _NormalSpriteScale("Normal Sprite Scale", Float) = 1.0
        _NormalIntensity("Normal Intensity", Float) = 1.0
		_Parallax("Parallax Depth", Range(0,10)) = 0.0
        _SubjectShininessFrequency("Subject Shininess Frequency", Float) = 10.0
        _SubjectShininessAmplitude("Subject Shininess Amplitude", Float) = 0.1
        _ForegroundShininessFrequency("Foreground Shininess Frequency", Float) = 2.0
        _ForegroundShininessAmplitude("Foreground Shininess Amplitude", Float) = 0.5
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

        sampler2D _Subject;
        float _SpriteScale;
        sampler2D _BackTex;
        float _BackSpriteScale;
        float _BackOpacity;
        sampler2D _ForegroundTex;
        float _ForegroundSpriteScale;
        float _ForegroundOpacity;

        float _SubjectBrightness;
        // float _OtherBrightness;
        float _BackTexBrightness;
        float _ForegroundTexBrightness;

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_Subject;
            float2 uv_BackTex;
            float2 uv_ForegroundTex;
            float2 uv_DepthMap;
			float2 uv_Normal;
            float2 uv_MainTex;
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
        float _DepthEffectScale;
        float _DepthSpriteScale;
        float _NormalSpriteScale;
        float _NormalIntensity = 1.0;
        float _FrontImageBrightness;
        float _SubjectShininessFrequency;
        float _SubjectShininessAmplitude;
        float _ForegroundShininessFrequency;
        float _ForegroundShininessAmplitude;

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
        fixed4 holographicEffect(fixed4 image, Input IN, float frequency = 10.0, float amplitude = 0.1, float3 norm = (1,1,1))
        {
            //See if I can use the info from here: https://www.cyanilux.com/tutorials/holofoil-card-shader-breakdown/
            //get the view direction
            float3 viewDir = normalize(IN.viewDir);
            //calculate a holographic color shift based on view direction
            // float shift = dot(viewDir, float3(1,1,1));
            norm = float3(norm.z, norm.y,norm.x);
            float shift = dot(viewDir.xy, norm);
            //filter the shift through a high frequency sine wave for a holographic effect
            float Rshift = sin(shift * frequency) * amplitude;
            float Gshift = sin((shift) * frequency + 0.33*2*3.14) * amplitude;
            float Bshift = sin((shift) * frequency + 0.66*2*3.14) * amplitude;
            // float shift2 = dot(In.)
            image.r += Rshift;
            image.g += Gshift;
            image.b += Bshift;
            fixed4 result = image;
            return result;
        }
        fixed4 DrawAoverB(fixed4 ACol, float AOpacity, fixed4 BCol, float BOpacity)
        {
            // Standard "A over B" compositing with opacity controls
            float aAlpha = ACol.a * AOpacity;
            float bAlpha = BCol.a * BOpacity;

            // Composite A over B: outA = aA + bA * (1 - aA)
            float outA = aAlpha + bAlpha * (1 - aAlpha);
            float3 outRGB = float3(0,0,0);
            if (outA > 0.0001)
            {
                // RGB: blend A and B using their final alphas
                outRGB = (ACol.rgb * aAlpha + BCol.rgb * bAlpha * (1 - aAlpha)) / outA;
            }
            return fixed4(outRGB, outA);
        }
        fixed3 DrawEmissionAoverB(fixed3 emissionA, float Apercent, fixed3 emissionB, float Bpercent)
        {
            // Similar to DrawAoverB but for emission values (no alpha channel)
            fixed3 outEmission = emissionA * Apercent + emissionB * Bpercent * (1 - Apercent);
            //pass B through where A is 0.
            if (emissionA.r < 0.0001 && emissionA.g < 0.0001 && emissionA.b < 0.0001)
            {
                outEmission = emissionB * Bpercent;
            }
            // float blendthreshold = 0.1;
            // if(emissionA.r < blendthreshold && emissionA.g < blendthreshold && emissionA.b < blendthreshold)
            // {
            //     float blendFactor = (emissionA.r + emissionA.g + emissionA.b) / (3.0 * blendthreshold);
            //     outEmission = lerp(emissionB * Bpercent, outEmission, blendFactor);
            // }
            return outEmission;
        }

        void stretchVertically(inout float2 uv, float stretchAmount)
        {
            uv.y *= stretchAmount;
        }
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            ////FIX UVS
            //magic number because all the mtg cards are the same size
            float stretch = 1;
            stretchVertically(IN.uv_Subject, stretch);
            stretchVertically(IN.uv_BackTex, stretch);
            stretchVertically(IN.uv_ForegroundTex, stretch);
            stretchVertically(IN.uv_DepthMap, stretch);
            stretchVertically(IN.uv_Normal, stretch);
            //// END OF FIX UVS
            // depth map for parallax
            // Use the depth map's own UVs (`uv_DepthMap`) so material Tiling/Offset on the DepthMap property applies.
            float d = tex2D(_DepthMap, IN.uv_DepthMap * _DepthSpriteScale).a * _DepthEffectScale;
            // float d = 0;

			float2 parallax = ParallaxOffset(d, _Parallax, IN.viewDir);
            
			o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal * _NormalSpriteScale + parallax));
            o.Normal = normalize(lerp(float3(0,0,1), o.Normal, _NormalIntensity));
            // o.Normal = normalize(float3(0, 0, 1));
            // Albedo comes from a texture tinted by color
            float2 parallaxtwo = ParallaxOffset(d, _ParallaxTwo, IN.viewDir);
            fixed4 myImage = tex2D (_Subject, IN.uv_Subject*_SpriteScale + parallaxtwo) * _Color;
            // myImage = holographicEffect(myImage, IN, 10.0, 0.05);
            myImage = holographicEffect(myImage, IN, _SubjectShininessFrequency, _SubjectShininessAmplitude, o.Normal);

            // Back texture parallax and sample
            float2 parallaxBack = ParallaxOffset(d, _BackParallax, IN.viewDir);
            fixed4 backCol = tex2D(_BackTex, IN.uv_BackTex * _BackSpriteScale + parallaxBack);

            // Foreground texture parallax and sample
            float2 parallaxFore = ParallaxOffset(d, _ForegroundParallax, IN.viewDir);
            fixed4 foreCol = tex2D(_ForegroundTex, IN.uv_ForegroundTex * _ForegroundSpriteScale + parallaxFore);
            foreCol = holographicEffect(foreCol, IN, _ForegroundShininessFrequency, _ForegroundShininessAmplitude);

            // Composite fore (top) over front over back using opacities and alphas
            // fixed4 result = CompositeColors(myImage, backCol, _BackOpacity, foreCol, _ForegroundOpacity);
            fixed4 result;
            fixed4 _MainTexCol = tex2D(_MainTex, IN.uv_MainTex);
            result = DrawAoverB(_MainTexCol, 1.0, backCol, _BackOpacity);
            result = DrawAoverB(foreCol, _ForegroundOpacity, result, 1.0);
            result = DrawAoverB(myImage, 1.0, result, 1.0);

            o.Albedo = result.rgb;
            // vec3 myImageEmission = myImage.rgb * myImage.a * _SubjectBrightness;
            // vec3 backEmission = min(backCol.rgb * backCol.a * _BackTexBrightness, myImageEmission);
            // vec3 foreEmission = foreCol.rgb * foreCol.a * _ForegroundTexBrightness, backEmission;
            o.Emission = myImage.rgb * myImage.a * _SubjectBrightness;
            // o.Emission += min(backCol.rgb * backCol.a * _BackTexBrightness, o.Emission);
            // o.Emission.r = max(o.Emission.r, backCol.r * backCol.a * _BackTexBrightness); //This is scuffed, please fix later. adapt that composite function
            // o.Emission.g = max(o.Emission.g, backCol.g * backCol.a * _BackTexBrightness);
            // o.Emission.b = max(o.Emission.b, backCol.b * backCol.a * _BackTexBrightness);
            // o.Emission += foreCol.rgb * foreCol.a * _ForegroundTexBrightness; 
            o.Emission = DrawEmissionAoverB(foreCol.rgb * foreCol.a * _ForegroundTexBrightness, 0.5, o.Emission, 0.5);
            o.Emission = DrawEmissionAoverB(o.Emission, 1.0, _BackTexBrightness, 1.0);
            // _MainTexCol.a/=2.0; //reduce alpha influence to lessen emission cutout
            // _MainTexCol _FrontImageBrightness;
            // fixed4 subtractEmission = DrawAoverB(_MainTexCol, 1, fixed4(o.Emission, 1), 1);
            // fixed4 subtractEmission2 = BooleanIntersect(_MainTexCol, fixed4(o.Emission, 1));
            o.Emission = DrawEmissionAoverB(_MainTexCol.rgb* _MainTexCol.a * _FrontImageBrightness,1.0, o.Emission, 1.0);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = result.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}