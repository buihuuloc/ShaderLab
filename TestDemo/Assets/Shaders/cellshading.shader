//basic phong CG shader with spec map


Shader "CG Shaders/Toon/Cell Shading"
{
	Properties
	{
		_diffuseColor("Diffuse Color", Color) = (1,1,1,1)
		_diffuseMap("Diffuse", 2D) = "white" {}
		_specularPower ("Specular Power", Range(1.0, 50.0)) = 10
		_specularPower (" ", Float) = 10		
		_specularIntensity ("Specular Intensity", Range(0.0, 1.0)) = 1.0
		_specularIntensity (" ", Float) = 1.0
		_specMapConstant ("Additive Specularity", Range(0.0, 0.5)) = 0.0
		_specMapConstant (" ", Float) = 0.0
		_specularColor("Specular Color", Color) = (1,1,1,1)
		_normalMap("Normal / Specular (A)", 2D) = "bump" {}
		_bands ("Bands", Range(2.0, 10.0)) = 6.0
		_bands (" ", Float) = 6.0
		
	}
	SubShader
	{
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
			uniform sampler2D _diffuseMap;
			uniform half4 _diffuseMap_ST;			
			uniform fixed4 _LightColor0; 
			uniform half _FrenselPower;
			uniform fixed4 _rimColor;
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
				return saturate( (dot(N, L)+ 0.5)/2);
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
				
				//removed rim light from diffuse				
				//combine all lighting terms for the first light
				fixed lighting = saturate(IN.lighting + (diffuseL) + ambientL) ;
				_bands = ceil(_bands);
				//multiply the lighting by the number of bands and raise to next highest int value
				//divide by the number of bands to return to correct variance
				//subtract by .5 and multiply by 2 before saturation to bring to correct range
				diffuseL =  saturate(((ceil(_bands * lighting) / _bands)-.5) *2);
				fixed3 diffuse = _LightColor0.xyz * (diffuseL + ambientL) * attenuation;
				
				fixed specularHighlight = phong(reflect(IN.viewDir , normalDir) ,lightDirection)*attenuation;
				//I get the intensity of the color and multiply it by the ceil of the spec value
				//this creates a 100% spec/diffuse alpha
				fixed specIntensity = ceil(specularHighlight ) * _specularIntensity;
				//modify the spec highlight to be 100% diffuse + specularHighlight
				specularHighlight = 1+ specularHighlight;
				//lerp between diffuse and specular 
				diffuse = lerp (diffuse, specularHighlight * _specularColor ,  specIntensity );
				//I add the spec map to the diffuse, after multiplying by _specMapConstant 
				//this is just personal preferance it may not work in all use cases.				
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
				fixed4 lighting					:	TEXCOORD6;	
			};
			
			fixed lambert(fixed3 N, fixed3 L)
			{
				//modified to shift the lighting
				return saturate( (dot(N, L)+ 0.5)/2);
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
				
				_bands = ceil(_bands);
				//multiply the lighting by the number of bands and raise to next highest int value
				//divide by the number of bands to return to correct variance
				//subtract by .5 and multiply by 2 before saturation to bring to correct range
				diffuseL =  saturate(((ceil(_bands * diffuseL) / _bands)-.5) *2);
				fixed3 diffuse = _LightColor0.xyz * diffuseL * attenuation;
				
				fixed specularHighlight = phong(reflect(IN.viewDir , normalDir) ,lightDirection)*attenuation;
				//I get the intensity of the color and multiply it by the ceil of the spec value
				//this creates a 100% spec/diffuse alpha
				fixed specIntensity = ceil(specularHighlight ) * _specularIntensity;
				//modify the spec highlight to be 100% diffuse + specularHighlight
				specularHighlight = 1+ specularHighlight;
				//lerp between diffuse and specular 
				diffuse = lerp (diffuse, specularHighlight * _specularColor ,  specIntensity );
				//I add the spec map to the diffuse, after multiplying by _specMapConstant 
				//this is just personal preferance it may not work in all use cases.				
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