# Android UiHost: load Asgard UI wire from classes.dex product tail

namespace asgard.ui.android;

using asgard.ui.host;
using asgard.ui.wire;
using asgard.ui.ir;
using asgard.ui.runtime;

class AndroidUiHost {
    product: [u8]
    tree: ViewTreeState
}

micro android_host_from_product(product: [u8]): AndroidUiHost {
    return AndroidUiHost { product: product, tree: create_view_tree() }
}

micro android_load_ir(host: AndroidUiHost): [UiComponent] {
    let section: [u8] = find_asgard_ui_section(host.product)
    if section.length == 0 {
        return []
    }
    return decode_package(section)
}

micro android_mount_all(host: AndroidUiHost): AndroidUiHost {
    let components: [UiComponent] = android_load_ir(host)
    let mut next: AndroidUiHost = host
    loop component in components {
        next.tree = mount_component_tree(next.tree, component)
    }
    return next
}

imply AndroidUiHost: UiHost {
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
