﻿Shader "kokichi/Mobile/Rim/Default (One Light)" {
	Properties {
		_basetexture("Diffuse (RGB) ", 2D)	= "white" {}
		
		_ambientscale	("Ambient Scale", Float) = 1.0

		_rimlightcolor ("Rim Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_rimlightscale ("Rim Light Scale", Float) = 1.0
		_rimlightpower ("Rim Light Power", Float) = 0.2
	}
	SubShader {
	Pass
	{
		Tags { "LIGHTMODE"="ForwardBase" "QUEUE"="Geometry"}
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		#define RIM_LIGHT
		
		#include "RimInput.cginc"
		#include "RimFunc.cginc"
		
		ENDCG
	}
		
	} 
	FallBack "Diffuse"
}
