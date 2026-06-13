---
title: "LETF Trades"
tags: [trading, tqqq, tecl, letf]
categories: blog
background-image: stocks.jpg
excerpt: "My leveraged ETF trades, updated daily."
---

<style>
.chart-frame {
  margin-bottom: 1rem;
}
.chart-controls {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.5rem;
}
.chart-container {
  position: relative;
  width: 100%;
  min-height: 400px;
  height: 70vh;
  max-height: 700px;
  overflow: hidden;
  border: 1px solid var(--theme-border-strong);
  border-radius: 8px;
  background: var(--theme-code-bg);
}
.chart-container iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: none;
}
.chart-fullscreen-button {
  padding: 0 0.85rem;
  height: 2.25rem;
  line-height: 2.25rem;
  border: 1px solid var(--theme-border-strong);
  border-radius: 999px;
  background: var(--theme-group-title-bg);
  color: var(--theme-fg-bold);
  cursor: pointer;
  font-size: 0.75rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.12);
}
.chart-fullscreen-button:hover,
.chart-fullscreen-button:focus {
  background: var(--theme-accent);
  color: var(--theme-bg);
}
.chart-fullscreen-shell {
  position: fixed;
  inset: 0;
  width: 100vw;
  height: 100vh;
  background: var(--theme-group-bg);
  display: none;
  overflow: hidden;
  z-index: 10000;
}
.chart-fullscreen-shell.is-active {
  display: block;
}
.chart-fullscreen-shell:fullscreen,
.chart-fullscreen-shell:-webkit-full-screen {
  position: fixed;
  inset: 0;
  width: 100vw;
  height: 100vh;
  background: var(--theme-group-bg);
  overflow: hidden;
}
.chart-fullscreen-shell .chart-controls {
  position: absolute;
  bottom: 1rem;
  right: 1rem;
  z-index: 2;
}
.chart-fullscreen-shell iframe {
  display: block;
  width: 100vw;
  height: 100vh;
  border: none;
  min-width: 0;
}
@media (max-width: 768px) {
  .chart-container {
    min-height: 350px;
    height: 60vh;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }
  .chart-container iframe {
    min-width: 600px;
  }
}
</style>

These are the trades I have backtested and executed so far on leveraged ETFs.

I am intentionally leaving this post unexplained—I don't have enough real-world data yet to prove this approach is significantly profitable. I'd rather not mislead anyone who stumbles upon this.

---

## TQQQ

<div class="chart-frame">
  <div class="chart-controls">
    <button class="chart-fullscreen-button" type="button">Full screen</button>
  </div>
  <div class="chart-container">
    <iframe src="/assets/charts/tqqq_ema_chart.html" title="TQQQ EMA chart" allowfullscreen></iframe>
  </div>
</div>

---

## TECL

<div class="chart-frame">
  <div class="chart-controls">
    <button class="chart-fullscreen-button" type="button">Full screen</button>
  </div>
  <div class="chart-container">
    <iframe src="/assets/charts/tecl_ema_chart.html" title="TECL EMA chart" allowfullscreen></iframe>
  </div>
</div>

---

## TECL from TQQQ Signals

<div class="chart-frame">
  <div class="chart-controls">
    <button class="chart-fullscreen-button" type="button">Full screen</button>
  </div>
  <div class="chart-container">
    <iframe src="/assets/charts/tecl_from_tqqq_ema_chart.html" title="TECL from TQQQ signals chart" allowfullscreen></iframe>
  </div>
</div>

---

*Charts updated daily after market close.*

<script>
function activeFullscreenElement() {
  return document.fullscreenElement || document.webkitFullscreenElement;
}

var activeChartFullscreen = null;

function chartFullscreenShell() {
  var shell = document.querySelector('.chart-fullscreen-shell');
  if (shell) return shell;

  shell = document.createElement('div');
  shell.className = 'chart-fullscreen-shell';
  shell.innerHTML = '<div class="chart-controls"><button class="chart-fullscreen-button" type="button">Exit full screen</button></div>';
  shell.querySelector('button').addEventListener('click', exitChartFullscreen);
  document.body.appendChild(shell);
  return shell;
}

function updateChartFullscreenButtons() {
  document.querySelectorAll('.chart-fullscreen-button').forEach(function(button) {
    var frame = button.closest('.chart-frame');
    if (frame) button.textContent = activeChartFullscreen && activeChartFullscreen.frame === frame ? 'Exit full screen' : 'Full screen';
  });
}

function resizeChartFrame(frame) {
  var iframe = activeChartFullscreen && activeChartFullscreen.frame === frame ? activeChartFullscreen.iframe : frame.querySelector('iframe');
  if (!iframe) return;

  var graph;
  try {
    if (!iframe.contentWindow || !iframe.contentDocument) return;
    graph = iframe.contentDocument.querySelector('.plotly-graph-div');
  } catch (error) {
    return;
  }
  if (!graph) return;

  graph.style.width = '100%';
  graph.style.height = Math.max(iframe.clientHeight, 320) + 'px';

  if (iframe.contentWindow.Plotly && iframe.contentWindow.Plotly.Plots) {
    iframe.contentWindow.Plotly.Plots.resize(graph);
  }
}

function resizeChartFrames() {
  var frames = activeChartFullscreen ? [activeChartFullscreen.frame] : document.querySelectorAll('.chart-frame');

  Array.prototype.forEach.call(frames, function(frame) {
    resizeChartFrame(frame);
    setTimeout(function() {
      resizeChartFrame(frame);
    }, 250);
  });
}

function restoreChartFullscreen() {
  if (!activeChartFullscreen) return;

  var active = activeChartFullscreen;
  var container = active.frame.querySelector('.chart-container');
  if (active.placeholder.parentNode) {
    active.placeholder.parentNode.replaceChild(active.iframe, active.placeholder);
  } else if (container) {
    container.appendChild(active.iframe);
  }

  active.shell.classList.remove('is-active');
  activeChartFullscreen = null;
  updateChartFullscreenButtons();
  resizeChartFrames();
}

function exitChartFullscreen() {
  if (activeFullscreenElement()) {
    if (document.exitFullscreen) {
      document.exitFullscreen();
      return;
    }

    if (document.webkitExitFullscreen) {
      document.webkitExitFullscreen();
      return;
    }
  }

  restoreChartFullscreen();
}

function enterChartFullscreen(frame) {
  if (activeChartFullscreen && activeChartFullscreen.frame === frame) {
    exitChartFullscreen();
    return;
  }

  if (activeChartFullscreen) restoreChartFullscreen();

  var iframe = frame.querySelector('iframe');
  if (!iframe) return;

  var shell = chartFullscreenShell();
  var placeholder = document.createComment('chart fullscreen placeholder');
  iframe.parentNode.insertBefore(placeholder, iframe);
  shell.appendChild(iframe);
  shell.classList.add('is-active');

  activeChartFullscreen = {
    frame: frame,
    iframe: iframe,
    placeholder: placeholder,
    shell: shell
  };

  updateChartFullscreenButtons();
  resizeChartFrames();

  var requestFullscreen = shell.requestFullscreen || shell.webkitRequestFullscreen;
  if (!requestFullscreen) {
    restoreChartFullscreen();
    return;
  }

  try {
    var result = requestFullscreen.call(shell);
    if (result && result.catch) {
      result.catch(restoreChartFullscreen);
    }
  } catch (error) {
    restoreChartFullscreen();
  }
}

document.querySelectorAll('.chart-fullscreen-button').forEach(function(button) {
  button.addEventListener('click', function() {
    var frame = button.closest('.chart-frame');
    enterChartFullscreen(frame);
  });
});

document.querySelectorAll('.chart-frame iframe').forEach(function(iframe) {
  iframe.addEventListener('load', resizeChartFrames);
});

window.addEventListener('resize', resizeChartFrames);
document.addEventListener('fullscreenchange', function() {
  if (activeChartFullscreen && !activeFullscreenElement()) restoreChartFullscreen();
  else resizeChartFrames();
});
document.addEventListener('webkitfullscreenchange', function() {
  if (activeChartFullscreen && !activeFullscreenElement()) restoreChartFullscreen();
  else resizeChartFrames();
});
resizeChartFrames();
</script>
