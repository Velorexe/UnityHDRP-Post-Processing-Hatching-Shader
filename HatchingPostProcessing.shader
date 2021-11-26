Shader "Hidden/Shader/HatchingPostProcessingEffect"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"

    #define TEXTURE2D_SAMPLER2D(textureName, samplerName) Texture2D textureName; SamplerState samplerName
    #define SAMPLE_TEXTURE2D(textureName, samplerName, coord2) textureName.Sample(samplerName, coord2)

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;

        float2 customTexcoord : TEXCOORD1;
        
        float3 worldDirection : TEXCOORD3;

        UNITY_VERTEX_OUTPUT_STEREO
    };

    TEXTURE2D_X(_CameraRender);

    TEXTURE2D_SAMPLER2D(_Strokes, sampler_Strokes);

    Matrix _InverseProjectionMatrix;
    Matrix _ViewToWorldMatrix;
    Matrix _ViewProjectInverse;

    float3 _CameraDirection;

    Matrix clipToWorld;

    float2 _Brightness = float2(0, 1);

    float4 _Params = float4(1, 0, 1, 1);

    float _Intensity = 1;

    Varyings Vert(Attributes input)
    {
        Varyings output;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);

        output.customTexcoord = output.texcoord;

        #if UNITY_UV_STARTS_AT_TOP
            output.customTexcoord = output.customTexcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
        #endif

        //Translates the inverted View Projection to a world view direction
        float4 cameraLocalDir = mul(_ViewProjectInverse, float4(output.texcoord.x * 2.0 - 1.0, output.texcoord.y * 2.0 - 1.0, 0.5, 1.0));
        cameraLocalDir.xyz /= cameraLocalDir.w;
        cameraLocalDir.xyz -= _WorldSpaceCameraPos;

        float4 cameraForwardDir = mul(_ViewProjectInverse, float4(0.0, 0.0, 0.5, 1.0));
        cameraForwardDir.xyz /= cameraForwardDir.w;
        cameraForwardDir.xyz -= _WorldSpaceCameraPos;

        output.worldDirection = cameraLocalDir.xyz / length(cameraForwardDir.xyz);

        return output;
    }

    float Hatching(float2 uv, float NdotL) 
    {
        half hatch = saturate(1 - NdotL);

		half3 tex = SAMPLE_TEXTURE2D(_Strokes, sampler_Strokes, uv).rgb;

		float dark = smoothstep(0, hatch, tex.r) + _Brightness.x;
		float light = smoothstep(0, hatch, tex.g) * _Brightness.y;

		hatch = lerp(dark, light, NdotL);

		return saturate(hatch);
    }

    float3 Blend(float3 color, float3 hatch, float lum) 
    {
        float3 col = color.rgb;

		col = lerp(color.rgb, color.rgb + hatch.rgb, _Params.z);

		return saturate(col);
    }

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        uint2 positionSS = input.texcoord * _ScreenSize.xy;

        float depth = LoadCameraDepth(positionSS);

        float3 worldPos = input.worldDirection * LinearEyeDepth(depth, _ZBufferParams) + _WorldSpaceCameraPos;

        float3 worldUV = worldPos.xyz * 0.01 * _Params.w;
        float2 uvX = worldUV.yz;
        float2 uvY = worldUV.xz;
        float2 uvZ = worldUV.xy;

        float3 screenColor = LOAD_TEXTURE2D_X(_CameraRender, positionSS).rgb;

        float luminance = SRGBToLinear(Luminance(screenColor)).r;

        float hatchX = Hatching(uvX, luminance);
        float hatchY = Hatching(uvY, luminance);
        float hatchZ = Hatching(uvZ, luminance);

        float3 hatch = (hatchX + hatchY + hatchZ) * 0.33;
        hatch = saturate(hatch);
        
        float3 col = Blend(Luminance(screenColor.rgb), hatch.rgb, luminance);

        return float4(lerp(screenColor, col, _Intensity), 1);
    }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment CustomPostProcess

            ENDHLSL
        }
    }
    Fallback Off
}
