import { Close } from "@/components/close";
import { Console } from "@/components/console";
import { Architecture } from "@/components/architecture";
import { Governance } from "@/components/governance";
import { Header } from "@/components/header";
import { Hero } from "@/components/hero";
import { Milestones } from "@/components/milestones";
import { Operations } from "@/components/operations";
import { Problem } from "@/components/problem";

export default function Home() {
  return (
    <div className="atmosphere min-h-screen">
      <Header />
      <main>
        <Hero />
        <Problem />
        <Architecture />
        <Milestones />
        <Console />
        <Governance />
        <Operations />
        <Close />
      </main>
    </div>
  );
}
