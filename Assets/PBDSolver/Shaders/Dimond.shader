Shader "Custom/Crystal"
{
    Properties
    {
        _BaseColor("Crystal Colour", Color) = (1, 1, 1, 1)
        _RefractionIndex("Index Of Refraction", Range(1, 2)) = 1.7
        _AngleOffset1("Angle Offset 1", float) = 8
        _CellDensity1("Cell Density 1", float) = 4
        _AngleOffset2("Angle Offset 2", float) = 6
        _CellDensity2("Cell Density 2", float) = 5
        _TriangleStrength("Triangle Strength 1", float) = 2
        [Space(10)]
        _RimStrenth("Rim Light Strength", float) = 1
        _Roughness("Roughness", Range(0, 1)) = 0.007
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "DelaunayTriangulationNoise.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _AngleOffset1, _CellDensity1, _AngleOffset2, _CellDensity2, _Roughness;
            float _RefractionIndex, _TriangleStrength, _TriangleStrength2, _RimStrenth;
            CBUFFER_END
            ENDHLSL

            Pass
            {
                Name "Crystal"
                Tags { "LightMode" = "UniversalForward" }

                HLSLPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _SHADOWS_SOFT

                struct a2v
                {
                    float4 positionOS: POSITION;
                    float2 uv: TEXCOORD0;
                    float4 normal: NORMAL;
                    float4 tangent: TANGENT;
                };

                struct v2f
                {
                    float4 positionCS: SV_POSITION;
                    float2 uv: TEXCOORD0;
                    float3 positionWS: TEXCOORD1;
                    float3 normalWS: TEXCOORD2;
                    float3 tangentWS: TEXCOORD3;
                };


                v2f vert(a2v v)
                {
                    v2f o;

                    VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                    o.positionCS = positionInputs.positionCS;
                    o.positionWS = positionInputs.positionWS;

                    o.uv = v.uv;
                    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalize(v.normal), v.tangent);
                    o.normalWS = vertexNormalInput.normalWS;
                    o.tangentWS = vertexNormalInput.tangentWS;
                    return o;
                }

                half3 Highlights(half3 positionWS, half roughness, half3 normalWS, half3 viewDirectionWS)
                {
                    Light mainLight = GetMainLight();
                    half roughness2 = roughness * roughness;
                    half3 halfDir = SafeNormalize(mainLight.direction + viewDirectionWS);
                    half NoH = saturate(dot(normalize(normalWS), halfDir));
                    half LoH = saturate(dot(mainLight.direction, halfDir));
                    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
                    half d = NoH * NoH * (roughness2 - 1.h) + 1.0001h;
                    half LoH2 = LoH * LoH;
                    half specularTerm = roughness2 / ((d * d) * max(0.1, LoH2) * (roughness + 0.5) * 4);
                    specularTerm = min(specularTerm, 10);
                    return specularTerm * mainLight.color * mainLight.distanceAttenuation;
                }

                float GetRandomValue(float2 uv)
                {
                    return frac(sin(dot(uv.xy, float2(18.5348, 43.253))) * 24358.545386);
                }

                float CalculateFresnel(float3 viewDir, float3 normal)
                {
                    float R_0 = (1 - 1 / _RefractionIndex) / (1 + 1 / _RefractionIndex);
                    R_0 *= R_0;
                    return R_0 + (1.0 - R_0) * pow((1.0 - saturate(dot(viewDir, normal))), _RimStrenth);
                }

                half4 frag(v2f i) : SV_Target
                {

                    real3x3 TtoW = CreateTangentToWorld(i.normalWS, i.tangentWS, -1);
                    float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - i.positionWS.xyz);
                    float3 viewDirectionTS = TransformWorldToTangent(viewDirectionWS, TtoW);
                    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
                    Light light = GetMainLight(shadowCoord);
                    //-------------DelaunayTriangulationNoise-------------
                    float3 normal = TransformWorldToTangent(i.normalWS, TtoW);
                    float3 refractDir = refract(viewDirectionTS, normal, 1 / _RefractionIndex);
                    float2 refractDir_XY = refractDir.xy / refractDir.z;

                    float Out1;
                    float2 Cell1;
                    float Out2;
                    float2 Cell2;
                    Unity_Delaunay_Triangulation_float(i.uv* float2(1.2, 1) + refractDir_XY, _AngleOffset1, _CellDensity1, Out1, Cell1);
                    Unity_Delaunay_Triangulation_float(i.uv* float2(1, 1.75) + refractDir_XY, _AngleOffset2, _CellDensity2, Out2, Cell2);
                    float randomTriangle1 = GetRandomValue(Cell1);
                    float randomTriangle2 = GetRandomValue(Cell2);

                    //remap shadow value from [0, 1] to [0.5, 1]
                    float triangleValue = randomTriangle1 * randomTriangle2 * _TriangleStrength * (light.shadowAttenuation * 0.5 + 0.5);

                    //-------------Rim-------------
                    float rim = CalculateFresnel(viewDirectionWS, i.normalWS);
                    rim = saturate(rim);

                    //-------------SH-------------
                    half3 SH = SampleSH(float4(-i.normalWS, 1));

                    //-------------HighLight-------------
                    float3 highLight = Highlights(i.positionWS, _Roughness, i.normalWS, viewDirectionWS) * light.shadowAttenuation;

                    return float4((triangleValue + rim) * SH * _BaseColor + highLight, 1);
                }
                ENDHLSL

            }
        }
}