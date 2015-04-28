﻿Shader "kokichi/Mobile/Dota2 Mobile (1 Directional Light) Transparent" {
	Properties {
		_basetexture("Diffuse (RGB) Self-Illumination (A)", 2D)	= "white" {}
		_normalmap	("Normal (RG) Metalness (B)", 2D) = "bump" {}
		_maskmap2	("Mask 2 (RGBA) ", 2D) = "black" {}
		_ambientscale("Ambient Scale", Float) = 3
		
		_rimlightcolor ("Rim Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_rimlightscale ("Rim Light Scale", Float) = 1.0
		_rimlightblendtofull ("Rim Light Blend To Full", Range(0.0, 1.0)) = 0.0
		
		_specularcolor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_specularexponent ("Specular Exponent", Float) = 1.0
		_specularscale ("Specular Scale", Float) = 1.0
		_specularblendtofull ("Specular Blend To Full", Range(0.0, 1.0)) = 0.0
		
		_selfillumblendtofull ("Self-Illumination Blend To Full", Range(0.0, 1.0)) = 0.0
		_alpha("Alpha ", Float) = 1
	}
	SubShader {
	Tags { "Queue" = "Transparent" } 
	Pass
	{
		Tags { "LIGHTMODE"="ForwardBase" "QUEUE"="Transparent" "IGNOREPROJECTOR"="true" "RenderType"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		
		#define ONE_LIGHT
		#define TRANSPARENT
		
		#include "Dota2Input.cginc"
		#include "Dota2Util.cginc"
		#include "Dota2Function.cginc"
		
		ENDCG
	}
		
	} 
	FallBack "Diffuse"
}