using UnityEngine;
using UnityEngine.InputSystem;

namespace Naksat
{
    /// <summary>
    /// ตัวผู้เล่น 2.5D: เดินซ้าย-ขวา วิ่ง กระโดด ยืนบนแท่นได้ (เหยียบจากด้านบน) โจมตี
    /// คำนวณการเคลื่อนที่เอง (ไม่ใช้ระบบฟิสิกส์) เพื่อให้ควบคุมแม่นและลื่นบนมือถือ
    /// </summary>
    public class Player : MonoBehaviour
    {
        public const float WalkSpeed = 4.2f, RunSpeed = 7f, JumpSpeed = 9.5f, Gravity = 26f;
        public Vector2 vel;
        public bool grounded = true;
        public int facing = 1;
        public HeroVisual visual;
        float dropTimer;          // กดลงบนแท่น = ลงจากแท่น
        float attackTimer;

        // ปุ่มสัมผัส (ตั้งค่าจาก TouchControls)
        public static float touchMove;
        public static bool touchJump, touchRun, touchAttack, touchDown;

        public static Player Spawn(Vector3 at, Transform parent)
        {
            var go = new GameObject("Player");
            go.transform.SetParent(parent);
            go.transform.position = at;
            var p = go.AddComponent<Player>();
            p.visual = HeroVisual.Create(go.transform);
            return p;
        }

        void Update()
        {
            var kb = Keyboard.current;
            float move = touchMove;
            bool run = touchRun, jump = touchJump, attack = touchAttack, down = touchDown;
            if (kb != null)
            {
                if (kb.leftArrowKey.isPressed || kb.aKey.isPressed) move = -1;
                if (kb.rightArrowKey.isPressed || kb.dKey.isPressed) move = 1;
                run |= kb.leftShiftKey.isPressed;
                jump |= kb.spaceKey.wasPressedThisFrame || kb.upArrowKey.wasPressedThisFrame || kb.wKey.wasPressedThisFrame;
                attack |= kb.jKey.wasPressedThisFrame || kb.zKey.wasPressedThisFrame;
                down |= kb.downArrowKey.isPressed || kb.sKey.isPressed;
            }
            touchJump = false;
            touchAttack = false;

            float dt = Time.deltaTime;
            float speed = run ? RunSpeed : WalkSpeed;
            float target = attackTimer > 0 && grounded ? move * speed * 0.3f : move * speed;
            vel.x = Mathf.MoveTowards(vel.x, target, (grounded ? 40f : 22f) * dt);
            if (move != 0) facing = move > 0 ? 1 : -1;

            if (jump && grounded)
            {
                if (down && OnPlatform()) dropTimer = 0.25f;  // ลงจากแท่น
                else vel.y = JumpSpeed;
                grounded = false;
            }
            if (attack && attackTimer <= 0f) attackTimer = 0.42f;
            attackTimer -= dt;
            dropTimer -= dt;

            vel.y -= Gravity * dt;
            var pos = transform.position;
            float oldY = pos.y;
            pos.x += vel.x * dt;
            pos.y += vel.y * dt;
            var st = World.I.stage;
            pos.x = Mathf.Clamp(pos.x, 0.5f, st.width - 0.5f);

            grounded = false;
            if (pos.y <= 0f) { pos.y = 0f; vel.y = 0; grounded = true; }
            else if (vel.y <= 0 && dropTimer <= 0)
            {
                foreach (var r in st.platforms)
                {
                    if (pos.x < r.xMin || pos.x > r.xMax) continue;
                    if (oldY >= r.y - 0.02f && pos.y <= r.y) { pos.y = r.y; vel.y = 0; grounded = true; break; }
                }
            }
            transform.position = pos;
            visual.Tick(this, Mathf.Abs(vel.x), attackTimer > 0 ? 1f - attackTimer / 0.42f : -1f, dt);
        }

        bool OnPlatform() => transform.position.y > 0.05f;
    }
}
