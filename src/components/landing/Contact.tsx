"use client";

import { useState, type ChangeEvent, type FormEvent } from "react";
import { Container, Reveal, Icon } from "@/components/landing/atoms";
import { goal } from "@/lib/ym";

/* ─── Types ─────────────────────────────────────────────────── */

interface FormState {
  name: string;
  phone: string;
  email: string;
  teamSize: string;
  currentTools: string[];
  launchTiming: string;
  message: string;
  /** Anti-bot honeypot — must stay empty */
  hp: string;
}

const INITIAL: FormState = {
  name: "",
  phone: "",
  email: "",
  teamSize: "",
  currentTools: [],
  launchTiming: "",
  message: "",
  hp: "",
};

/* ─── Qualification options ──────────────────────────────────── */

const TEAM_SIZE_OPTIONS = [
  { value: "до 5", label: "до 5" },
  { value: "6–20", label: "6–20" },
  { value: "21–50", label: "21–50" },
  { value: "51–100", label: "51–100" },
  { value: "больше 100", label: "больше 100" },
] as const;

const CURRENT_TOOLS_OPTIONS = [
  "Битрикс24",
  "1С",
  "amoCRM",
  "Excel и почта",
  "ничего из этого",
] as const;

const LAUNCH_TIMING_OPTIONS = [
  { value: "в этом месяце", label: "В этом месяце" },
  { value: "в течение квартала", label: "В течение квартала" },
  { value: "пока изучаем", label: "Пока изучаем" },
] as const;

/* ─── Validation ─────────────────────────────────────────────── */

interface FormErrors {
  name?: string;
  phone?: string;
  consent?: string;
}

function validateForm(form: FormState, agreed: boolean): FormErrors {
  const errors: FormErrors = {};

  if (form.name.trim().length < 2) {
    errors.name = "Введите имя (минимум 2 символа)";
  }

  const digits = form.phone.replace(/\D/g, "");
  if (digits.length < 10) {
    errors.phone = "Введите номер телефона (минимум 10 цифр)";
  }

  if (!agreed) {
    errors.consent = "Необходимо согласие на обработку персональных данных";
  }

  return errors;
}

/* ─── Trust items ────────────────────────────────────────────── */

const TRUST_ITEMS = [
  {
    icon3d: "phone" as const,
    title: "Быстрый ответ",
    desc: "Свяжемся в течение 15 минут",
  },
  {
    icon3d: "check-green" as const,
    title: "Без обязательств",
    desc: "Консультация ни к чему не обязывает",
  },
  {
    icon3d: "data" as const,
    title: "Конфиденциальность",
    desc: "Ваши данные под надёжной защитой",
  },
];

/* ─── Field styles ───────────────────────────────────────────── */

const inputBase =
  "w-full rounded-[15px] border bg-[#f9fcff] px-4 py-4 font-[inherit] text-base outline-none transition-colors focus:border-[var(--color-brand)] focus:ring-2 focus:ring-[var(--color-brand)]/20 border-[#e4eef8]";

const inputError =
  "border-rose-400 focus:border-rose-400 focus:ring-rose-400/20";

/* ─── Step indicator ─────────────────────────────────────────── */

const STEPS = [
  { label: "Контакт" },
  { label: "О компании" },
  { label: "Детали" },
];

function StepIndicator({ current }: { current: number }) {
  return (
    <div className="mb-6 flex items-center justify-between">
      {STEPS.map((s, i) => {
        const stepNum = i + 1;
        const isDone = stepNum < current;
        const isActive = stepNum === current;

        return (
          <div key={s.label} className="flex flex-1 items-center">
            {/* Circle */}
            <div className="flex flex-col items-center gap-1">
              <div
                className={[
                  "flex size-8 shrink-0 items-center justify-center rounded-full text-sm font-bold transition-colors",
                  isActive || isDone
                    ? "bg-[#006DFF] text-white"
                    : "bg-[#e4eef8] text-[#4B638A]",
                ].join(" ")}
              >
                {isDone ? (
                  <svg
                    viewBox="0 0 12 10"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                    className="size-3.5 shrink-0"
                    aria-hidden="true"
                  >
                    <path
                      d="M1 5l3.5 3.5L11 1"
                      stroke="white"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                ) : (
                  stepNum
                )}
              </div>
              <span
                className={[
                  "text-[11px] font-medium whitespace-nowrap",
                  isActive || isDone ? "text-[#006DFF]" : "text-[#4B638A]",
                ].join(" ")}
              >
                {s.label}
              </span>
            </div>

            {/* Connector line (not after last item) */}
            {i < STEPS.length - 1 && (
              <div
                className={[
                  "mx-2 mb-4 h-px flex-1 transition-colors",
                  stepNum < current ? "bg-[#006DFF]" : "bg-[#e4eef8]",
                ].join(" ")}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

/* ─── Component ─────────────────────────────────────────────── */

export function Contact() {
  const [form, setForm] = useState<FormState>(INITIAL);
  const [errors, setErrors] = useState<FormErrors>({});
  const [agreed, setAgreed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [step, setStep] = useState(1);

  function handleChange(
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value } as FormState));
    if (name === "name" || name === "phone") {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
  }

  function toggleTool(tool: string) {
    setForm((prev) => {
      const has = prev.currentTools.includes(tool);
      if (has) {
        return { ...prev, currentTools: prev.currentTools.filter((t) => t !== tool) };
      }
      // "ничего из этого" resets all others
      if (tool === "ничего из этого") {
        return { ...prev, currentTools: ["ничего из этого"] };
      }
      // selecting any real tool removes "ничего из этого"
      const next = prev.currentTools.filter((t) => t !== "ничего из этого");
      return { ...prev, currentTools: [...next, tool] };
    });
  }

  function handleStep1Next() {
    const validationErrors = validateForm(form, agreed);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }
    setErrors({});
    setStep(2);
  }

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    // Silently drop bot submissions
    if (form.hp) return;

    const validationErrors = validateForm(form, agreed);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      setStep(1);
      return;
    }

    setErrors({});
    setLoading(true);
    // Simulated async submit
    setTimeout(() => {
      setLoading(false);
      setSubmitted(true);
      goal('contact_submit');
    }, 900);
  }

  return (
    <section
      id="contact"
      className="relative overflow-hidden py-20 md:py-28"
      style={{
        background:
          "radial-gradient(circle at 85% 32%, rgba(22,119,255,.18), transparent 38%), radial-gradient(circle at 12% 70%, rgba(0,183,255,.14), transparent 32%), linear-gradient(135deg, #f0f8ff 0%, #e6f3ff 50%, #edf6ff 100%)",
      }}
    >
      {/* Decorative glows */}
      <div
        aria-hidden
        className="pointer-events-none absolute right-[-80px] top-[-80px] size-[320px] rounded-full blur-[140px]"
        style={{ background: "rgba(0,109,255,0.10)" }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute bottom-[-60px] left-[-60px] size-[280px] rounded-full blur-[120px]"
        style={{ background: "rgba(0,183,255,0.08)" }}
      />
      {/* Decorative waves */}
      <svg
        aria-hidden
        className="pointer-events-none absolute inset-0 h-full w-full"
        preserveAspectRatio="xMidYMid slice"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M0,160 C200,220 400,80 700,140 C900,180 1100,60 1440,120 L1440,400 L0,400 Z"
          fill="rgba(0,109,255,0.04)"
        />
        <path
          d="M0,220 C250,160 500,280 750,200 C1000,130 1200,240 1440,180 L1440,400 L0,400 Z"
          fill="rgba(0,183,255,0.04)"
        />
      </svg>

      <Container>
        <Reveal>
          <div className="grid items-start gap-10 lg:grid-cols-2 lg:gap-16">

            {/* ── Left: heading + trust items ─────────────────── */}
            <div className="flex flex-col">
              <h2
                className="text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl lg:text-[56px]"
                style={{ color: "#071A3F" }}
              >
                Обсудим ваш проект?
              </h2>

              <p
                className="mt-5 max-w-md text-lg leading-relaxed"
                style={{ color: "var(--color-muted-foreground)" }}
              >
                Оставьте заявку — проведём бесплатную консультацию и подготовим
                предложение под ваши задачи.
              </p>

              {/* Trust items */}
              <ul className="mt-8 space-y-4">
                {TRUST_ITEMS.map((item) => (
                  <li key={item.title} className="flex items-start gap-4">
                    <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
                      <img
                        src={`/assets/gen/ic3d-${item.icon3d}.png`}
                        alt=""
                        aria-hidden="true"
                        width={44}
                        height={44}
                        className="size-11 select-none object-contain"
                        loading="lazy"
                        decoding="async"
                      />
                    </span>
                    <div>
                      <div className="font-semibold">{item.title}</div>
                      <div
                        className="mt-0.5 text-sm leading-snug"
                        style={{ color: "var(--color-muted-foreground)" }}
                      >
                        {item.desc}
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>

            {/* ── Right: form card ─────────────────────────────── */}
            <div className="rounded-[28px] bg-white p-8 shadow-[0_24px_80px_rgba(7,26,63,0.08)] md:p-10">
              {submitted ? (
                /* Success state */
                <div className="flex flex-col items-center justify-center gap-4 py-10 text-center">
                  <div
                    className="grid size-16 place-items-center rounded-full shadow-[0_8px_24px_rgba(0,109,255,0.30)]"
                    style={{ background: "var(--gradient-brand)" }}
                  >
                    <Icon name="rocket" className="size-8" />
                  </div>
                  <h3 className="text-2xl font-bold">Заявка отправлена!</h3>
                  <p style={{ color: "var(--color-muted-foreground)" }}>
                    Перезвоним в течение 15 минут
                  </p>
                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setForm(INITIAL);
                      setAgreed(false);
                      setStep(1);
                    }}
                    className="mt-2 rounded text-sm underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2"
                    style={{
                      color: "var(--color-brand)",
                    }}
                  >
                    Отправить ещё одну заявку
                  </button>
                </div>
              ) : (
                /* Form */
                <form onSubmit={handleSubmit} noValidate className="relative">
                  {/* Honeypot — hidden from real users */}
                  <input
                    name="hp"
                    tabIndex={-1}
                    aria-hidden="true"
                    value={form.hp}
                    onChange={handleChange}
                    autoComplete="off"
                    className="absolute -z-10 h-0 w-0 opacity-0"
                  />

                  {/* Step indicator */}
                  <StepIndicator current={step} />

                  {/* ── Step 1: Contact ──────────────────────────── */}
                  {step === 1 && (
                    <>
                      {/* Name */}
                      <div className="space-y-1.5">
                        <input
                          id="c-name"
                          name="name"
                          required
                          placeholder="Ваше имя"
                          value={form.name}
                          onChange={handleChange}
                          aria-describedby={errors.name ? "c-name-error" : undefined}
                          className={[
                            inputBase,
                            errors.name ? inputError : "",
                          ].join(" ")}
                        />
                        {errors.name && (
                          <p id="c-name-error" role="alert" className="text-xs text-rose-500">
                            {errors.name}
                          </p>
                        )}
                      </div>

                      {/* Phone */}
                      <div className="mt-3 space-y-1.5">
                        <input
                          id="c-phone"
                          name="phone"
                          type="tel"
                          required
                          placeholder="Телефон или e-mail"
                          value={form.phone}
                          onChange={handleChange}
                          aria-describedby={errors.phone ? "c-phone-error" : undefined}
                          className={[
                            inputBase,
                            errors.phone ? inputError : "",
                          ].join(" ")}
                        />
                        {errors.phone && (
                          <p id="c-phone-error" role="alert" className="text-xs text-rose-500">
                            {errors.phone}
                          </p>
                        )}
                      </div>

                      {/* Consent checkbox */}
                      <label className="mt-4 flex cursor-pointer items-start gap-3 select-none">
                        <span className="relative mt-0.5 shrink-0">
                          <input
                            type="checkbox"
                            required
                            checked={agreed}
                            onChange={(e) => {
                              setAgreed(e.target.checked);
                              setErrors((prev) => ({ ...prev, consent: undefined }));
                            }}
                            className="peer sr-only"
                          />
                          {/* Custom checkbox box */}
                          <span
                            className={[
                              "flex size-5 items-center justify-center rounded-[6px] border-2 transition-colors",
                              agreed
                                ? "border-[#006DFF] bg-[#006DFF]"
                                : errors.consent
                                ? "border-rose-400"
                                : "border-[#c8d9ee] bg-white",
                              "peer-focus-visible:ring-2 peer-focus-visible:ring-[#006DFF] peer-focus-visible:ring-offset-2",
                            ].join(" ")}
                          >
                            {agreed && (
                              <svg
                                viewBox="0 0 12 10"
                                fill="none"
                                xmlns="http://www.w3.org/2000/svg"
                                className="size-3 shrink-0"
                                aria-hidden="true"
                              >
                                <path
                                  d="M1 5l3.5 3.5L11 1"
                                  stroke="white"
                                  strokeWidth="2"
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                />
                              </svg>
                            )}
                          </span>
                        </span>
                        <span className="text-[13px] leading-snug" style={{ color: "var(--color-muted-foreground)" }}>
                          Согласен(на) на{" "}
                          <a
                            href="/privacy.html"
                            target="_blank"
                            rel="noopener noreferrer"
                            onClick={(e) => e.stopPropagation()}
                            className="underline underline-offset-2 transition-colors hover:text-[var(--color-foreground)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] rounded"
                            style={{ color: "var(--color-brand)" }}
                          >
                            обработку персональных данных
                          </a>
                        </span>
                      </label>
                      {errors.consent && (
                        <p role="alert" className="mt-1 text-xs text-rose-500">
                          {errors.consent}
                        </p>
                      )}

                      {/* Next button */}
                      <button
                        type="button"
                        onClick={handleStep1Next}
                        style={{ background: "var(--gradient-brand)" }}
                        className="mt-4 h-12 w-full rounded-[15px] font-bold text-white shadow-[0_12px_30px_rgba(22,119,255,0.22)] transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                      >
                        Далее
                      </button>
                    </>
                  )}

                  {/* ── Step 2: Qualification ────────────────────── */}
                  {step === 2 && (
                    <>
                      {/* 1. Team size — select */}
                      <div>
                        <label
                          htmlFor="c-team-size"
                          className="mb-1.5 block text-sm font-medium"
                          style={{ color: "#4B638A" }}
                        >
                          Сколько человек будет работать в системе?
                        </label>
                        <div className="relative">
                          <select
                            id="c-team-size"
                            name="teamSize"
                            value={form.teamSize}
                            onChange={handleChange}
                            className={[
                              inputBase,
                              "appearance-none pr-10",
                              form.teamSize === "" ? "text-[#a0b4cc]" : "",
                            ].join(" ")}
                          >
                            <option value="" disabled>Выберите вариант</option>
                            {TEAM_SIZE_OPTIONS.map((opt) => (
                              <option key={opt.value} value={opt.value}>
                                {opt.label}
                              </option>
                            ))}
                          </select>
                          {/* Custom chevron */}
                          <span
                            className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2"
                            aria-hidden="true"
                          >
                            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                              <path d="M4 6l4 4 4-4" stroke="#4B638A" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                            </svg>
                          </span>
                        </div>
                      </div>

                      {/* 2. Current tools — chip multiselect */}
                      <div className="mt-4">
                        <p
                          className="mb-2 text-sm font-medium"
                          style={{ color: "#4B638A" }}
                        >
                          Что уже используете?
                        </p>
                        <div className="flex flex-wrap gap-2" role="group" aria-label="Что уже используете">
                          {CURRENT_TOOLS_OPTIONS.map((tool) => {
                            const active = form.currentTools.includes(tool);
                            return (
                              <button
                                key={tool}
                                type="button"
                                onClick={() => toggleTool(tool)}
                                aria-pressed={active}
                                className={[
                                  "rounded-full border px-3.5 py-1.5 text-sm font-medium transition-all duration-150 select-none focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] focus-visible:ring-offset-2",
                                  active
                                    ? "border-[#006DFF] bg-[#006DFF] text-white shadow-[0_2px_8px_rgba(0,109,255,0.25)]"
                                    : "border-[#dce9f7] bg-[#f4f9ff] text-[#4B638A] hover:border-[#006DFF]/40 hover:bg-[#eef6ff]",
                                ].join(" ")}
                              >
                                {tool}
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      {/* 3. Launch timing — radio */}
                      <div className="mt-4">
                        <p
                          className="mb-2 text-sm font-medium"
                          style={{ color: "#4B638A" }}
                        >
                          Когда планируете запуск?
                        </p>
                        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap" role="radiogroup" aria-label="Когда планируете запуск">
                          {LAUNCH_TIMING_OPTIONS.map((opt) => {
                            const active = form.launchTiming === opt.value;
                            return (
                              <label
                                key={opt.value}
                                className={[
                                  "flex cursor-pointer items-center gap-2.5 rounded-[12px] border px-4 py-3 text-sm transition-all duration-150 select-none",
                                  active
                                    ? "border-[#006DFF] bg-[#eef6ff] text-[#006DFF] font-medium"
                                    : "border-[#dce9f7] bg-[#f4f9ff] text-[#4B638A] hover:border-[#006DFF]/40",
                                ].join(" ")}
                              >
                                <input
                                  type="radio"
                                  name="launchTiming"
                                  value={opt.value}
                                  checked={active}
                                  onChange={handleChange}
                                  className="sr-only"
                                />
                                {/* Custom radio dot */}
                                <span
                                  className={[
                                    "flex size-4 shrink-0 items-center justify-center rounded-full border-2 transition-colors",
                                    active ? "border-[#006DFF]" : "border-[#c8d9ee]",
                                  ].join(" ")}
                                >
                                  {active && (
                                    <span className="size-2 rounded-full bg-[#006DFF]" />
                                  )}
                                </span>
                                {opt.label}
                              </label>
                            );
                          })}
                        </div>
                      </div>

                      {/* Navigation */}
                      <div className="mt-5 flex gap-3">
                        <button
                          type="button"
                          onClick={() => setStep(1)}
                          className="h-12 flex-1 rounded-[15px] border-2 border-[#006DFF] font-bold text-[#006DFF] transition-colors hover:bg-[#eef6ff] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                        >
                          Назад
                        </button>
                        <button
                          type="button"
                          onClick={() => setStep(3)}
                          style={{ background: "var(--gradient-brand)" }}
                          className="h-12 flex-1 rounded-[15px] font-bold text-white shadow-[0_12px_30px_rgba(22,119,255,0.22)] transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                        >
                          Далее
                        </button>
                      </div>
                    </>
                  )}

                  {/* ── Step 3: Details ──────────────────────────── */}
                  {step === 3 && (
                    <>
                      {/* Message — optional */}
                      <div>
                        <textarea
                          id="c-message"
                          name="message"
                          rows={5}
                          placeholder="Опишите задачу (необязательно)"
                          value={form.message}
                          onChange={handleChange}
                          className="w-full resize-none rounded-[15px] border border-[#e4eef8] bg-[#f9fcff] px-4 py-4 font-[inherit] text-base outline-none transition-colors focus:border-[var(--color-brand)] focus:ring-2 focus:ring-[var(--color-brand)]/20 placeholder:text-[#a0b4cc]"
                        />
                      </div>

                      {/* Navigation */}
                      <div className="mt-4 flex gap-3">
                        <button
                          type="button"
                          onClick={() => setStep(2)}
                          className="h-12 flex-1 rounded-[15px] border-2 border-[#006DFF] font-bold text-[#006DFF] transition-colors hover:bg-[#eef6ff] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                        >
                          Назад
                        </button>
                        <button
                          type="submit"
                          disabled={loading}
                          style={{ background: "var(--gradient-brand)" }}
                          className="h-12 flex-1 rounded-[15px] font-bold text-white shadow-[0_12px_30px_rgba(22,119,255,0.22)] transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed"
                        >
                          {loading ? "Отправляем…" : "Отправить заявку"}
                        </button>
                      </div>
                    </>
                  )}
                </form>
              )}
            </div>

          </div>
        </Reveal>
      </Container>
    </section>
  );
}
