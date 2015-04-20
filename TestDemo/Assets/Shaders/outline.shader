//basic phong CG shader with spec map


Shader "CG Shaders/Toon/Outline"
{
	Properties
	{
		_lightingRamp("Lighting", 2D) = "white" {}
		_outlineColor("Outline Color", Color) = (0,0,0,1)
		_outlineThickness ("Outline Thickness", Range(0.0, 0.025)) = 0.01
		_outlineThickness(" ", Float) = 0.01
		_outlineShift ("Outline Light Shift", Range(0.0, 0.025)) = 0.01
		_outlineShift(" ", Float) = 0.01
		_diffuseColor("Diffuse Color", Color) = (1,1,1,1)
		_diffuseMap("Diffuse", 2D) = "white" {}
		_specularIntensity ("Specular Intensity", Range(0.0, 1.0)) = 1.0
		_specularIntensity (" ", Float) = 1.0
		_specularPower ("Specular Power", Range(1.0, 50.0)) = 10
		_specularPower (" ", Float) = 10
		_specMapConstant ("Additive Specularity", Range(0.0, 0.5)) = .25
		_specMapConstant (" ", Float) = .25
		_specularColor("Specular Color", Color) = (1,1,1,1)
		_normalMap("Normal / Specular (A)", 2D) = "bump" {}

		
	}
	SubShader
	{
		//prepass for outline
		
		Pass
		{
			ZWrite On
			 Tags {"Queue"="Transparent" "RenderType"="Transparent"}
			//ZTest Less      
			Cull Front
			
			CGPROGRAM
			#pragma vertex vShader
			#pragma fragment pShader
			#include "UnityCG.cginc"
			
			uniform fixed4 _outlineColor;
			uniform fixed _outlineThickness;
			uniform fixed _outlineShift;
			
			struct app2vert {
				float4 vertex 	: 	POSITION;
				fixed4 normal 	:	NORMAL;	
			};
			
			struct vert2Pixel
			{
				float4 pos 						: 	SV_POSITION;
			};
			vert2Pixel vShader(app2vert IN)
			{
				vert2Pixel OUT;
				float4x4 WorldViewProjection = UNITY_MATRIX_MVP;
				float4x4 WorldInverseTranspose = _World2Object; 
				float4x4 World = _Object2World;
				
				float4 deformedPosition = mul(World, IN.vertex);
				fixed3 norm = normalize(mul(  IN.normal , WorldInverseTranspose ).xyz);	
				
				half3 pixelToLightSource =_WorldSpaceLightPos0.xyz - (deformedPosition.xyz *_WorldSpaceLightPos0.w);
				fixed3 lightDirection = normalize(-pixelToLightSource);
				fixed diffuse = saturate(ceil(dot(IN.normal, lightDirection)));				
				
				deformedPosition.xyz += ( norm * _outlineThickness) + (lightDirection * _outlineShift);
			
				deformedPosition.xyz = mul(WorldInverseTranspose, float4 (deformedPosition.xyz, 1)).xyz * unity_Scale.w;
					
				
				OUT.pos = mul(WorldViewProjection, deformedPosition);
				
				return OUT;
			}
			
			fixed4 pShader(vert2Pixel IN): COLOR
			{
				fixed4 outColor;							
				outColor =  _outlineColor;
				return outColor;
				
			}
			ENDCG
		}
		
		
		Pass
		{
			Tags { "LightMode" = "ForwardBase" } 
            
			CGPROGRAM
			
			#pragma vertex vShader
			#pragma fragment pShader
			#include "UnityCG.cginc"
			#pragma multi_compile_fwdbase
			#pragma target 3.0
			
			uniform fixed3 _diffuseColor;
			uniform sampler2D _lightingRamp;
			uniform sampler2D _diffuseMap;
			uniform half4 _diffuseMap_ST;			
			uniform fixed4 _LightColor0; 
			uniform half _specularPower;
			uniform half _specularIntensity;
			uniform fixed4 _specularColor;
			uniform sampler2D _normalMap;
			uniform half4 _normalMap_ST;	
			uniform half _bands;
			uniform fixed _specMapConstant;
			
			struct app2vert {
				float4 vertex 	: 	POSITION;
				fixed2 texCoord : 	TEXCOORD0;
				fixed4 normal 	:	NORMAL;
				fixed4 tangent : TANGENT;
				
			};
			struct vert2Pixel
			{
				float4 pos 						: 	SV_POSITION;
				fixed2 uvs						:	TEXCOORD0;
				fixed3 normalDir						:	TEXCOORD1;	
				fixed3 binormalDir					:	TEXCOORD2;	
				fixed3 tangentDir					:	TEXCOORD3;	
				half3 posWorld						:	TEXCOORD4;	
				fixed3 viewDir						:	TEXCOORD5;
				fixed3 lighting						:	TEXCOORD6;
			};
			
			fixed lambert(fixed3 N, fixed3 L)
			{
				//modified to shift the lighting
				return saturate( (dot(N, L)+1)/2);
			}
			fixed frensel(fixed3 V, fixed3 N, half P)
			{	
				return pow(1 - saturate(dot(N, V)), P);
			}
			fixed phong(fixed3 R, fixed3 L)
			{
				//modified to return a sharp higlight
				return floor(2 * pow(saturate(dot(R, L)), _specularPower))/ 2;
			}
			vert2Pixel vShader(app2vert IN)
			{
				vert2Pixel OUT;
				float4x4 WorldViewProjection = UNITY_MATRIX_MVP;
				float4x4 WorldInverseTranspose = _World2Object; 
				float4x4 World = _Object2World;
				
			
							
				OUT.pos = mul(WorldViewProjection, IN.vertex);
				OUT.uvs = IN.texCoord;					
				OUT.normalDir = normalize(mul(IN.normal, WorldInverseTranspose).xyz);
				OUT.tangentDir = normalize(mul(IN.tangent, WorldInverseTranspose).xyz);
				OUT.binormalDir = normalize(cross(OUT.normalDir, OUT.tangentDir)); 
				OUT.posWorld = mul(World, IN.vertex).xyz;
				OUT.viewDir = normalize( OUT.posWorld - _WorldSpaceCameraPos);

				//vertex lights
				fixed3 vertexLighting = fixed3(0.0, 0.0, 0.0);
				#ifdef VERTEXLIGHT_ON
				 for (int index = 0; index < 4; index++)
					{    						
						half3 vertexToLightSource = half3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]) - OUT.posWorld;
						fixed attenuation  = (1.0/ length(vertexToLightSource)) *.5;	
						fixed3 diffuse = unity_LightColor[index].xyz * lambert(OUT.normalDir, normalize(vertexToLightSource)) * attenuation;
						vertexLighting = vertexLighting + diffuse;
					}
				vertexLighting = saturate( vertexLighting );
				#endif
				OUT.lighting = vertexLighting ;
				//vertex lighting is VERY reactive to this shader for some reason, but the flickering is unnacceptable
				//leaving this in to 
				OUT.lighting = 0;
				return OUT;
			}
			
			fixed4 pShader(vert2Pixel IN): COLOR
			{
				half2 normalUVs = TRANSFORM_TEX(IN.uvs, _normalMap);
				fixed4 normalD = tex2D(_normalMap, normalUVs);
				normalD.xyz = (normalD.xyz * 2) - 1;
			
				
				//half3 normalDir = half3(2.0 * normalSample.xy - float2(1.0), 0.0);
				//deriving the z component
				//normalDir.z = sqrt(1.0 - dot(normalDir, normalDir));
               // alternatively you can approximate deriving the z component without sqrt like so:  
				//normalDir.z = 1.0 - 0.5 * dot(normalDir, normalDir);
				
				fixed3 normalDir = normalD.xyz;	
				fixed specMap = normalD.w;
				normalDir = normalize((normalDir.x * IN.tangentDir) + (normalDir.y * IN.binormalDir) + (normalDir.z * IN.normalDir));
	
				fixed3 ambientL = UNITY_LIGHTMODEL_AMBIENT.xyz;
	
				//Main Light calculation - includes directional lights
				half3 pixelToLightSource =_WorldSpaceLightPos0.xyz - (IN.posWorld*_WorldSpaceLightPos0.w);
				fixed attenuation  = lerp(1.0, 1.0/ length(pixelToLightSource), _WorldSpaceLightPos0.w);				
				fixed3 lightDirection = normalize(pixelToLightSource);
				fixed diffuseL = lambert(normalDir, lightDirection);				
				
				fixed lighting = saturate(saturate(IN.lighting - diffuseL) + diffuseL + ambientL) ;
				fixed lightUV = clamp( lighting, 0.01 , .99);
				fixed3 diffuse = tex2D(_lightingRamp, fixed2(lightUV,0)).xyz;
				diffuse = _LightColor0.xyz * (diffuse + ambientL) * attenuation;
				
				fixed specularHighlight = phong(reflect(IN.viewDir , normalDir) ,lightDirection)*attenuation;
				fixed specIntensity = ceil(specularHighlight ) * _specularIntensity;
				specularHighlight = 1+ specularHighlight;
				diffuse = lerp (diffuse, specularHighlight * _specularColor ,  specIntensity );
				diffuse += specMap * diffuse *_specMapConstant;
				
				fixed4 outColor;							
				half2 diffuseUVs = TRANSFORM_TEX(IN.uvs, _diffuseMap);
				fixed4 texSample = tex2D(_diffuseMap, diffuseUVs);
				fixed3 diffuseS = (diffuse * texSample.xyz) * _diffuseColor.xyz;
				outColor = fixed4( diffuseS ,1.0);
				return outColor;
			}
			
			ENDCG
		}	
		
		//the second pass for additional lights
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" } 
			Blend One One  
			
			CGPROGRAM
			#pragma vertex vShader
			#pragma fragment pShader
			#include "UnityCG.cginc"
			#pragma target 3.0
			
			uniform fixed3 _diffuseColor;
			uniform sampler2D _diffuseMap;
			uniform half4 _diffuseMap_ST;
			uniform fixed4 _LightColor0; 			
			uniform half _specularPower;
			uniform half _specularIntensity;
			uniform fixed4 _specularColor;
			uniform sampler2D _normalMap;
			uniform half4 _normalMap_ST;	
			uniform fixed _specMapConstant;
			uniform sampler2D _lightingRamp;
			
			
			struct app2vert {
				float4 vertex 	: 	POSITION;
				fixed2 texCoord : 	TEXCOORD0;
				fixed4 normal 	:	NORMAL;
				fixed4 tangent : TANGENT;
			};
			struct vert2Pixel
			{
				float4 pos 						: 	SV_POSITION;
				fixed2 uvs						:	TEXCOORD0;	
				fixed3 normalDir						:	TEXCOORD1;	
				fixed3 binormalDir					:	TEXCOORD2;	
				fixed3 tangentDir					:	TEXCOORD3;	
				half3 posWorld						:	TEXCOORD4;	
				fixed3 viewDir						:	TEXCOORD5;
				fixed4 lighting					:	TEXCOORD6;	
			};
			
			fixed lambert(fixed3 N, fixed3 L)
			{
				return saturate( (dot(N, L)+1)/2);
			}
			fixed frensel(fixed3 V, fixed3 N, half P)
			{	
				return pow(1 - saturate(dot(N, V)), P);
			}
			fixed phong(fixed3 R, fixed3 L)
			{
				return floor(2 * pow(saturate(dot(R, L)), _specularPower))/ 2;
			}
			vert2Pixel vShader(app2vert IN)
			{
				vert2Pixel OUT;
				float4x4 WorldViewProjection = UNITY_MATRIX_MVP;
				float4x4 WorldInverseTranspose = _World2Object; 
				float4x4 World = _Object2World;
				
				OUT.pos = mul(WorldViewProjection, IN.vertex);
				OUT.uvs = IN.texCoord;	
				OUT.normalDir = normalize(mul(IN.normal, WorldInverseTranspose).xyz);
				OUT.tangentDir = normalize(mul(IN.tangent, WorldInverseTranspose).xyz);
				OUT.binormalDir = normalize(cross(OUT.normalDir, OUT.tangentDir)); 
				OUT.posWorld = mul(World, IN.vertex).xyz;
				OUT.viewDir = normalize( OUT.posWorld - _WorldSpaceCameraPos);
				return OUT;
			}
			fixed4 pShader(vert2Pixel IN): COLOR
			{
				half2 normalUVs = TRANSFORM_TEX(IN.uvs, _normalMap);
				fixed4 normalD = tex2D(_normalMap, normalUVs);
				normalD.xyz = (normalD.xyz * 2) - 1;
				
				//half3 normalDir = half3(2.0 * normalSample.xy - float2(1.0), 0.0);
				//deriving the z component
				//normalDir.z = sqrt(1.0 - dot(normalDir, normalDir));
               // alternatively you can approximate deriving the z component without sqrt like so: 
				//normalDir.z = 1.0 - 0.5 * dot(normalDir, normalDir);
				
				fixed3 normalDir = normalD.xyz;	
				fixed specMap = normalD.w;
				normalDir = normalize((normalDir.x * IN.tangentDir) + (normalDir.y * IN.binormalDir) + (normalDir.z * IN.normalDir));
				
				//Fill lights
				half3 pixelToLightSource =_WorldSpaceLightPos0.xyz- (IN.posWorld*_WorldSpaceLightPos0.w);
				fixed attenuation  = lerp(1.0, 1.0/ length(pixelToLightSource), _WorldSpaceLightPos0.w);				
				fixed3 lightDirection = normalize(pixelToLightSource);
				fixed diffuseL = lambert(normalDir, lightDirection);	
				
				//sample the lighting ramp based on the lighting amount
				//lighting must be clamped slightly inside 0-1 to avoid wrapping
				fixed lightUV = clamp( diffuseL, 0.01 , .99);
				fixed3 diffuse = tex2D(_lightingRamp, fixed2(lightUV,0)).xyz;
				
				diffuse = _LightColor0.xyz * diffuse * attenuation;
				
				//specular highlight
				fixed specularHighlight = phong(reflect(IN.viewDir , normalDir) ,lightDirection)*attenuation;
				fixed specIntensity = ceil(specularHighlight ) * _specularIntensity;
				specularHighlight = 1+ specularHighlight;
				diffuse = lerp (diffuse, specularHighlight * _specularColor ,  specIntensity );
				diffuse += specMap * diffuse *_specMapConstant;
				
				fixed4 outColor;							
				half2 diffuseUVs = TRANSFORM_TEX(IN.uvs, _diffuseMap);
				fixed4 texSample = tex2D(_diffuseMap, diffuseUVs);
				fixed3 diffuseS = (diffuse * texSample.xyz) * _diffuseColor.xyz;
				outColor = fixed4( diffuseS,1.0);
				return outColor;
			}
			
			ENDCG
		}	
	}
}