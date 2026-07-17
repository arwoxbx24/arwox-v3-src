/**
 * ARWOX Landing V3 — CaseStudy Section
 * Санаторно-курортный комплекс
 * Ownership: CaseStudy.tsx
 */

import { Container, Pill, Reveal, Icon } from '@/components/landing/atoms';

/* ── Stat badges (5 ключевых метрик) ── */
interface StatBadge {
  icon: string;
  value: string;
  label: string;
  highlight?: boolean;
}

const STAT_BADGES: StatBadge[] = [
  { icon: 'clock', value: '30 дней', label: 'Срок внедрения' },
  { icon: 'crm_users', value: '50 человек', label: 'Команда клиента' },
  { icon: 'funnel', value: '1 окно', label: 'Все заявки в CRM', highlight: true },
  { icon: 'chart_up', value: 'real-time', label: 'Аналитика звонков', highlight: true },
  { icon: 'shield', value: '×0', label: 'Потерянных обращений', highlight: true },
];

/* ── Solution items ── */
const SOLUTION_ITEMS = [
  'Bitrix24 Коробка на 50 пользователей',
  'CRM + телефония: IP-шлюз и маршрутизация звонков',
  'Интеграция Marquiz для опросов + КИНТ',
  'Аналитика звонков в реальном времени',
];

/* ── Result items ── */
interface ResultItem {
  value: string;
  label: string;
}

const RESULT_ITEMS: ResultItem[] = [
  { value: '1 окно', label: 'Все заявки в единой CRM' },
  { value: 'real-time', label: 'Аналитика звонков для руководителя' },
  { value: '×0', label: 'Потерянных обращений' },
];

/* ── Main export ── */

export function CaseStudy() {
  return (
    <section id="case" className="bg-[#EEF6FF] py-16 md:py-20">
      <Container>
        <Reveal>
          <div
            className="overflow-hidden rounded-[32px] bg-white"
            style={{ boxShadow: '0 18px 55px rgba(0,75,160,.10)' }}
          >

            {/* ── TOP: 2-column split (photo left, text right) ── */}
            <div className="flex flex-col md:flex-row">

              {/* LEFT: Photo card with blue gradient overlay + badge */}
              <div className="relative md:w-[45%] min-h-[280px] md:min-h-[420px] shrink-0 overflow-hidden md:rounded-br-[0] rounded-t-[32px] md:rounded-tl-[32px] md:rounded-bl-[0] md:rounded-tr-[0]">
                <img
                  src="/assets/images/sanatorium.jpg"
                  alt="Санаторно-курортный комплекс"
                  className="absolute inset-0 w-full h-full object-cover"
                  loading="lazy"
                />
                {/* Blue gradient overlay (not black) */}
                <div
                  className="absolute inset-0"
                  style={{
                    background:
                      'linear-gradient(160deg, rgba(0,109,255,0.55) 0%, rgba(0,89,214,0.45) 40%, rgba(6,26,61,0.72) 100%)',
                  }}
                />

                {/* Badge top-left */}
                <div className="absolute top-5 left-5">
                  <div
                    className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold text-white backdrop-blur-sm"
                    style={{ background: 'rgba(0,109,255,0.55)', border: '1px solid rgba(255,255,255,0.25)' }}
                  >
                    <Icon name="shield" className="size-3.5 opacity-90" />
                    Санаторно-курортный комплекс
                  </div>
                </div>

                {/* Overlay title (bottom of image) */}
                <div className="absolute inset-0 flex flex-col justify-end p-6 md:p-8">
                  <p className="text-white/60 text-xs font-medium uppercase tracking-widest mb-2">
                    Bitrix24 Коробка · 50 пользователей
                  </p>
                </div>
              </div>

              {/* RIGHT: Text on white background */}
              <div className="flex flex-col justify-center gap-5 px-7 py-8 md:px-10 md:py-10 md:w-[55%]">

                {/* Pill header */}
                <div className="flex items-center gap-3">
                  <Pill>Кейс клиента</Pill>
                </div>

                {/* Title */}
                <h2
                  className="font-extrabold leading-snug"
                  style={{
                    fontSize: 'clamp(22px, 3vw, 32px)',
                    color: 'var(--color-text)',
                  }}
                >
                  Заявки в одном окне, менеджеры работают вместе,{' '}
                  <span className="text-gradient">за первый месяц ни одного потерянного обращения</span>
                </h2>

                {/* Solution items */}
                <ul className="space-y-2.5">
                  {SOLUTION_ITEMS.map((item, i) => (
                    <li key={i} className="flex gap-3 text-sm leading-snug" style={{ color: 'var(--color-text-muted)' }}>
                      <span
                        className="mt-[2px] size-5 shrink-0 rounded-full grid place-items-center text-white text-[10px] font-bold"
                        style={{ background: 'var(--gradient-brand)' }}
                      >
                        {i + 1}
                      </span>
                      {item}
                    </li>
                  ))}
                </ul>

                {/* Result highlights */}
                <div className="flex flex-wrap gap-x-6 gap-y-3 pt-1">
                  {RESULT_ITEMS.map((item, i) => (
                    <div key={i} className="flex items-baseline gap-2">
                      <p className="text-gradient text-2xl font-extrabold leading-none whitespace-nowrap">
                        {item.value}
                      </p>
                      <p className="text-xs leading-snug" style={{ color: 'var(--color-text-muted)' }}>
                        {item.label}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* ── STATS ROW: 5 badges ── */}
            <div
              className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 px-7 pt-6 pb-5 md:px-10"
              style={{ borderTop: '1px solid var(--color-border)' }}
            >
              {STAT_BADGES.map((badge) => (
                <div
                  key={badge.value}
                  className={`flex flex-col items-center gap-1.5 rounded-[20px] p-3 text-center transition-all duration-200 hover:-translate-y-0.5 ${
                    badge.highlight
                      ? 'border border-[var(--color-brand)]/20 bg-gradient-to-br from-[var(--color-brand)]/[0.06] to-[var(--color-brand-2)]/[0.06]'
                      : 'bg-[var(--surface-soft)] border border-[var(--color-border)]'
                  }`}
                >
                  <Icon
                    name={badge.icon}
                    className={`size-9 ${badge.highlight ? 'opacity-90' : 'opacity-55'}`}
                  />
                  <p
                    className={`font-extrabold text-lg leading-none ${
                      badge.highlight ? 'text-gradient' : 'text-foreground'
                    }`}
                  >
                    {badge.value}
                  </p>
                  <p className="text-[11px] leading-snug" style={{ color: 'var(--color-text-muted)' }}>
                    {badge.label}
                  </p>
                </div>
              ))}
            </div>

            {/* Footnote: период для ×0 (честная формулировка) */}
            <p className="px-7 md:px-10 pb-2 text-[11px] leading-snug" style={{ color: 'var(--color-text-muted)' }}>
              * За первый месяц после запуска потерянных обращений не зафиксировано.
            </p>

            {/* ── BODY: 3 columns (Задача / Решение / Результат) ── */}
            <div
              className="grid md:grid-cols-3 gap-6 px-7 py-7 md:px-10 md:py-8"
              style={{ borderTop: '1px solid var(--color-border)', background: '#F8FBFF' }}
            >

              {/* Column 1: Задача */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <span
                    className="size-9 rounded-[16px] grid place-items-center shrink-0"
                    style={{ background: 'rgba(0,109,255,0.10)' }}
                  >
                    <Icon name="shield" className="size-5 opacity-80" />
                  </span>
                  <h3
                    className="font-bold text-xs uppercase tracking-[0.1em]"
                    style={{ color: 'var(--color-primary)' }}
                  >
                    Задача
                  </h3>
                </div>
                <p className="text-sm leading-relaxed" style={{ color: 'var(--color-text-muted)' }}>
                  Заявки приходили в личные телефоны и почту, терялись. Менеджеры держали по 4 окна
                  одновременно. Руководитель не видел картину звонков и обращений.
                </p>
              </div>

              {/* Column 2: Решение */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <span
                    className="size-9 rounded-[16px] grid place-items-center shrink-0"
                    style={{ background: 'rgba(0,109,255,0.10)' }}
                  >
                    <Icon name="document" className="size-5 opacity-80" />
                  </span>
                  <h3
                    className="font-bold text-xs uppercase tracking-[0.1em]"
                    style={{ color: 'var(--color-primary)' }}
                  >
                    Решение
                  </h3>
                </div>
                <ul className="space-y-2">
                  {SOLUTION_ITEMS.map((item, i) => (
                    <li
                      key={i}
                      className="flex gap-2 text-sm leading-snug"
                      style={{ color: 'var(--color-text-muted)' }}
                    >
                      <span
                        className="mt-[3px] size-4 shrink-0 rounded-full grid place-items-center text-white text-[9px] font-bold"
                        style={{ background: 'var(--gradient-brand)' }}
                      >
                        {i + 1}
                      </span>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>

              {/* Column 3: Результаты */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <span
                    className="size-9 rounded-[16px] grid place-items-center shrink-0"
                    style={{ background: 'rgba(0,109,255,0.10)' }}
                  >
                    <Icon name="chart_up" className="size-5 opacity-80" />
                  </span>
                  <h3
                    className="font-bold text-xs uppercase tracking-[0.1em]"
                    style={{ color: 'var(--color-primary)' }}
                  >
                    Результаты
                  </h3>
                </div>
                <div className="space-y-3">
                  {RESULT_ITEMS.map((item, i) => (
                    <div key={i} className="flex items-start gap-3">
                      <p className="text-gradient text-2xl font-extrabold leading-none whitespace-nowrap">
                        {item.value}
                      </p>
                      <p className="text-sm leading-snug pt-0.5" style={{ color: 'var(--color-text-muted)' }}>
                        {item.label}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* ── QUOTE ── */}
            <div
              className="px-7 py-6 md:px-10"
              style={{ borderTop: '1px solid var(--color-border)', background: '#EEF6FF' }}
            >
              <div className="flex flex-wrap items-start gap-4">
                {/* Avatar with gradient ring */}
                <div
                  className="size-14 shrink-0 rounded-full grid place-items-center text-white text-base font-extrabold"
                  style={{
                    background: 'var(--gradient-brand)',
                    boxShadow: '0 4px 16px rgba(0,109,255,0.30)',
                  }}
                  aria-hidden="true"
                >
                  АК
                </div>
                <div className="flex-1 min-w-0">
                  <p
                    className="text-sm leading-relaxed italic"
                    style={{ color: 'var(--color-text)' }}
                  >
                    «Перестали терять обращения. Команда наконец-то работает в одном окне, а я вижу
                    картину звонков в реальном времени.»
                  </p>
                  <p className="mt-2 text-xs font-semibold" style={{ color: 'var(--color-text-muted)' }}>
                    Андрей К.{' '}
                    <span className="font-normal">· Руководитель, санаторно-курортный комплекс</span>
                  </p>
                </div>
              </div>
            </div>

          </div>
        </Reveal>

        <Reveal>
          <h3 className="text-xl font-bold mt-10 mb-6 text-center" style={{ color: 'var(--color-text)' }}>
            Другие проекты
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

            {/* Mini-card 1: КДП */}
            <div
              className="rounded-[20px] bg-white p-6"
              style={{ boxShadow: '0 18px 55px rgba(0,75,160,0.10)' }}
            >
              <span className="inline-block bg-[#EEF6FF] text-[#006DFF] text-xs font-semibold px-3 py-1 rounded-full">
                HR / Кадры
              </span>
              <h4 className="text-lg font-bold text-[#071A3F] mt-3">
                КДП: приём и оформление сотрудников
              </h4>
              <p className="text-sm text-[#4B638A] mt-2">
                У клиента (сеть общепита) не было кадрового отдела — приём сотрудников вёлся
                вручную через почту и бумажные документы. Собрали бизнес-требования с аналитиком,
                спроектировали сценарии и внедрили процесс в Битрикс24: пошаговый сбор документов,
                чек-листы и контроль этапов и сроков. Весь наём — в одном окне.
              </p>
              <p className="text-xs text-[#006DFF] mt-4 font-medium">
                Пошаговый сбор документов · Чек-листы · Контроль сроков
              </p>
            </div>

            {/* Mini-card 2: Окна Плюс */}
            <div
              className="rounded-[20px] bg-white p-6"
              style={{ boxShadow: '0 18px 55px rgba(0,75,160,0.10)' }}
            >
              <span className="inline-block bg-[#EEF6FF] text-[#006DFF] text-xs font-semibold px-3 py-1 rounded-full">
                Розница / 1С
              </span>
              <h4 className="text-lg font-bold text-[#071A3F] mt-3">
                Окна Плюс: переход с amoCRM на Битрикс24
              </h4>
              <p className="text-sm text-[#4B638A] mt-2">
                Компания по продаже отделочных материалов работала в amoCRM — не хватало
                функциональности. Перенесли данные в Битрикс24, настроили воронку продаж и
                производство, интегрировали 1С Фреш: счета и документы формируются из 1С и
                доступны прямо в таймлайне сделки. Вся работа — в одном продукте.
              </p>
              <p className="text-xs text-[#006DFF] mt-4 font-medium">
                Миграция из amoCRM · Воронка + производство · Интеграция 1С Фреш
              </p>
            </div>

          </div>
        </Reveal>
      </Container>
    </section>
  );
}
