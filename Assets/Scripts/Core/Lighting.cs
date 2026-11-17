using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Naksat
{
    /// <summary>แสงแดดยามบ่าย + ท้องฟ้า + ฟิลเตอร์ภาพ (bloom, โทนสีหนัง) ให้ภาพดูสวยสมจริง</summary>
    public static class Lighting
    {
        public static Light Sun;

        public static void Setup(Transform parent)
        {
            var sunGo = new GameObject("Sun");
            sunGo.transform.SetParent(parent);
            sunGo.transform.rotation = Quaternion.Euler(38f, -35f, 0f);
            Sun = sunGo.AddComponent<Light>();
            Sun.type = LightType.Directional;
            Sun.color = new Color(1f, 0.93f, 0.8f);
            Sun.intensity = 1.6f;
            Sun.shadows = LightShadows.Soft;
            Sun.shadowStrength = 0.75f;

            // แสงรอบตัวจากท้องฟ้า (ฟ้าอมฟ้า พื้นอมเขียว)
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.62f, 0.74f, 0.95f);
            RenderSettings.ambientEquatorColor = new Color(0.62f, 0.66f, 0.6f);
            RenderSettings.ambientGroundColor = new Color(0.32f, 0.3f, 0.24f);
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.Linear;
            RenderSettings.fogColor = new Color(0.72f, 0.82f, 0.95f);
            RenderSettings.fogStartDistance = 35f;
            RenderSettings.fogEndDistance = 140f;

            var sky = new Material(Shader.Find("Skybox/Procedural"));
            sky.SetFloat("_SunSize", 0.04f);
            sky.SetFloat("_AtmosphereThickness", 0.9f);
            sky.SetColor("_SkyTint", new Color(0.45f, 0.62f, 0.95f));
            sky.SetColor("_GroundColor", new Color(0.4f, 0.45f, 0.4f));
            sky.SetFloat("_Exposure", 1.2f);
            RenderSettings.skybox = sky;
            RenderSettings.sun = Sun;

            // ฟิลเตอร์ภาพรวม
            var volGo = new GameObject("PostFX");
            volGo.transform.SetParent(parent);
            var vol = volGo.AddComponent<Volume>();
            vol.isGlobal = true;
            var profile = ScriptableObject.CreateInstance<VolumeProfile>();
            var tone = profile.Add<Tonemapping>(true);
            tone.mode.Override(TonemappingMode.ACES);
            var bloom = profile.Add<Bloom>(true);
            bloom.intensity.Override(0.6f);
            bloom.threshold.Override(1.0f);
            bloom.scatter.Override(0.6f);
            var color = profile.Add<ColorAdjustments>(true);
            color.postExposure.Override(0.25f);
            color.saturation.Override(12f);
            color.contrast.Override(8f);
            var vig = profile.Add<Vignette>(true);
            vig.intensity.Override(0.22f);
            vol.profile = profile;
        }
    }
}
