"use client";

import { useEffect, useRef, useState, useCallback } from "react";

/* ─── Data ──────────────────────────────────────────────── */

interface KpiItem {
  prefix: string;
  target: number;
  suffix: string;
  isFloat: boolean;
  label: string;
  delta: string;
}

const KPI: KpiItem[] = [
  { prefix: "", target: 124, suffix: "", isFloat: false, label: "Лидов", delta: "↑ 18%" },
  { prefix: "", target: 38,  suffix: "", isFloat: false, label: "Сделок", delta: "↑ 12%" },
  { prefix: "", target: 31,  suffix: "%", isFloat: false, label: "Конверсия", delta: "↑ с 14%" },
  { prefix: "₽", target: 3.2, suffix: "М", isFloat: true, label: "Выручка", delta: "↑ 8%" },
];

const FUNNEL = [
  { label: "Новые",       count: 124, width: "100%" },
  { label: "Переговоры",  count: 52,  width: "42%" },
  { label: "Счёт",        count: 44,  width: "35%" },
  { label: "Закрыты",     count: 38,  width: "31%" },
] as const;

const BAR_HEIGHTS = [18, 22, 25, 30, 34, 40, 52, 70];

const ACTIVITIES = [
  {
    initials: "ИА",
    name: "Позвонить Иванову А.В.",
    deal: "Сделка: Внедрение CRM",
    time: "14:00",
    badge: "Скоро",
    badgeCls: "bg-amber-100 text-amber-700",
  },
  {
    initials: "П",
    name: "Отправить КП Петрову",
    deal: "Сделка: Интеграция 1С",
    time: "11:30",
    badge: "Готово",
    badgeCls: "bg-emerald-100 text-emerald-700",
  },
] as const;

/* ─── Animated Counter ───────────────────────────────────── */

function useCounter(target: number, active: boolean, isFloat: boolean, duration = 1200) {
  const [value, setValue] = useState(0);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    if (!active) return;
    let startTs: number | null = null;

    const tick = (ts: number) => {
      if (!startTs) startTs = ts;
      const elapsed = ts - startTs;
      const progress = Math.min(elapsed / duration, 1);
      // easeOutQuart
      const eased = 1 - Math.pow(1 - progress, 4);
      setValue(eased * target);
      if (progress < 1) rafRef.current = requestAnimationFrame(tick);
      else setValue(target);
    };

    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, [active, target, duration]);

  return isFloat ? value.toFixed(1) : String(Math.round(value));
}

function KpiCard({ item, active }: { item: KpiItem; active: boolean }) {
  const display = useCounter(item.target, active, item.isFloat);

  return (
    <div className="rounded-xl p-3" style={{ background: "#F0F6FF" }}>
      <div className="text-xl font-bold leading-tight sm:text-2xl text-[#071A3F]">
        {item.prefix}
        {display}
        {item.suffix}
      </div>
      <div className="mt-0.5 text-[11px] text-[#4B638A]">{item.label}</div>
      <div className="text-[11px] text-emerald-600 font-medium">{item.delta}</div>
    </div>
  );
}

/* ─── Main Component ─────────────────────────────────────── */

export function DashboardMock() {
  const rootRef = useRef<HTMLDivElement>(null);
  const [active, setActive] = useState(false);
  const [tilt, setTilt] = useState({ x: 0, y: 0 });
  const [hovered, setHovered] = useState(false);

  useEffect(() => {
    const el = rootRef.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setActive(true);
          obs.unobserve(el);
        }
      },
      { threshold: 0.15 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  const handleMouseMove = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    const el = rootRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    setTilt({
      x: ((e.clientY - cy) / (rect.height / 2)) * -4,
      y: ((e.clientX - cx) / (rect.width / 2)) * 5,
    });
  }, []);

  const handleMouseLeave = useCallback(() => {
    setTilt({ x: 0, y: 0 });
    setHovered(false);
  }, []);

  const handleMouseEnter = useCallback(() => setHovered(true), []);

  return (
    <div
      ref={rootRef}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      onMouseEnter={handleMouseEnter}
      className="overflow-hidden rounded-[28px]"
      style={{
        background: "rgba(255, 255, 255, 0.88)",
        backdropFilter: "blur(24px)",
        WebkitBackdropFilter: "blur(24px)",
        border: "1px solid rgba(0, 109, 255, 0.14)",
        padding: "10px",
        transform: `perspective(1200px) rotateX(${6 + tilt.x}deg) rotateY(${-3 + tilt.y}deg) translateZ(0)`,
        transition: hovered
          ? "transform 90ms ease, box-shadow 90ms ease"
          : "transform 700ms cubic-bezier(0.16,1,0.3,1), box-shadow 700ms ease",
        boxShadow: [
          "0 18px 55px rgba(0,75,160,0.10)",
          "0 8px 24px rgba(0,109,255,0.08)",
          "0 0 0 1px rgba(0,109,255,0.05)",
          "inset 0 1px 0 rgba(255,255,255,0.95)",
        ].join(","),
      }}
    >
      <div
        className="rounded-2xl p-4 sm:p-5"
        style={{ background: "#FFFFFF" }}
      >
        {/* ── Title bar ── */}
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-1.5" aria-hidden="true">
            <span className="size-3 rounded-full bg-[#ff5f57]" />
            <span className="size-3 rounded-full bg-[#febc2e]" />
            <span className="size-3 rounded-full bg-[#28c840]" />
          </div>
          <div className="text-xs font-medium text-[#4B638A]">
            Битрикс24 · демо-дашборд
          </div>
          <div className="inline-flex items-center gap-1.5 rounded-full bg-[#EEF6FF] px-2 py-0.5 text-[10px] font-semibold text-[#4B638A]">
            <span className="size-1.5 rounded-full bg-[#006DFF] animate-pulse" aria-hidden="true" />
            Демо · данные условные
          </div>
        </div>

        {/* ── KPI row ── */}
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
          {KPI.map((k) => (
            <KpiCard key={k.label} item={k} active={active} />
          ))}
        </div>

        {/* ── Funnel ── */}
        <div className="mt-4 rounded-xl p-3 sm:p-4" style={{ background: "#F4F8FF" }}>
          <div className="mb-3 flex justify-between text-xs">
            <span className="font-semibold text-[#071A3F]">ВОРОНКА ПРОДАЖ</span>
            <span className="text-[#006DFF] font-medium">124 → 38 сделок</span>
          </div>
          <div className="space-y-2">
            {FUNNEL.map((row, i) => (
              <div key={row.label} className="flex items-center gap-2 text-xs">
                <div className="w-[88px] shrink-0 text-[#4B638A]">
                  {row.label} ({row.count})
                </div>
                <div className="h-2 flex-1 overflow-hidden rounded-full bg-[#D9E8FF]">
                  <div
                    className="h-full rounded-full bg-gradient-brand transition-[width] ease-out"
                    style={{
                      width: active ? row.width : "0%",
                      transitionDuration: "700ms",
                      transitionDelay: `${i * 120}ms`,
                    }}
                    role="progressbar"
                    aria-valuenow={parseInt(row.width)}
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-label={row.label}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── Bottom panels ── */}
        <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {/* Bar chart */}
          <div className="rounded-xl p-3 sm:p-4" style={{ background: "#F4F8FF" }}>
            <div className="mb-2 flex justify-between text-xs">
              <span className="text-[#4B638A]">КОНВЕРСИЯ ПО МЕСЯЦАМ</span>
              <span className="text-[#006DFF] font-medium">+122% за год</span>
            </div>
            <div className="flex h-24 items-end gap-1" aria-label="Столбчатый график конверсии">
              {BAR_HEIGHTS.map((h, i) => (
                <div
                  key={i}
                  className="flex-1 rounded-t bg-gradient-brand transition-[height] ease-out"
                  style={{
                    height: active ? `${h}%` : "0%",
                    transitionDuration: "500ms",
                    transitionDelay: `${400 + i * 60}ms`,
                  }}
                  aria-hidden="true"
                />
              ))}
            </div>
            <div className="mt-1 flex justify-between text-[10px] text-[#4B638A]">
              <span>Ноя</span>
              <span>Май</span>
            </div>
          </div>

          {/* Donut chart */}
          <div className="rounded-xl p-3 sm:p-4" style={{ background: "#F4F8FF" }}>
            <div className="mb-2 text-xs text-[#4B638A]">ЗАДАЧИ КОМАНДЫ</div>
            <div className="flex items-center gap-4">
              <div
                className="relative grid size-20 shrink-0 place-items-center rounded-full"
                role="img"
                aria-label="Диаграмма задач: 72% выполнено, 18% в работе, 10% просрочено"
                style={{
                  background:
                    "conic-gradient(#006DFF 0% 72%, #00B7FF 72% 90%, #f43f5e 90% 100%)",
                }}
              >
                <div
                  className="grid size-[52px] place-items-center rounded-full text-sm font-bold text-[#071A3F]"
                  style={{ background: "#FFFFFF" }}
                >
                  72%
                </div>
              </div>
              <div className="space-y-1.5 text-xs text-[#4B638A]">
                <div className="flex items-center gap-2">
                  <span className="size-2 shrink-0 rounded-full bg-[#006DFF]" />
                  Выполнено 72%
                </div>
                <div className="flex items-center gap-2">
                  <span className="size-2 shrink-0 rounded-full bg-[#00B7FF]" />
                  В работе 18%
                </div>
                <div className="flex items-center gap-2">
                  <span className="size-2 shrink-0 rounded-full bg-rose-400" />
                  Просрочено 10%
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── Activity ── */}
        <div className="mt-4 rounded-xl p-3 sm:p-4" style={{ background: "#F4F8FF" }}>
          <div className="mb-3 text-xs font-semibold text-[#071A3F]">
            АКТИВНОСТЬ СЕГОДНЯ
          </div>
          <div className="space-y-2">
            {ACTIVITIES.map((a) => (
              <div
                key={a.name}
                className="flex items-center justify-between rounded-lg p-2 text-xs"
                style={{ background: "rgba(255,255,255,0.75)" }}
              >
                <div className="flex min-w-0 items-center gap-2">
                  <div className="grid size-7 shrink-0 place-items-center rounded-full bg-gradient-brand text-[10px] font-bold text-white">
                    {a.initials}
                  </div>
                  <div className="min-w-0">
                    <div className="truncate font-medium text-[#071A3F]">{a.name}</div>
                    <div className="truncate text-[10px] text-[#4B638A]">
                      {a.deal}
                    </div>
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-1.5 pl-2">
                  <span className="text-[#4B638A]">Сегодня {a.time}</span>
                  <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${a.badgeCls}`}>
                    {a.badge}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
