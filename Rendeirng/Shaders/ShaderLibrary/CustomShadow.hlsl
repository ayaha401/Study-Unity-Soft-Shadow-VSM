#ifndef CUSTOM_SHADOW_HLSL_INCLUDED
#define CUSTOM_SHADOW_HLSL_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_CharacterShadowMapTexture);
SAMPLER(sampler_CharacterShadowMapTexture);
float2 _CharacterShadowMapTexture_TexelSize;

TEXTURE2D(_BgShadowMapTexture);
SAMPLER(sampler_BgShadowMapTexture);
float2 _BgShadowMapTexture_TexelSize;

float4x4 _LightVP; // ライト用のViewProjection行列
float3 _LightPos; // ライト位置

float SampleCustomShadow_VSM(float depth, float2 shadowCoord)
{
    float2 shadowMapDepth;
    shadowMapDepth = SAMPLE_TEXTURE2D_LOD(_CharacterShadowMapTexture, sampler_CharacterShadowMapTexture, shadowCoord.xy, 2).rg;
    
    #if UNITY_REVERSED_Z
    shadowMapDepth = 1.0 - shadowMapDepth;
    #endif
    
    float2 moments = float2(shadowMapDepth.x, shadowMapDepth.y);
    float mean = moments.x;
    float mean2 = moments.y;
    float variance = max(mean2 - mean * mean, 0.00002);

    float d = depth - mean;
    float p = variance / (variance + d * d);
    
    return saturate(1.0 - p);
}

half SampleCustomShadow(float3 positionWS)
{
    // ワールド空間の座標をクリップ空間に変換
    float3 shadowCoord = mul(_LightVP, positionWS - _LightPos);

    // 範囲[-1,1]を範囲[0,1]に変換 
    shadowCoord.xy = (shadowCoord.xy * 0.5 + 0.5);
    
    // 影のレンダリング範囲内なら1.0
    half inVolume = step(shadowCoord.x, 1);
    inVolume = min(inVolume, min(step(shadowCoord.x, 1), step(0, shadowCoord.x)));
    inVolume = min(inVolume, min(step(shadowCoord.y, 1), step(0, shadowCoord.y)));

    // プラットフォームによっては、テクスチャのUVのyが反転しているので、その補正を入れる
    #if UNITY_UV_STARTS_AT_TOP 
    shadowCoord.y = 1 - shadowCoord.y;
    #endif
    shadowCoord.xy = saturate(shadowCoord.xy);

    // 頂点座標から深度値を取り出す
    float depth = shadowCoord.z; 

    // プラットフォームによって、深度値の向きが異なっているため、その補正を入れる
    #if UNITY_REVERSED_Z
    depth = -depth; // near=0, far=1 となるように補正
    #endif
    
    float shadowMapDepth = SampleCustomShadow_VSM(depth, shadowCoord.xy);

    // 影のレンダリング範囲外を0にする
    half shadowAttenuation = inVolume > 0 ? shadowMapDepth : 1;
    return shadowAttenuation;
}

#endif
