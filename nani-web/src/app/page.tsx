'use client';

import { useEffect, useRef, useState } from 'react';
import ThemeToggle from '@/components/ThemeToggle';
import SoundCard from '@/components/SoundCard';

const SOUNDS = [
  { jp: '頑張れ', name: 'GAMBARE!', desc: 'Do your best!', audioSrc: '/sounds/gambare_gambare.mp3' },
  { jp: '凄い', name: 'SUGOI!', desc: 'Amazing!', audioSrc: '/sounds/anime_wow.mp3' },
  { jp: '先輩', name: 'SENPAI!', desc: 'Notice me', audioSrc: '/sounds/anime_girl_senpai.mp3' },
  { jp: '可愛い', name: 'KAWAII!', desc: 'Cute!', audioSrc: '/sounds/wow_cute_anime.mp3' },
  { jp: 'くる', name: 'KURU KURU!', desc: 'Spinning~', audioSrc: '/sounds/kuru_kuru.mp3' },
  { jp: 'やめて', name: 'YAMETE!', desc: 'Stop it', audioSrc: '/sounds/yamete_kudasai.mp3' },
  { jp: 'トゥッ', name: 'TUTURU!', desc: 'Mayuri~', audioSrc: '/sounds/tuturu.mp3' },
  { jp: '弱いも', name: 'YOWAI MO!', desc: "You're weak!", audioSrc: '/sounds/yowai_mo.mp3' },
];

export default function Home() {
  const progressBarRef = useRef<HTMLDivElement>(null);
  const [interacted, setInteracted] = useState(false);

  useEffect(() => {
    // Detect user interaction to satisfy Audio Autoplay policies
    const handleInteraction = () => setInteracted(true);
    window.addEventListener('click', handleInteraction, { once: true });
    window.addEventListener('keydown', handleInteraction, { once: true });

    // Scroll progress bar
    const updateProgress = () => {
      if (!progressBarRef.current) return;
      const scrollTop = window.scrollY;
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const pct = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
      progressBarRef.current.style.width = `${pct}%`;
    };

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress();

    // Scroll reveal observer
    const revealElements = document.querySelectorAll('.reveal');
    const revealObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('active');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

    revealElements.forEach(el => revealObserver.observe(el));

    return () => {
      window.removeEventListener('scroll', updateProgress);
      window.removeEventListener('click', handleInteraction);
      window.removeEventListener('keydown', handleInteraction);
      revealObserver.disconnect();
    };
  }, []);

  return (
    <>
      <div className="scroll-progress" id="scrollProgress" ref={progressBarRef}></div>
      <div className="manga-paper"></div>
      <div className="jp-watermark" style={{ top: '10%', right: '-5%' }}>ナニ？！</div>
      <div className="jp-watermark" style={{ top: '60%', left: '-5%' }}>すごい</div>

      {/* Audio Interaction Hint */}
      {!interacted && (
        <div style={{ position: 'fixed', bottom: 16, right: 16, background: 'var(--ink)', color: 'var(--paper-bg)', padding: '8px 16px', zIndex: 1000, fontFamily: 'var(--font-mono)', fontSize: 12, boxShadow: 'var(--shadow-solid)', border: '2px solid var(--border-ink)' }}>
          Click anywhere to enable audio
        </div>
      )}

      {/* Header */}
      <header>
        <a href="#" className="logo">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="app-icon" src="/assets/app-icon.png" alt="Nani app icon" />
          Nani
        </a>
        <nav>
          <a href="#features"><span className="nav-jp">特徴</span>Features</a>
          <a href="#sounds"><span className="nav-jp">音</span>Library</a>
          <a href="https://github.com/iamvibecoding/Nani" target="_blank" rel="noopener noreferrer"><span className="nav-jp">源</span>GitHub</a>
        </nav>
        <div className="header-actions">
          <ThemeToggle />
        </div>
      </header>

      {/* Hero Section */}
      <section id="hero">
        <div className="action-lines" aria-hidden="true"></div>
        <span className="manga-sfx" style={{ fontSize: '96px', top: '18%', left: '3%' }} aria-hidden="true">ドーン!</span>
        <span className="manga-sfx" style={{ fontSize: '140px', top: '58%', right: '2%', animationDelay: '1.2s' }} aria-hidden="true">ビシッ</span>
        <span className="manga-sfx" style={{ fontSize: '72px', bottom: '12%', left: '38%', animationDelay: '2.1s' }} aria-hidden="true">ズキン</span>
        <div className="container hero-grid">
          <div className="hero-content reveal">
            <h1 className="hero-headline">Your Mac<br/><em>speaks</em> anime.</h1>
            <p className="hero-lead">Nani is a hyper-native macOS app. Plug a cable. Hear anime. Unplug. Hear anime. Zero bloat, pure adrenaline.</p>

            <div className="hero-actions">
              <a href="#download" className="btn-mega">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Get Nani Free
              </a>
              <a href="#sounds" className="btn-outline">
                View Sounds
              </a>
            </div>
          </div>

          <div className="hero-visual reveal">
            <div className="console-card brutal-panel-static">
              
              <div className="port-row">
                 <div className="port-left">
                   <svg className="port-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2a3 3 0 0 0-3 3v2.5l-2 4V14h10v-2.5l-2-4V5a3 3 0 0 0-3-3z"/><line x1="12" y1="22" x2="12" y2="14"/></svg>
                   <h3>USB-C</h3>
                 </div>
                 <div className="sfx-tag">何?!</div>
              </div>

              <div className="port-row">
                 <div className="port-left">
                   <svg className="port-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="7" width="20" height="10" rx="2"/><line x1="6" y1="12" x2="18" y2="12"/></svg>
                   <h3>HDMI</h3>
                 </div>
                 <div className="sfx-tag">すごい!</div>
              </div>

              <div className="port-row" style={{ marginBottom: 0 }}>
                 <div className="port-left">
                   <svg className="port-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>
                   <h3>AUDIO</h3>
                 </div>
                 <div className="sfx-tag">かわいい</div>
              </div>

            </div>
          </div>
        </div>
      </section>

      {/* Sound Ticker Marquee */}
      <div className="sound-ticker" aria-label="Sound library ticker">
        <div className="ticker-track">
          {SOUNDS.map((sound, i) => (
            <span key={i} className="ticker-item"><span className="jp">{sound.jp}！</span> {sound.name}</span>
          ))}
          {/* Duplicated for seamless loop */}
          {SOUNDS.map((sound, i) => (
            <span key={`dup-${i}`} className="ticker-item"><span className="jp">{sound.jp}！</span> {sound.name}</span>
          ))}
        </div>
      </div>

      {/* Features Section */}
      <section id="features">
        <div className="container">
          <div className="reveal">
            <h2 className="section-title">System <em>Specs</em></h2>
            <p className="section-desc">Nani intercepts macOS hardware events at the system level. It is completely native, incredibly fast, and brutally simple.</p>
          </div>

          <div className="features-grid">
            <div className="feat-card brutal-panel large reveal" data-reveal="left" style={{ '--reveal-i': 0 } as React.CSSProperties}>
              <svg className="feat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2a3 3 0 0 0-3 3v2.5l-2 4V14h10v-2.5l-2-4V5a3 3 0 0 0-3-3z"/><line x1="12" y1="22" x2="12" y2="14"/></svg>
              <h3>Universal Sync</h3>
              <p>Real-time detection for USB-C, USB-A, HDMI, audio jacks, and MagSafe. Plug anything in, and Nani reacts instantly.</p>
            </div>

            <div className="feat-card brutal-panel small reveal" data-reveal="scale" style={{ '--reveal-i': 1 } as React.CSSProperties}>
              <svg className="feat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
              <h3>Studio FX</h3>
              <p>30+ pristine, copyright-free anime reactions built-in.</p>
            </div>

            <div className="feat-card brutal-panel small reveal" data-reveal="scale" style={{ '--reveal-i': 2 } as React.CSSProperties}>
              <svg className="feat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="10" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
              <h3>Full Control</h3>
              <p>Import custom .mp3 or .wav files for absolute personalization.</p>
            </div>

            <div className="feat-card brutal-panel large reveal" data-reveal="right" style={{ '--reveal-i': 3 } as React.CSSProperties}>
              <svg className="feat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>
              <h3>Hyper Native</h3>
              <p>A native Swift application that sips power. It lives quietly in your menu bar using under 12MB of RAM when idle.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Dynamic Sounds Section */}
      <section id="sounds">
        <div className="container">
          <div className="reveal">
            <h2 className="section-title">Sound <em>Arsenal</em></h2>
            <p className="section-desc">A glimpse at the built-in library. Hover over the cards to hear the anime reactions.</p>
          </div>
          
          <div className="sound-grid reveal">
            {SOUNDS.map((sound) => (
              <SoundCard 
                key={sound.name}
                jp={sound.jp}
                name={sound.name}
                desc={sound.desc}
                audioSrc={sound.audioSrc}
              />
            ))}
          </div>
        </div>
      </section>

      {/* Giant Download CTA */}
      <section id="download">
        <div className="container reveal">
          <div className="giant-cta brutal-panel-static">
            <h2>DOWNLOAD FREE</h2>
            
            <div className="hero-actions" style={{ justifyContent: 'center', marginBottom: '12px', gap: '16px', display: 'flex', flexWrap: 'wrap' }}>
              <a href="/Nani_1.0.0.zip" download className="btn-mega">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Download .zip
              </a>
              <a href="https://github.com/iamvibecoding/Nani/releases" target="_blank" rel="noopener noreferrer" className="btn-outline" style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '1.1rem', padding: '12px 24px' }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22"></path></svg>
                GitHub Releases
              </a>
            </div>
            
            <div style={{ background: 'var(--bg)', padding: '16px', borderRadius: '4px', border: '2px dashed var(--border-ink)', maxWidth: '420px', margin: '0 auto 24px auto', textAlign: 'left', fontSize: '0.85rem' }}>
              <h4 style={{ margin: '0 0 8px 0', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                How to Open (macOS)
              </h4>
              <p style={{ margin: '0 0 8px 0', opacity: 0.8 }}>Because Nani is an indie app, macOS may show a warning on first launch. To easily bypass this:</p>
              <ol style={{ margin: 0, paddingLeft: '20px', opacity: 0.8 }}>
                <li style={{ marginBottom: '4px' }}>When the alert pops up, click the <strong>? (Help) icon</strong> in the top right.</li>
                <li style={{ marginBottom: '4px' }}>Click the link in the help window to open <strong>Privacy &amp; Security Settings</strong>.</li>
                <li>Scroll down and click <strong>"Open Anyway"</strong> (you only have to do this once).</li>
              </ol>
            </div>

            <p className="cta-meta">macOS 13+ required. No subscriptions.</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer>
        <div className="container footer-grid reveal">
          <div className="footer-brand">
            <a href="#" className="logo">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img className="app-icon" src="/assets/app-icon.png" alt="Nani app icon" />
              Nani
            </a>
            <p>A hyper-native macOS utility designed to inject pure anime joy into the mundane act of connecting cables.</p>
            <span className="footer-jp">電源ケーブル接続システム</span>
          </div>
          <div className="footer-col">
            <h4 data-jp="道">Navigation</h4>
            <a href="#features">System Specs</a>
            <a href="#sounds">Sound Arsenal</a>
            <a href="#download">Download App</a>
          </div>
          <div className="footer-col">
            <h4 data-jp="伝">Transmission</h4>
            <a href="https://github.com/iamvibecoding/Nani" target="_blank" rel="noopener noreferrer">GitHub Source</a>
            <a href="https://x.com/iamvibecoder" target="_blank" rel="noopener noreferrer">X (Twitter)</a>
            <a href="https://github.com/iamvibecoding/Nani/issues/new?labels=bug&title=Bug%3A+" target="_blank" rel="noopener noreferrer">Bug Report</a>
            <a href="https://github.com/iamvibecoding/Nani/issues/new?labels=enhancement&title=Feature%3A+" target="_blank" rel="noopener noreferrer">Feature Request</a>
          </div>
        </div>
        <div className="container footer-bottom">
          <span className="footer-tagline">完全自動・接続完了・おつかれさま</span>
          <span className="footer-stamp">NAMI 01 // 電</span>
        </div>
      </footer>
    </>
  );
}
