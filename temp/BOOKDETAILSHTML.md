<!DOCTYPE html>

<html class="dark" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Kaminari Browser - Item Details</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&amp;family=Noto+Sans+JP:wght@400;500;700&amp;family=Space+Grotesk:wght@600;700&amp;family=JetBrains+Mono:wght@500&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">tailwind.config = {darkMode: "class", theme: {extend: {colors: {"on-tertiary-fixed": "#002020", "outline-variant": "#4b4735", "primary-fixed-dim": "#ddc73f", "tertiary-fixed": "#57f8f9", "error-container": "#93000a", "secondary-container": "#524918", background: "#15130b", "on-secondary-fixed-variant": "#504716", "on-surface-variant": "#cdc6af", "on-error": "#690005", "surface-container-high": "#2c2a21", "secondary-fixed": "#f1e3a3", tertiary: "#ffffff", "surface-dim": "#15130b", "primary-fixed": "#fbe359", "on-error-container": "#ffdad6", surface: "#15130b", "surface-container-highest": "#37352b", "surface-variant": "#37352b", "tertiary-fixed-dim": "#29dcdd", "surface-container": "#222017", "on-secondary-container": "#c6b97c", secondary: "#d5c789", "on-secondary-fixed": "#211b00", "surface-bright": "#3c392f", primary: "#ffffff", "on-primary-fixed": "#211c00", outline: "#96917b", "surface-container-low": "#1e1c13", "surface-container-lowest": "#100e07", "on-primary": "#383000", "inverse-primary": "#6c5e00", error: "#ffb4ab", "on-primary-container": "#726400", "inverse-on-surface": "#333027", "tertiary-container": "#57f8f9", "inverse-surface": "#e8e2d4", "on-secondary": "#383002", "on-tertiary-container": "#007071", "on-tertiary": "#003737", "on-background": "#e8e2d4", "surface-tint": "#ddc73f", "on-surface": "#e8e2d4", "secondary-fixed-dim": "#d5c789", "on-primary-fixed-variant": "#514700", "on-tertiary-fixed-variant": "#004f50", "primary-container": "#fbe359"}, borderRadius: {DEFAULT: "0.25rem", lg: "0.5rem", xl: "0.75rem", full: "9999px"}, spacing: {"stack-lg": "2rem", base_unit: "4px", "margin-mobile": "1.25rem", "gutter-mobile": "1rem", "stack-sm": "0.5rem", "stack-md": "1rem"}, fontFamily: {"body-lg-jp": ["Noto Sans JP"], "label-sm-mono": ["JetBrains Mono"], "headline-md": ["Space Grotesk"], "display-lg": ["Space Grotesk"], "body-md": ["Inter"]}, fontSize: {"body-lg-jp": ["18px", {lineHeight: "28px", fontWeight: "500"}], "label-sm-mono": ["12px", {lineHeight: "16px", letterSpacing: "0.05em", fontWeight: "500"}], "headline-md": ["24px", {lineHeight: "32px", fontWeight: "600"}], "display-lg": ["32px", {lineHeight: "40px", letterSpacing: "-0.02em", fontWeight: "700"}], "body-md": ["16px", {lineHeight: "24px", fontWeight: "400"}]}}}};</script>
<style>
        .glass-card {
            background: rgba(30, 30, 30, 0.6);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(250, 227, 89, 0.1);
        }
        .electric-glow {
            box-shadow: 0 0 15px rgba(221, 199, 63, 0.3);
        }
        .scrollbar-hide::-webkit-scrollbar {
            display: none;
        }
        .scrollbar-hide {
            -ms-overflow-style: none;
            scrollbar-width: none;
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
<body class="bg-background text-on-background min-h-screen selection:bg-primary-fixed selection:text-on-primary-fixed">
<!-- Top Navigation Bar (Contextual Back State) -->
<header class="fixed top-0 left-0 w-full z-50 bg-surface/40 backdrop-blur-xl flex justify-between items-center h-16 px-margin-mobile border-b border-primary/10">
<div class="flex items-center gap-4">
<button class="w-10 h-10 flex items-center justify-center rounded-full bg-surface-container-high/50 text-primary-fixed active:scale-95 duration-200">
<span class="material-symbols-outlined" data-icon="arrow_back">arrow_back</span>
</button>
<h1 class="font-headline-md text-headline-md font-bold text-primary-fixed tracking-tight">Kaminari Browser</h1>
</div>
<button class="w-10 h-10 flex items-center justify-center rounded-full bg-surface-container-high/50 text-primary-fixed active:scale-95 duration-200">
<span class="material-symbols-outlined" data-icon="bookmark" data-weight="fill" style="font-variation-settings: 'FILL' 1;">bookmark</span>
</button>
</header>
<main class="pb-24 pt-16">
<!-- Hero Cover Art Section -->
<section class="relative w-full aspect-[3/4] md:aspect-[16/9] overflow-hidden">
<img alt="Manga Cover Art" class="w-full h-full object-cover" data-alt="A cinematic, high-contrast book cover featuring a dramatic character silhouette in the foreground against a neon-lit Tokyo night cityscape. Intense yellow lightning bolts crackle through a deep indigo and charcoal sky. The artistic style is a fusion of modern manga aesthetics and dark synthwave visuals, with sharp, energetic linework and a glowing, electric atmosphere that feels sophisticated and fast-paced." src="https://lh3.googleusercontent.com/aida-public/AB6AXuA87VKJVB1SgRkQzTgDKHSssUaKKoTmKQYsyHDcyV22DophVDGIxAZ5WXYSVgv-5PvFhwFATrJvZ1LOF-Q2N1UXAQ1B2QHx45n-Zl_89Mb6IUCiZiziLlnzLAiPJFJE96AZuOVYVN9WEZFA77n438ux3REjvsk1Wl5rvbyVl1k0rFEWcbgH9TR6WpDqSSEQtC0BVUcl5egjG5mBmjejws15kHspmwLKzw1GGNVF_OMnQ5JwpWyPyhlL4i2HMBrsYbt1QcEposxoGmCV"/>
<div class="absolute inset-0 bg-gradient-to-t from-background via-background/20 to-transparent"></div>
<!-- Floating Quick Info Overlay -->
<div class="absolute bottom-8 left-margin-mobile right-margin-mobile">
<div class="glass-card p-6 rounded-xl flex flex-col gap-2">
<span class="font-label-sm-mono text-label-sm-mono text-primary-fixed uppercase tracking-widest">Ongoing Series</span>
<h2 class="font-display-lg text-display-lg text-primary leading-tight">影の稲妻: Shadow Bolt</h2>
<div class="flex items-center gap-3">
<span class="font-body-md text-body-md text-on-surface-variant italic">By Haruto Takahashi</span>
<span class="w-1 h-1 rounded-full bg-outline-variant"></span>
<span class="font-body-md text-body-md text-tertiary-fixed underline decoration-primary-fixed/30 underline-offset-4">manga-kaminari.jp</span>
</div>
</div>
</div>
</section>
<div class="px-margin-mobile space-y-stack-lg -mt-4 relative z-10">
<!-- Learning Stats / Progress Section -->
<section class="space-y-stack-sm">
<div class="flex justify-between items-end mb-2">
<div class="flex flex-col">
<span class="font-label-sm-mono text-label-sm-mono text-on-surface-variant">VOLTAGE PROGRESS</span>
<span class="font-headline-md text-headline-md text-primary-fixed font-bold">142 <span class="text-on-surface-variant font-normal">/ 320 Pages</span></span>
</div>
<span class="font-label-sm-mono text-label-sm-mono text-primary-fixed bg-primary-container/10 px-2 py-1 rounded">44% COMPLETE</span>
</div>
<div class="w-full h-[6px] bg-surface-container-highest rounded-full overflow-hidden">
<div class="h-full bg-primary-fixed electric-glow transition-all duration-1000" style="width: 44.3%;"></div>
</div>
</section>
<!-- Main Action Button -->
<section>
<button class="w-full h-16 bg-primary-fixed hover:bg-primary-fixed-dim text-on-primary-fixed font-headline-md text-headline-md rounded-xl flex items-center justify-center gap-3 active:scale-95 duration-150 electric-glow">
<span class="material-symbols-outlined" data-icon="play_arrow" data-weight="fill" style="font-variation-settings: 'FILL' 1;">play_arrow</span>
                    CONTINUE READING
                </button>
</section>
<!-- Tags Section -->
<section>
<div class="flex gap-2 overflow-x-auto scrollbar-hide pb-2">
<span class="flex-shrink-0 px-4 py-2 bg-surface-container-highest/60 rounded-full border border-primary/5 font-body-md text-body-md text-on-surface-variant hover:border-primary-fixed hover:text-primary-fixed transition-colors">Fantasy</span>
<span class="flex-shrink-0 px-4 py-2 bg-primary-container/20 rounded-full border border-primary-fixed/20 font-body-md text-body-md text-primary-fixed">Japanese Learning</span>
<span class="flex-shrink-0 px-4 py-2 bg-surface-container-highest/60 rounded-full border border-primary/5 font-body-md text-body-md text-on-surface-variant hover:border-primary-fixed hover:text-primary-fixed transition-colors">Seinen</span>
<span class="flex-shrink-0 px-4 py-2 bg-surface-container-highest/60 rounded-full border border-primary/5 font-body-md text-body-md text-on-surface-variant hover:border-primary-fixed hover:text-primary-fixed transition-colors">Action</span>
<span class="flex-shrink-0 px-4 py-2 bg-surface-container-highest/60 rounded-full border border-primary/5 font-body-md text-body-md text-on-surface-variant hover:border-primary-fixed hover:text-primary-fixed transition-colors">Isekai</span>
</div>
</section>
<!-- Description / Summary -->
<section class="space-y-stack-md">
<h3 class="font-headline-md text-headline-md text-primary flex items-center gap-2">
<span class="material-symbols-outlined text-primary-fixed" data-icon="description">description</span>
                    Synopsis
                </h3>
<div class="max-h-64 overflow-y-auto pr-2 space-y-4 font-body-lg-jp text-body-lg-jp text-on-surface-variant leading-relaxed text-justify">
<p>
                        In a Tokyo where shadows hold the power of forgotten circuits, young Kaito discovers an ancient terminal that grants him the ability to "read" the electrical pulse of the city. 
                    </p>
<p class="font-body-lg-jp">
                        東京の影に潜む古の回路。海人は都市の電気パルスを「読む」能力を手に入れた。この力は彼の運命を、そして壊れゆく世界の未来を大きく変えることになる。
                    </p>
<p>
                        Every chapter in this series is optimized for language learning with high-frequency JLPT N2 vocabulary and real-world tech slang found in Shibuya's digital underground. The narrative flows with high-voltage energy, pushing the boundaries of what a digital reading experience can be.
                    </p>
</div>
</section>
<!-- Kanji Highlights / Mastery (Bento style) -->
<section class="grid grid-cols-2 gap-stack-md">
<div class="glass-card p-4 rounded-2xl flex flex-col items-center justify-center gap-2 text-center aspect-square">
<span class="font-display-lg text-display-lg text-primary-fixed" style="font-size: 48px;">雷</span>
<span class="font-label-sm-mono text-label-sm-mono text-on-surface-variant uppercase">Key Kanji: Thunder</span>
<div class="w-full h-1 bg-surface-container rounded-full mt-2">
<div class="h-full bg-primary-fixed w-[85%] rounded-full"></div>
</div>
</div>
<div class="glass-card p-4 rounded-2xl flex flex-col justify-between aspect-square">
<div class="flex justify-between items-start">
<span class="material-symbols-outlined text-tertiary-fixed" data-icon="bolt">bolt</span>
<span class="font-label-sm-mono text-label-sm-mono text-tertiary-fixed">85%</span>
</div>
<div>
<p class="font-headline-md text-headline-md text-primary">Vocab Mastered</p>
<p class="font-body-md text-body-md text-on-surface-variant">24/28 Words</p>
</div>
</div>
</section>
</div>
</main>
<!-- Suppressed Bottom Nav (Replaced with specific Task Actions for Detail View) -->
<nav class="fixed bottom-0 left-0 w-full z-50 bg-surface-container-highest/80 backdrop-blur-xl h-20 px-4 pb-safe flex items-center justify-around border-t border-primary/10 rounded-t-xl shadow-[0_-4px_20px_rgba(0,0,0,0.5)]">
<div class="flex flex-col items-center justify-center text-on-surface-variant active:scale-90 duration-150">
<span class="material-symbols-outlined" data-icon="menu_book">menu_book</span>
<span class="font-label-sm-mono text-label-sm-mono">Chapter List</span>
</div>
<div class="flex flex-col items-center justify-center text-on-surface-variant active:scale-90 duration-150">
<span class="material-symbols-outlined" data-icon="translate">translate</span>
<span class="font-label-sm-mono text-label-sm-mono">Translation</span>
</div>
<div class="flex flex-col items-center justify-center text-on-surface-variant active:scale-90 duration-150">
<span class="material-symbols-outlined" data-icon="auto_stories">auto_stories</span>
<span class="font-label-sm-mono text-label-sm-mono">Reader Mode</span>
</div>
<div class="flex flex-col items-center justify-center text-on-surface-variant active:scale-90 duration-150">
<span class="material-symbols-outlined" data-icon="share">share</span>
<span class="font-label-sm-mono text-label-sm-mono">Export</span>
</div>
</nav>
</body></html>