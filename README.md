# Study-Unity-Soft-Shadow-VSM
UnityでソフトシャドウをVSMという手法を使用して作る勉強をした。

[【URP14】シャドウマップを自作して、キャラクターの影をキャラクターが受けないようにする](https://zenn.dev/r_ngtm/articles/urp14-custom-shadow)
この記事をベースに


<img width="809" height="680" alt="image" src="https://github.com/user-attachments/assets/7e4eb390-b889-4537-9eb7-015e99ba7ed7" /><br>
[Variance Shadow Maps](https://asura.iaigiri.com/XNA_GS/xna33.html)この記事を参考にVSMを実装した。

<img width="1091" height="698" alt="image" src="https://github.com/user-attachments/assets/e39bc4f2-9ae6-4b0d-a375-65e037e25196" /><br>
でも、オブジェクトが埋まると影の位置がおかしくなる。

# 実装の説明

```C#  
characterDepthTexture ??= rtHandleSystem.Alloc(
shadowMapWidth,
shadowMapHeight,
depthBufferBits: DepthBits.None,
filterMode: FilterMode.Trilinear,
colorFormat: GraphicsFormat.R16G16_SFloat,
useMipMap: true,
autoGenerateMips: true, 
isShadowMap: false);
```
CustomShadowFeatureでシャドウマップにR値とG値を保存できるようにし、テクスチャはTrilinearなどのフィルターをかける。(VSMをするために必要な手順)、Mipmapも使うので`useMipMap: true`にする。

```C
half4 frag (v2f i) : SV_Target
{
    float depth = i.depthLinear;
    float2 moments = float2(depth, depth * depth);

    return float4(moments, 0.0, 1.0);
}
```
CustomShadowCasterPass.hlsl でR値にdepth、G値にdepthの2乗を入れる。

```C
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
```
CustomShadow.hlslで[チェビシェフの不等式](https://ja.wikipedia.org/wiki/%E3%83%81%E3%82%A7%E3%83%93%E3%82%B7%E3%82%A7%E3%83%95%E3%81%AE%E4%B8%8D%E7%AD%89%E5%BC%8F)という式をもとに影になる確率を計算する。ここでDepthとDepthの2乗、Mipmapを使用する。Mipmapの段階に応じでシャドウマップのボケが変わる
