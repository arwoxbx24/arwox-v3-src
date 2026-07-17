"use client";

import { useEffect, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import { X, CheckCircle2 } from "lucide-react";
import { goal } from "@/lib/ym";

/* ─── Types ──────────────────────────────────────────────────── */

interface LeadMagnetModalProps {
  open: boolean;
  onClose: () => void;
}

interface FormState {
  name: string;
  email: string;
}

const INITIAL: FormState = { name: "", email: "" };

/* ─── Field styles (matching Contact.tsx) ────────────────────── */

const inputBase =
  "w-full rounded-[15px] border bg-[#f9fcff] px-4 py-4 font-[inherit] text-base outline-none transition-colors focus:border-[var(--color-brand)] focus:ring-2 focus:ring-[var(--color-brand)]/20 border-[#e4eef8] placeholder:text-[#a0b4cc]";

const inputError =
  "border-rose-400 focus:border-rose-400 focus:ring-rose-400/20";

/* ─── Component ──────────────────────────────────────────────── */

export function LeadMagnetModal({ open, onClose }: LeadMagnetModalProps) {
  const [form, setForm] = useState<FormState>(INITIAL);
  const [errors, setErrors] = useState<Partial<FormState & { consent: string }>>({});
  const [agreed, setAgreed] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const overlayRef = useRef<HTMLDivElement>(null);
  const firstInputRef = useRef<HTMLInputElement>(null);

  /* Close on Escape */
  useEffect(() => {
    if (!open) return;
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, [open, onClose]);

  /* Focus first input on open */
  useEffect(() => {
    if (open) {
      setTimeout(() => firstInputRef.current?.focus(), 50);
    }
  }, [open]);

  /* Prevent body scroll when open */
  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => { document.body.style.overflow = ""; };
  }, [open]);

  /* Reset on close */
  useEffect(() => {
    if (!open) {
      setForm(INITIAL);
      setErrors({});
      setAgreed(false);
      setLoading(false);
      setSubmitted(false);
    }
  }, [open]);

  if (!open) return null;

  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: undefined }));
  }

  function validate(): boolean {
    const next: typeof errors = {};
    if (form.name.trim().length < 2) next.name = "Введите имя (минимум 2 символа)";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) next.email = "Введите корректный e-mail";
    if (!agreed) next.consent = "Необходимо согласие на обработку персональных данных";
    setErrors(next);
    return Object.keys(next).length === 0;
  }

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setSubmitted(true);
      goal('lead_magnet_submit');
    }, 900);
  }

  function handleOverlayClick(e: React.MouseEvent<HTMLDivElement>) {
    if (e.target === overlayRef.current) onClose();
  }

  return (
    <div
      ref={overlayRef}
      onClick={handleOverlayClick}
      role="dialog"
      aria-modal="true"
      aria-labelledby="lead-magnet-title"
      className="fixed inset-0 z-[90] flex items-center justify-center p-4"
      style={{ background: "rgba(8,29,58,0.60)", backdropFilter: "blur(4px)" }}
    >
      <div className="relative w-full max-w-md rounded-[28px] bg-white p-8 shadow-2xl">
        {/* Close button */}
        <button
          type="button"
          onClick={onClose}
          aria-label="Закрыть"
          className="absolute right-5 top-5 flex size-8 items-center justify-center rounded-full text-[#4B638A] transition-colors hover:bg-[#f0f6ff] hover:text-[#071A3F] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF]"
        >
          <X className="size-5" />
        </button>

        {submitted ? (
          /* Success state */
          <div className="flex flex-col items-center justify-center gap-4 py-6 text-center">
            <CheckCircle2 className="size-16 text-[#006DFF]" strokeWidth={1.5} />
            <h3 className="text-2xl font-bold text-[#071A3F]">Чек-лист отправлен!</h3>
            <p className="text-[#4B638A]">Проверьте вашу почту — письмо уже в пути.</p>
          </div>
        ) : (
          <>
            {/* Heading */}
            <h2
              id="lead-magnet-title"
              className="pr-8 text-2xl font-bold leading-snug text-[#071A3F]"
            >
              Чек-лист внедрения Битрикс24
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-[#4B638A]">
              12 шагов, которые сэкономят вам время и бюджет. Отправим на почту.
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} noValidate className="mt-6 space-y-3">
              {/* Name */}
              <div className="space-y-1">
                <input
                  ref={firstInputRef}
                  id="lm-name"
                  name="name"
                  required
                  placeholder="Ваше имя"
                  value={form.name}
                  onChange={handleChange}
                  aria-describedby={errors.name ? "lm-name-error" : undefined}
                  className={[inputBase, errors.name ? inputError : ""].join(" ")}
                />
                {errors.name && (
                  <p id="lm-name-error" role="alert" className="text-xs text-rose-500">
                    {errors.name}
                  </p>
                )}
              </div>

              {/* Email */}
              <div className="space-y-1">
                <input
                  id="lm-email"
                  name="email"
                  type="email"
                  required
                  placeholder="E-mail для отправки"
                  value={form.email}
                  onChange={handleChange}
                  aria-describedby={errors.email ? "lm-email-error" : undefined}
                  className={[inputBase, errors.email ? inputError : ""].join(" ")}
                />
                {errors.email && (
                  <p id="lm-email-error" role="alert" className="text-xs text-rose-500">
                    {errors.email}
                  </p>
                )}
              </div>

              {/* Consent checkbox */}
              <label className="flex cursor-pointer items-start gap-3 select-none pt-1">
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
                <span className="text-[13px] leading-snug text-[#4B638A]">
                  Согласен(на) на{" "}
                  <a
                    href="/privacy.html"
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={(e) => e.stopPropagation()}
                    className="text-[#006DFF] underline underline-offset-2 transition-colors hover:text-[#071A3F] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] rounded"
                  >
                    обработку персональных данных
                  </a>
                </span>
              </label>
              {errors.consent && (
                <p role="alert" className="text-xs text-rose-500">
                  {errors.consent}
                </p>
              )}

              {/* Submit */}
              <button
                type="submit"
                disabled={loading}
                style={{ background: "var(--gradient-brand)" }}
                className="mt-2 h-14 w-full rounded-[15px] font-bold text-white shadow-[0_12px_30px_rgba(22,119,255,0.22)] transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {loading ? "Отправляем…" : "Получить чек-лист"}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
