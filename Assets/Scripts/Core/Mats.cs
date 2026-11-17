using System.Collections.Generic;
using UnityEngine;

namespace Naksat
{
    /// <summary>วัสดุ (สี/ผิว) แบบ URP Lit ที่ใช้ซ้ำ</summary>
    public static class Mats
    {
        static readonly Dictionary<string, Material> cache = new();
        static Shader lit;

        public static Material Get(string key, Color c, float smooth = 0.25f, float metal = 0f)
        {
            if (cache.TryGetValue(key, out var m)) return m;
            lit ??= Shader.Find("Universal Render Pipeline/Lit");
            m = new Material(lit) { name = key };
            m.SetColor("_BaseColor", c);
            m.SetFloat("_Smoothness", smooth);
            m.SetFloat("_Metallic", metal);
            cache[key] = m;
            return m;
        }

        /// <summary>สร้างกล่อง/ทรงพื้นฐานพร้อมวัสดุ (ใช้แทนโมเดลที่ยังไม่มี)</summary>
        public static GameObject Prim(PrimitiveType t, string name, Transform parent, Vector3 pos, Vector3 scale, Material m, bool keepCollider = false)
        {
            var g = GameObject.CreatePrimitive(t);
            g.name = name;
            g.transform.SetParent(parent, false);
            g.transform.localPosition = pos;
            g.transform.localScale = scale;
            g.GetComponent<Renderer>().sharedMaterial = m;
            if (!keepCollider) Object.Destroy(g.GetComponent<Collider>());
            return g;
        }

        /// <summary>โหลดโมเดลจาก Resources/Models (ทำจาก Blender) ถ้าไม่มีคืน null</summary>
        public static GameObject Model(string name, Transform parent, Vector3 pos, float yRot = 0f, float scale = 1f)
        {
            var prefab = Resources.Load<GameObject>("Models/" + name);
            if (prefab == null) return null;
            var g = Object.Instantiate(prefab, parent);
            g.name = name;
            g.transform.localPosition = pos;
            g.transform.localRotation = Quaternion.Euler(0, yRot, 0);
            g.transform.localScale = Vector3.one * scale;
            foreach (var c in g.GetComponentsInChildren<Collider>()) Object.Destroy(c);
            return g;
        }
    }
}
