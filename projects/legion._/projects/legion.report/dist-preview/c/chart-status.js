(function() {
  'use strict';

// AWSL 组件胶水：chart-status（逻辑在 WASM）
var RENDER_EXPORT = 'awsl_render_chart_status';

function factory() {
  var voa = globalThis.__voa;
  if (!voa || !voa.isLoaded()) {
    return document.createComment('voa:wasm-pending');
  }
  var handle = voa.callExport(RENDER_EXPORT);
  var node = voa.getDomHandle(handle);
  if (!node) {
    var el = document.createElement('div');
    el.setAttribute('data-voa-wasm-handle', String(handle));
    return el;
  }
  return node;
}

globalThis.__voa.registerComponent('chart-status', factory);
})();
