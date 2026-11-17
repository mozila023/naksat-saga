using UnityEngine;

namespace Naksat
{
    /// <summary>
    /// ภาพตัวละครฮีโร่ (โมเดลจาก Blender แบบชิ้นส่วนแยก) + ท่าทางด้วยโค้ด:
    /// ยืนหายใจ เดิน/วิ่งแกว่งแขนขา กระโดด และฟันอาวุธ
    /// ข้อต่อในโมเดลต้องชื่อ hips, torso, head, arm_l, arm_r, leg_l, leg_r
    /// </summary>
    public class HeroVisual : MonoBehaviour
    {
        Transform model, hips, torso, head, armL, armR, legL, legR;
        float t, turn = FaceRightYaw;
        public const float FaceRightYaw = 115f;  // โมเดลหันหน้าไปทาง +Z: 115° = หันขวาและเฉียงเข้าหากล้อง

        public static HeroVisual Create(Transform parent)
        {
            var go = new GameObject("Visual");
            go.transform.SetParent(parent, false);
            var v = go.AddComponent<HeroVisual>();
            var m = Mats.Model("hero", go.transform, Vector3.zero);
            if (m == null) m = Fallback(go.transform);
            v.model = m.transform;
            v.hips = Find(m.transform, "hips");
            v.torso = Find(m.transform, "torso");
            v.head = Find(m.transform, "head");
            v.armL = Find(m.transform, "arm_l");
            v.armR = Find(m.transform, "arm_r");
            v.legL = Find(m.transform, "leg_l");
            v.legR = Find(m.transform, "leg_r");
            foreach (var r in m.GetComponentsInChildren<Renderer>()) r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
            return v;
        }

        static Transform Find(Transform root, string n)
        {
            foreach (var t in root.GetComponentsInChildren<Transform>()) if (t.name == n) return t;
            return null;
        }

        /// <summary>ตัวสำรองตอนยังไม่มีโมเดล: แคปซูลกับหัวกลม</summary>
        static GameObject Fallback(Transform parent)
        {
            var root = new GameObject("hero_fallback");
            root.transform.SetParent(parent, false);
            var skin = Mats.Get("skin", new Color(0.93f, 0.74f, 0.6f), 0.4f);
            var shirt = Mats.Get("shirt", new Color(0.95f, 0.95f, 0.93f), 0.2f);
            var hips = new GameObject("hips").transform; hips.SetParent(root.transform, false); hips.localPosition = new Vector3(0, 0.62f, 0);
            var torso = new GameObject("torso").transform; torso.SetParent(hips, false);
            Mats.Prim(PrimitiveType.Capsule, "body", torso, new Vector3(0, 0.25f, 0), new Vector3(0.36f, 0.3f, 0.3f), shirt);
            var head = new GameObject("head").transform; head.SetParent(torso, false); head.localPosition = new Vector3(0, 0.5f, 0);
            Mats.Prim(PrimitiveType.Sphere, "face", head, new Vector3(0, 0.22f, 0), Vector3.one * 0.5f, skin);
            return root;
        }

        public void Tick(Player p, float speed, float attack, float dt)
        {
            t += dt;
            // หันหน้าซ้าย/ขวา (เฉียงเข้าหากล้องนิดหน่อยให้เห็นหน้า) หมุนแบบนุ่ม ๆ
            float goal = p.facing > 0 ? FaceRightYaw : -FaceRightYaw;
            turn = Mathf.MoveTowardsAngle(turn, goal, dt * 900f);
            transform.localRotation = Quaternion.Euler(0, turn, 0);

            float run = Mathf.Clamp01(speed / Player.RunSpeed);
            float cycle = t * (6f + 6f * run);
            float swing = Mathf.Sin(cycle) * Mathf.Lerp(0f, 55f, Mathf.Clamp01(speed / Player.WalkSpeed));
            float bob = speed > 0.1f ? Mathf.Abs(Mathf.Sin(cycle)) * 0.06f : Mathf.Sin(t * 2.4f) * 0.012f;

            if (!p.grounded)
            {
                float up = Mathf.Clamp(p.vel.y / Player.JumpSpeed, -1f, 1f);
                Set(legL, 25f + 20f * up); Set(legR, -35f * up);
                Set(armL, -150f * Mathf.Max(0, up) - 30f); Set(armR, -40f);
                bob = 0f;
            }
            else
            {
                Set(legL, swing); Set(legR, -swing);
                Set(armL, -swing * 0.9f); Set(armR, swing * 0.9f);
            }
            if (attack >= 0f)
            {
                // ฟัน: ยกแขนขวาไปข้างหลังแล้วฟาดลงข้างหน้า
                float a = attack < 0.35f ? Mathf.Lerp(0f, -160f, attack / 0.35f) : Mathf.Lerp(-160f, 60f, (attack - 0.35f) / 0.3f);
                Set(armR, a);
                if (torso) torso.localRotation = Quaternion.Euler(0, attack < 0.35f ? -20f : 25f, 0);
            }
            else if (torso) torso.localRotation = Quaternion.Euler(run * 10f, 0, 0);
            if (hips) hips.localPosition = new Vector3(0, hips.localPosition.y, 0);
            if (model) model.localPosition = new Vector3(0, bob, 0);
            if (head) head.localRotation = Quaternion.Euler(Mathf.Sin(t * 1.3f) * 3f, 0, 0);
        }

        static void Set(Transform j, float xDeg)
        {
            if (j) j.localRotation = Quaternion.Euler(xDeg, 0, 0);
        }
    }
}
