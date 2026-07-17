/**
 * ARWOX Landing V3 — Results Section
 * «Что меняется после внедрения Битрикс24»
 * Ownership: Results.tsx
 * Текст — дословно из designland (landing_text_content.md + OCR result-карточек).
 */

import { Container, SectionTitle, Reveal } from '@/components/landing/atoms';

/* ── Данные: 3 короткие результат-карточки ── */
interface ResultCard {
  icon: string;
  title: string;
  desc: string;
  metric: string;
  metricLabel: string;
  positive: boolean;
}

const RESULT_CARDS: ResultCard[] = [
  {
    icon: '/assets/gen/ic3d-growth.png',
    title: 'Рост продаж',
    desc: 'Прозрачная воронка и контроль каждой сделки увеличивают конверсию и средний чек.',
    metric: '+47%',
    metricLabel: 'рост конверсии',
    positive: true,
  },
  {
    icon: '/assets/gen/ic3d-time.png',
    title: 'Экономия времени',
    desc: 'Автоматизация задач и процессов ускоряет работу команды в 2–3 раза.',
    metric: '−32%',
    metricLabel: 'рутины и ручных задач',
    positive: false,
  },
  {
    icon: '/assets/gen/ic3d-data.png',
    title: 'Точные данные',
    desc: 'Аналитика в реальном времени — принимайте решения на основе фактов, а не ощущений.',
    metric: '+28%',
    metricLabel: 'точности планирования',
    positive: true,
  },
];

/* ── Данные: 3 подробных сценария ── */
interface ScenarioMetric {
  value: string;
  label: string;
  was?: string;
}
interface Scenario {
  num: string;
  icon: string;
  problem: string;
  desc: string;
  baseValue: string;
  baseLabel: string;
  didHead: string;
  steps: string[];
  period: string;
  resultHead: string;
  metrics: ScenarioMetric[];
  spinQuestion: string;
}

const SCENARIOS: Scenario[] = [
  {
    num: '01',
    icon: '/assets/gen/ic3d-analytics.png',
    problem: 'Лиды теряются на трёх этапах воронки',
    desc: 'Клиент приходит с жалобой: конверсия 14%, заявки ведут в Excel, ответственные не назначены, повторных звонков нет. Руководитель не видит, на каком этапе обрываются продажи.',
    baseValue: '14%',
    baseLabel: 'конверсия лид → сделка',
    didHead: 'CRM-воронка с автоматическими задачами на каждом шаге',
    steps: [
      'Настроили воронку под реальный цикл продаж — от первой заявки до закрытия',
      'Роботы ставят задачи, напоминают о звонках, автоматически создают счета',
      'Руководитель видит каждый лид и его статус в реальном времени',
    ],
    period: 'Итог — через 90 дней',
    resultHead: 'Конверсия выросла в 2,2 раза',
    metrics: [
      { value: '31%', label: 'конверсия', was: 'было 14%' },
      { value: '16 дн', label: 'закрытие', was: 'было 28 дней' },
    ],
    spinQuestion: 'Посчитайте: сколько заявок в месяц у вас доходит до счёта — и сколько «повисает» без ответственного?',
  },
  {
    num: '02',
    icon: '/assets/gen/ic3d-whatsapp.png',
    problem: 'Заявки из WhatsApp, сайта и Авито теряются',
    desc: 'Обращения поступают в разные места — телефон, почта, мессенджеры. Часть теряется, часть обрабатывается спустя часы. Клиент успевает уйти к конкуренту.',
    baseValue: '3–4 ч',
    baseLabel: 'среднее время первого ответа',
    didHead: 'Все каналы — в единую воронку через Open Channels',
    steps: [
      'Подключили WhatsApp, Telegram, форму сайта и Авито через Open Channels Битрикс24',
      'Каждое обращение автоматически создаёт лид и назначает ответственного',
      'Бот мгновенно отвечает клиенту и ставит задачу менеджеру с дедлайном',
    ],
    period: 'Итог — через 60 дней',
    resultHead: 'Скорость ответа выросла в 13 раз',
    metrics: [
      { value: '18 мин', label: 'первый ответ', was: 'было 3–4 ч' },
      { value: '+23%', label: 'конв. первого контакта', was: 'к базовому периоду' },
    ],
    spinQuestion: 'Клиент, которому не ответили за час, уже пишет вашему конкуренту. Сколько таких за месяц?',
  },
  {
    num: '03',
    icon: '/assets/gen/ic3d-robot.png',
    problem: 'Нет контроля: сотрудники работают хаотично',
    desc: 'Регламенты не соблюдаются, документы не прикладываются. Руководитель не понимает, где сотрудник «застрял» и как объективно оценить эффективность команды.',
    baseValue: '0',
    baseLabel: 'видимость работы команды',
    didHead: 'Прозрачные процессы и единые регламенты для команды',
    steps: [
      'Внедрили регламенты и шаблоны бизнес-процессов в Битрикс24',
      'Подключили контроль задач, дедлайнов и автоматические напоминания',
      'Настроили дашборды эффективности: руководитель видит загрузку каждого',
    ],
    period: 'Итог — через 75 дней',
    resultHead: 'Команда работает в едином ритме',
    metrics: [
      { value: '+35%', label: 'продуктивность' },
      { value: '−50%', label: 'время на поиск инфо' },
    ],
    spinQuestion: 'Сколько часов в неделю вы тратите, выясняя «кто чем занят», вместо управления?',
  },
];

const SCENARIO_DISCLAIMER =
  '* Замер выполняется после корректного внедрения. Результат зависит от специфики бизнеса и не является гарантией.';

const CARDS_FOOTNOTE =
  '* Усреднённые показатели по нашим сценариям внедрения. Результат зависит от бизнеса и не является гарантией. ' +
  'Замеры проводятся после корректного внедрения: разрабатываем ТЗ на сбор аналитики, фиксируем базовые показатели и измеряем динамику на дистанции. ' +
  'Примеры показателей, возможных к измерению после внедрения (зависит от бизнеса): ' +
  'снижение пропущенных звонков; качество отработки звонков менеджерами — видит руководитель; ' +
  'снижение потерянных заявок; все источники заявок в одном окне; ' +
  'число заявок по источникам за месяц/год; ROI; стоимость обращения.';

/* ── Карточка результата ── */
function ResultSummaryCard({ card, delay }: { card: ResultCard; delay: number }) {
  return (
    <Reveal delay={delay}>
      <article
        className="flex h-full flex-col rounded-[24px] bg-white p-6"
        style={{ boxShadow: '0 18px 55px rgba(0,75,160,.10)' }}
      >
        <div className="flex items-center gap-3">
          <span className="grid size-16 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
            <img src={card.icon} alt="" aria-hidden="true" width={52} height={52} className="size-13 select-none object-contain" loading="lazy" decoding="async" />
          </span>
          <h3 className="text-lg font-bold text-[#071A3F]">{card.title}</h3>
        </div>
        <p className="mt-3 text-sm leading-relaxed text-[#4B638A]">{card.desc}</p>
        <div className="mt-auto flex items-baseline gap-2 pt-5">
          <span
            className="text-[34px] font-extrabold leading-none"
            style={{ color: card.positive ? '#006DFF' : '#22C55E' }}
          >
            {card.metric}<sup className="text-lg font-semibold align-super">*</sup>
          </span>
          <span className="text-sm text-[#4B638A]">{card.metricLabel}</span>
        </div>
      </article>
    </Reveal>
  );
}

/* ── Карточка сценария ── */
function ScenarioCard({ s, delay }: { s: Scenario; delay: number }) {
  return (
    <Reveal delay={delay}>
      <article
        className="flex h-full flex-col rounded-[28px] bg-white p-6 md:p-7"
        style={{ boxShadow: '0 18px 55px rgba(0,75,160,.10)' }}
      >
        {/* Шапка: номер + иконка */}
        <div className="flex items-center justify-between">
          <span
            className="grid size-11 shrink-0 place-items-center rounded-xl text-sm font-extrabold text-white"
            style={{ background: 'linear-gradient(135deg,#006DFF 0%,#1677FF 52%,#8B5CF6 100%)' }}
          >
            {s.num}
          </span>
          <img src={s.icon} alt="" aria-hidden="true" width={52} height={52} className="size-13 select-none object-contain" loading="lazy" decoding="async" />
        </div>

        {/* Проблема */}
        <p className="mt-4 text-[11px] font-semibold uppercase tracking-wider text-[#006DFF]">
          Проблема
        </p>
        <h3 className="mt-1 text-xl font-bold leading-snug text-[#071A3F]">{s.problem}</h3>
        <p className="mt-2 text-sm leading-relaxed text-[#4B638A]">{s.desc}</p>

        {/* SPIN-вопрос */}
        <blockquote className="mt-4 border-l-[3px] border-[#006DFF] pl-4 py-1">
          <p className="text-sm italic leading-relaxed text-[#4B638A]">{s.spinQuestion}</p>
        </blockquote>

        {/* Базовый замер */}
        <div className="mt-4 rounded-2xl bg-[#EEF6FF] px-4 py-3">
          <div className="text-[11px] uppercase tracking-wider text-[#4B638A]">
            Базовый замер — до
          </div>
          <div className="mt-0.5 flex items-baseline gap-2">
            <span className="text-2xl font-extrabold text-[#071A3F]">{s.baseValue}</span>
            <span className="text-xs text-[#4B638A]">{s.baseLabel}</span>
          </div>
        </div>

        {/* Что сделали */}
        <p className="mt-5 text-sm font-semibold text-[#071A3F]">Что сделали</p>
        <p className="mt-1 text-sm font-medium text-[#006DFF]">{s.didHead}</p>
        <ol className="mt-3 flex flex-col gap-2.5">
          {s.steps.map((step, i) => (
            <li key={step} className="flex gap-2.5 text-sm leading-snug text-[#334665]">
              <span
                className="grid size-5 shrink-0 place-items-center rounded-full text-[11px] font-bold text-white"
                style={{ background: '#006DFF' }}
              >
                {i + 1}
              </span>
              {step}
            </li>
          ))}
        </ol>

        {/* Итог */}
        <div
          className="mt-auto rounded-2xl border p-4"
          style={{
            borderColor: 'rgba(0,109,255,0.18)',
            background: 'linear-gradient(135deg,rgba(0,109,255,0.06),rgba(139,92,246,0.06))',
          }}
        >
          <div className="text-[11px] uppercase tracking-wider text-[#4B638A]">{s.period}</div>
          <p className="mt-0.5 text-sm font-bold text-[#071A3F]">{s.resultHead}</p>
          <div className="mt-3 flex gap-6">
            {s.metrics.map((m) => (
              <div key={m.label}>
                <div className="text-2xl font-extrabold text-[#006DFF]">{m.value}</div>
                <div className="text-xs text-[#4B638A]">{m.label}</div>
                {m.was && <div className="text-[11px] text-[#93A6C4]">{m.was}</div>}
              </div>
            ))}
          </div>
        </div>

        <p className="mt-3 text-[11px] leading-snug text-[#93A6C4]">{SCENARIO_DISCLAIMER}</p>
      </article>
    </Reveal>
  );
}

/* ── Main export ── */
export function Results() {
  return (
    <section id="results" className="py-16 md:py-24" style={{ background: '#F6FAFF' }}>
      <Container>
        <Reveal>
          <SectionTitle
            eyebrow="Результат"
            title="Что меняется после внедрения Битрикс24"
            titleGradient="Битрикс24"
            subtitle="Три сценария из практики. Сначала замеряем ваши базовые показатели — потом внедряем и отслеживаем динамику. Цифры появляются после, не до."
          />
        </Reveal>

        {/* 3 короткие результат-карточки */}
        <div className="mt-10 grid grid-cols-1 gap-4 sm:grid-cols-3 md:gap-6">
          {RESULT_CARDS.map((card, i) => (
            <ResultSummaryCard key={card.title} card={card} delay={i * 80} />
          ))}
        </div>

        {/* Сноска к результат-карточкам */}
        <p className="mt-4 text-[11px] leading-relaxed text-[#93A6C4]">
          {CARDS_FOOTNOTE}
        </p>

        {/* 3 подробных сценария */}
        <div className="mt-6 grid grid-cols-1 gap-4 md:mt-8 md:gap-6 lg:grid-cols-3">
          {SCENARIOS.map((s, i) => (
            <ScenarioCard key={s.num} s={s} delay={i * 100} />
          ))}
        </div>
      </Container>
    </section>
  );
}
