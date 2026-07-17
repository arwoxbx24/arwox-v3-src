/**
 * Process — «Как мы внедряем Bitrix24»
 * Desktop (lg+): 6 шагов в один горизонтальный ряд (grid-cols-6),
 *                между шагами пунктирные стрелки-коннекторы.
 * Mobile (<lg):  вертикальный стек, стрелки скрыты.
 * Под шагами: 4 pill-карточки с 3D-иконками.
 */

import { Container, SectionTitle, Reveal } from '@/components/landing/atoms';

/* ── Steps data ── */
interface Step {
  num: string;
  icon3d: string;
  title: string;
  description: string;
}

const STEPS: Step[] = [
  {
    num: '01',
    icon3d: '/assets/gen/ic3d-analytics.png',
    title: 'Диагностика',
    description:
      'Разбираем текущую ситуацию: как приходят заявки, где теряются клиенты, что работает вручную.',
  },
  {
    num: '02',
    icon3d: '/assets/gen/ic3d-docs.png',
    title: 'Разработка ТЗ',
    description:
      'Составляем полное ТЗ с аналитиком. Утверждаем с вашей стороны до старта работ.',
  },
  {
    num: '03',
    icon3d: '/assets/gen/ic3d-rocket.png',
    title: 'Настройка и тестирование',
    description:
      'Реализуем систему по ТЗ и тестируем внутри команды перед показом вам.',
  },
  {
    num: '04',
    icon3d: '/assets/gen/ic3d-check-green.png',
    title: 'Демонстрация и правки',
    description:
      'Показываем настроенный портал, проверяем соответствие ТЗ, вносим корректировки.',
  },
  {
    num: '05',
    icon3d: '/assets/gen/ic3d-crm.png',
    title: 'Обучение и опытная эксплуатация',
    description:
      'Обучаем команду на ваших сценариях. Видеоинструкции и PDF входят в комплект.',
  },
  {
    num: '06',
    icon3d: '/assets/gen/ic3d-docs.png',
    title: 'Приёмка по ТЗ и акты',
    description:
      'Принимаете результат по ТЗ, закрываем проект документально. Результат зафиксирован.',
  },
];

/* ── Guarantee pills data ── */
interface GuaranteePill {
  icon3d: string;
  title: string;
  subtitle: string;
}

const PILLS: GuaranteePill[] = [
  { icon3d: '/assets/gen/ic3d-analytics.png', title: 'Понятный процесс', subtitle: 'на каждом этапе' },
  { icon3d: '/assets/gen/ic3d-docs.png', title: 'Прозрачность', subtitle: 'и согласование' },
  { icon3d: '/assets/gen/ic3d-check-green.png', title: 'Соблюдаем сроки', subtitle: 'и договорённости' },
  { icon3d: '/assets/gen/ic3d-rocket.png', title: 'Приёмка по ТЗ', subtitle: 'и поддержка' },
];

/* ── Dashed arrow connector between steps (desktop only) ── */
function StepConnector() {
  return (
    // mt-7 = 28px ≈ half of 56px icon → aligns connector with icon vertical center
    <div
      aria-hidden
      className="hidden lg:flex items-center justify-center flex-shrink-0 w-8 mt-7"
    >
      <div className="relative w-full flex items-center">
        {/* Dashed line — thin, grey */}
        <div
          className="flex-1 border-t border-dashed"
          style={{ borderColor: '#CBD5E1' }}
        />
        {/* Arrow head */}
        <div
          className="flex-shrink-0"
          style={{
            width: 0,
            height: 0,
            borderTop: '4px solid transparent',
            borderBottom: '4px solid transparent',
            borderLeft: '6px solid #CBD5E1',
          }}
        />
      </div>
    </div>
  );
}

/* ── Single step card ── */
function StepCard({ step, delay }: { step: Step; delay: number }) {
  return (
    <Reveal delay={delay} className="flex flex-col items-center text-center min-w-0">
      {/* Icon circle — ~56px, light blue gradient bg, subtle shadow */}
      <div
        className="flex items-center justify-center rounded-full mb-3 w-14 h-14 shrink-0"
        style={{
          background: 'linear-gradient(135deg, #EEF6FF 0%, #DBEAFE 100%)',
          boxShadow: '0 2px 8px rgba(0,75,160,0.08)',
        }}
      >
        <img
          src={step.icon3d}
          alt=""
          aria-hidden="true"
          width={36}
          height={36}
          className="size-9 select-none object-contain"
          loading="lazy"
          decoding="async"
        />
      </div>

      {/* Step number — small, regular weight, blue */}
      <span
        className="mb-1"
        style={{ fontSize: '12px', fontWeight: 400, color: '#1677ff', letterSpacing: '0.02em' }}
      >
        {step.num}
      </span>

      {/* Title — semibold ~15px */}
      <h3
        className="leading-snug text-[var(--color-foreground)] mb-1.5"
        style={{ fontSize: '15px', fontWeight: 600 }}
      >
        {step.title}
      </h3>

      {/* Description — ~13px, muted grey */}
      <p
        className="leading-relaxed"
        style={{ fontSize: '13px', color: '#6B7280' }}
      >
        {step.description}
      </p>
    </Reveal>
  );
}

/* ── Guarantee pill card ── */
function PillCard({ pill, delay }: { pill: GuaranteePill; delay: number }) {
  return (
    <Reveal delay={delay}>
      <div
        className="flex items-center gap-3 rounded-2xl bg-white px-5 py-4"
        style={{
          border: '1px solid #E5E7EB',
          boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
        }}
      >
        <div
          className="flex items-center justify-center w-9 h-9 rounded-xl shrink-0"
          style={{ background: 'linear-gradient(135deg, #EEF6FF 0%, #DBEAFE 100%)' }}
        >
          <img
            src={pill.icon3d}
            alt=""
            aria-hidden="true"
            width={24}
            height={24}
            className="size-6 select-none object-contain"
            loading="lazy"
            decoding="async"
          />
        </div>
        <div className="min-w-0">
          <p className="text-sm font-semibold leading-snug text-[var(--color-foreground)]">
            {pill.title}
          </p>
          <p className="text-xs text-[var(--color-muted-foreground)] mt-0.5">
            {pill.subtitle}
          </p>
        </div>
      </div>
    </Reveal>
  );
}

/* ════════════════════════════════════════
   EXPORT: Process section
═══════════════════════════════════════════ */
export function Process() {
  return (
    <section className="bg-white py-16 md:py-20" id="process">
      <Container>
        {/* Heading — left-aligned matching reference */}
        <Reveal>
          <SectionTitle
            eyebrow="этапы работы"
            title="Как мы внедряем Bitrix24"
            subtitle="Гибкий подход с экспертизой — от первого разбора задачи до подписания актов. Понятный и результативный процесс."
            align="left"
          />
        </Reveal>

        {/* ── Steps row ── */}
        <div className="mt-12">
          {/* Desktop: horizontal flex with connectors */}
          <div className="hidden lg:flex items-start gap-0">
            {STEPS.map((step, i) => (
              <div key={step.num} className="flex items-start min-w-0 flex-1">
                <StepCard step={step} delay={i * 80} />
                {i < STEPS.length - 1 && <StepConnector />}
              </div>
            ))}
          </div>

          {/* Mobile: vertical stack */}
          <div className="flex flex-col gap-6 lg:hidden">
            {STEPS.map((step, i) => (
              <Reveal key={step.num} delay={i * 60}>
                <div className="flex items-start gap-4">
                  {/* Icon circle — matches desktop */}
                  <div
                    className="flex items-center justify-center rounded-full shrink-0 w-14 h-14"
                    style={{
                      background: 'linear-gradient(135deg, #EEF6FF 0%, #DBEAFE 100%)',
                      boxShadow: '0 2px 8px rgba(0,75,160,0.08)',
                    }}
                  >
                    <img
                      src={step.icon3d}
                      alt=""
                      aria-hidden="true"
                      width={36}
                      height={36}
                      className="size-9 select-none object-contain"
                      loading="lazy"
                      decoding="async"
                    />
                  </div>

                  <div className="min-w-0 pt-1">
                    <span
                      style={{ fontSize: '12px', fontWeight: 400, color: '#1677ff', letterSpacing: '0.02em' }}
                    >
                      {step.num}
                    </span>
                    <h3
                      className="leading-snug text-[var(--color-foreground)] mt-0.5 mb-1"
                      style={{ fontSize: '15px', fontWeight: 600 }}
                    >
                      {step.title}
                    </h3>
                    <p
                      className="leading-relaxed"
                      style={{ fontSize: '13px', color: '#6B7280' }}
                    >
                      {step.description}
                    </p>
                  </div>
                </div>
              </Reveal>
            ))}
          </div>
        </div>

        {/* ── Guarantee pills ── */}
        <div className="mt-10 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {PILLS.map((pill, i) => (
            <PillCard key={pill.title} pill={pill} delay={500 + i * 80} />
          ))}
        </div>
      </Container>
    </section>
  );
}
