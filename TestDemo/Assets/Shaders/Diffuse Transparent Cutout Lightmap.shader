﻿Shader "Custom/Transparent Cutout Lightmap" {
 
  Properties {
    _basetexture ("Texture 1", 2D) = "white" {}
    _color("Color", Color) = (1,1,1,1)
    _alphaCut("Cut", float) = 0.5
  }
 
  SubShader {
    Tags {  "Queue" = "AlphaTest" }
 
    Pass {
      // Disable lighting, we're only using the lightmap
      Lighting Off
      CGPROGRAM
      // Must be a vert/frag shader, not a surface shader: the necessary variables
      // won't be defined yet for surface shaders.
      #pragma vertex vert
      #pragma fragment frag
 
      #include "UnityCG.cginc"
 
      struct v2f {
        float4 pos : SV_POSITION;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
      };
 
      struct appdata_lightmap {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;
        float2 texcoord1 : TEXCOORD1;
      };
 
      // These are prepopulated by Unity
      sampler2D unity_Lightmap;
      float4 unity_LightmapST;
      float4 _color;
      float _alphaCut;
 
      sampler2D _basetexture;
      float4 _basetexture_ST; // Define this since its expected by TRANSFORM_TEX; it is also pre-populated by Unity.
 
      v2f vert(appdata_lightmap i) {
        v2f o;
        o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 
        // UnityCG.cginc - Transforms 2D UV by scale/bias property
        // #define TRANSFORM_TEX(tex,name) (tex.xy * name##_ST.xy + name##_ST.zw)
        o.uv0 = TRANSFORM_TEX(i.texcoord, _basetexture);
 
        // Use `unity_LightmapST` NOT `unity_Lightmap_ST`
        o.uv1 = i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        return o;
      }
 
      half4 frag(v2f i) : COLOR {
        half4 main_color = tex2D(_basetexture, i.uv0) * _color;
 
        // Decodes lightmaps:
        // - doubleLDR encoded on GLES
        // - RGBM encoded with range [0;8] on other platforms using surface shaders
        // inline fixed3 DecodeLightmap(fixed4 color) {
        // #if defined(SHADER_API_GLES) && defined(SHADER_API_MOBILE)
          // return 2.0 * color.rgb;
        // #else
          // return (8.0 * color.a) * color.rgb;
        // #endif
        // }
 
        main_color.rgb *= DecodeLightmap(tex2D(unity_Lightmap, i.uv1));
        clip(main_color.a - _alphaCut);
        return main_color;
      }
      ENDCG
    }
  }
}