import { useState, useRef, useEffect } from "react";
import { Download } from "lucide-react";
import { Header } from "@/components/landing/Header";
import { Hero } from "@/components/landing/Hero";
import { Results } from "@/components/landing/Results";
import { Demo } from "@/components/landing/Demo";
import { CaseStudy } from "@/components/landing/CaseStudy";
import { WhyUs } from "@/components/landing/WhyUs";
import { Process } from "@/components/landing/Process";
import { ServicePackages } from "@/components/landing/ServicePackages";
import { Integrations } from "@/components/landing/Integrations";
import { BitrixGPT } from "@/components/landing/BitrixGPT";
import { Partners } from "@/components/landing/Partners";
import { Certificates } from "@/components/landing/Certificates";
import { Tariffs } from "@/components/landing/Tariffs";
import { FAQ } from "@/components/landing/FAQ";
import { Websites } from "@/components/landing/Websites";
import { Contact } from "@/components/landing/Contact";
import { Footer } from "@/components/landing/Footer";
import { FloatingMessenger } from "@/components/landing/FloatingMessenger";
import { LeadMagnetModal } from "@/components/landing/LeadMagnetModal";

export default function App() {
  const [leadOpen, setLeadOpen] = useState(false);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const [nearFooter, setNearFooter] = useState(false);
  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    const io = new IntersectionObserver(([e]) => setNearFooter(e.isIntersecting), { rootMargin: "0px 0px 140px 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <>
      <Header />
      <main className="bg-background text-foreground">
        {/* Hero (содержит CompetenceRibbon внутри) */}
        <Hero />

        {/* Результаты */}
        <Results />

        {/* Демо на настроенном портале (P1-3) */}
        <Demo />

        {/* Кейс */}
        <CaseStudy />

        {/* Почему мы */}
        <WhyUs />

        {/* Процесс работы */}
        <Process />

        {/* Пакеты внедрения (P2-1) */}
        <ServicePackages />

        {/* Интеграции */}
        <Integrations />

        {/* Партнёры и сервисы */}
        <Partners />

        <Certificates />

        {/* Битрикс GPT */}
        <BitrixGPT />

        {/* Тарифы */}
        <Tariffs />

        {/* FAQ */}
        <FAQ />

        {/* Разработка сайтов */}
        <Websites />

        {/* Контакты */}
        <Contact />
      </main>
      <div ref={sentinelRef} aria-hidden="true" />
      <Footer />

      {/* Плавающая кнопка Telegram (P2-4) */}
      <FloatingMessenger />

      {/* Кнопка чек-листа внедрения */}
      <button
        onClick={() => setLeadOpen(true)}
        className={`fixed bottom-6 left-6 z-50 flex items-center gap-2 rounded-full bg-gradient-to-r from-[#006DFF] to-[#8B5CF6] px-5 py-3 text-sm font-semibold text-white shadow-lg transition-opacity duration-200 ${nearFooter ? "opacity-0 pointer-events-none" : ""}`}
      >
        <Download className="h-4 w-4" />
        Чек-лист внедрения
      </button>

      <LeadMagnetModal open={leadOpen} onClose={() => setLeadOpen(false)} />
    </>
  );
}
