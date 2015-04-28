﻿Shader "kokichi/Mobile/Dota2 Mobile (Multiple Light) Simple Hue" {
	Properties {
		_basetexture("Diffuse (RGB) Self-Illumination (A)", 2D)	= "white" {}
		_normalmap	("Normal (RG) Metalness (B) Hue (A)", 2D) = "bump" {}
		_maskmap2	("Mask 2 (RGBA) ", 2D) = "black" {}
		_ambientscale("Ambient Scale", Float) = 3
		
		_rimlightcolor ("Rim Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_specularcolor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_HueShift("HueShift", Range(0,359) ) = 0
	}
	SubShader {
	Pass
	{
		Tags { "LIGHTMODE"="ForwardBase" "Queue"="Geometry"}
		
		CGPROGRAM
		
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0
		
		#define SIMPLE
		#define HUE
		
		#include "Dota2Input.cginc"
		#include "HueLib.cginc"
		#include "Dota2Util.cginc"
		#include "Dota2Function.cginc"
		
		ENDCG
	}
	
	Pass
	{
		Tags { "LIGHTMODE"="ForwardAdd" "Queue"="Geometry"}
		Blend One One
		
		CGPROGRAM
		
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0
		
		#define SIMPLE
		#define HUE
		
		#include "Dota2Input.cginc"
		#include "HueLib.cginc"
		#include "Dota2Util.cginc"
		#include "Dota2Function.cginc"
		
		ENDCG
	}	
		
	} 
	FallBack "Diffuse"
}