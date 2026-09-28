---
title: "A VPN That Only the Right Apps Use: Network Namespaces for Opt-In Access"
tags: [linux, vpn, network-namespaces, ssh, awesomewm, networking, workflow]
categories: blog
background-image: vpn-namespace-panel-tooltip.png
excerpt: "How I keep my everyday connection outside the VPN, opt SSH and a browser into an isolated network namespace, and switch to host-wide routing only when a task needs it."
---

For a long time, connecting to a work VPN meant changing the network for my entire laptop. That is convenient when everything needs the same private network, but it is a poor fit for a day when only one SSH session or one browser window needs it. My personal browsing, downloads, and other applications do not need to follow an internal route just because I am working on a remote machine.

The useful mental shift was to stop treating **VPN connected** and **this application uses the VPN** as the same statement. On Linux, a network namespace lets me separate those two things. The VPN can be up inside its own network environment while the rest of the desktop keeps its ordinary connection. I opt specific traffic into that environment, and switch to a host-wide connection when the work genuinely spans many processes.

## Two Routing Modes, One Intentional Choice

My default is an **isolated connection**. The VPN client and its tunnel live in a dedicated network namespace. The host retains its physical default route, so launching an ordinary application does not automatically put it on the VPN.

I use a **host-wide connection** for tasks whose network activity is scattered across tools or child processes: cloning a work repository, authenticating a build, or using remote execution in a build system. Trying to wrap every subprocess individually would make those workflows fragile. In host-wide mode, the VPN can update the host's routes and DNS as usual; the VPN's own routing policy still determines which destinations actually use the tunnel. Switching modes tears down the previous connection first, rather than leaving two competing VPN states active.

| Task | Connection choice | Why |
| --- | --- | --- |
| Remote SSH session | Isolated | Only the SSH connection needs the private route. |
| Occasional internal site | Isolated browser | Only that browser process needs the private route. |
| Repository access, build authentication, remote execution | Host-wide | Multiple independent processes may need the VPN. |
| Everyday browsing | Ordinary host network | No reason to opt in. |

The important distinction is **where the network operation happens**, not which window happens to be open on the desktop.

## What the Namespace Actually Separates

A Linux network namespace has its own interfaces, routes, and network view. The VPN service starts inside it, so the tunnel interface and any default route the client installs belong to that namespace instead of the host. A small virtual Ethernet link gives the namespace a path to the internet for the initial VPN connection. The host forwards and translates that traffic through its physical connection, with firewall rules narrow enough to allow the namespace's outbound packets and replies. Those resources are removed when the isolated connection stops.

Routing isolation alone is not enough. Some VPN clients also try to change DNS through the host's resolver, NetworkManager, or system bus. If those host services remain reachable, the tunnel may be isolated while the host's name resolution is not. In this design, the VPN service gets a private view of resolver configuration and cannot modify the host's DNS services. Applications running inside the namespace must also receive usable DNS settings for both the VPN gateway and internal names.

This is why a working setup needs a lifecycle, not just a one-line `ip netns exec` command: create the namespace and its uplink, start the VPN service there, keep its DNS changes there, and undo the forwarding and temporary state on disconnect. A system service can join an existing namespace with `NetworkNamespacePath`, while its own mount and service isolation keep host configuration from leaking across the boundary.

## SSH: Put the Socket on the VPN, Not the Whole Workflow

For SSH, I want the normal terminal, keys, agent, and host aliases to stay where they are. Only the TCP connection to the remote machine needs to originate from the VPN namespace. A small connection helper opens that socket inside the namespace; SSH uses it as its transport while still reading its usual configuration and credentials on the host. The wrapper can start the isolated VPN if it is not connected yet, then wait for the tunnel to be ready before invoking SSH.

This also requires thinking about SSH connection sharing. An existing multiplexed control socket may reuse a connection established outside the namespace, bypassing the new transport entirely. For a VPN-bound invocation, I disable multiplexing for that invocation rather than asking everyone to rearrange their global SSH configuration.

I keep the *decision* about which hosts need this behavior explicit. An ordinary SSH alias might carry a simple, generic marker:

```sshconfig
Host work-machine
    HostName remote.example.invalid
    Tag vpn-required
```

In an interactive zsh shell, my `ssh` function asks OpenSSH for the effective configuration of the requested host. If the resolved configuration has the VPN tag, it delegates to the VPN-aware SSH wrapper; otherwise it runs regular SSH. It also avoids taking over connections that already have a proxy or jump host, and avoids redirecting local addresses. An address being outside the local network is **not** a useful VPN signal: public Git hosts are remote too. The tag expresses intent; the wrapper handles routing.

That shell function is a convenience for interactive use, not a system-wide replacement for SSH. Scripts and applications that call the SSH executable directly should invoke the VPN-aware wrapper explicitly when they need it. Likewise, a generic implementation should test how its SSH version exposes the effective tag before relying on it.

## A Browser Must Start on the Right Side of the Boundary

The same opt-in principle applies to browsing. Starting the VPN does not move an already-running browser into the namespace. My ordinary browsers remain on the host connection; a dedicated launcher starts the chosen browser inside the namespace when I need internal sites. The authentication browser used to sign in to the VPN can remain on the host as well: completing authentication does not imply that all subsequent browsing uses the tunnel.

There is a subtle trap with browsers that reuse an existing profile process. Opening a second window with the same profile may forward the request to a browser already running on the host. The new window then looks like a VPN window but still uses the host network. To reuse an existing profile safely, close its host-side browser process before launching it in the namespace, or refuse the launch and explain why. A launcher should also detach cleanly so opening a VPN browser does not occupy the terminal until the browser exits.

## Make the State Visible

My AwesomeWM top panel has a small VPN icon. I find it useful to distinguish three states at a glance: **disconnected**, **namespace connected**, and **host-wide connected**. A small **N** on the connected icon indicates the namespace mode. Without that extra cue, a single “VPN on” light could mislead me into thinking all applications are routed through it—or that none of them are.

![AwesomeWM top panel showing the N-marked VPN icon and a tooltip reading “VPN connected (namespace: opt-in SSH/browser)”.]({{ '/images/vpn-namespace-panel-tooltip.png' | relative_url }})

*The live panel indicator and its tooltip make the opt-in routing mode explicit.*

The indicator should reflect the actual service and tunnel state, not merely the last button pressed. A connection request can fail, or briefly appear successful before the tunnel settles. For the same reason, I verify the separation from both sides: the host route should remain on the physical network in isolated mode, the tunnel should exist inside the namespace, and a VPN-launched process should actually be in that namespace. A public-IP check in each browser is a useful extra observation, but routing policy may send some destinations directly even when the VPN is active.

## A Pattern Worth Reusing

The implementation details depend on the VPN client and the distribution, but the design is portable: give the VPN its own network and DNS context, make entry into that context an explicit application-level decision, and offer a separate host-wide mode for workflows that cannot be contained to one application. Package the namespace lifecycle, narrowly scoped privileged helper, and status reporting together so using it does not require a collection of manual firewall and SSH edits.

For me, the result is a calmer default. I can work on a remote machine or open an internal page without silently changing the network for everything else. When a build or repository workflow needs broad access, I make that switch deliberately—and the panel tells me which world I am in.
