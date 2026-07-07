# Atlas 内置中间件

namespace atlas.core;

using std.text;
using atlas.http;
using atlas.systems;

micro exception_middleware_step(
    middleware: AtlasMiddleware,
    mut ctx: AtlasRouteContext,
    next_index: i32,
    mut pipeline: MiddlewarePipeline,
    mut host: AtlasHost
): unit {
    let _mw: AtlasMiddleware = middleware
    pipeline.execute_at(next_index, ctx, host)
    if ctx.response.status_code >= 500 {
        let result: AtlasResult = AtlasResult::internal_error()
        result.apply_to(ctx)
    }
}

micro request_log_middleware_step(
    middleware: AtlasMiddleware,
    mut ctx: AtlasRouteContext,
    next_index: i32,
    mut pipeline: MiddlewarePipeline,
    mut host: AtlasHost
): unit {
    let _mw: AtlasMiddleware = middleware
    let logger: ConsoleAtlasSystemLogger = ConsoleAtlasSystemLogger::new("atlas")
    logger.log("request", ctx.request.method.concat(" ").concat(ctx.request.path))
    pipeline.execute_at(next_index, ctx, host)
}

micro response_log_middleware_step(
    middleware: AtlasMiddleware,
    mut ctx: AtlasRouteContext,
    next_index: i32,
    mut pipeline: MiddlewarePipeline,
    mut host: AtlasHost
): unit {
    let _mw: AtlasMiddleware = middleware
    pipeline.execute_at(next_index, ctx, host)
    let logger: ConsoleAtlasSystemLogger = ConsoleAtlasSystemLogger::new("atlas")
    logger.log("response", "completed")
}
