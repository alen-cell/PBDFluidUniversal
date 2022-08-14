Shader "TNShaderPractise/ShaderPractise_Jade_BackLight"
{
	Properties
	{ [Header(Textures   IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII)]
		 [Space(8)]
		_MainTex("Texture", 2D) = "white" {}
		_NormalMap("NormalMap",2D) = "bump"{}
		_ThickMap("ThickMap",2D) = "white"{}

		[Space(8)][Header(Colors   IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII)]
		[Space(8)]
		[HDR]_MainColor("Main Color", Color) = (1,1,1,1)
		[HDR]_BackColor("BackColor Color", Color) = (1,1,1,1)

		[Spece(8)][Header(Parameters   IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII)]
		[Space(8)]
		_ThickMapIntensity("ThickMapIntensity",Float) = 1
		[Toggle(_ThickMapInvert)]_ThickMapInvert("ThickMapInvert",Float) = 0
		_NormalIntensity("NormalIntensity",Float) = 1
		_dis("distor",Range(0,1)) = 0
		_Pow("Pow",Range(0.05,10)) = 5
		_Value("Value",Range(0,10)) = 1
			//只是为了面板上能分块明显点.....
			[Space(8)][Header(MatCap   IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII)]
			[Space(8)]

			_MatCap("MatCapSpecular",2D) = "black"{}
			[HDR]_MatCapColor("_MatCapColor",Color) = (1,1,1,1)
		    _Blend("MapColorBlend",Range(0,1))=0.6
			_Roughness("Roughness",Range(0.02,1)) = 1
			_rotation("Rotation",Range(0,360)) = 0

	}
		SubShader
			{
				Tags { "RenderType" = "Opaque" "Queue" = "Geometry"  }

				Pass
				{

					Tags {  "LightMode" = "ForwardBase" }
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma multi_compile_fwdbase
					#include "AutoLight.cginc"
					#include "UnityCG.cginc"
					#include "Lighting.cginc"

					struct a2v
					{
						float4 vertex : POSITION;
						float3 normal : NORMAL;
						float4 tangent : TANGENT;
						float2 texcoord : TEXCOORD0;

					};

					struct v2f
					{
						float2 uv : TEXCOORD0;
						float4 pos : SV_POSITION;
						float3 posWS : TEXCOORD1;
						float3 nDir : TEXCOORD2;
						float3 tDir : TEXCOORD3;
						float3 bDir : TEXCOORD4;
						SHADOW_COORDS(5)
					};

					sampler2D _MainTex;
					float4 _MainTex_ST;
					sampler2D _ThickMap;
					float _ThickMapIntensity;
					float4 _MainColor;
					float4 _BackColor;
					sampler2D _NormalMap;
					float4 _NormalMap_ST;
					float _NormalIntensity;
					float _dis;
					float _Pow;
					float _Value;
					sampler2D _MatCap;
					float4 _MatCapColor;
					float _Roughness;
					float _rotation;
					float _ThickMapInvert;
					float _Blend;

					v2f vert(a2v v)
					{
						v2f o;
						o.pos = UnityObjectToClipPos(v.vertex);
						o.uv = v.texcoord;
						o.posWS = mul(unity_ObjectToWorld,v.vertex);
						o.nDir = UnityObjectToWorldNormal(v.normal);
						o.tDir = mul(unity_ObjectToWorld,v.tangent);
						o.bDir = cross(o.nDir,o.tDir) * v.tangent.w;

						TRANSFER_SHADOW(o);

						return o;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						//Normal
						half3 Ndir = normalize(i.nDir);
						half3 Tdir = normalize(i.tDir);
						half3 Bdir = normalize(i.bDir);
						float3x3 TBN = float3x3(Tdir,Bdir,Ndir);
						half3 bump = UnpackNormal(tex2D(_NormalMap,i.uv));
						bump.xy *= _NormalIntensity;
						bump.z = sqrt(1 - saturate(dot(bump.xy,bump.xy)));
						half3 normalDir = normalize(mul(bump,TBN));
						//再算一套法线用于光滑度粗细度控制 不然高光太受法线影响不好看
						half3 bump2 = half3(bump.xy * saturate(1 - _Roughness),bump2.z);
						bump2.z = sqrt(1 - saturate(dot(bump2.xy,bump2.xy)));
						half3 normalDir2 = normalize(mul(bump2,TBN));

						//Direction
						half3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
						half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWS.xyz));
						half3 reflDir = normalize(reflect(normalDir,-viewDir));


						//BackLight
						// 做了一下灯光角度偏转,显示情况中很少会有绝对水平的方向光. 后边做点光的时候需要再改回去
						half3 backLight = -normalize(float3(lightDir.x,lightDir.y - 0.75,lightDir.z) + normalDir * _dis * 0.15);
						half3 halfDir_back = normalize(viewDir + backLight + normalDir * _dis * 0.1);

						//DOT Prepare
						half VdotL = pow(saturate(dot(viewDir,backLight)),_Pow * 20) * _Value;
						half VdotLF = dot(viewDir,lightDir) * 0.5 + 0.5;
						//half NdotH_back = saturate(dot(normalDir,halfDir_back));
						half NdotV = saturate(dot(normalDir,viewDir));
						half NdotV2 = saturate(dot(normalDir2,viewDir));
						half NdotL = dot(normalDir,lightDir) * 0.5 + 0.5;

						//MatCap
						half3 Vnormal = normalize(mul(UNITY_MATRIX_V,normalDir2));
						//旋转MatCap
						float2 MatCapUV = Vnormal.xy * 0.5 + 0.5;
						float cosAngle = cos(radians(_rotation));
						float sinAngle = sin(radians(_rotation));
						float2x2 rot = float2x2(cosAngle,-sinAngle,sinAngle,cosAngle);
						float2 center = float2(0.5,0.5);
						MatCapUV -= center;
						MatCapUV = mul(rot,MatCapUV);
						MatCapUV += center;

						//这步计算没啥道理,就自己想当然来的 
						float4 MatCapSpecular = tex2D(_MatCap,MatCapUV) * _MatCapColor * pow(NdotV2,_Roughness * 1000);
						float4 MapCapColor = tex2D(_MatCap, MatCapUV);
						UNITY_LIGHT_ATTENUATION(atten,i,i.posWS);


						//ThickMap 根据实际提供的贴图 可以随意进行反向转换
						float4 thickness;
						if (_ThickMapInvert == 0)
						{
							thickness = tex2D(_ThickMap,i.uv) * _ThickMapIntensity;
						}
						else
						{
							thickness = (1 - tex2D(_ThickMap,i.uv)) * _ThickMapIntensity;
						}

						//IndirectSpecular
						half mip = (1 - _Roughness) * 6;

						half3 envMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflDir,mip),unity_SpecCube0_HDR);
						//玉表面会有镜面反射，但是不会像金属和镜子一样那么清晰 所以减弱点乘以0.1 这个看个人喜好
						half4 indirectSpecular = float4(envMap,1) * 0.1 + MatCapSpecular;

						//sh 用SH来作为光源计算 不然没有方向光的时候会全黑
						float4 SH = float4(ShadeSH9(float4(normalDir,1)),1);

						//FinalColor
						fixed4 col = tex2D(_MainTex, i.uv);
						float4 frontCol = col * _MainColor * NdotL * _LightColor0 * atten;
						float4 backCol = col * _BackColor * VdotL * _LightColor0 * thickness;

						float4 finalCol = lerp(frontCol,backCol,VdotLF);

						float4 IBLdiff = lerp(col * _MainColor * SH,col * _BackColor * SH,1 - NdotL);
						IBLdiff = _Blend * MapCapColor + (1 - _Blend) * IBLdiff;
						return finalCol += indirectSpecular + IBLdiff;
					}
					ENDCG
				}

				//AdditionalLightPass	   关键在于背光
				Pass
				{
					Blend One One
					Tags {  "LightMode" = "ForwardAdd" }
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma multi_compile_fwdadd
					#include "AutoLight.cginc"
					#include "UnityCG.cginc"
					#include "Lighting.cginc"

					struct a2v
					{
						float4 vertex : POSITION;
						float3 normal : NORMAL;
						float4 tangent : TANGENT;
						float2 texcoord : TEXCOORD0;

					};

					struct v2f
					{
						float2 uv : TEXCOORD0;
						float4 pos : SV_POSITION;
						float3 posWS : TEXCOORD1;
						float3 nDir : TEXCOORD2;
						float3 tDir : TEXCOORD3;
						float3 bDir : TEXCOORD4;
						SHADOW_COORDS(5)
					};

					sampler2D _MainTex;
					float4 _MainTex_ST;
					sampler2D _ThickMap;
					float _ThickMapIntensity;
					float4 _MainColor;
					float4 _SecondColor;
					float4 _BackColor;
					sampler2D _NormalMap;
					float4 _NormalMap_ST;
					float _NormalIntensity;
					float _dis;
					float _Pow;
					float _Value;
					sampler2D _MatCap;
					float4 _MatCapColor;
					float _Roughness;
					float _rotation;
					float _ThickMapInvert;
					

					v2f vert(a2v v)
					{
						v2f o;
						o.pos = UnityObjectToClipPos(v.vertex);
						o.uv = v.texcoord;
						o.posWS = mul(unity_ObjectToWorld,v.vertex);
						o.nDir = UnityObjectToWorldNormal(v.normal);
						o.tDir = mul(unity_ObjectToWorld,v.tangent);
						o.bDir = cross(o.nDir,o.tDir) * v.tangent.w;

						TRANSFER_SHADOW(o);

						return o;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						//Normal
						half3 Ndir = normalize(i.nDir);
						half3 Tdir = normalize(i.tDir);
						half3 Bdir = normalize(i.bDir);
						float3x3 TBN = float3x3(Tdir,Bdir,Ndir);
						half3 bump = UnpackNormal(tex2D(_NormalMap,i.uv));
						bump.xy *= _NormalIntensity;
						bump.z = sqrt(1 - saturate(dot(bump.xy,bump.xy)));
						half3 normalDir = normalize(mul(bump,TBN));
						//再算一套法线用于光滑度粗细度控制 不然高光太受法线影响不好看
						half3 bump2 = half3(bump.xy * saturate(1 - _Roughness),bump2.z);
						bump2.z = sqrt(1 - saturate(dot(bump2.xy,bump2.xy)));
						half3 normalDir2 = normalize(mul(bump2,TBN));

						//Direction
						half3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
						half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWS.xyz));
						half3 reflDir = normalize(reflect(normalDir,-viewDir));


						//BackLight
						// BasePass做了一下灯光角度偏转,但点光源是范围光源 不能矫正 所以要改回标准算法
						half3 backLight = -normalize(lightDir + normalDir * _dis * 0.15);
						half3 halfDir_back = normalize(viewDir + backLight + normalDir * _dis * 0.1);

						//DOT Prepare
						half VdotL = pow(saturate(dot(viewDir,backLight)),_Pow * 20) * _Value;
						half VdotLF = dot(viewDir,lightDir) * 0.5 + 0.5;
						//half NdotH_back = saturate(dot(normalDir,halfDir_back));
						half NdotV = saturate(dot(normalDir,viewDir));
						half NdotV2 = saturate(dot(normalDir2,viewDir));
						half NdotL = dot(normalDir,lightDir) * 0.5 + 0.5;

						//MatCap
						half3 Vnormal = normalize(mul(UNITY_MATRIX_V,normalDir2));
						//旋转MatCap
						float2 MatCapUV = Vnormal.xy * 0.5 + 0.5;
						float cosAngle = cos(radians(_rotation));
						float sinAngle = sin(radians(_rotation));
						float2x2 rot = float2x2(cosAngle,-sinAngle,sinAngle,cosAngle);
						float2 center = float2(0.5,0.5);
						MatCapUV -= center;
						MatCapUV = mul(rot,MatCapUV);
						MatCapUV += center;

						//这步计算没啥道理,就自己想当然来的 
						float4 MatCapSpecular = tex2D(_MatCap,MatCapUV) * _MatCapColor * pow(NdotV2,_Roughness * 1000);

						UNITY_LIGHT_ATTENUATION(atten,i,i.posWS);


						//ThickMap 根据实际提供的贴图 可以随意进行反向转换
						float4 thickness;
						if (_ThickMapInvert == 0)
						{
							thickness = tex2D(_ThickMap,i.uv) * _ThickMapIntensity;
						}
						else
						{
							thickness = (1 - tex2D(_ThickMap,i.uv)) * _ThickMapIntensity;
						}

						//FinalColor
						fixed4 col = tex2D(_MainTex, i.uv);
						float4 frontCol = col * _MainColor * NdotL * _LightColor0 * atten;
						float4 backCol = col * _BackColor * VdotL * _LightColor0 * thickness;

						float4 finalCol = lerp(frontCol,backCol,VdotLF);


						return finalCol;
					}
					ENDCG
				}
			}
				FallBack "Diffuse"
}


