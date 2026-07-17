/**
 * ARWOX Landing V3 — Shared Primitive Atoms
 *
 * Все экспорты именованные. TypeScript strict.
 * Использует только: React, Tailwind v4, CSS-переменные из styles.css.
 * Без внешних зависимостей кроме lucide-react (уже в проекте).
 */

"use client";

import {
  useEffect,
  useRef,
  useState,
  forwardRef,
  type ReactNode,
  type CSSProperties,
  type HTMLAttributes,
  type ImgHTMLAttributes,
} from "react";

/* ─────────────────────────────────────────────────────────────
   Container
   Центрированный max-w-7xl wrapper с горизонтальными паддингами.
   Принимает произвольные className поверх базовых.
───────────────────────────────────────────────────────────────*/
interface ContainerProps extends HTMLAttributes<HTMLDivElement> {
  /** Дополнительные Tailwind-классы */
  className?: string;
  children: ReactNode;
}

export function Container({ className = "", children, ...rest }: ContainerProps) {
  return (
    <div
      className={`mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8 ${className}`}
      {...rest}
    >
      {children}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Pill
   Маленький лейбл-бейдж (eyebrow).
   variant="light" (default) — белый фон + brand border.
   variant="dark"  — для dark-scope секций (border white/15, bg white/6).
───────────────────────────────────────────────────────────────*/
interface PillProps {
  children: ReactNode;
  variant?: "light" | "dark";
  className?: string;
}

export function Pill({ children, variant = "light", className = "" }: PillProps) {
  const base =
    "inline-flex items-center gap-2 rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]";

  const variants: Record<"light" | "dark", string> = {
    light:
      "border border-[var(--color-border)] bg-white text-[var(--color-brand)]",
    dark:
      "border border-white/15 bg-white/[0.06] text-[var(--color-brand-2)]",
  };

  const dotVariants: Record<"light" | "dark", string> = {
    light: "bg-[var(--color-brand)]",
    dark: "bg-[var(--color-brand-2)]",
  };

  return (
    <div className={`${base} ${variants[variant]} ${className}`}>
      <span className={`size-1.5 rounded-full ${dotVariants[variant]}`} />
      {children}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   SectionTitle
   Составной заголовок секции:
     eyebrow  — Pill с лейблом (опционально)
     title    — H2 (или H1 если as="h1")
     titleGradient — подстрока title, которую нужно покрасить text-gradient
     subtitle — параграф под заголовком
   Поддерживает выравнивание center/left/right.
───────────────────────────────────────────────────────────────*/
interface SectionTitleProps {
  eyebrow?: string;
  title: string;
  /** Точная подстрока из title, которой применяется text-gradient */
  titleGradient?: string;
  subtitle?: string;
  as?: "h1" | "h2" | "h3";
  align?: "center" | "left" | "right";
  variant?: "light" | "dark";
  className?: string;
}

export function SectionTitle({
  eyebrow,
  title,
  titleGradient,
  subtitle,
  as: Tag = "h2",
  align = "center",
  variant = "light",
  className = "",
}: SectionTitleProps) {
  const alignClass =
    align === "center"
      ? "text-center"
      : align === "right"
        ? "text-right"
        : "text-left";

  const itemsClass =
    align === "center"
      ? "items-center"
      : align === "right"
        ? "items-end"
        : "items-start";

  /** Разбиваем title на части: до, gradient-часть, после */
  let titleNode: ReactNode = title;
  if (titleGradient && title.includes(titleGradient)) {
    const [before, after] = title.split(titleGradient);
    titleNode = (
      <>
        {before}
        <span className="text-gradient">{titleGradient}</span>
        {after}
      </>
    );
  }

  return (
    <div className={`flex flex-col ${itemsClass} ${alignClass} ${className}`}>
      {eyebrow && <Pill variant={variant}>{eyebrow}</Pill>}
      <Tag
        className={`mt-4 text-4xl font-bold leading-tight sm:text-5xl ${
          variant === "dark" ? "text-white" : "text-[var(--color-foreground)]"
        }`}
      >
        {titleNode}
      </Tag>
      {subtitle && (
        <p
          className={`mt-4 max-w-2xl text-base leading-relaxed ${
            variant === "dark"
              ? "text-[var(--color-muted-foreground)]"
              : "text-[var(--color-muted-foreground)]"
          }`}
        >
          {subtitle}
        </p>
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Logo
   Логотип ARWOX: фирменный марк (inline-SVG) + wordmark.
   Марк — стилизованная «A» из 3 слоёв-лент с linearGradient
   (cyan #00C8FF → blue #006DFF) и диагональным бликом.
   variant="light" — тёмный wordmark #071A3F (default).
   variant="dark"  — белый wordmark #FFFFFF (для dark-scope).
───────────────────────────────────────────────────────────────*/
interface LogoProps {
  variant?: "light" | "dark";
  className?: string;
  /** Скрывать текст, показывать только иконку */
  iconOnly?: boolean;
}

export function Logo({ variant = "light", className = "", iconOnly = false }: LogoProps) {
  // Брендбук §5/§13: тёмный фон → полностью белая инверсная версия
  // (белый знак И белое написание), светлый фон → цветная.
  // Знак — утверждённый рендер из брендбука (PNG 1024px, §7: PNG 2x-3x).
  const dark = variant === "dark";
  const wordmarkColor = dark ? "#FFFFFF" : "#081D3A";

  return (
    <div className={`flex items-center gap-2.5 ${className}`}>
      <img
        src={dark ? "/assets/gen/logo-mark-white.png" : "/assets/gen/logo-mark-color.png"}
        alt=""
        aria-hidden="true"
        width={36}
        height={36}
        className="size-9 shrink-0 select-none object-contain"
        decoding="async"
      />

      {!iconOnly && (
        <span
          className="select-none text-xl font-bold tracking-tight"
          style={{ color: wordmarkColor }}
          aria-label="ARWOX"
        >
          ARWOX
        </span>
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Reveal
   Обёртка scroll-reveal на IntersectionObserver.
   При пересечении viewport добавляет класс .reveal-visible,
   снимает .reveal-hidden → CSS-переход opacity + translateY.

   Props:
     delay   — задержка в мс (каскадный reveal для карточек)
     once    — снять observer после первого срабатывания (default: true)
     threshold — 0..1, какая доля элемента должна быть видна (default: 0.12)
───────────────────────────────────────────────────────────────*/
interface RevealProps {
  children: ReactNode;
  delay?: number;
  once?: boolean;
  threshold?: number;
  className?: string;
  as?: keyof HTMLElementTagNameMap;
  style?: CSSProperties;
}

export function Reveal({
  children,
  delay = 0,
  once = true,
  threshold = 0.12,
  className = "",
  as: Tag = "div",
  style,
}: RevealProps) {
  const ref = useRef<HTMLElement | null>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Headless / automated browser (Playwright, Puppeteer): reveal immediately
    // so full-page screenshots capture all content without IntersectionObserver.
    if (typeof navigator !== "undefined" && navigator.webdriver) {
      setVisible(true);
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          if (once) observer.unobserve(el);
        } else if (!once) {
          setVisible(false);
        }
      },
      { threshold }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [once, threshold]);

  const Comp = Tag as React.ElementType;

  return (
    <Comp
      ref={ref}
      className={`${visible ? "reveal-visible" : "reveal-hidden"} ${className}`}
      style={{
        transitionDelay: delay > 0 ? `${delay}ms` : undefined,
        ...style,
      }}
    >
      {children}
    </Comp>
  );
}

/* ─────────────────────────────────────────────────────────────
   Icon
   Рендерит фирменный SVG-тайл из /assets/icons/{name}.svg через <img>.
   name — имя файла без расширения (например "rocket", "funnel").
   Поддерживает любые HTMLImageElement атрибуты.

   ПРАВИЛА использования:
   • Фирменные тайлы (128×128, градиентный скруглённый квадрат +
     белый глиф + тень) — рендерить КАК ЕСТЬ, без обёрток, без фильтров.
     Правильно:   <Icon name="crm" />
     НЕВЕРНО:     <GradientIconBox><Icon name="crm" className="brightness-0 invert" /></GradientIconBox>
   • НЕ применять brightness-0 invert к фирменным тайлам — это
     уничтожает градиент и превращает тайл в синий квадрат с кашей.
   • GradientIconBox использовать ТОЛЬКО для lucide-глифов (см. ниже).
   • Дефолтный размер: size-12 (48px). Меняется через className или prop size.
───────────────────────────────────────────────────────────────*/
interface IconProps extends Omit<ImgHTMLAttributes<HTMLImageElement>, "src" | "alt"> {
  /** Имя файла из /assets/icons/ без .svg */
  name: string;
  /** alt-текст (default: пустая строка — иконка декоративная) */
  alt?: string;
  size?: number | string;
}

export function Icon({ name, alt = "", size, className = "size-12", ...rest }: IconProps) {
  const sizeStyle: CSSProperties =
    typeof size === "number"
      ? { width: size, height: size }
      : typeof size === "string"
        ? { width: size, height: size }
        : {};

  return (
    <img
      src={`/assets/icons/${name}.svg`}
      alt={alt}
      aria-hidden={alt === "" ? true : undefined}
      className={className}
      style={sizeStyle}
      loading="lazy"
      decoding="async"
      {...rest}
    />
  );
}

/* ─────────────────────────────────────────────────────────────
   GradientIconBox
   Контейнер с градиентным фоном ТОЛЬКО для lucide-глифов
   (компоненты из lucide-react: <Zap />, <Check /> и т.п.),
   у которых нет фирменного SVG-тайла в /assets/icons/.

   НЕВЕРНО: оборачивать в GradientIconBox фирменные тайлы <Icon name="..."/>.
   Фирменные тайлы уже содержат встроенный градиент — GradientIconBox им не нужен.

   gradient: "brand" | "competence" | "green"
───────────────────────────────────────────────────────────────*/
interface GradientIconBoxProps {
  children: ReactNode;
  size?: "sm" | "md" | "lg";
  gradient?: "brand" | "competence" | "green";
  className?: string;
}

const GRADIENT_MAP: Record<string, string> = {
  brand: "linear-gradient(135deg, #006DFF 0%, #1677FF 52%, #8B5CF6 100%)",
  competence: "linear-gradient(135deg, #00B7FF 0%, #006DFF 55%, #8B5CF6 100%)",
  green: "linear-gradient(135deg, #22C55E 0%, #84CC16 60%, #2BCBFF 100%)",
};

const SIZE_MAP: Record<string, string> = {
  sm: "size-9 rounded-lg",
  md: "size-11 rounded-xl",
  lg: "size-12 rounded-xl",
};

export const GradientIconBox = forwardRef<HTMLDivElement, GradientIconBoxProps>(
  ({ children, size = "md", gradient = "brand", className = "" }, ref) => {
    return (
      <div
        ref={ref}
        className={`grid shrink-0 place-items-center text-white ${SIZE_MAP[size]} ${className}`}
        style={{ background: GRADIENT_MAP[gradient] }}
      >
        {children}
      </div>
    );
  }
);
GradientIconBox.displayName = "GradientIconBox";

/* ─────────────────────────────────────────────────────────────
   IconTile
   Обёртка для фирменного SVG-тайла <Icon> — даёт «воздух»
   вокруг иконки: скруглённый квадрат с белым фоном, бордером и тенью.

   variant="light" (default) — белый фон, brand border (для светлых секций).
   variant="dark"            — bg-white/[0.06], border white/15 (для тёмных).

   Использование:
     <IconTile><Icon name="crm" className="size-10" /></IconTile>

   НЕ оборачивать GradientIconBox в IconTile — они несовместимы по назначению.
───────────────────────────────────────────────────────────────*/
interface IconTileProps {
  children: ReactNode;
  variant?: "light" | "dark";
  /** Tailwind-класс размера паддинга (default: "p-2.5") */
  padding?: string;
  className?: string;
}

export function IconTile({
  children,
  variant = "light",
  padding = "p-2.5",
  className = "",
}: IconTileProps) {
  const base = `inline-flex shrink-0 items-center justify-center rounded-2xl shadow-sm ${padding}`;

  const variants: Record<"light" | "dark", string> = {
    light: "border border-[var(--color-border)] bg-white",
    dark:  "border border-white/15 bg-white/[0.06]",
  };

  return (
    <div className={`${base} ${variants[variant]} ${className}`}>
      {children}
    </div>
  );
}
