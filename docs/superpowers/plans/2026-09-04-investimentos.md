# Investimentos redesign — Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign da aba Investimentos (gráfico com números, variação MoM, sem input/seletor) e mover Poder de Compra para o topo de Sonhos.

**Architecture:** Funções puras novas + ajustes em `GcInvestimentos`, `GcAreaChart`, `GcSonhos` e wiring em `App` — tudo em `index.html`. Sem mudança de schema.

**Tech Stack:** React 18 + Babel Standalone em `index.html` (arquivo único).

**Spec:** `docs/superpowers/specs/2026-09-04-investimentos-design.md`

---

### Task 1: Funções puras

**Files:** Modify `index.html` (perto de `gcPoderDeCompra`)

- [x] `gcVariacaoSnapshot(atual, anterior) → { delta, pct }`
- [x] `gcFmtMoneyCompact(v)` para labels do gráfico (ex. 51,8k)
- [x] Helpers de formatação/cor de delta

### Task 2: GcAreaChart com valores opcionais

- [x] Prop `showValues` — labels HTML nos pontos (sem distorcer com SVG stretch)

### Task 3: GcInvestimentos

- [x] Remover input, seletor, Poder de Compra
- [x] Cards Saldo + Último mês; gráfico; histórico com MoM
- [x] Simplificar props

### Task 4: GcSonhos + App

- [x] Statcard Poder de Compra no topo de Sonhos
- [x] Remover `investimentosComp`; FAB usa `competenciaAtual()`

### Task 5: CSS mínimo

- [x] Estilos para valor no gráfico e delta no histórico
