# Azure adaptor — 应用 composition root

namespace atlas.adaptor.azure;

using atlas;
using atlas.core;

micro build_host(): AtlasHost {
    let mut host: AtlasHost = builder()
    host = host.get_route("/api/health", "health")
    host = host.get_route("/api/users", "users")
    host = host.build()
    return host
}
