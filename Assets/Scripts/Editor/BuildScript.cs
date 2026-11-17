using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Naksat.EditorTools
{
    /// <summary>
    /// สร้างไฟล์เกมจากบรรทัดคำสั่ง (ใช้ใน GitHub Actions)
    /// เว็บ: build/WebGL  มือถือ: build/Android/NaksatSaga.apk
    /// </summary>
    public static class BuildScript
    {
        static string[] Scenes => EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();

        public static void WebGL()
        {
            // GitHub Pages ไม่ส่งหัวข้อบีบอัดให้ จึงต้องให้เกมแตกไฟล์เอง
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Gzip;
            PlayerSettings.WebGL.decompressionFallback = true;
            PlayerSettings.WebGL.dataCaching = true;
            Build(BuildTarget.WebGL, "build/WebGL");
        }

        public static void Android()
        {
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.mozila023.naksatsaga");
            EditorUserBuildSettings.buildAppBundle = false;
            Build(BuildTarget.Android, "build/Android/NaksatSaga.apk");
        }

        static void Build(BuildTarget target, string path)
        {
            var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = Scenes,
                locationPathName = path,
                target = target,
                options = BuildOptions.None,
            });
            Debug.Log($"BUILD {target}: {report.summary.result} ({report.summary.totalSize / 1048576} MB)");
            if (report.summary.result != BuildResult.Succeeded) EditorApplication.Exit(1);
        }
    }
}
