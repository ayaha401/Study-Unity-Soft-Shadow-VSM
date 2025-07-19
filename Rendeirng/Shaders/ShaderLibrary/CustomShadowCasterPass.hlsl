#ifndef CUSTOM_SHADOW_CASTER_PASS_INCLUDED
#define CUSTOM_SHADOW_CASTER_PASS_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float  depthLinear : TEXCOORD0;
};

float4x4 _LightVP; // ライト用のViewProjection行列
float _ShadowBias; // 影のバイアス
float3 _LightPos; // ライト位置
v2f vert (appdata v)
{
    const float3 positionWS = TransformObjectToWorld(v.vertex);
    const float3 lightDir = _LightVP[2].xyz; // ライトの向き
    
    v2f o;
    o.positionCS = mul(_LightVP, float4(positionWS + lightDir * _ShadowBias, 1));

    float depth = o.positionCS.z / o.positionCS.w;      // OpenGL 互換の NDC
    #if UNITY_REVERSED_Z                   // URP のプラットフォーム別マクロ
    // depth = 1.0 - depth;
    #endif
    o.depthLinear = saturate(depth);
    return o;
}

half4 frag (v2f i) : SV_Target
{
    float depth = i.depthLinear;
    float2 moments = float2(depth, depth * depth);

    return float4(moments, 0.0, 1.0);
    // return 0;
}
#endif