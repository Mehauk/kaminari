<!DOCTYPE html>

<html class="dark" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&amp;family=Inter:wght@300;400;500;600&amp;family=Noto+Sans+JP:wght@400;500;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<style>
        .glass-card {
            background: rgba(30, 30, 30, 0.6);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(250, 227, 89, 0.05);
            transition: all 0.3s ease;
        }
        .glass-card:hover {
            border-color: rgba(250, 227, 89, 0.4);
            box-shadow: 0 0 20px rgba(221, 199, 63, 0.15);
            transform: translateY(-4px);
        }
        .electric-glow {
            box-shadow: 0 0 10px rgba(250, 227, 89, 0.3);
        }
        .line-clamp-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
    </style>
<script id="tailwind-config">tailwind.config = {darkMode: "class", theme: {extend: {colors: {"on-tertiary-fixed": "#002020", "outline-variant": "#4b4735", "primary-fixed-dim": "#ddc73f", "tertiary-fixed": "#57f8f9", "error-container": "#93000a", "secondary-container": "#524918", background: "#15130b", "on-secondary-fixed-variant": "#504716", "on-surface-variant": "#cdc6af", "on-error": "#690005", "surface-container-high": "#2c2a21", "secondary-fixed": "#f1e3a3", tertiary: "#ffffff", "surface-dim": "#15130b", "primary-fixed": "#fbe359", "on-error-container": "#ffdad6", surface: "#15130b", "surface-container-highest": "#37352b", "surface-variant": "#37352b", "tertiary-fixed-dim": "#29dcdd", "surface-container": "#222017", "on-secondary-container": "#c6b97c", secondary: "#d5c789", "on-secondary-fixed": "#211b00", "surface-bright": "#3c392f", primary: "#ffffff", "on-primary-fixed": "#211c00", outline: "#96917b", "surface-container-low": "#1e1c13", "surface-container-lowest": "#100e07", "on-primary": "#383000", "inverse-primary": "#6c5e00", error: "#ffb4ab", "on-primary-container": "#726400", "inverse-on-surface": "#333027", "tertiary-container": "#57f8f9", "inverse-surface": "#e8e2d4", "on-secondary": "#383002", "on-tertiary-container": "#007071", "on-tertiary": "#003737", "on-background": "#e8e2d4", "surface-tint": "#ddc73f", "on-surface": "#e8e2d4", "secondary-fixed-dim": "#d5c789", "on-primary-fixed-variant": "#514700", "on-tertiary-fixed-variant": "#004f50", "primary-container": "#fbe359"}, borderRadius: {DEFAULT: "0.25rem", lg: "0.5rem", xl: "0.75rem", full: "9999px"}, spacing: {"stack-lg": "2rem", base_unit: "4px", "margin-mobile": "1.25rem", "gutter-mobile": "1rem", "stack-sm": "0.5rem", "stack-md": "1rem"}, fontFamily: {"body-lg-jp": ["Noto Sans JP"], "label-sm-mono": ["JetBrains Mono"], "headline-md": ["Space Grotesk"], "display-lg": ["Space Grotesk"], "body-md": ["Inter"]}, fontSize: {"body-lg-jp": ["18px", {lineHeight: "28px", fontWeight: "500"}], "label-sm-mono": ["12px", {lineHeight: "16px", letterSpacing: "0.05em", fontWeight: "500"}], "headline-md": ["24px", {lineHeight: "32px", fontWeight: "600"}], "display-lg": ["32px", {lineHeight: "40px", letterSpacing: "-0.02em", fontWeight: "700"}], "body-md": ["16px", {lineHeight: "24px", fontWeight: "400"}]}}}};</script>
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
<body class="bg-background text-on-background font-body-md min-h-screen pb-32">
<!-- TopAppBar -->
<header class="fixed top-0 left-0 w-full bg-surface/80 dark:bg-surface/80 backdrop-blur-xl border-b border-primary/10 shadow-[0_0_15px_rgba(221,199,63,0.1)] z-50 h-16 flex justify-between items-center px-margin-mobile">
<div class="flex items-center gap-3">
<span class="material-symbols-outlined text-primary-fixed" style="font-variation-settings: 'FILL' 1;">bolt</span>
<h1 class="font-headline-md text-headline-md font-bold text-primary-fixed tracking-tight">Kaminari Browser</h1>
</div>
<div class="flex items-center gap-4">
<button class="active:scale-95 duration-200">
<span class="material-symbols-outlined text-on-surface-variant">account_circle</span>
</button>
</div>
</header>
<main class="pt-20 px-margin-mobile space-y-6">
<!-- Search & Import Section -->
<div class="flex gap-3">
<div class="relative flex-1 group">
<span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline">search</span>
<input class="w-full bg-surface-container-low border-b-2 border-outline/30 focus:border-primary-fixed outline-none py-3 pl-12 pr-4 text-body-md transition-all rounded-t-lg focus:bg-surface-container" placeholder="Search titles, authors, URLs..." type="text"/>
</div>
<button class="bg-primary-fixed text-on-primary-fixed px-4 rounded-xl flex items-center justify-center active:scale-95 transition-transform shadow-[0_0_15px_rgba(250,227,89,0.2)]">
<span class="material-symbols-outlined">add</span>
</button>
</div>
<!-- Filter Chips -->
<div class="flex gap-2 overflow-x-auto pb-2 no-scrollbar">
<button class="bg-primary-container/20 text-primary-fixed border border-primary-fixed/30 px-5 py-2 rounded-full font-label-sm-mono text-label-sm-mono whitespace-nowrap shadow-[0_0_10px_rgba(250,227,89,0.1)]">All</button>
<button class="bg-surface-container-highest text-on-surface-variant px-5 py-2 rounded-full font-label-sm-mono text-label-sm-mono whitespace-nowrap hover:bg-surface-variant/50 transition-colors">Light Novels</button>
<button class="bg-surface-container-highest text-on-surface-variant px-5 py-2 rounded-full font-label-sm-mono text-label-sm-mono whitespace-nowrap hover:bg-surface-variant/50 transition-colors">Manga</button>
<button class="bg-surface-container-highest text-on-surface-variant px-5 py-2 rounded-full font-label-sm-mono text-label-sm-mono whitespace-nowrap hover:bg-surface-variant/50 transition-colors">Top Rated</button>
</div>
<!-- Bento Grid Layout -->
<div class="grid grid-cols-2 md:grid-cols-4 gap-gutter-mobile">
<!-- Card 1 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="A cinematic close-up of a Japanese manga cover featuring a futuristic samurai under neon lightning. The art style is hyper-detailed with vibrant electric yellow highlights against a dark, tech-noir cityscape background. The mood is energetic and high-voltage, consistent with a premium language learning platform aesthetic." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBAM6pilxIHDQ86aOPcfulMu3N0-G1_l52Tgpg_BrlXJnoetaNnvL-mVe_ZU7hDQwYQKEZTlTcNVzylERI2NudXlw2xHYcODehuVjneis4WJBnZJKHFdYgk8HaSoI1p5lhWJcJZsSJsoEmqKBlNAQ_Dqsuuo61OkKmvGdtLsJRotAMor-JJ3pHoJKYyYHFwQ6MCMQVfBKVP-znV0DyALYccVmAzd7MPkgwtLqeCUnUooY0OPuw3HTNCh18GhQuHqc0a2aj3nowh4QEm"/>
<div class="absolute top-3 left-3 bg-primary-fixed text-on-primary-fixed px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Manga</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">The Electric Blade of Edo</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">Kenta Sato</p>
</div>
</div>
<!-- Card 2 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="A soft-focus light novel cover illustration depicting a high school library at dusk with golden sunlight filtering through windows. The style is painterly and nostalgic, featuring a single open book on a desk with a subtle glowing yellow aura. The atmosphere is quiet, scholarly, and sophisticated." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDvQEgaUQUKkbAvpt6h0W7EZoM9ZFop6FwTi2rgEROQ4Q4j3Xjke19SHnWwFMEQrDyq010_GsX78gWEPpgkNL6oytRjQURYPg8t_UfDKLI8snqf_5lQhP9Qp5ZKxaBBRIVFysHmQeq7DDbL7c5sD19WUeyU4816a_H4NXnxlVgbp-5akso2vK88DcwV3cktGswy0kRwi5PJAI2nhENy5FReeDtPYg7Dn97CaJuaROe8Z7g2XFZ04lfWTL2LxIo5hlEnEAZn9zrwPc-X"/>
<div class="absolute top-3 left-3 bg-secondary-container text-on-secondary-container px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Novel</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">Quiet Days in the Archive</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">Yuki Tanaka</p>
</div>
</div>
<!-- Card 3 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="Modern abstract digital art used as a book cover, featuring fluid golden lines resembling electrical currents flowing through a deep obsidian void. The lighting is high-contrast with intense yellow glows. The aesthetic is clean, futuristic, and tech-savvy, symbolizing the energy of learning." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDTWWWd4HU8CrU0X3VQL9LlxWrm_u8Pj120XrDPpIktp6czaNThPugOboJwINHJf3Dc3MrOjAyzjMhKw3iiE4HQHLTX7OpRvqXV9O5wzkjnLNu4B6pSVhrbzRRhl0R6Dk-nPOf6g-vLTEJcVYoOyCoPaY2nRiSsOFXteiTN0qs-pdNYR9RYUAquLt6TebA1_l9WrzIg8QwwarlEAZWXk2-Z_uEXbVXB1fBXuDPo-uKmUoRiojnNgHPpLaE2JPdN2OvoVYQXUlyEcZxO"/>
<div class="absolute top-3 left-3 bg-primary-fixed text-on-primary-fixed px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Manga</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">Circuit Breaker: Alpha</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">Studio Kaminari</p>
</div>
</div>
<!-- Card 4 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="A dark and moody fantasy novel cover with a mysterious figure holding a glowing yellow crystal. The background features deep purple and black mountain silhouettes under a stormy sky. The lighting from the crystal creates a sharp yellow illumination on the character's face, conveying mystery and focus." src="https://lh3.googleusercontent.com/aida-public/AB6AXuB994Hx2b2B8xnGMFRpOMTP7sle2p6ZeJMg-oMc2qJXILg-Rm3pwHJYTKHg-_Se8syd3OutxX1d0pr6L5sx-3S1z98lBuTLFRmk04kBvFgRil2Gs4BOLFzD4ltpo9u07fASDT9Pxl2I1I-0NUWiAy_32GWUkayYcplZiqq1ewAWPDZQtS1OQ7z84gEJv8ouQP8AF_oS279tDsJKEwfZsA0-MmnVtsD_NCI-4ZQmKyMEMOORFWXVM6JN05Edj0f4Ibbvno47TMtSv9Hl"/>
<div class="absolute top-3 left-3 bg-secondary-container text-on-secondary-container px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Novel</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">Secrets of the Storm</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">Rin Hashimoto</p>
</div>
</div>
<!-- Card 5 (Large Bento Style) -->
<div class="col-span-2 glass-card rounded-2xl overflow-hidden group relative">
<div class="flex h-48 md:h-64">
<div class="w-1/3 h-full overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="An artistic illustration of a traditional Japanese pagoda silhouetted against a futuristic yellow neon moon. The composition is asymmetrical and modern, using a limited palette of black, charcoal gray, and electric yellow. The mood is a perfect blend of tradition and high-tech efficiency." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBW-Wx4PRYjjoxywoVhVGO8ciy4JRywO717yoCLql0JFKF8vnxKt5159nuIqwefJBYV_D3HRpl50o0k0I7qKbyEvpZuEBAUiBnCTN6x_aTNDxJI3Dw4uanv7faACXlSv6qiND7sN4uziceuCxK7FmiiEi8hEdeU4pXQDcdRsWZsoD0dMVkmk4_qSQ0bObUhtpK3r48VjayUcUIPsJEvyuawW1Yd5cpw7xObvKg6lhiagZ8dqhmLVuz00Ek-hF4SXQEe0jm5cBW7xu6v"/>
</div>
<div class="w-2/3 p-6 flex flex-col justify-center space-y-2">
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary-fixed text-sm">stars</span>
<span class="text-primary-fixed font-label-sm-mono text-xs uppercase tracking-widest">Editor's Pick</span>
</div>
<h2 class="font-display-lg text-lg text-primary">Advanced Kanji Strategy: N1 Beyond</h2>
<p class="text-on-surface-variant text-sm line-clamp-2">Master complex readings with the lightning-fast mnemonic system designed for polyglots.</p>
<div class="pt-2 flex items-center gap-4">
<div class="flex items-center gap-1">
<span class="material-symbols-outlined text-primary-fixed text-xs" style="font-variation-settings: 'FILL' 1;">timer</span>
<span class="text-xs font-label-sm-mono text-on-surface-variant">12h left</span>
</div>
<button class="text-primary-fixed font-bold text-sm flex items-center gap-1 group/btn">
                                Read Now <span class="material-symbols-outlined text-sm group-hover/btn:translate-x-1 transition-transform">arrow_forward</span>
</button>
</div>
</div>
</div>
</div>
<!-- Card 6 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="A minimalist digital artwork featuring clean geometric lines and a vibrant yellow orb against a dark slate background. The image represents modern architectural precision and technical clarity, perfectly aligned with a tech-savvy audience and sleek dark-mode UI." src="https://lh3.googleusercontent.com/aida-public/AB6AXuArX2AJlhwKRN89bgMagboT4OZnVj-Twk6rfe966vIsEzXMldSLhqt9t29nXXPAWA0OIJ7f42VtU13ynH1b2-vZ86b_F9dOoLZ-ljWek9LWM8I8pCT21dQH0TmKyBKn1uakYpB-ELRbg1r-gr-QEKHzEom2EkYjgNk3UdliNNTdqB_OJdnVuTQvBON4geox6g1U_n0egG_8j78p8nAyf1xXQgIrHFCihI6i0rYblq-cYymIWY95Z_-xlkLmIMtXR27-lUJCch0pdKAD"/>
<div class="absolute top-3 left-3 bg-primary-fixed text-on-primary-fixed px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Manga</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">Neon Paradox</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">M. Arisaka</p>
</div>
</div>
<!-- Card 7 -->
<div class="glass-card rounded-2xl overflow-hidden group">
<div class="relative aspect-[3/4] overflow-hidden">
<img class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" data-alt="A dramatic book cover illustration of a lightning bolt striking a dark mountain peak. The lightning is a vivid, glowing yellow that cuts through the deep indigo and black shadows of the night. The visual is high-contrast, energetic, and powerful." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDNTulBYKvMkbqQP51xxv1CSKABqlvBygUAvx0hadXHle1fWs17c5iLGnFQJME-4U50G93mMEkCIq_kbUg7V77YkMYJhLO8c7jnQ3q0XsXdssakRjMME3V-NJfrYYz1XWI9RwS3b6tkVE0pFr7seeT81GYfrhKc9dV-HTMUj9K1CSna8LnzTxqDpKB2zFbs3e17bbR8e_gC0HdlesrHhpzmjEhkjgPJ8DMG6EUM0SB8RCbLwH-rLC6HUOLC9w5IfY0r-uoR6IrSQzcO"/>
<div class="absolute top-3 left-3 bg-secondary-container text-on-secondary-container px-3 py-1 rounded-full text-[10px] font-bold tracking-wider uppercase">Novel</div>
</div>
<div class="p-4 space-y-1">
<h3 class="font-headline-md text-sm text-primary leading-tight line-clamp-2">Voltage Horizon</h3>
<p class="text-on-surface-variant text-xs font-label-sm-mono">S. Kenji</p>
</div>
</div>
</div>
</main>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 w-full z-50 flex justify-around items-center h-20 px-2 pb-safe bg-surface-container-highest/80 dark:bg-surface-container-highest/80 backdrop-blur-xl border-t border-primary/10 shadow-[0_-4px_20px_rgba(0,0,0,0.5)] rounded-t-xl">
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all px-4 py-1 active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined">home</span>
<span class="font-label-sm-mono text-label-sm-mono">Home</span>
</a>
<a class="flex flex-col items-center justify-center text-primary-fixed bg-primary-container/20 rounded-xl px-4 py-1 active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">explore</span>
<span class="font-label-sm-mono text-label-sm-mono">Discover</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all px-4 py-1 active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined">bookmark</span>
<span class="font-label-sm-mono text-label-sm-mono">Favorites</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-variant/50 transition-all px-4 py-1 active:scale-90 duration-150" href="#">
<span class="material-symbols-outlined">history</span>
<span class="font-label-sm-mono text-label-sm-mono">History</span>
</a>
</nav>
</body></html>