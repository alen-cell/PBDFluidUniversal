Shader "Unlit/S_MaterialCapture"
{
	Properties
	{
		_MatCapTexure("MaterialCaptureTexture", 2D) = "white" {}
		_Normaltexture("Normaltexture", 2D) = "bump" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 tangent : TEXCOORD2;
				float3 normal : TEXCOORD3;
				float3 binormal : TEXCOORD4;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MatCapTexure;
			float4 _MatCapTexure_ST;
			sampler2D _Normaltexture;
			float4 _Normaltexture_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MatCapTexure);
				o.tangent = UnityObjectToWorldDir(v.tangent);
				o.normal = UnityObjectToWorldDir(v.normal);
				o.binormal = cross(v.tangent, v.normal);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 finalcolor = half4(1, 1, 1, 1);

				// sample the texture
				float3 texnorm = UnpackNormal(tex2D(_Normaltexture, i.uv));
				float3x3 transmatrix = float3x3(i.tangent, i.binormal, i.normal);

				float3 texnorm_ws = normalize(mul(texnorm, transmatrix));
				float3 texnorm_vs = mul(UNITY_MATRIX_V, texnorm_ws);


				float3 vv = float3(0, 0, 1);
				float3 rv = vv - (dot(vv, texnorm_vs) * -2 * texnorm_vs);
				float2 matcapuv = rv.xy / (sqrt((rv.x * rv.x) + (rv.y * rv.y) + (rv.z + 1) * (rv.z + 1)) * 0.75) + 0.5;

				fixed4 MatCapColor = tex2D(_MatCapTexure, matcapuv);

				finalcolor.rgb = MatCapColor;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalcolor);
				return finalcolor;
			}
			ENDCG
		}
	}
}