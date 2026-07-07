(function (global) {
  'use strict';
  var domHandles = [null];
  var wasmExports = null;
  var componentFactories = new Map();

  function storeDomHandle(node) {
    var id = domHandles.length;
    domHandles.push(node);
    return id;
  }
  function getDomHandle(id) { return domHandles[id] || null; }
  function isLoaded() { return wasmExports !== null; }
  function callExport(name) {
    if (!wasmExports || typeof wasmExports[name] !== 'function') {
      throw new Error('WASM export not found: ' + name);
    }
    return wasmExports[name]();
  }
  function registerComponent(name, factory) { componentFactories.set(name, factory); }

  function mountIslands() {
    componentFactories.forEach(function (factory, name) {
      document.querySelectorAll('[data-component="' + name + '"]').forEach(function (host) {
        if (host.__voaMounted) return;
        var node = factory({});
        if (node && node.nodeType) host.appendChild(node);
        host.__voaMounted = true;
      });
    });
  }

  function loadScript(url) {
    return new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = url;
      s.onload = resolve;
      s.onerror = function () { reject(new Error('script load failed: ' + url)); };
      document.head.appendChild(s);
    });
  }

  var hostApi = { storeDomHandle: storeDomHandle, getDomHandle: getDomHandle };

  async function start(manifestUrl) {
    var manifest = await fetch(manifestUrl).then(function (r) { return r.json(); });
    if (manifest.wasm && manifest.wasm.length > 0) {
      var entry = manifest.wasm[0];
      try {
        var glue = await import(entry.glue);
        var imports = { __voa: hostApi, env: hostApi };
        if (typeof glue.instantiate === 'function') {
          var instance = await glue.instantiate(entry.url, imports);
          wasmExports = instance.exports;
        }
      } catch (e) {
        console.warn('WASM unavailable in preview, using static chart fallback:', e);
        mountPreviewChart();
        return manifest;
      }
    }
    if (manifest.components) {
      for (var i = 0; i < manifest.components.length; i++) {
        await loadScript(manifest.components[i].js);
      }
    }
    mountIslands();
    return manifest;
  }

  /** Preview-only: 无真实 WASM 时展示柱图结构（真实构建由 WASM 渲染 InteractiveColPlot） */
  function mountPreviewChart() {
    var host = document.querySelector('[data-component="chart-status"]');
    if (!host || host.__voaMounted) return;
    host.innerHTML = [
      '<div class="asgard-icol">',
      '  <h3 class="asgard-icol-title">Test Status</h3>',
      '  <div class="asgard-icol-plot">',
      '    <div class="asgard-icol-col"><button type="button" class="asgard-icol-bar" style="height:100%;background:#22c55e"></button><span class="asgard-icol-xlabel">pass</span></div>',
      '    <div class="asgard-icol-col"><button type="button" class="asgard-icol-bar" style="height:50%;background:#ef4444"></button><span class="asgard-icol-xlabel">fail</span></div>',
      '    <div class="asgard-icol-col"><button type="button" class="asgard-icol-bar" style="height:4%;background:#f97316"></button><span class="asgard-icol-xlabel">skip</span></div>',
      '  </div>',
      '  <p style="font-size:12px;color:#888;margin:8px 0 0">preview fallback — real dist uses legion-test.wasm + legion-test.mjs</p>',
      '</div>'
    ].join('');
    host.__voaMounted = true;
  }

  global.__voa = {
    storeDomHandle: storeDomHandle,
    getDomHandle: getDomHandle,
    isLoaded: isLoaded,
    callExport: callExport,
    registerComponent: registerComponent,
    mountIslands: mountIslands,
    start: start
  };

  start('manifest.json').catch(function (e) { console.error('voa start failed:', e); });
})(globalThis);
