using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/ColorMask")]
public sealed class ColorMaskEffect : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    Material m_Material;

    public bool IsActive() => m_Material != null && Active.value;

    public BoolParameter Active = new BoolParameter(false);

    public TextureParameter ColoringMask = new TextureParameter(null);

    public TextureParameter Strokes = new TextureParameter(null);

    public FloatParameter MaskTolerance = new FloatParameter(0.1f);
    public ColorParameter MaskColor = new ColorParameter(new Color(1f, 0f, 1f));

    [Range(0f, 1f)]
    public FloatParameter Intensity = new FloatParameter(1f);
    public Vector2Parameter Brightness = new Vector2Parameter(new Vector2(0f, 1f));

    [Range(1f, 32f)]
    public FloatParameter Tiling = new FloatParameter(8f);

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        Shader colorMask = Shader.Find("Hidden/Shader/ColorMaskPostProcessing");
        if (colorMask != null) m_Material = new Material(colorMask);
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null) return;

        m_Material.SetTexture("_CameraRender", source);

        m_Material.SetTexture("_Strokes", Strokes.value);

        m_Material.SetMatrix("_InverseProjectionMatrix", camera.camera.projectionMatrix.inverse);

        m_Material.SetMatrix("_ViewProjectInverse", (camera.camera.projectionMatrix * camera.camera.worldToCameraMatrix).inverse);
        m_Material.SetMatrix("_ViewToWorldMatrix", camera.camera.projectionMatrix);

        var p = GL.GetGPUProjectionMatrix(camera.camera.projectionMatrix, false);
        p[2, 3] = p[3, 2] = 0.0f;
        p[3, 3] = 1.0f;
        var clipToWorld = Matrix4x4.Inverse(p * camera.camera.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -p[2, 2]), Quaternion.identity, Vector3.one);
        m_Material.SetMatrix("clipToWorld", clipToWorld);

        m_Material.SetVector("_Params", new Vector4(0, 1, Intensity.value, Tiling.value));
        m_Material.SetVector("_Brightness", Brightness.value);

        m_Material.SetTexture("_ColoringMask", ColoringMask.value);
        
        m_Material.SetFloat("_MaskTolerance", MaskTolerance.value);
        m_Material.SetColor("_MaskColor", MaskColor.value);

        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);
}
