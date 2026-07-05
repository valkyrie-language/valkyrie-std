# HealthController — 健康检查（live / ready）

namespace atlas.core;

using std.text;
using atlas.wire;
using atlas.systems;

class HealthController {
    system_name: utf8
}

imply HealthController {
    micro new(system_name: utf8): Self {
        return Self { system_name: system_name }
    }

    micro wire(container: AtlasWireContainer): Self {
        let mut sys: AtlasSystem = AtlasSystem::new("Health")
        wire_system(sys, container)
        return Self { system_name: sys.system_name }
    }

    micro get_health(self): AtlasResult {
        let body: utf8 = "status-ok,system:".concat(self.system_name)
        return AtlasResult::ok_json(body)
    }

    micro get_live(self): AtlasResult {
        return AtlasResult::ok_json("alive")
    }

    micro get_ready(self): AtlasResult {
        return atlas_run_health_checks()
    }
}

micro atlas_run_health_checks(): AtlasResult {
    return AtlasResult::ok_json("ready")
}
