<!DOCTYPE html>

<html class="dark" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Library - Kaminari Browser</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&amp;family=Noto+Sans+JP:wght@500;700&amp;family=Space+Grotesk:wght@600;700&amp;family=JetBrains+Mono:wght@500&amp;display=swap" rel="stylesheet"/>
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
        box-shadow: 0 0 15px rgba(221, 199, 63, 0.15);
      }
      .material-symbols-outlined {
        font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        vertical-align: middle;
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
<body class="bg-background text-on-background min-h-screen pb-32">
<!-- Top App Bar -->
<header class="bg-surface/80 dark:bg-surface/80 backdrop-blur-xl border-b border-primary/10 shadow-[0_0_15px_rgba(221,199,63,0.1)] fixed top-0 left-0 w-full flex justify-between items-center h-16 px-margin-mobile w-full z-50">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-primary-fixed" data-icon="bolt">bolt</span>
<h1 class="font-headline-md text-headline-md font-bold text-primary-fixed tracking-tight">Kaminari Browser</h1>
</div>
<button class="active:scale-95 duration-200">
<span class="material-symbols-outlined text-on-surface-variant" data-icon="account_circle">account_circle</span>
</button>
</header>
<main class="pt-24 px-margin-mobile max-w-2xl mx-auto">
<!-- Tab Switcher -->
<div class="flex p-1 bg-surface-container-low rounded-xl mb-stack-lg border border-outline/10">
<button class="flex-1 py-3 text-center rounded-lg font-headline-md text-body-md transition-all bg-primary-container text-on-primary-container font-bold shadow-lg">
                Favorites
            </button>
<button class="flex-1 py-3 text-center rounded-lg font-headline-md text-body-md transition-all text-on-surface-variant hover:text-on-surface">
                History
            </button>
</div>
<!-- Library Content -->
<div class="space-y-stack-md">
<!-- Item 1 -->
<div class="glass-card p-4 rounded-xl flex gap-4 items-center group active:scale-[0.98] transition-transform">
<div class="w-16 h-20 rounded-lg overflow-hidden flex-shrink-0 bg-surface-container-highest border border-primary/20">
<img alt="Book Cover" class="w-full h-full object-cover" data-alt="A macro shot of a vintage Japanese novel cover with elegant gold leaf Kanji detailing. The atmosphere is warm and scholarly, lit by soft incandescent library lighting. The color palette features deep indigo blue and metallic yellow accents, perfectly capturing a high-end, focused learning aesthetic." src="https://lh3.googleusercontent.com/aida-public/AB6AXuAO9RzbgoIBqMjf-xM1ZQmvYtSBPglFwd7YBJe8uSBPg7npOmA3mIUWYPmnuehMEY_NZ0qCrCkQ0i3uTo_svJxmrkKh5PmzPh-13McgmOps_CSNWEF2ZTOV0jzKbiSaESYoHsm6t9eUGznIe6lEzyh2vx5VsaRRFuO70oP2Nrh3UE10VQNO2TENm4hiEiw0Ydqfqsj_Mn_d3-hUQ7hKtBkaJ-CfaAkfS1l54V_nAYqSIxjbPQIpYWQidZNYBYK7u1vnDUrT3jFRh_44"/>
</div>
<div class="flex-1 min-w-0">
<h3 class="font-body-lg-jp text-body-lg-jp text-on-surface truncate">ノルウェイの森 (Norwegian Wood)</h3>
<div class="flex flex-wrap gap-x-4 gap-y-1 mt-1 text-on-surface-variant font-label-sm-mono text-label-sm-mono opacity-80">
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="schedule">schedule</span>
                            2 hours ago
                        </span>
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="auto_stories">auto_stories</span>
                            Page 42 / 380
                        </span>
</div>
<!-- Voltage Meter (Progress Bar) -->
<div class="mt-3 w-full bg-surface-container-highest h-1 rounded-full overflow-hidden">
<div class="bg-primary-fixed h-full w-[11%] electric-glow shadow-[0_0_8px_rgba(250,227,89,0.4)]"></div>
</div>
</div>
<button class="p-2 text-on-surface-variant hover:text-primary-fixed transition-colors">
<span class="material-symbols-outlined" data-icon="more_vert">more_vert</span>
</button>
</div>
<!-- Item 2 -->
<div class="glass-card p-4 rounded-xl flex gap-4 items-center group active:scale-[0.98] transition-transform">
<div class="w-16 h-20 rounded-lg overflow-hidden flex-shrink-0 bg-surface-container-highest border border-primary/20">
<img alt="Book Cover" class="w-full h-full object-cover" data-alt="Digital illustration of a cyberpunk city guide cover, featuring glowing neon signage in Katakana. The lighting is dominated by electric yellow and deep shadow, with high-contrast surfaces. The mood is energetic and futuristic, aligned with a high-voltage tech-savvy brand identity." src="https://lh3.googleusercontent.com/aida-public/AB6AXuCA0kAGwEn9kjjUu93JtXsCyU7LN3wQzL_PjPj6ftvGwjzE1m9y9jXZUTy4fIdWpao36wW2yjq5WAzto6_U5HX9pJDjC8WTXkOnXCaHzX9dFuJ24XB9YFZdyT83tdzoesjEghYEuTaHlXOckSgm8H9VgpgGWZCYLcq5jxRa2p3WnPsB-bL5efe0M8f6jI5dltxEhD9By-Euv2-HXMXQOwU3IBqzCBWG9Ji8JXamFlDLpgQATnKeBLaJldR6Sh_lqYaHXF8WZ5c2RD9t"/>
</div>
<div class="flex-1 min-w-0">
<h3 class="font-body-lg-jp text-body-lg-jp text-on-surface truncate">Advanced Kanji Master N1</h3>
<div class="flex flex-wrap gap-x-4 gap-y-1 mt-1 text-on-surface-variant font-label-sm-mono text-label-sm-mono opacity-80">
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="schedule">schedule</span>
                            Yesterday
                        </span>
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="auto_stories">auto_stories</span>
                            Page 156 / 200
                        </span>
</div>
<div class="mt-3 w-full bg-surface-container-highest h-1 rounded-full overflow-hidden">
<div class="bg-primary-fixed h-full w-[78%] electric-glow shadow-[0_0_8px_rgba(250,227,89,0.4)]"></div>
</div>
</div>
<button class="p-2 text-on-surface-variant hover:text-primary-fixed transition-colors">
<span class="material-symbols-outlined" data-icon="more_vert">more_vert</span>
</button>
</div>
<!-- Item 3 -->
<div class="glass-card p-4 rounded-xl flex gap-4 items-center group active:scale-[0.98] transition-transform">
<div class="w-16 h-20 rounded-lg overflow-hidden flex-shrink-0 bg-surface-container-highest border border-primary/20">
<img alt="Book Cover" class="w-full h-full object-cover" data-alt="An abstract artistic representation of a Japanese haiku scroll. The scene is shot in a dark, minimalist room with a single spotlight illuminating the texture of the paper and the sharp black ink of the Kanji. The mood is serene yet intense, with subtle yellow atmospheric lighting in the background." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBfYT489cK1M-YKRsuBsboDbV29o05OtNYm5Y7qLYFxl0-kDxkSJ5-OoUPSNDWQOXgwRiEWtqvR-OWbARrcvsZOmWFVgauGZPs-d-3eeNyTyTGGOddWTVUPXVglwi5b__NpqBSGbINqP0tqnPVTKszK3ifTfCSKdJ3oBVvuZs9h7nJVz8_kpCmCVu8lyibhuLG291Pnf1m_dH9UBysxfC-UZ3j24_nVDCD0WZW8ZQ778kof2lCFHhAs4q5CMBY0W9SZcGe4AB_tZX5U"/>
</div>
<div class="flex-1 min-w-0">
<h3 class="font-body-lg-jp text-body-lg-jp text-on-surface truncate">Japanese Short Stories</h3>
<div class="flex flex-wrap gap-x-4 gap-y-1 mt-1 text-on-surface-variant font-label-sm-mono text-label-sm-mono opacity-80">
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="schedule">schedule</span>
                            3 days ago
                        </span>
<span class="flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="auto_stories">auto_stories</span>
                            Page 12 / 120
                        </span>
</div>
<div class="mt-3 w-full bg-surface-container-highest h-1 rounded-full overflow-hidden">
<div class="bg-primary-fixed h-full w-[10%] electric-glow shadow-[0_0_8px_rgba(250,227,89,0.4)]"></div>
</div>
</div>
<button class="p-2 text-on-surface-variant hover:text-primary-fixed transition-colors">
<span class="material-symbols-outlined" data-icon="more_vert">more_vert</span>
</button>
</div>
</div>
<!-- Empty State (Hidden by default but provided for reference) -->
<div class="hidden flex flex-col items-center justify-center py-20 text-center">
<div class="w-24 h-24 rounded-full bg-surface-container-high flex items-center justify-center mb-6 border border-primary/10">
<span class="material-symbols-outlined text-primary-fixed text-4xl" data-icon="bookmark_border">bookmark_border</span>
</div>
<h2 class="font-headline-md text-headline-md text-on-surface mb-2">Nothing here yet</h2>
<p class="font-body-md text-body-md text-on-surface-variant mb-8 max-w-[240px]">Your saved articles and books will appear here once you start reading.</p>
<button class="px-8 py-3 bg-primary-fixed text-on-primary-fixed font-bold rounded-full active:scale-95 transition-all shadow-lg shadow-primary-fixed/20">
                Go Discover
            </button>
</div>
</main>
<!-- Bottom Navigation Bar -->
<nav class="fixed bottom-0 w-full z-50 flex justify-around items-center h-20 px-2 pb-safe bg-surface-container-highest/80 dark:bg-surface-container-highest/80 backdrop-blur-xl border-t border-primary/10 shadow-[0_-4px_20px_rgba(0,0,0,0.5)] rounded-t-xl">
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined" data-icon="home">home</span>
<span class="font-label-sm-mono text-label-sm-mono">Home</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined" data-icon="explore">explore</span>
<span class="font-label-sm-mono text-label-sm-mono">Discover</span>
</a>
<a class="flex flex-col items-center justify-center text-primary-fixed bg-primary-container/20 rounded-xl px-4 py-1 active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined" data-icon="bookmark" style="font-variation-settings: 'FILL' 1;">bookmark</span>
<span class="font-label-sm-mono text-label-sm-mono">Favorites</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined" data-icon="history">history</span>
<span class="font-label-sm-mono text-label-sm-mono">History</span>
</a>
</nav>
</body></html>