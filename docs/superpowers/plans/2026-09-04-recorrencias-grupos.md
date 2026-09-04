# Reorganização de grupos + fixo/variável — Implementation Plan

> **For agentic workers:** Execute task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Trocar grupos de despesas para áreas da vida, adicionar `valorTipo`/`valorConfirmado`, e ajustar UIs de Recorrências e Despesas conforme a spec.

**Architecture:** Tudo em `index.html` (app single-file). Seed + helpers puros + geração lazy + telas/formulários. Sem migração Firestore.

**Tech Stack:** React 18 + Babel Standalone no `index.html`; Firebase só em produção (modo demo local).

**Spec:** `docs/superpowers/specs/2026-09-04-recorrencias-grupos-design.md`

---

### Task 1: Seed, helpers e geração

**Files:** Modify `index.html` (constantes, `gcNovaInstanciaDeTemplate`, demo data)

- [ ] Atualizar `GC_EXPENSE_GROUPS_SEED`
- [ ] Helper `gcValorTipo(t)` → `"fixo"|"variavel"` (default fixo)
- [ ] Helper `gcValorConfirmado(i)` → boolean (default true)
- [ ] `gcNovaInstanciaDeTemplate` seta `valorConfirmado` conforme tipo
- [ ] Remapear `expenseTemplates` e avulsas no demo

### Task 2: UI Recorrências + form template

**Files:** Modify `GcRecorrencias`, `GcExpenseTemplateForm`

- [ ] Lista agrupada por categoria
- [ ] Pill Fixo/Variável depois do nome
- [ ] Segmented valorTipo no form + label do valor

### Task 3: UI Despesas + form instância

**Files:** Modify `GcDespesas`, `GcExpenseInstanceForm`

- [ ] Statcard “A confirmar”
- [ ] Badge “a confirmar” + subtítulo estimado
- [ ] Avulsa: default grupo `pessoal`; salvar com `valorConfirmado: true`
- [ ] Edição: `valorConfirmado: true` ao salvar

### Task 4: CSS + verificação visual

- [ ] Estilos pill variável/a confirmar se necessário
- [ ] Abrir app em modo demo e checar checklist da spec
