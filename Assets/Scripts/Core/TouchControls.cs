using UnityEngine;
using UnityEngine.UIElements;

namespace Naksat
{
    /// <summary>
    /// ปุ่มสัมผัสบนมือถือ (UI Toolkit): ซ้าย/ขวา, วิ่ง, กระโดด, ตี
    /// ใช้ตัวสร้างตัวอักษรขั้นสูง (Advanced Text Generator) เพื่อให้สระ/วรรณยุกต์ภาษาไทยวางถูกที่
    /// </summary>
    public class TouchControls : MonoBehaviour
    {
        public static void Create(Transform parent)
        {
            var go = new GameObject("TouchUI");
            go.transform.SetParent(parent);
            var doc = go.AddComponent<UIDocument>();
            var settings = ScriptableObject.CreateInstance<PanelSettings>();
            settings.scaleMode = PanelScaleMode.ScaleWithScreenSize;
            settings.referenceResolution = new Vector2Int(1280, 720);
            settings.match = 0.5f;
            settings.themeStyleSheet = Resources.Load<ThemeStyleSheet>("UI/NaksatTheme");
            doc.panelSettings = settings;
            go.AddComponent<TouchControls>();
        }

        void OnEnable()
        {
            var root = GetComponent<UIDocument>().rootVisualElement;
            if (root == null) return;
            root.style.unityTextGenerator = TextGeneratorType.Advanced;
            var font = Resources.Load<Font>("Fonts/Mali-Bold");
            if (font != null) root.style.unityFontDefinition = FontDefinition.FromFont(font);
            bool touch = Application.isMobilePlatform || UnityEngine.InputSystem.Touchscreen.current != null;
            if (!touch) return;
            Button(root, "◀", 40, null, 30, 180, () => Player.touchMove = -1, () => { if (Player.touchMove < 0) Player.touchMove = 0; });
            Button(root, "▶", 200, null, 30, 180, () => Player.touchMove = 1, () => { if (Player.touchMove > 0) Player.touchMove = 0; });
            Button(root, "ตี", null, 40, 40, 200, () => Player.touchAttack = true, null);
            Button(root, "โดด", null, 260, 30, 170, () => Player.touchJump = true, null);
            Button(root, "วิ่ง", null, 70, 260, 120, () => Player.touchRun = true, () => Player.touchRun = false);
        }

        static void Button(VisualElement root, string label, float? left, float? right, float bottom, float size, System.Action down, System.Action up)
        {
            var b = new Label(label);
            b.style.position = Position.Absolute;
            if (left.HasValue) b.style.left = left.Value;
            if (right.HasValue) b.style.right = right.Value;
            b.style.bottom = bottom;
            b.style.width = size;
            b.style.height = size;
            float r = size / 2;
            b.style.borderTopLeftRadius = r; b.style.borderTopRightRadius = r;
            b.style.borderBottomLeftRadius = r; b.style.borderBottomRightRadius = r;
            b.style.backgroundColor = new Color(1, 1, 1, 0.22f);
            b.style.borderLeftWidth = 3; b.style.borderRightWidth = 3; b.style.borderTopWidth = 3; b.style.borderBottomWidth = 3;
            var bc = new Color(1, 1, 1, 0.6f);
            b.style.borderLeftColor = bc; b.style.borderRightColor = bc; b.style.borderTopColor = bc; b.style.borderBottomColor = bc;
            b.style.color = Color.white;
            b.style.fontSize = size * 0.32f;
            b.style.unityTextAlign = TextAnchor.MiddleCenter;
            b.RegisterCallback<PointerDownEvent>(e => { down?.Invoke(); b.CapturePointer(e.pointerId); });
            b.RegisterCallback<PointerUpEvent>(e => { up?.Invoke(); b.ReleasePointer(e.pointerId); });
            root.Add(b);
        }
    }
}
