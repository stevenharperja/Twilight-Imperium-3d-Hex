// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/CardSurface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _BackgroundsMerged ("Backgrounds", 2D) = "white" {}
        _FoilPattern ("FoilPattern", 2D) = "white" {}


        _BackgroundTex ("Background", 2D) = "white" {}
        _BackgroundDepth ("Background Depth", Range(0,100)) = 0
        _BackgroundNormal ("Background Normal", Vector) = (0,1,0,0)
        _BackgroundSize ("Background Size", Vector) = (1,1,0,0)
        _BackgroundIndex ("Background Index", Int) = 0

        _Background2Tex ("Background2", 2D) = "white" {}
        _Background2Depth ("Background2 Depth", Range(0,100)) = 0
        _Background2Normal ("Background2 Normal", Vector) = (0,1,0,0)
        _Background2Size ("Background2 Size", Vector) = (1,1,0,0)
        _Background2Index ("Background2 Index", Int) = 0
    

        _ContentTex ("Content", 2D) = "white" {}
        _ContentDepth ("Content Depth", Range(0,100)) = 0
        _ContentNormal ("Content Normal", Vector) = (0,1,0,0)
        _ContentSize ("Content Size", Vector) = (1,1,0,0)

        _CardBack ("Card Back", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CULL Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.5

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_FoilPattern;
            float2 uv_MainTex;
            float3 viewDir;
            float3 viewDirTangent;
            float3 worldPos;
            float3 normal;
            float3 tangent_input;
            float3 binormal_input;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        sampler2D _BackgroundsMerged;

  
        sampler2D _BackgroundTex;
        float _BackgroundDepth;
        float3 _BackgroundNormal;
        float4 _BackgroundSize;
        int _BackgroundIndex;

        sampler2D _Background2Tex;
        float _Background2Depth;
        float3 _Background2Normal;
        float4 _Background2Size;
        int _Background2Index;

        sampler2D _ContentTex;
        float _ContentDepth;
        float3 _ContentNormal;
        float4 _ContentSize;

        sampler2D _FoilPattern;
        sampler2D _CardBack;

        void vert(inout appdata_full i, out Input o)
        {       
            UNITY_INITIALIZE_OUTPUT(Input, o);

            half4 p_normal = mul(float4(i.normal,0.0f),unity_WorldToObject);
            half4 p_tangent = mul(unity_ObjectToWorld,i.tangent);
                                            
            half3 normal_input = normalize(p_normal.xyz);
            half3 tangent_input = normalize(p_tangent.xyz);
            half3 binormal_input = cross(p_normal.xyz,tangent_input.xyz) * i.tangent.w;
                
            o.tangent_input = tangent_input ;
            o.binormal_input = binormal_input ;

             // Compute TBN matrix
            float3x3 TBN = float3x3(tangent_input, binormal_input, normal_input);

            // Compute view direction in world space
            float3 viewDirWorld = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, i.vertex).xyz);

            // Transform view direction to tangent space
            o.viewDirTangent = mul(TBN, viewDirWorld);
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float4 ProjectRayTo(float3 rayOrigin, float3 rayDirection, float3 planeNormal, float3 planePosition)
        {
            float d = dot(planeNormal, planePosition);
            float denom = dot(planeNormal, rayDirection);
            if (abs(denom) > 0.0001)
            {
                float t = (d - dot(planeNormal, rayOrigin)) / denom;
                return float4(rayOrigin + t * rayDirection, 1.0f);
            }
            else
            {
    
                return float4(rayOrigin,1.0f);
            }
        }
        
        float4 GetLayerColor2(float2 uv, float3 viewDir, float depth, float3 localPlaneNormal, sampler2D tex, float4 size, float4 uvRect, float2 sampleOffset = float2(0,0))
		{
            float4 localPlanePosition = float4(0, -depth, 0, 1);
			float4 worldPlanePosition = mul(unity_ObjectToWorld, localPlanePosition);
			float3 worldPlaneNormal = normalize(mul((float3x3)unity_ObjectToWorld, localPlaneNormal).xyz);


			float4 worldProjectedPos = ProjectRayTo(
				_WorldSpaceCameraPos,
				viewDir,
				worldPlaneNormal,
				worldPlanePosition
			);

			float4 localProjectedPos = mul(unity_WorldToObject, worldProjectedPos);
			float2 backgroundUVs = localProjectedPos.xz + sampleOffset;
            backgroundUVs *= size.xy;

			return tex2D(tex, backgroundUVs);
		}
        
        float4 GetLayerColor(float3 viewDir, float depth, float3 localPlaneNormal, sampler2D tex, float4 size, float4 uvRect, out float2 layerUV, float2 sampleOffset = float2(0,0), int2 clampAxes = int2(1, 1))
		{
            float4 localPlanePosition = float4(0, -depth, 0, 1);
			float4 worldPlanePosition = mul(unity_ObjectToWorld, localPlanePosition);
			float3 worldPlaneNormal = normalize(mul((float3x3)unity_ObjectToWorld, localPlaneNormal).xyz);

			float4 worldProjectedPos = ProjectRayTo(
				_WorldSpaceCameraPos,
				viewDir,
				worldPlaneNormal,
				worldPlanePosition
			);

			float4 localProjectedPos = mul(unity_WorldToObject, worldProjectedPos);
			float2 backgroundUVs = localProjectedPos.xz + sampleOffset;

            layerUV = backgroundUVs;
			backgroundUVs.x = clampAxes.x ? 1.0f - clamp((backgroundUVs.x + size.z) * size.x, 0.025f, 0.975f) : backgroundUVs.x * size.x + size.z;
			backgroundUVs.y = clampAxes.y ? 1.0f - clamp((backgroundUVs.y + size.w) * size.y, 0.025f, 0.975f) : backgroundUVs.y * size.y + size.w;
            // backgroundUVs = lerp(uvRect.xy, uvRect.zw, frac(backgroundUVs));
            
			return tex2D(tex, backgroundUVs);
		}

        float sdRoundedBox( in float2 p, in float2 b, in float4 r )
        {
            r.xy = (p.x>0.0)?r.xy : r.zw;
            r.x  = (p.y>0.0)?r.x  : r.y;
            float2 q = abs(p)-b+r.x;
            return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
        }

        float random(float2 st){
			return frac(sin(dot(st.xy,float2(12.9898,78.233))) * 43758.5453123);
		}

        float randomGradient (float2 st, float2 grad){
			return frac(sin(dot(st.xy,grad)) * 43758.5453123);
		}

        float3 colorDodge(float3 base, float3 blend) {
			return (blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0);
		}

        float2 RotateUV(float2 uv, float2 center, float rotation)
        {
            float2 translatedUV = uv - center;
            float cosTheta = cos(rotation);
            float sinTheta = sin(rotation);
            float2 rotatedUV;
            rotatedUV.x = translatedUV.x * cosTheta - translatedUV.y * sinTheta;
            rotatedUV.y = translatedUV.x * sinTheta + translatedUV.y * cosTheta;
            return rotatedUV + center;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            float smoothalpha = 1.0 - smoothstep(0.0, 0.75, c.a);
            c.a = 1.0f - smoothalpha;
            c.rgb *= c.a;

            float2 backgroundsMergedDimensions = float2(5, 2); //the number of background textures in the x and y directions

            float eps = 0.01f;
            float4 background1UVRect = float4(
                (1.0f / backgroundsMergedDimensions.x) * _BackgroundIndex + eps,
                0.5f + eps,
                (1.0f / backgroundsMergedDimensions.x) * (_BackgroundIndex+1) - eps,
                1.0f - eps
            );
            
            float4 background2UVRect = float4(
                (1.0f / backgroundsMergedDimensions.x) * _Background2Index + eps,
                -1.0f - eps,
                (1.0f / backgroundsMergedDimensions.x) * (_Background2Index+1) - eps,
                -0.5f + eps
            );
            
            float2 background1UV;
            float2 background2UV;
            float2 contentUV;
            
            fixed4 b1 = GetLayerColor(IN.viewDir, _BackgroundDepth, _BackgroundNormal, _BackgroundTex, _BackgroundSize,float4(0,0,1,1),background1UV,float2(0,0), int2(0,1));

            fixed4 b2 = GetLayerColor(IN.viewDir, _Background2Depth, _Background2Normal, _Background2Tex, _Background2Size,float4(0,0,1,1), background2UV,float2(0,0), int2(0,1));

            float3 customNormal = _ContentNormal;
            // float4 localCameraPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0f));
            // float3 localCameraDir = normalize(localCameraPosition.xyz);
            // localCameraDir.yz = 0;
            // customNormal += (localCameraDir + float3(0.0f, 0.0f, 0.25f)) * 0.2;
            // customNormal = normalize(customNormal);


            fixed4 c1 = GetLayerColor(
                IN.viewDir,
                _ContentDepth,
                customNormal,
                _ContentTex,
                _ContentSize,
                float4(0,0,1,1), 
                contentUV, 
                float2(0,sin(_Time.y * 0.75) * 0.05), 
                int2(1,1)
            );

            float2 usedUV = lerp(background1UV, background2UV, 1.0f - b1.a);
            usedUV = lerp(usedUV, contentUV, c1.a);

            float4 bg = lerp(b1, b2, 1.0f - b1.a);
            float4 fg = lerp(c, c1, 1.0f - c.a);

            float r = 0.15f;
            float2 sizeFac = float2(1.175f, 1.1f);
            float roundedBox = sdRoundedBox(
                (IN.uv_MainTex * float2(1.0f, 1.75f)) - float2(0.5, 1.75/2),
                float2(0.5, 1.75/2) * sizeFac,
                r
            );
            float alpha = step(roundedBox, -0.1f);
            
            float4 final = lerp(bg*alpha, fg, fg.a);
            if (final.a < 0.5) {discard;}

            float4 finalBack = tex2D(_CardBack, IN.uv_MainTex * float2(-1.0f, 1.0f));

            float3 planeUp = normalize(mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0)).xyz);
            float3 planeRight = normalize(mul((float3x3)unity_ObjectToWorld, float3(1, 0, 0)).xyz);
            float viewSide = dot(IN.viewDir, planeUp);
            float sideFac = step(0,viewSide);

            o.Albedo = lerp(finalBack, final, sideFac);


            
            fixed4 FoilPattern = GetLayerColor2(
                float2(0,0),
                IN.viewDir,
                _Background2Depth,
                _Background2Normal,
                _FoilPattern,
                _Background2Size,
                float4(0,0,1,1),
                float2(0,0)
            );

            // fixed4 FoilPattern = tex2D(_FoilPattern, usedUV * 0.25) * 1.5;
            
            float2 foilUV = IN.uv_MainTex;
            foilUV *= float2(1.5f, 1.5f);

            float dotP0 = dot(normalize(IN.viewDir), planeUp);
            float dotP1 = dot(normalize(IN.viewDir), planeRight);
            foilUV += float2(dotP0, dotP1) * 1.5;

            fixed4 foil = tex2D(_BackgroundsMerged, foilUV * 5);

            float luminance = max(
                dot(b1.rgb * (1.0f-c1.a), float3(0.299, 0.587, 0.114)),
                dot(c1.rgb * c1.a, float3(0.299, 0.587, 0.114))
            );
            

            //o.Albedo = lerp(o.Albedo, foil, c.a * 0.75 * (luminance * luminance * luminance * luminance) * smoothstep(0.2,0,FoilPattern.r));

            float luminanceModified = pow(luminance, 1.5) * 1; 
            luminanceModified = smoothstep(0.5,1,luminanceModified);

            float2 uv = RotateUV(IN.viewDirTangent.xy*-1, float2(0.5,0.5), 3.14 * 0.66);
            float3 foilresult = colorDodge(o.Albedo, tex2D(_BackgroundsMerged, uv) * 0.75f * (1.0f - c1.a) * (1.0f - c.a) * pow(FoilPattern.r,1));
            o.Albedo = foilresult;

            //float3 noiseNormals = b2.rgb;
            //float3 unpacked = UnpackNormal (tex2D (_Background2Tex, background2UV*0.01));
            //float3 unpackedWorld = mul((float3x3)unity_ObjectToWorld, unpacked);
            //float3 dd = abs(dot(IN.viewDir, unpacked));

            //o.Albedo = lerp(o.Albedo, foil.rgb, dd*luminance);

            // o.Albedo = lerp(o.Albedo.rgb, foil.rgb, saturate(luminanceModified * pow(FoilPattern*2, 5)) * (1.0f-c.a));
            // o.Albedo = colorDodge(o.Albedo.rgb, foil.rgb * 0.75);

            // o.Albedo = luminanceModified;
            

            o.Smoothness = _Glossiness;
            o.Metallic = _Metallic;
            o.Emission = c1 * c1.a * 0.1f * (1.0f - c.a) + (foilresult * 0.5f*pow(FoilPattern.r,1)) *(1.0f - c1.a);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
