using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Naksat
{
    /// <summary>กล้องมองด้านข้างเอียงลงนิดหน่อย ตามผู้เล่นแบบนุ่ม ๆ (มุมแบบ 2.5D)</summary>
    public class CameraRig : MonoBehaviour
    {
        Transform target;
        Stage stage;
        Camera cam;
        Vector3 vel;

        public static CameraRig Create(Transform target, Stage stage)
        {
            var go = new GameObject("Camera");
            go.tag = "MainCamera";
            var cam = go.AddComponent<Camera>();
            cam.fieldOfView = 32f;
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 400f;
            cam.clearFlags = CameraClearFlags.Skybox;
            var data = go.AddComponent<UniversalAdditionalCameraData>();
            data.renderPostProcessing = true;
            data.antialiasing = AntialiasingMode.FastApproximateAntialiasing;
            go.AddComponent<AudioListener>();
            var rig = go.AddComponent<CameraRig>();
            rig.target = target;
            rig.stage = stage;
            rig.cam = cam;
            go.transform.rotation = Quaternion.Euler(8f, 0f, 0f);
            go.transform.position = rig.Goal();
            return rig;
        }

        Vector3 Goal()
        {
            // จอแนวตั้ง (มือถือ) ถอยกล้องออกไปอีกให้เห็นกว้างพอ
            float aspect = (float)Screen.width / Mathf.Max(1, Screen.height);
            float dist = aspect < 1f ? 26f : 17f;
            var t = target.position;
            float x = Mathf.Clamp(t.x, 6f, stage.width - 6f);
            return new Vector3(x, 2.6f + t.y * 0.5f + dist * Mathf.Tan(8f * Mathf.Deg2Rad), -dist);
        }

        void LateUpdate()
        {
            transform.position = Vector3.SmoothDamp(transform.position, Goal(), ref vel, 0.18f);
        }
    }
}
