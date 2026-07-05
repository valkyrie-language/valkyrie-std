using System;
using System.IO;
using System.Reflection;

internal static class Program
{
    private static int Main(string[] args)
    {
        var unityRoot = args.Length > 0
            ? args[0]
            : @"E:\UnityEditor\6000.2.6f2\Editor\Data\Managed\UnityEngine";
        var checks = new (string Module, string Type, string Member)[]
        {
            ("UnityEngine.CoreModule.dll", "UnityEngine.Application", "get_dataPath"),
            ("UnityEngine.CoreModule.dll", "UnityEngine.Debug", "Log"),
            ("UnityEngine.UnityWebRequestModule.dll", "UnityEngine.Networking.UnityWebRequest", "Get"),
        };

        var passed = 0;
        foreach (var (module, typeName, member) in checks)
        {
            var path = Path.Combine(unityRoot, module);
            if (!File.Exists(path))
            {
                Console.WriteLine($"FAIL missing {path}");
                continue;
            }

            var asm = Assembly.LoadFrom(path);
            var type = asm.GetType(typeName, throwOnError: true);
            var flags = BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance;
            MemberInfo? resolved = null;
            if (member.StartsWith("get_", StringComparison.Ordinal))
            {
                resolved = type.GetProperty(member[4..], flags)?.GetGetMethod();
            }
            else if (member == "Log")
            {
                resolved = type.GetMethod("Log", flags, new[] { typeof(object) });
            }
            else if (member == "Get")
            {
                resolved = type.GetMethod("Get", flags, new[] { typeof(string) });
            }
            else
            {
                resolved = type.GetMethod(member, flags);
            }
            if (resolved == null)
            {
                Console.WriteLine($"FAIL {typeName}::{member}");
                continue;
            }

            Console.WriteLine($"OK   {typeName}::{member} [{module}]");
            passed++;
        }

        Console.WriteLine($"unity-api-smoke: {passed}/{checks.Length} passed");
        return passed == checks.Length ? 0 : 1;
    }
}
