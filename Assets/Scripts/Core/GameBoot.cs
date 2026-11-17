using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Naksat
{
    /// <summary>
    /// จุดเริ่มเกม: สร้างทุกอย่างด้วยโค้ด (แสง กล้อง ฉาก ตัวละคร) ไม่ต้องจัดฉากในโปรแกรม
    /// ทำงานเองอัตโนมัติหลังโหลดฉากแรก
    /// </summary>
    public static class GameBoot
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Boot()
        {
            if (Object.FindAnyObjectByType<World>() != null) return;
            // ล้างของตัวอย่างจากเทมเพลต (กล้อง/แสงเดิม) แล้วสร้างใหม่ทั้งหมด
            foreach (var cam in Object.FindObjectsByType<Camera>(FindObjectsSortMode.None)) Object.Destroy(cam.gameObject);
            foreach (var l in Object.FindObjectsByType<Light>(FindObjectsSortMode.None)) Object.Destroy(l.gameObject);
            Application.targetFrameRate = 60;
            new GameObject("World").AddComponent<World>();
        }
    }

    /// <summary>ตัวคุมโลกเกม: ถือฉากปัจจุบัน ผู้เล่น และกล้อง</summary>
    public class World : MonoBehaviour
    {
        public static World I;
        public Player player;
        public CameraRig rig;
        public Stage stage;

        void Awake()
        {
            I = this;
            Lighting.Setup(transform);
            stage = Stage.Build("village", transform);
            player = Player.Spawn(stage.SpawnPoint, transform);
            rig = CameraRig.Create(player.transform, stage);
            TouchControls.Create(transform);
        }
    }
}
