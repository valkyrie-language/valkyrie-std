# Linux desktop UiHost

namespace asgard.ui.linux;

using asgard.ui.host;
using asgard.ui.wire;
using asgard.ui.ir;
using asgard.ui.runtime;

class LinuxUiHost {
    executable: [u8]
    tree: ViewTreeState
}

micro linux_host_from_executable(exe: [u8]): LinuxUiHost {
    return LinuxUiHost { executable: exe, tree: create_view_tree() }
}

micro linux_load_ir(host: LinuxUiHost): [UiComponent] {
    let section: [u8] = find_asgard_ui_section(host.executable)
    if section.length == 0 {
        return []
    }
    return decode_package(section)
}

imply LinuxUiHost: UiHost {
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
