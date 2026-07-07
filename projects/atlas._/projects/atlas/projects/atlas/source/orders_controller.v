# OrdersController — 订单 API 示例

namespace atlas.core;

using std.text;
using atlas.wire;
using atlas.systems;

class OrdersController {
    order_system: OrderSystem
}

imply OrdersController {
    micro new(): Self {
        return Self {
            order_system: OrderSystem::new("OrderSystem")
        }
    }

    micro wire(container: AtlasWireContainer): Self {
        let mut sys: OrderSystem = OrderSystem::new("OrderSystem")
        sys = sys.wire_from(container)
        return Self { order_system: sys }
    }

    micro get_orders(self): AtlasResult {
        if self.order_system.store.is_ready() == false {
            return AtlasResult::bad_request("store not wired")
        }
        let body: utf8 = "orders-from:".concat(self.order_system.store.name)
        return AtlasResult::ok_json(body)
    }
}
