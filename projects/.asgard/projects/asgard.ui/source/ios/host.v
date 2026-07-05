# iOS UiHost: load Asgard UI wire from Mach-O and drive SwiftUI

namespace asgard.ui.ios;

using asgard.ui.host;
using asgard.ui.wire;
using asgard.ui.ir;
using asgard.ui.runtime;

class IosUiHost {
    executable: [u8]
    tree: ViewTreeState
}

micro ios_host_from_executable(exe: [u8]): IosUiHost {
    return IosUiHost { executable: exe, tree: create_view_tree() }
}

micro ios_load_ir(host: IosUiHost): [UiComponent] {
    let section: [u8] = find_asgard_ui_section(host.executable)
    if section.length == 0 {
        return []
    }
    return decode_package(section)
}

micro ios_mount_all(host: IosUiHost): IosUiHost {
    let components: [UiComponent] = ios_load_ir(host)
    let mut next: IosUiHost = host
    loop component in components {
        next.tree = mount_component_tree(next.tree, component)
    }
    return next
}

imply IosUiHost: UiHost {
    micro mount(mut self, component: UiComponent): unit {
        let _summary: utf8 = component_summary(component)
    }

    micro patch(mut self, key: utf8, value: utf8): unit {
        let _k: utf8 = key
        let _v: utf8 = value
    }

    micro on_event(mut self, name: utf8): unit {
        let _n: utf8 = name
    }
}
