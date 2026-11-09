// The Last Wild Paw: page behaviour. No scroll listeners: IntersectionObserver / ResizeObserver only.
(function () {
  var root = document.documentElement;
  root.classList.add("js");
  var reduce = matchMedia("(prefers-reduced-motion: reduce)");

  // Language toggle (TH / EN), remembered per browser
  document.querySelectorAll("[data-lang-toggle]").forEach(function (b) {
    b.addEventListener("click", function () {
      var next = root.lang === "th" ? "en" : "th";
      root.lang = next;
      localStorage.setItem("lwp.lang", next);
    });
  });

  // Reveal blocks as they enter
  var items = document.querySelectorAll(".reveal");
  if (!("IntersectionObserver" in window)) {
    items.forEach(function (el) { el.classList.add("in"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.15 });
    items.forEach(function (el) { io.observe(el); });

    // Solid nav once the hero is mostly gone
    var hero = document.querySelector(".hero"), nav = document.querySelector(".nav");
    if (hero && nav) {
      new IntersectionObserver(function (e) {
        nav.classList.toggle("solid", !e[0].isIntersecting);
      }, { threshold: 0.12 }).observe(hero);
    }

    // Teaser plays only while visible, never under reduced motion
    var v = document.querySelector("[data-teaser]");
    if (v) {
      new IntersectionObserver(function (e) {
        if (e[0].isIntersecting && !reduce.matches) { v.preload = "auto"; v.play().catch(function () {}); }
        else v.pause();
      }, { threshold: 0.35 }).observe(v);
    }
  }

  // Soundtrack: one track at a time
  document.addEventListener("play", function (e) {
    document.querySelectorAll(".tracks audio").forEach(function (a) { if (a !== e.target) a.pause(); });
  }, true);

  // Seasons pan: section height = sideways travel + one screen (used by the CSS scroll-driven animation)
  var pan = document.querySelector("[data-pan]"), track = document.querySelector("[data-pan-track]");
  if (pan && track && "ResizeObserver" in window) {
    var size = function () {
      var travel = Math.max(0, track.scrollWidth - innerWidth);
      pan.style.setProperty("--pan-h", travel + innerHeight + "px");
    };
    new ResizeObserver(size).observe(track);
    addEventListener("resize", size);
    size();
  }
})();
