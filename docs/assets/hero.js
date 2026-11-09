// Hero: a paper diorama in three.js. Layers from the series art (back plane, reed and scrub cut-outs)
// sit at different depths; the camera follows the pointer so the paper planes slide past each other.
// Scrolling through the hero dollies the camera in while the reeds part and the scrub sinks (scroll position
// read once per frame, no scroll listener).
// Skipped (the poster image stays) under reduced motion, Save-Data, or without WebGL.
const stage = document.querySelector("[data-hero]");
const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
const saveData = navigator.connection && navigator.connection.saveData;

function hasWebGL() {
  try { return !!document.createElement("canvas").getContext("webgl2"); } catch { return false; }
}

if (stage && !reduce && !saveData && hasWebGL()) {
  start().catch((e) => console.warn("hero: poster only", e));
}

async function start() {
  const THREE = await import("./vendor/three.module.min.js");
  const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: "low-power" });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  stage.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color("#efe6d6");
  const camera = new THREE.PerspectiveCamera(30, 1, 0.1, 100);
  const CAM_Z = 12;
  const halfTan = Math.tan(THREE.MathUtils.degToRad(15));

  const loader = new THREE.TextureLoader();
  const load = (name) => new Promise((ok, fail) => loader.load(`assets/img/${name}.webp`, (t) => {
    t.colorSpace = THREE.SRGBColorSpace;
    t.anisotropy = 4;
    ok(t);
  }, undefined, fail));
  const [back, reedsL, reedsR, scrub] = await Promise.all(["hero-back", "reeds-left", "reeds-right", "scrub"].map(load));

  const plane = (tex, z, order) => {
    const m = new THREE.Mesh(
      new THREE.PlaneGeometry(1, 1),
      new THREE.MeshBasicMaterial({ map: tex, transparent: order > 0, alphaTest: order > 0 ? 0.02 : 0, depthWrite: order === 0 })
    );
    m.position.z = z;
    m.renderOrder = order;
    m.userData.aspect = tex.image.width / tex.image.height;
    scene.add(m);
    return m;
  };
  const backM = plane(back, 0, 0);
  const scrubM = plane(scrub, 2.2, 1);
  const reedLM = plane(reedsL, 3.4, 2);
  const reedRM = plane(reedsR, 3.9, 3);

  // Paper flecks drifting through the light
  const flecks = [];
  const colors = ["#c9a36a", "#7d7f4a", "#f4ede1", "#7a5a3c", "#9a8c7a"];
  const fleckGeo = new THREE.PlaneGeometry(1, 1);
  for (let i = 0; i < 34; i++) {
    const m = new THREE.Mesh(fleckGeo, new THREE.MeshBasicMaterial({
      color: colors[i % colors.length], transparent: true, opacity: 0.55 + Math.random() * 0.35, side: THREE.DoubleSide, depthWrite: false,
    }));
    m.renderOrder = 4;
    m.userData = { speed: 0.08 + Math.random() * 0.16, spin: (Math.random() - 0.5) * 0.6, wobble: Math.random() * Math.PI * 2 };
    scene.add(m);
    flecks.push(m);
  }

  // Frustum size at depth z (camera at rest)
  const view = (z) => {
    const h = 2 * (CAM_Z - z) * halfTan;
    return { w: h * camera.aspect, h };
  };
  let v0;
  function layout() {
    const w = stage.clientWidth, h = stage.clientHeight;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    v0 = view(0);

    // Back plane covers the view with room to move; keep Kai (right of centre) in frame on narrow screens
    const a = backM.userData.aspect;
    const bh = Math.max(v0.h, v0.w / a) * 1.14;
    backM.scale.set(bh * a, bh, 1);
    const slack = Math.max(0, (bh * a - v0.w) / 2 - 0.7); // keep 0.7 for the camera pan (max 0.55) so no edge shows
    backM.position.x = -THREE.MathUtils.clamp(0.14 * bh * a, -slack, slack);

    const place = (m, z, hFrac, x, yFrac) => {
      const vz = view(z);
      const ph = vz.h * hFrac;
      m.scale.set(ph * m.userData.aspect, ph, 1);
      m.position.set(x(vz, ph * m.userData.aspect), -vz.h / 2 + ph * yFrac, z);
      m.userData.base = m.position.clone();
    };
    const narrow = camera.aspect < 0.9;
    place(reedLM, 3.4, narrow ? 0.62 : 0.92, (vz, pw) => -vz.w / 2 + pw * 0.32, 0.42);
    place(reedRM, 3.9, narrow ? 0.55 : 0.85, (vz, pw) => vz.w / 2 - pw * 0.3, 0.4);
    place(scrubM, 2.2, narrow ? 0.22 : 0.3, (vz) => -vz.w * 0.12, 0.38);

    flecks.forEach((m) => resetFleck(m, true));
  }
  function resetFleck(m, anywhere) {
    const z = 1 + Math.random() * 5;
    const vz = view(z);
    const s = 0.018 + Math.random() * 0.04;
    m.scale.set(s * (1.4 + Math.random()), s, 1);
    m.position.set(
      (Math.random() - 0.5) * vz.w * 1.1,
      anywhere ? (Math.random() - 0.5) * vz.h : -vz.h / 2 - 0.2,
      z
    );
    m.rotation.z = Math.random() * Math.PI;
  }

  // Pointer parallax (eased); slow idle sway when there is no pointer
  const target = { x: 0, y: 0 };
  let pointerSeen = false;
  stage.closest(".hero").addEventListener("pointermove", (e) => {
    pointerSeen = true;
    target.x = (e.clientX / innerWidth - 0.5) * 2;
    target.y = (e.clientY / innerHeight - 0.5) * 2;
  }, { passive: true });

  let running = false, last = 0, firstFrame = true, scroll = 0;
  const clock = new THREE.Clock();
  function frame(t) {
    if (!running) return;
    const dt = Math.min(0.05, (t - last) / 1000 || 0.016);
    last = t;
    const time = clock.getElapsedTime();
    const tx = pointerSeen ? target.x : Math.sin(time * 0.18) * 0.6;
    const ty = pointerSeen ? target.y : Math.sin(time * 0.13) * 0.3;
    camera.position.x += (tx * 0.55 - camera.position.x) * 0.045;
    camera.position.y += (-ty * 0.28 - camera.position.y) * 0.045;
    // Scroll: 0 at the top, 1 once the hero has scrolled out; eased so wheel steps do not jump
    const p = Math.min(1, scrollY / stage.clientHeight);
    scroll += (p - scroll) * 0.12;
    camera.position.z = CAM_Z - scroll * 2.2;
    reedLM.position.x = reedLM.userData.base.x - scroll * 1.4;
    reedRM.position.x = reedRM.userData.base.x + scroll * 1.6;
    scrubM.position.y = scrubM.userData.base.y - scroll * 0.5;
    camera.lookAt(0, 0, 0);

    for (const m of flecks) {
      const u = m.userData;
      m.position.y += u.speed * dt;
      m.position.x += Math.sin(time * 0.7 + u.wobble) * 0.002 - 0.03 * dt;
      m.rotation.z += u.spin * dt;
      m.rotation.y = Math.sin(time + u.wobble) * 0.9;
      if (m.position.y > view(m.position.z).h / 2 + 0.2) resetFleck(m, false);
    }
    renderer.render(scene, camera);
    if (firstFrame) { firstFrame = false; stage.classList.add("ready"); }
    requestAnimationFrame(frame);
  }
  const run = (on) => {
    if (on && !running) { running = true; last = performance.now(); requestAnimationFrame(frame); }
    if (!on) running = false;
  };

  layout();
  new ResizeObserver(layout).observe(stage);
  let visible = true;
  new IntersectionObserver((e) => { visible = e[0].isIntersecting; run(visible && !document.hidden); }).observe(stage);
  document.addEventListener("visibilitychange", () => run(visible && !document.hidden));
  run(true);
}
