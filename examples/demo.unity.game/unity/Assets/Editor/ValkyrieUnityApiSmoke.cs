using System;
using UnityEngine;
using UnityEditor;

namespace Valkyrie.Unity.Smoke
{
    public static class UnityApiSmoke
    {
        public static void Run()
        {
            var dataPath = Application.dataPath;
            Debug.Log($"[Valkyrie] Application.dataPath = {dataPath}");
            Debug.Log($"[Valkyrie] EditorApplication.dataPath = {EditorApplication.applicationContentsPath}");
            var requestType = Type.GetType("UnityEngine.Networking.UnityWebRequest, UnityEngine.UnityWebRequestModule");
            if (requestType == null)
            {
                throw new InvalidOperationException("UnityWebRequest type missing");
            }
            var getMethod = requestType.GetMethod("Get", new[] { typeof(string) });
            if (getMethod == null)
            {
                throw new InvalidOperationException("UnityWebRequest.Get missing");
            }
            Debug.Log("[Valkyrie] Unity API smoke passed");
        }
    }
}
