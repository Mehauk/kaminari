<!DOCTYPE html>

<html class="dark" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Kaminari Browser - Dashboard</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&amp;family=Inter:wght@300;400;500;600&amp;family=JetBrains+Mono:wght@400;500&amp;family=Noto+Sans+JP:wght@400;500;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">tailwind.config = {darkMode: "class", theme: {extend: {colors: {"on-tertiary-fixed": "#002020", "outline-variant": "#4b4735", "primary-fixed-dim": "#ddc73f", "tertiary-fixed": "#57f8f9", "error-container": "#93000a", "secondary-container": "#524918", background: "#15130b", "on-secondary-fixed-variant": "#504716", "on-surface-variant": "#cdc6af", "on-error": "#690005", "surface-container-high": "#2c2a21", "secondary-fixed": "#f1e3a3", tertiary: "#ffffff", "surface-dim": "#15130b", "primary-fixed": "#fbe359", "on-error-container": "#ffdad6", surface: "#15130b", "surface-container-highest": "#37352b", "surface-variant": "#37352b", "tertiary-fixed-dim": "#29dcdd", "surface-container": "#222017", "on-secondary-container": "#c6b97c", secondary: "#d5c789", "on-secondary-fixed": "#211b00", "surface-bright": "#3c392f", primary: "#ffffff", "on-primary-fixed": "#211c00", outline: "#96917b", "surface-container-low": "#1e1c13", "surface-container-lowest": "#100e07", "on-primary": "#383000", "inverse-primary": "#6c5e00", error: "#ffb4ab", "on-primary-container": "#726400", "inverse-on-surface": "#333027", "tertiary-container": "#57f8f9", "inverse-surface": "#e8e2d4", "on-secondary": "#383002", "on-tertiary-container": "#007071", "on-tertiary": "#003737", "on-background": "#e8e2d4", "surface-tint": "#ddc73f", "on-surface": "#e8e2d4", "secondary-fixed-dim": "#d5c789", "on-primary-fixed-variant": "#514700", "on-tertiary-fixed-variant": "#004f50", "primary-container": "#fbe359"}, borderRadius: {DEFAULT: "0.25rem", lg: "0.5rem", xl: "0.75rem", full: "9999px"}, spacing: {"stack-lg": "2rem", base_unit: "4px", "margin-mobile": "1.25rem", "gutter-mobile": "1rem", "stack-sm": "0.5rem", "stack-md": "1rem"}, fontFamily: {"body-lg-jp": ["Noto Sans JP"], "label-sm-mono": ["JetBrains Mono"], "headline-md": ["Space Grotesk"], "display-lg": ["Space Grotesk"], "body-md": ["Inter"]}, fontSize: {"body-lg-jp": ["18px", {lineHeight: "28px", fontWeight: "500"}], "label-sm-mono": ["12px", {lineHeight: "16px", letterSpacing: "0.05em", fontWeight: "500"}], "headline-md": ["24px", {lineHeight: "32px", fontWeight: "600"}], "display-lg": ["32px", {lineHeight: "40px", letterSpacing: "-0.02em", fontWeight: "700"}], "body-md": ["16px", {lineHeight: "24px", fontWeight: "400"}]}}}};</script>
<style>
        .glass {
            background: rgba(30, 30, 30, 0.6);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(250, 227, 89, 0.1);
        }
        .electric-border {
            border: 1px solid rgba(250, 227, 89, 0.3);
            box-shadow: inset 0 0 10px rgba(250, 227, 89, 0.05);
        }
        .voltage-glow {
            box-shadow: 0 0 15px rgba(250, 227, 89, 0.4);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background text-on-background font-body-md text-body-md min-h-screen pb-24">
<!-- TopAppBar -->
<header class="fixed top-0 left-0 w-full bg-surface/80 dark:bg-surface/80 backdrop-blur-xl border-b border-primary/10 shadow-[0_0_15px_rgba(221,199,63,0.1)] z-50 flex justify-between items-center h-16 px-margin-mobile">
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary-fixed" style="font-variation-settings: 'FILL' 1;">bolt</span>
<h1 class="font-headline-md text-headline-md font-bold text-primary-fixed tracking-tight">Kaminari Browser</h1>
</div>
<button class="active:scale-95 duration-200">
<span class="material-symbols-outlined text-on-surface-variant text-3xl">account_circle</span>
</button>
</header>
<main class="pt-20 px-margin-mobile space-y-stack-lg">
<!-- Quick Stats Section -->
<section class="grid grid-cols-2 gap-gutter-mobile">
<div class="glass p-4 rounded-xl flex flex-col justify-between h-24">
<span class="text-label-sm-mono font-label-sm-mono text-on-surface-variant">DAILY STREAK</span>
<div class="flex items-end gap-2">
<span class="text-display-lg font-display-lg text-primary-fixed">12</span>
<span class="text-label-sm-mono font-label-sm-mono mb-2 text-primary-fixed-dim">DAYS</span>
</div>
</div>
<div class="glass p-4 rounded-xl flex flex-col justify-between h-24">
<span class="text-label-sm-mono font-label-sm-mono text-on-surface-variant">WORDS LEARNED</span>
<div class="flex items-end gap-2">
<span class="text-display-lg font-display-lg text-primary-fixed">842</span>
<span class="material-symbols-outlined text-primary-fixed mb-2">trending_up</span>
</div>
</div>
</section>
<!-- Jump Back In Card (Bento Focus) -->
<section class="relative group">
<div class="absolute inset-0 bg-primary-fixed/5 blur-2xl rounded-3xl -z-10 group-hover:bg-primary-fixed/10 transition-colors"></div>
<div class="glass rounded-2xl overflow-hidden electric-border">
<div class="relative h-48 w-full overflow-hidden">
<img alt="Light Novel Cover" class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="A cinematic, high-contrast close-up of a Japanese light novel resting on a sleek black tech desk. The background features blurred neon Tokyo city lights in electric yellow and deep violet, creating a moody, futuristic atmosphere. Soft lighting highlights the intricate Kanji characters on the book's spine, while a faint glowing yellow energy arc sweeps across the frame, emphasizing the 'High-Voltage Learning' brand identity." src="https://lh3.googleusercontent.com/aida-public/AB6AXuAsmvERQIxb69zOnC3qKBAhy-utzthLY4MKFP6Cna6vzDRyZBZRGPp2J6WEUCiRmVJL-f3q2U3jq1A94N7GbNG3lKuNOP9CoN5kzB2SMJh-62WJUjTsxlLAUiFfA4Oc-9CXr8VrJJ_7iBjGaP2xwIK-h5_sXYSqlGgJJz-vDvP_qe_Db6Kcw4Be4OxX-g07-ucZwCrxxAsUIzSZPGD5_LpXQjO7HHu3StMKAjIa_bubKQA88L9z9RYqn8yjJO7xGXByqLQbGV4DKjVI"/>
<div class="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent"></div>
<div class="absolute top-4 left-4">
<span class="bg-primary-fixed text-on-primary-fixed font-label-sm-mono text-label-sm-mono px-3 py-1 rounded-full uppercase tracking-widest font-bold">Novel</span>
</div>
</div>
<div class="p-6 -mt-12 relative z-10">
<h2 class="font-headline-md text-headline-md text-primary mb-1">Overlord: Volume 14</h2>
<p class="font-body-lg-jp text-body-lg-jp text-on-surface-variant mb-6">Chapter 3: The Witch of the Falling Kingdom</p>
<div class="flex items-center justify-between gap-4">
<div class="flex-1 space-y-2">
<div class="flex justify-between text-label-sm-mono font-label-sm-mono">
<span class="text-on-surface-variant">READING PROGRESS</span>
<span class="text-primary-fixed">68%</span>
</div>
<div class="h-1 bg-surface-container-highest rounded-full overflow-hidden">
<div class="h-full bg-primary-fixed w-[68%] voltage-glow"></div>
</div>
</div>
<button class="bg-primary-fixed text-on-primary-fixed px-6 py-3 rounded-xl font-bold active:scale-90 transition-all flex items-center gap-2 shadow-lg shadow-primary-fixed/20">
                            Continue
                            <span class="material-symbols-outlined">play_arrow</span>
</button>
</div>
</div>
</div>
</section>
<!-- Progression Section -->
<section class="space-y-stack-md">
<h3 class="font-headline-md text-headline-md text-on-surface flex items-center gap-2">
<span class="material-symbols-outlined text-primary-fixed">analytics</span>
                Mastery
            </h3>
<div class="grid grid-cols-1 md:grid-cols-2 gap-gutter-mobile">
<!-- Kana Progress -->
<div class="glass p-6 rounded-2xl flex items-center justify-between electric-border">
<div class="space-y-1">
<h4 class="font-headline-md text-headline-md text-primary">Kana</h4>
<p class="text-on-surface-variant font-body-md text-sm">Hiragana &amp; Katakana</p>
</div>
<div class="relative flex items-center justify-center w-20 h-20">
<svg class="w-full h-full transform -rotate-90">
<circle class="text-surface-container-highest" cx="40" cy="40" fill="transparent" r="34" stroke="currentColor" stroke-width="6"></circle>
<circle class="text-primary-fixed voltage-glow" cx="40" cy="40" fill="transparent" r="34" stroke="currentColor" stroke-dasharray="213.6" stroke-dashoffset="21.3" stroke-width="6"></circle>
</svg>
<span class="absolute text-label-sm-mono font-label-sm-mono font-bold text-primary">90%</span>
</div>
</div>
<!-- Kanji Progress -->
<div class="glass p-6 rounded-2xl flex items-center justify-between border border-primary/5">
<div class="space-y-1">
<h4 class="font-headline-md text-headline-md text-primary">Kanji</h4>
<p class="text-on-surface-variant font-body-md text-sm">JLPT N2 Level Focus</p>
</div>
<div class="relative flex items-center justify-center w-20 h-20">
<svg class="w-full h-full transform -rotate-90">
<circle class="text-surface-container-highest" cx="40" cy="40" fill="transparent" r="34" stroke="currentColor" stroke-width="6"></circle>
<circle class="text-primary-fixed-dim" cx="40" cy="40" fill="transparent" r="34" stroke="currentColor" stroke-dasharray="213.6" stroke-dashoffset="128.1" stroke-width="6"></circle>
</svg>
<span class="absolute text-label-sm-mono font-label-sm-mono font-bold text-primary">40%</span>
</div>
</div>
</div>
</section>
<!-- Kanji Highlight (Thematic Card) -->
<section class="glass p-6 rounded-2xl border-l-4 border-primary-fixed bg-gradient-to-r from-primary-fixed/10 to-transparent">
<div class="flex justify-between items-start mb-4">
<div>
<span class="text-label-sm-mono font-label-sm-mono text-primary-fixed">KANJI OF THE DAY</span>
<h2 class="text-5xl font-bold font-body-lg-jp mt-1">電</h2>
</div>
<div class="text-right">
<p class="text-label-sm-mono font-label-sm-mono text-on-surface-variant">ONYOMI</p>
<p class="font-body-lg-jp text-primary-fixed">デン (Den)</p>
</div>
</div>
<div class="flex items-center gap-4 py-3 border-t border-primary/10">
<span class="material-symbols-outlined text-primary-fixed">electric_bolt</span>
<p class="font-body-md text-on-surface">Electricity, Lightning</p>
</div>
</section>
</main>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 w-full z-50 flex justify-around items-center h-20 px-2 pb-safe bg-surface-container-highest/80 dark:bg-surface-container-highest/80 backdrop-blur-xl border-t border-primary/10 shadow-[0_-4px_20px_rgba(0,0,0,0.5)] rounded-t-xl">
<a class="flex flex-col items-center justify-center text-primary-fixed bg-primary-container/20 rounded-xl px-4 py-1 transition-all" href="#">
<span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">home</span>
<span class="font-label-sm-mono text-label-sm-mono">Home</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all" href="#">
<span class="material-symbols-outlined">explore</span>
<span class="font-label-sm-mono text-label-sm-mono">Discover</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all" href="#">
<span class="material-symbols-outlined">bookmark</span>
<span class="font-label-sm-mono text-label-sm-mono">Favorites</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all" href="#">
<span class="material-symbols-outlined">history</span>
<span class="font-label-sm-mono text-label-sm-mono">History</span>
</a>
</nav>
</body></html>