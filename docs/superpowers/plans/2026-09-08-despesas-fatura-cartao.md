# Lançar fatura do cartão em Despesas — Implementation Plan

> **For agentic workers:** Implement task-by-task. Steps use checkbox syntax.

**Goal:** No `+` de Despesas, opção “Fatura do cartão” que cria uma instância especial com total ao vivo e zera o custo das compras cobertas.

**Architecture:** Flags `pagamentoFatura`/`faturaCardId`/`faturaCompetencia` em `expense_instances`; helpers puros `gcFaturaTotalAoVivo` / cobertura; `gcCustoInstance` e totais passam a receber `cards`; modal `GcDespesasFaturaPicker` + form slim `mode="pagamentoFatura"`.

**Tech Stack:** `index.html` (React CDN), sem build.

**Files:** só `index.html` (+ plan/spec).

---

### Task 1: Fórmulas + UI + wire

- [x] Helpers de pagamento/cobertura/valor ao vivo; atualizar agregadores
- [x] `GcDespesasFaturaPicker` + pills na lista + form slim
- [x] FAB Despesas + `GcRoot` (cards no Dashboard/Despesas)
- [x] Smoke das fórmulas (substituição de custo)
