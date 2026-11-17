using System.Collections.Generic;
using UnityEngine;

namespace Naksat
{
    /// <summary>
    /// ฉากแบบ 2.5D: ตัวละครเดินบนแนวแกน X (ซ้าย-ขวา) ที่ z = 0 ฉากหลังเป็นโมเดล 3D วางลึกเข้าไปในแกน z
    /// พื้นอยู่ที่ y = 0, แท่นกระโดด (Platform) เหยียบได้จากด้านบนอย่างเดียว
    /// </summary>
    public class Stage : MonoBehaviour
    {
        public float width = 120f;
        public Vector3 SpawnPoint = new(6f, 0f, 0f);
        public readonly List<Rect> platforms = new();  // x, y = ขอบซ้าย/ผิวบน, width, height(หนา)

        public static Stage Build(string id, Transform parent)
        {
            var go = new GameObject("Stage_" + id);
            go.transform.SetParent(parent);
            var s = go.AddComponent<Stage>();
            s.BuildVillage();
            return s;
        }

        void BuildVillage()
        {
            width = 120f;
            var road = Mats.Get("road", new Color(0.55f, 0.43f, 0.3f), 0.15f);
            var grass = Mats.Get("grass", new Color(0.33f, 0.55f, 0.22f), 0.1f);
            var rice = Mats.Get("rice", new Color(0.55f, 0.75f, 0.25f), 0.2f);
            var water = Mats.Get("water", new Color(0.3f, 0.5f, 0.6f), 0.9f);

            // ถนนดินที่ตัวละครเดิน + หญ้าด้านหน้าและหลัง
            Mats.Prim(PrimitiveType.Cube, "road", transform, new Vector3(width / 2, -0.5f, 0.5f), new Vector3(width + 40, 1f, 3f), road);
            Mats.Prim(PrimitiveType.Cube, "grass_front", transform, new Vector3(width / 2, -0.52f, -4f), new Vector3(width + 40, 1f, 6f), grass);
            Mats.Prim(PrimitiveType.Cube, "grass_back", transform, new Vector3(width / 2, -0.52f, 12f), new Vector3(width + 60, 1f, 20f), grass);
            // นาข้าวแถบหลัง + คลองเล็ก
            Mats.Prim(PrimitiveType.Cube, "paddy", transform, new Vector3(width / 2, -0.4f, 30f), new Vector3(width + 80, 0.6f, 18f), rice);
            Mats.Prim(PrimitiveType.Cube, "canal", transform, new Vector3(width / 2, -0.45f, 21f), new Vector3(width + 80, 0.5f, 2f), water);
            // ภูเขาไกล ๆ
            var mtn = Mats.Get("mountain", new Color(0.35f, 0.48f, 0.42f), 0.05f);
            for (int i = 0; i < 9; i++)
            {
                float x = -20 + i * 20 + (i % 2) * 7;
                float h = 18 + (i * 37 % 11);
                var m = Mats.Prim(PrimitiveType.Sphere, "mountain" + i, transform, new Vector3(x, -2f, 85 + (i % 3) * 10), new Vector3(34, h * 2, 20), mtn);
            }

            // บ้านไทยใต้ถุนสูง ต้นมะพร้าว กล้วย (โมเดลจาก Blender ถ้ามี ไม่มีก็ใช้ทรงพื้นฐาน)
            float[] houses = { 14, 34, 58, 84, 104 };
            foreach (var hx in houses) House(new Vector3(hx, 0, 8f + (hx % 3)));
            for (int i = 0; i < 14; i++) Tree(new Vector3(4 + i * 8.6f + (i % 3) * 1.7f, 0, 4f + (i % 4) * 3.2f), i);

            // แท่นไม้ไผ่ให้กระโดด
            Platform(22, 2.2f, 5);
            Platform(29, 4.2f, 4);
            Platform(46, 2.4f, 6);
            Platform(70, 2.2f, 5);
            Platform(76, 4.4f, 4);
            Platform(95, 2.6f, 6);
        }

        void House(Vector3 p)
        {
            if (Mats.Model("thai_house", transform, p, 180f) != null) return;
            var wood = Mats.Get("teak", new Color(0.45f, 0.27f, 0.15f), 0.3f);
            var roof = Mats.Get("roof", new Color(0.55f, 0.18f, 0.12f), 0.35f);
            var h = new GameObject("house").transform;
            h.SetParent(transform, false);
            h.localPosition = p;
            for (int i = 0; i < 4; i++)
                Mats.Prim(PrimitiveType.Cylinder, "post", h, new Vector3(-2.6f + (i % 2) * 5.2f, 1.2f, -1.6f + (i / 2) * 3.2f), new Vector3(0.25f, 1.2f, 0.25f), wood);
            Mats.Prim(PrimitiveType.Cube, "floor", h, new Vector3(0, 2.5f, 0), new Vector3(6.2f, 0.25f, 4f), wood);
            Mats.Prim(PrimitiveType.Cube, "walls", h, new Vector3(0, 3.8f, 0), new Vector3(5.6f, 2.4f, 3.6f), wood);
            var r1 = Mats.Prim(PrimitiveType.Cube, "roofL", h, new Vector3(0, 5.8f, -1.1f), new Vector3(7f, 0.2f, 3f), roof);
            r1.transform.localRotation = Quaternion.Euler(-40, 0, 0);
            var r2 = Mats.Prim(PrimitiveType.Cube, "roofR", h, new Vector3(0, 5.8f, 1.1f), new Vector3(7f, 0.2f, 3f), roof);
            r2.transform.localRotation = Quaternion.Euler(40, 0, 0);
        }

        void Tree(Vector3 p, int i)
        {
            if (Mats.Model(i % 2 == 0 ? "coconut" : "banana", transform, p, i * 47f, 0.9f + (i % 3) * 0.15f) != null) return;
            var bark = Mats.Get("bark", new Color(0.4f, 0.3f, 0.2f), 0.1f);
            var leaf = Mats.Get("leaf", new Color(0.22f, 0.5f, 0.18f), 0.25f);
            var t = new GameObject("tree").transform;
            t.SetParent(transform, false);
            t.localPosition = p;
            Mats.Prim(PrimitiveType.Cylinder, "trunk", t, new Vector3(0, 2.5f, 0), new Vector3(0.35f, 2.5f, 0.35f), bark);
            Mats.Prim(PrimitiveType.Sphere, "crown", t, new Vector3(0, 5.6f, 0), new Vector3(3.2f, 2.4f, 3.2f), leaf);
        }

        void Platform(float x, float y, float w)
        {
            platforms.Add(new Rect(x, y, w, 0.3f));
            if (Mats.Model("bamboo_platform", transform, new Vector3(x + w / 2, y, 0f), 0f, 1f) is { } g)
            {
                g.transform.localScale = new Vector3(w / 4f, 1, 1);
                return;
            }
            var bamboo = Mats.Get("bamboo", new Color(0.7f, 0.65f, 0.35f), 0.4f);
            Mats.Prim(PrimitiveType.Cube, "platform", transform, new Vector3(x + w / 2, y - 0.15f, 0.2f), new Vector3(w, 0.3f, 1.6f), bamboo);
        }
    }
}
