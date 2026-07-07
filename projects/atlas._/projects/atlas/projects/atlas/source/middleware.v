# Atlas 中间件管线

namespace atlas.core;

using std.text;
using atlas.http;

class AtlasMiddleware {
    name: utf8
    priority: i32
}

class MiddlewarePipeline {
    middlewares: [AtlasMiddleware]
}

imply AtlasMiddleware {
    micro new(name: utf8, priority: i32): Self {
        return Self { name: name, priority: priority }
    }
}

imply MiddlewarePipeline {
    micro new(): Self {
        return Self { middlewares: [] }
    }

    micro add(mut self, middleware: AtlasMiddleware): unit {
        push(self.middlewares, middleware)
        self.middlewares = sort_by_priority(self.middlewares)
    }

    micro names(self): [utf8] {
        let mut out: [utf8] = []
        let mut i: i32 = 0
        while i < self.middlewares.length {
            push(out, self.middlewares[i].name)
            i = i + 1
        }
        return out
    }

    micro execute(mut self, mut ctx: AtlasRouteContext, mut host: AtlasHost): unit {
        self.execute_at(0, ctx, host)
    }

    micro execute_at(mut self, index: i32, mut ctx: AtlasRouteContext, mut host: AtlasHost): unit {
        if ctx.short_circuit {
            return
        }
        if index >= self.middlewares.length {
            host.run_terminal(ctx)
            return
        }
        let mw: AtlasMiddleware = self.middlewares[index]
        let next_index: i32 = index + 1
        atlas_invoke_middleware(mw.name, mw, ctx, next_index, self, host)
    }
}

micro sort_by_priority(items: [AtlasMiddleware]): [AtlasMiddleware] {
    let mut out: [AtlasMiddleware] = []
    let mut i: i32 = 0
    while i < items.length {
        push(out, items[i])
        i = i + 1
    }

    let mut a: i32 = 1
    while a < out.length {
        let mut b: i32 = a
        while b > 0 {
            if out[b].priority < out[b - 1].priority {
                let swap: AtlasMiddleware = out[b]
                out[b] = out[b - 1]
                out[b - 1] = swap
                b = b - 1
            } else {
                break
            }
        }
        a = a + 1
    }
    return out
}
