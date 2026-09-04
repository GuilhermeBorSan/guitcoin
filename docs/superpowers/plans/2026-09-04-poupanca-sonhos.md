# Poupança Sonhos Implementation Plan

> **For agentic workers:** implement task-by-task in `index.html` (single-file app).

**Goal:** Snapshots mensais de poupança dedicada à Lista de Sonhos; Poder de Compra nessa tela usa só esse saldo; ao comprar, perguntar se desconta.

**Architecture:** Nova coleção `wishlist_savings_snapshots` espelhando `investment_snapshots`; fórmulas `gcSaldoPoupancaSonhos`; UI em `GcSonhos` (2 cards + histórico + lista); FAB com menu 2 opções; `confirm` no toggle comprado.

**Tech Stack:** React 18 + Babel Standalone + Firebase Firestore (compat), tudo em `index.html`.

---

### Task 1: Fórmulas + demo + hook
- [ ] `gcSaldoPoupancaSonhos`
- [ ] `GC_DEMO_DATA.wishlistSavingsSnapshots`
- [ ] estado/load/save/delete em `useGcData`

### Task 2: Form + GcSonhos UI
- [ ] `GcWishlistSavingsSnapshotForm`
- [ ] `GcSonhos` com cards, histórico, props novas

### Task 3: Shell — FAB, toggle com desconto, wiring
- [ ] Menu FAB em sonhos
- [ ] Desconto no marcar comprado
- [ ] Passar dados/callbacks

### Task 4: Verificar no demo local
- [ ] Abrir index.html / checar números e fluxos
