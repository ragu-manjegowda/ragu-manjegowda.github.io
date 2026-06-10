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
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #fff;
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
  border: 1px solid rgba(0, 0, 0, 0.18);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.92);
  color: #333;
  cursor: pointer;
  font-size: 0.75rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.12);
}
.chart-fullscreen-button:hover,
.chart-fullscreen-button:focus {
  background: #fff;
  color: #111;
}
.chart-frame:fullscreen,
.chart-frame:-webkit-full-screen {
  width: 100vw;
  height: 100vh;
  padding: 1rem;
  background: #fff;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
}
.chart-frame:fullscreen .chart-container,
.chart-frame:-webkit-full-screen .chart-container {
  flex: 1;
  height: auto;
  min-height: 0;
  max-height: none;
  border: none;
  border-radius: 0;
}
.chart-frame:fullscreen iframe,
.chart-frame:-webkit-full-screen iframe {
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

function updateChartFullscreenButtons() {
  var activeElement = activeFullscreenElement();

  document.querySelectorAll('.chart-fullscreen-button').forEach(function(button) {
    var frame = button.closest('.chart-frame');
    button.textContent = activeElement === frame ? 'Exit full screen' : 'Full screen';
  });
}

document.querySelectorAll('.chart-fullscreen-button').forEach(function(button) {
  button.addEventListener('click', function() {
    var frame = button.closest('.chart-frame');
    var iframe = frame.querySelector('iframe');

    if (activeFullscreenElement() === frame) {
      if (document.exitFullscreen) {
        document.exitFullscreen();
        return;
      }

      if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
        return;
      }
    }

    if (frame.requestFullscreen) {
      frame.requestFullscreen();
      return;
    }

    if (frame.webkitRequestFullscreen) {
      frame.webkitRequestFullscreen();
      return;
    }

    window.open(iframe.src, '_blank', 'noopener');
  });
});

document.addEventListener('fullscreenchange', updateChartFullscreenButtons);
document.addEventListener('webkitfullscreenchange', updateChartFullscreenButtons);
</script>
