# Form slim do Cartão — Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps use checkbox syntax.

**Goal:** FAB do Cartão com Avulsa / Recorrente / Parcelada e forms slim (data + fatura), sem Situação/Dividida/Pago no cartão.

**Architecture:** Prop `mode="cartao"` em `GcExpenseInstanceForm` e `GcExpenseTemplateForm`; helper `gcCompetenciaDeFatura` para anti double-shift; menu `cartaoFabMenu` no `GcRoot`.

**Tech Stack:** `index.html` (React CDN), sem build.

**Files:** só `index.html` (+ este plan / spec já existentes).

---

### Task 1: Helper anti double-shift

- Modify: `index.html` (junto de `gcFaturaCompetencia`)

- [x] Add `gcCompetenciaDeFatura` + `gcDataDeDiaCompra`
- [x] `GcExpenseInstanceForm` modo cartão
- [x] `GcExpenseTemplateForm` modo cartão
- [x] `cartaoFabMenu` + wire forms
- [ ] Smoke manual no browser
