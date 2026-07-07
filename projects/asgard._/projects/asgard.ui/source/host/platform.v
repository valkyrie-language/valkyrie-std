# Platform UiHost trait (Compose / SwiftUI / WinUI / Linux native providers)

namespace asgard.ui.host;

using asgard.ui.ir;

trait UiHost {
    micro mount(mut self, component: UiComponent): unit
    micro patch(mut self, key: utf8, value: utf8): unit
    micro on_event(mut self, name: utf8): unit
}
