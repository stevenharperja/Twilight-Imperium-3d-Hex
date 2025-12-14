// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/RaisedSurface"
{
    /*
     * SEE https://github.com/bentoBAUX/Parallax-Mapping-with-Self-Shadowing
     *      - https://bentobaux.github.io/posts/parallax-mapping-with-self-shadowing/
     */
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_DepthMap("DepthMap", 2D) = "grey" {}
		_Normal("Normal", 2D) = "bump" {}
		// _Parallax("Parallax Depth", Range(0,10)) = 0.0
        _DepthScale("Depth Scale", Range(0,10)) = 0.0
        _ParallaxLayers("Parallax Layers", Range(1,50)) = 5
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 0.5
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

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_Normal;
			float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		// float _Parallax;
        float _DepthScale;
        int _ParallaxLayers;
		sampler2D _DepthMap, _Normal;
        float _ShadowIntensity;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


        float2 SteepParallaxMapping(sampler2D depthMap, float2 texCoords, float3 viewDir, int numLayers, float depthScale)
        {
            // Calculate the size of a single layer
            float layerDepth = 1.0 / numLayers;

            // Determine the step vector based on our view angle
            float2 p = viewDir.xy * depthScale;
            float2 stepVector = p / numLayers;

            // Initialise and set starting values before the loop
            float currentLayerDepth = 0.0;
            float2 currentTexCoords = texCoords;

            // Sample with fixed LOD to avoid issues in loops that will cause GPU timeouts
            float currentDepthMapValue = tex2Dlod(depthMap, float4(currentTexCoords, 0, 0.0)).r;

            // Loop until we have stepped too far below the surface (the surface is where the depth map says it is)
            while (currentLayerDepth < currentDepthMapValue)
            {
                // Shift the texture coordinates in the direction of step vector
                currentTexCoords -= stepVector;

                // Sample the depthmap with the new texture coordinate to get the new depth value
                currentDepthMapValue = tex2Dlod(depthMap, float4(currentTexCoords, 0, 0.0)).r;

                // Move on to the next layer
                currentLayerDepth += layerDepth;
            }

            // Compute the texture coordinates from the previous iteration
            float2 prevTexCoords = currentTexCoords + stepVector;

            // Compute how far below the surface we are at the current step
            float surfaceOffsetAfter = currentDepthMapValue - currentLayerDepth;

            // Compute how far above the surface we were at the previous step
            float surfaceOffsetBefore = tex2Dlod(depthMap, float4(prevTexCoords, 0, 0)).r - currentLayerDepth + layerDepth;

            // Linearly interpolate the texture coordinates using the calculated weight
            float weight = surfaceOffsetAfter / (surfaceOffsetAfter - surfaceOffsetBefore);
            float2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

            return finalTexCoords;
        }

        float SelfShadowing(sampler2D depthMap, float2 texCoords, float3 lightDir, float numLayers, float depthScale, float shadowintensity)
        {
            if (lightDir.y <= 0) return 0.0;
            lightDir.y *=-1;

            float layerDepth = 1.0 / numLayers;

            float2 p = lightDir.xz / lightDir.y * depthScale; // Normalize step size
            float2 stepVector = p / numLayers;

            float2 currentTexCoords = texCoords;
            float currentDepthMapValue = tex2D(depthMap, currentTexCoords).r;
            float currentLayerDepth = currentDepthMapValue;

            float shadowBias = 0.03; // Bias to reduce self-shadowing
            int maxIterations = 32; // Cap iterations
            int iterationCount = 0;

            // Traverse along the light direction
            while (currentLayerDepth <= currentDepthMapValue + shadowBias && currentLayerDepth > 0.0 && iterationCount < maxIterations)
            {
                currentTexCoords += stepVector;
                currentDepthMapValue = tex2D(depthMap, currentTexCoords).r;
                currentLayerDepth -= layerDepth;
                iterationCount++;
            }

            return currentLayerDepth > currentDepthMapValue ? (currentLayerDepth-currentDepthMapValue)*1/shadowintensity : 1.0; // No occlusion = fully lit
        }

        fixed3 BlinnPhong(fixed3 lightDir, fixed3 viewDir, fixed3 normal, fixed shininess)
        {
            fixed3 halfDir = normalize(lightDir + viewDir);
            float NdotL = max(dot(normal, lightDir), 0);
            float NdotH = max(dot(normal, halfDir), 0);
            float spec = pow(NdotH, shininess);
            return NdotL + spec;
        }
        

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// depth map for parallax	
			// float d = tex2D(_DepthMap, IN.uv_MainTex).r;
            // IN.uv_MainTex = shiftWaterOverTime(IN.uv_MainTex, 0.05);
			IN.uv_MainTex = SteepParallaxMapping(
                _DepthMap, 
                IN.uv_MainTex, 
                IN.viewDir, 
                _ParallaxLayers, 
                _DepthScale
                );
            IN.uv_Normal = IN.uv_MainTex;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz );
            // fixed3 lightDir = fixed3(0,-1,0); // Light coming straight down
            lightDir = normalize(mul((float3x3)unity_WorldToObject, lightDir)); // Transform to tangent space
            lightDir = fixed3(lightDir.x, lightDir.y, lightDir.z);

            float darkness = SelfShadowing(
                _DepthMap, 
                IN.uv_MainTex, 
                lightDir, 
                _ParallaxLayers, 
                _DepthScale,
                _ShadowIntensity
                );
			o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
            // c.rgb = BlinnPhong(normalize(_WorldSpaceLightPos0.xyz), normalize(IN.viewDir), o.Normal, 32.0);
            // Albedo comes from a texture tinted by color
            o.Albedo = c.rgb * darkness;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}