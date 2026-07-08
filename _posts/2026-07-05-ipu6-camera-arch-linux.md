---
title: "Intel IPU6 Camera on Arch Linux: Current Setup After Kernel 6.18.3"
tags: [arch-linux, linux, ipu6, webcam, libcamera, pipewire, gstreamer, v4l2loopback]
categories: blog
background-image: ipu6.png
excerpt: "The current Arch Linux setup I use for Intel IPU6 webcams now that the kernel driver is upstream: libcamera, GStreamer, and v4l2loopback, with notes on the older HAL workaround."
---

Intel IPU6 webcams have been one of those laptop Linux problems that always felt almost solved. The device would show up somewhere in `dmesg`, maybe expose a pile of `/dev/video*` nodes, and still fail in the applications that actually matter: browsers, video calls, OBS, Zoom, and Meet.

The situation changed once the IPU6 driver started landing upstream. Before kernel 6.10, most working Arch setups relied on DKMS modules and Intel's proprietary camera HAL stack. Around kernel 6.10, the kernel side started improving, but userspace was still rough. As of July 2026, on kernels newer than 6.18.3, the practical setup is simpler: use the in-tree IPU6 driver, let `libcamera` talk to it, and bridge the stream into a normal V4L2 device when applications still do not understand libcamera/PipeWire correctly.

The Arch forum thread I followed, [How to use the IPU6 webcam with kernel 6.10+?](https://bbs.archlinux.org/viewtopic.php?id=297262), is worth reading because it captures the transition from old DKMS/HAL workarounds to the current upstream-driver workflow. The thread started in 2024 and was still active through 2026, with working reports on kernel `6.18.4-arch1-1` and later.

This post documents the current setup I would use first on Arch today.

---

## What Changed

Older IPU6 setups usually needed packages like:

```text
intel-ipu6-dkms-git
intel-ipu6-camera-bin
intel-ipu6-camera-hal-git
icamerasrc-git
v4l2-relayd
```

That route used Intel's proprietary HAL and `icamerasrc`. I still keep notes for that path because it was useful before the upstream driver matured, but it is no longer the first thing I would try on a current kernel.

For kernel versions above `6.18.3`, start with the upstream stack:

```text
kernel IPU6 driver -> libcamera -> GStreamer -> v4l2loopback -> browser/app
```

This is also the direction reflected in the later Arch forum posts: users report working cameras through `libcamera`, `gst-plugin-libcamera`, and `v4l2loopback`, without the old Intel HAL packages.

---

## Install Packages

Install the core packages:

```bash
sudo pacman -S \
  libcamera \
  libcamera-ipa \
  libcamera-tools \
  gst-plugin-libcamera \
  gstreamer \
  gst-plugins-base \
  gst-plugins-good \
  pipewire-libcamera \
  pipewire-v4l2 \
  v4l2loopback-dkms \
  v4l2loopback-utils \
  v4l-utils
```

Optional, but useful for testing the loopback device:

```bash
sudo pacman -S ffmpeg
```

`ffplay` comes from `ffmpeg`.

---

## Verify the Kernel Sees IPU6

First check the kernel side:

```bash
dmesg | grep -i ipu6
```

Good signs look like this:

```text
intel-ipu6 0000:00:05.0: Found supported sensor INT3537:00
intel-ipu6 0000:00:05.0: Connected 1 cameras
```

The exact sensor name varies. Examples from the Arch thread include:

```text
INT3537 -> hi556
OVTI02C1 -> ov02c10
OV2740
OVTI08F4 -> ov08x40
```

Then check libcamera:

```bash
cam -l
```

If libcamera is happy, you should see something like:

```text
Available cameras:
1: 'hi556' (_SB_.PC00.LNK1)
```

If `cam -l` shows nothing, the bridge below will not help yet. That means the problem is still at the kernel, firmware, sensor, or libcamera level.

---

## Create a V4L2 Loopback Device

Most desktop applications still understand a normal V4L2 webcam better than they understand raw IPU6/libcamera devices. Create a stable loopback camera:

```bash
sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null <<'EOF'
options v4l2loopback video_nr=60 card_label="IPU6 Loopback" exclusive_caps=1
EOF
```

Load it now:

```bash
sudo modprobe v4l2loopback
```

Confirm it exists:

```bash
v4l2-ctl --list-devices
```

You should see a device like:

```text
IPU6 Loopback
    /dev/video60
```

---

## Bridge libcamera into V4L2

Start with a direct GStreamer bridge. Keep this command running; it does not open a preview window by itself. It reads from `libcamera` and writes frames into the loopback device:

```bash
gst-launch-1.0 \
  libcamerasrc ! \
  queue ! \
  videoconvert ! \
  video/x-raw,format=YUY2 ! \
  v4l2sink device=/dev/video60 sync=false
```

In a second terminal, show the loopback stream:

```bash
ffplay /dev/video60
```

If `ffplay` opens a live camera preview, the bridge is working.

If you only want to check whether `libcamera` can display frames before involving `v4l2loopback`, test a direct preview first:

```bash
gst-launch-1.0 libcamerasrc ! videoconvert ! autovideosink
```

That direct preview proves the sensor/libcamera path works. The `ffplay /dev/video60` test proves the application-facing V4L2 loopback path works.

For some sensors, forcing resolution can produce a blank or white image. If that happens, do not force width/height at first. Let libcamera choose the mode.

If the stream flickers or drops buffers, try a lower frame rate and a leaky queue:

```bash
gst-launch-1.0 \
  libcamerasrc ! \
  video/x-raw,framerate=15/1 ! \
  queue leaky=downstream max-size-buffers=2 ! \
  videoconvert ! \
  video/x-raw,format=NV12,framerate=15/1 ! \
  v4l2sink device=/dev/video60 sync=false
```

The later Arch forum updates report this kind of pipeline as the practical solution for making the camera usable in browsers and meeting software.

---

## Run the Bridge as a User Service

Once the command works, make it a user service:

```bash
mkdir -p ~/.config/systemd/user
```

Create `~/.config/systemd/user/ipu6-camera-bridge.service`:

```ini
[Unit]
Description=Bridge IPU6 libcamera stream to v4l2loopback
After=graphical-session.target pipewire.service wireplumber.service

[Service]
ExecStart=/usr/bin/gst-launch-1.0 libcamerasrc ! queue ! videoconvert ! video/x-raw,format=YUY2 ! v4l2sink device=/dev/video60 sync=false
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

Enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ipu6-camera-bridge.service
```

Check logs:

```bash
systemctl --user status ipu6-camera-bridge.service
journalctl --user -u ipu6-camera-bridge.service -f
```

If your working pipeline needs the 15 fps version, put that command in `ExecStart` instead.

---

## Browser Notes

Chromium-based browsers usually see the loopback device once the bridge is running.

Firefox may need PipeWire camera support enabled:

```text
about:config -> media.webrtc.camera.allow-pipewire -> true
```

If Firefox shows dozens of raw `ipu6` entries instead of one usable camera, that setting is the first thing to check.

OBS is also a good test application because it directly lists V4L2 devices.

---

## Tuning Files and Image Quality

Getting frames is only half the story. The image may be green, washed out, too dark, or flickery. That usually means libcamera is falling back to weak or missing tuning data for your sensor.

The forum thread has working examples for sensors such as `ov2740` and `hi556`. For example, some users improved flicker by disabling AGC in a libcamera simple-pipeline tuning file:

```yaml
# /usr/share/libcamera/ipa/simple/ov2740.yaml
%YAML 1.1
---
version: 1
algorithms:
  - BlackLevel:
  - Awb:
#  - Agc:
  - Adjust:
```

Other users experimented with CCM matrices to reduce green tint. This is sensor-specific; do not blindly copy a CCM from another laptop and expect perfect color.

Keep a backup of any tuning file you edit because package updates can overwrite files under `/usr/share/libcamera`.

---

## What About the Old HAL Path?

My copied setup notes used Intel's proprietary HAL path:

```bash
paru -S intel-ipu6-dkms-git intel-ipu6-camera-bin intel-ipu6-camera-hal-git icamerasrc-git v4l2-relayd
```

That setup required `icamerasrc`, `v4l2loopback`, `v4l2-relayd`, and sometimes manual fixes like loading PSYS:

```bash
sudo modprobe intel_ipu6_psys
```

It also involved patching AUR builds when `intel-ipu6-camera-hal-git` failed on `-Werror`, and working around missing unversioned linker names for Intel binary libraries.

That path is still useful if your specific sensor is not usable through the upstream/libcamera route. But on current kernels, I would treat it as a fallback, not the default.

---

## Current Checklist

For kernel versions newer than `6.18.3`, my current Arch checklist is:

1. Install `libcamera`, `gst-plugin-libcamera`, `pipewire-libcamera`, and `v4l2loopback-dkms`.
2. Confirm `dmesg` shows a supported IPU6 sensor.
3. Confirm `cam -l` lists a camera.
4. Create `/dev/video60` with `v4l2loopback`.
5. Bridge `libcamerasrc` into `/dev/video60` with GStreamer.
6. Test with `ffplay` or OBS.
7. Use Chromium, Firefox with PipeWire camera support, or any app that can see the loopback device.
8. Add a user service once the pipeline works.
9. Tune libcamera only if the image quality is bad.

---

## References

- [Arch Linux forum: How to use the IPU6 webcam with kernel 6.10+?](https://bbs.archlinux.org/viewtopic.php?id=297262)
- [Arch Linux forum page 8: 2026 working reports and GStreamer/v4l2loopback examples](https://bbs.archlinux.org/viewtopic.php?id=297262&p=8)
