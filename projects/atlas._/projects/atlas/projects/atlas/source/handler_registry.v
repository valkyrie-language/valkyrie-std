# Atlas Handler 注册表 — dispatch 委托编译期生成的 atlas_invoke_handler

namespace atlas.core;

using std.text;
using atlas.http;
using atlas.wire;

class AtlasHandlerRegistry {
    ids: [utf8]
}

imply AtlasHandlerRegistry {
    micro new(): Self {
        return Self { ids: [] }
    }

    micro register(mut self, handler_id: utf8): unit {
        if self.contains(handler_id) {
            return
        }
        push(self.ids, handler_id)
    }

    micro contains(self, handler_id: utf8): bool {
        let mut i: i32 = 0
        while i < self.ids.length {
            if self.ids[i].equals(handler_id) {
                return true
            }
            i = i + 1
        }
        return false
    }

    micro invoke(self, handler_id: utf8, ctx: AtlasRouteContext, container: AtlasWireContainer): AtlasResult {
        return atlas_invoke_handler(handler_id, ctx, container)
    }
}
