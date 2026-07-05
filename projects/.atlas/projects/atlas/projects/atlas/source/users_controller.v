# Users API 示例

namespace atlas.core;

using std.text;
using atlas.wire;
using atlas.systems;

class UsersController {
    _pad: i32
}

imply UsersController {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro wire(container: AtlasWireContainer): Self {
        let _c: AtlasWireContainer = container
        return Self { _pad: 0 }
    }

    micro get_users(self): AtlasResult {
        let _self: UsersController = self
        return AtlasResult::ok_json("users-list")
    }
}
