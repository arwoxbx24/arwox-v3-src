"use client";

import { useEffect, useState } from "react";
import { Container, Reveal } from "@/components/landing/atoms";

/* ─── Data ───────────────────────────────────────────────────── */

interface Cert {
  id: number;
  /** Мини-превью (~30 KB) */
  thumb: string;
  /** Полная страница сертификата (для модалки) */
  full: string;
  title: string;
}

const CERTS: Cert[] = [
  { id: 1, thumb: "/assets/certs/cert1-thumb.png", full: "/assets/certs/cert1.png", title: "No-code в Битрикс24" },
  { id: 2, thumb: "/assets/certs/cert2-thumb.png", full: "/assets/certs/cert2.png", title: "Автоматизация цифровых рабочих мест" },
  { id: 3, thumb: "/assets/certs/cert3-thumb.png", full: "/assets/certs/cert3.png", title: "Курс партнёра Битрикс24" },
  { id: 4, thumb: "/assets/certs/cert4-thumb.png", full: "/assets/certs/cert4.png", title: "Автоматизация бизнес-процессов" },
  { id: 5, thumb: "/assets/certs/cert5-thumb.png", full: "/assets/certs/cert5.png", title: "Сертификат Битрикс24" },
  { id: 6, thumb: "/assets/certs/cert6-thumb.png", full: "/assets/certs/cert6.png", title: "Задачи и проекты" },
];

/* ─── Lightbox ──────────────────────────────────────────────── */

function Lightbox({ cert, onClose }: { cert: Cert; onClose: () => void }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-[100] grid place-items-center bg-[#081D3A]/80 p-4 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-label={cert.title}
      onClick={onClose}
    >
      <div
        className="relative max-h-[92vh] max-w-[720px] overflow-auto rounded-2xl bg-white p-2 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Закрыть"
          className="absolute right-3 top-3 z-10 grid size-9 place-items-center rounded-full bg-[#081D3A]/70 text-lg leading-none text-white transition-colors hover:bg-[#081D3A]"
        >
          ×
        </button>
        <img
          src={cert.full}
          alt={`Сертификат: ${cert.title}`}
          className="h-auto w-full rounded-xl"
          decoding="async"
        />
        <div className="px-3 py-2.5 text-center text-sm font-semibold text-[#081D3A]">
          {cert.title}
        </div>
      </div>
    </div>
  );
}

/* ─── Section ───────────────────────────────────────────────── */

export function Certificates() {
  const [open, setOpen] = useState<Cert | null>(null);

  return (
    <section id="certificates" className="bg-white py-14 md:py-20">
      <Container>
        <Reveal>
          <div className="mb-10 flex flex-col items-center text-center">
            <h2 className="text-3xl font-extrabold leading-tight text-[#081D3A] sm:text-4xl">
              Сертификаты и{" "}
              <span className="text-[#1677FF]">компетенции</span>
            </h2>
            <p className="mt-3 max-w-xl text-base leading-relaxed text-[#4B638A]">
              Сдаём официальные модули и курсы Битрикс24 — компетенции
              подтверждены сертификатами. Нажмите, чтобы посмотреть. Бизнес-партнёр Битрикс24 с 2021 года.
            </p>
          </div>
        </Reveal>

        {/* Мини-превью в один ряд */}
        <div className="grid grid-cols-3 gap-3 sm:gap-4 md:grid-cols-6">
          {CERTS.map((c, i) => (
            <Reveal key={c.id} delay={i * 50}>
              <button
                type="button"
                onClick={() => setOpen(c)}
                className="group block w-full overflow-hidden rounded-xl border border-[#E6ECF4] bg-white text-left shadow-[0_10px_30px_rgba(0,75,160,0.08)] transition-all hover:-translate-y-1 hover:shadow-[0_18px_45px_rgba(0,75,160,0.16)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#1677FF]"
                aria-label={`Открыть сертификат: ${c.title}`}
              >
                <img
                  src={c.thumb}
                  alt={`Сертификат: ${c.title}`}
                  className="aspect-[596/842] w-full bg-white object-contain object-top"
                  loading="lazy"
                  decoding="async"
                />
                <div className="border-t border-[#E6ECF4] px-2 py-2 text-center text-[11px] font-medium leading-tight text-[#4B638A] group-hover:text-[#081D3A]">
                  {c.title}
                </div>
              </button>
            </Reveal>
          ))}
        </div>
      </Container>

      {open && <Lightbox cert={open} onClose={() => setOpen(null)} />}
    </section>
  );
}
