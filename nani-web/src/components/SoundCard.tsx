'use client';

interface SoundCardProps {
  jp: string;
  name: string;
  desc: string;
  audioSrc: string;
}

export default function SoundCard({ jp, name, desc, audioSrc }: SoundCardProps) {
  const handleMouseEnter = () => {
    const audio = new Audio(audioSrc);
    audio.play().catch(() => {
      // Silently catch autoplay policy errors so they don't flood the terminal or browser console
    });
  };

  return (
    <div className="brutal-panel sound-item" onMouseEnter={handleMouseEnter}>
      <span className="s-jp-large">{jp}</span>
      <span className="s-name">{name}</span>
      <span className="s-desc">{desc}</span>
    </div>
  );
}
