/**
 * ARWOX Landing V3 — FloatingMessenger
 * Плавающая кнопка Telegram + бейдж «Ответим в течение 15 минут» (P2-4)
 */

"use client";

import { useState } from 'react';
import { X } from 'lucide-react';
import { goal } from "@/lib/ym";

/* ── Telegram SVG icon ── */
function TelegramIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
    >
      <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
    </svg>
  );
}

/* ── Main export ── */
export function FloatingMessenger() {
  const [dismissed, setDismissed] = useState(false);
  const [badgeVisible, setBadgeVisible] = useState(true);

  if (dismissed) return null;

  return (
    <div
      className="fixed bottom-6 right-5 z-50 flex flex-col items-end gap-2"
      role="complementary"
      aria-label="Связь через Telegram"
    >
      {/* Badge «Ответим в течение 15 минут» */}
      {badgeVisible && (
        <div
          className="relative flex items-center gap-2 rounded-2xl bg-white py-2 pl-3 pr-8 text-xs font-medium text-[#071A3F]"
          style={{
            boxShadow: '0 8px 32px rgba(0,75,160,.18)',
            maxWidth: '220px',
          }}
        >
          {/* Пульсирующая точка */}
          <span className="relative flex size-2 shrink-0">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75" />
            <span className="relative inline-flex size-2 rounded-full bg-green-500" />
          </span>
          Ответим в течение&nbsp;15&nbsp;минут

          {/* Кнопка закрытия бейджа */}
          <button
            onClick={() => setBadgeVisible(false)}
            className="absolute right-1.5 top-1.5 grid size-5 place-items-center rounded-full text-[#4B638A] hover:bg-[#EEF6FF] focus-visible:outline-none"
            aria-label="Скрыть подсказку"
          >
            <X className="size-3" />
          </button>
        </div>
      )}

      {/* Кнопка Telegram */}
      <div className="flex items-center gap-2">
        {/* Кнопка закрытия всего виджета */}
        <button
          onClick={() => setDismissed(true)}
          className="grid size-7 place-items-center rounded-full bg-white text-[#4B638A] shadow-md hover:bg-[#EEF6FF] focus-visible:outline-none"
          aria-label="Скрыть кнопку мессенджера"
        >
          <X className="size-3.5" />
        </button>

        <a
          href="https://t.me/arwox"
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => goal('tg_click')}
          aria-label="Написать в Telegram ARWOX"
          className="grid size-14 place-items-center rounded-full text-white transition-transform hover:scale-105 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] focus-visible:ring-offset-2 active:scale-95"
          style={{
            background: 'linear-gradient(135deg, #006DFF 0%, #229ED9 100%)',
            boxShadow: '0 8px 32px rgba(0,109,255,0.40)',
          }}
        >
          <TelegramIcon className="size-7" />
        </a>
      </div>
    </div>
  );
}
