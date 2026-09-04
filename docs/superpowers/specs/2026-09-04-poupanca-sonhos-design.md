# Poupança da Lista de Sonhos

**Data:** 2026-09-04  
**App:** Guitcoin  
**Status:** aprovado em brainstorm  
**Abordagem:** 1 — espelho dos Investimentos (coleção de snapshots mensais)

## Problema

Na Lista de Sonhos o Poder de Compra hoje usa o Saldo em Caixa dos investimentos. O Gui quer uma **quantia separada**, registrada todo mês, dedicada a comprar itens da wishlist — e o Poder de Compra **nessa tela** deve refletir só essa poupança.

## Decisões

1. **Modelo:** snapshots mensais iguais a `investment_snapshots` (competência + saldo + observação)
2. **Poder de Compra em Sonhos:** `gcPoderDeCompra(saldoPoupancaSonhos)` — **não** soma com investimentos
3. **Dashboard / Investimentos:** inalterados (Poder de Compra / Saldo em Caixa continuam só com investimentos)
4. **Layout Sonhos:** cards Poupança + Poder de Compra → saldo/histórico → lista de itens (layout A)
5. **Ao marcar comprado:** se o item tem preço, perguntar se desconta da poupança; sem preço, só marca comprado

## Dados

**Nova coleção** `users/{uid}/wishlist_savings_snapshots/{id}`

| Campo | Tipo | Notas |
|---|---|---|
| `competencia` | string `"YYYY-MM"` | um snapshot por mês (upsert por competência, como investimentos) |
| `saldo` | number | saldo total da poupança naquele mês |
| `observacao` | string | opcional |

`firestore.rules` já cobre via `match /users/{uid}/{document=**}` — sem alteração de regras.

**Hook `useGcData`:** carregar a coleção no `Promise.all`; verbos `saveWishlistSavingsSnapshot` / `deleteWishlistSavingsSnapshot` (padrão de `saveInvestmentSnapshot` / `deleteInvestmentSnapshot`).

**Demo local:** array `wishlistSavingsSnapshots` em `GC_DEMO_DATA` (ex. Jan–Jul/2026 com saldos crescentes) para Poder de Compra ≠ 0% no modo demo.

## Fórmulas

```
gcSaldoPoupancaSonhos(snapshots) =
  saldo do snapshot com competência mais recente (0 se vazio)

poderDeCompraSonhos =
  gcPoderDeCompra(gcSaldoPoupancaSonhos(wishlistSavingsSnapshots))
  // = (saldo / GC_PODER_COMPRA_BASE) * 100
```

`GC_PODER_COMPRA_BASE = 1000` e `gcPoderDeCompra` **não mudam**.  
Dashboard continua: `gcPoderDeCompra(gcSaldoEmCaixa(investmentSnapshots))`.

**Desconto ao comprar** (após `confirm` positivo):

1. Localiza snapshot da competência atual (`gcCompetenciaAtual()` / equivalente já usado no app)
2. Se existe: `saldo = max(0, saldo - preco)`
3. Se não existe: cria snapshot do mês atual com `saldo = max(0, 0 - preco)` → na prática `0` se preço > 0 e não havia saldo (ou: cria com `max(0, saldoAnteriorMaisRecente - preco)`?). **Decisão explícita:** se não há snapshot do mês atual, baseia o desconto no **saldo mais recente** (carry) e grava um novo snapshot na competência atual com `max(0, saldoMaisRecente - preco)`. Assim o mês atual passa a ter registro sem “zerar” a poupança por acidente.

## UI — Lista de Sonhos

### Statcards (2)

| Card | Conteúdo |
|---|---|
| Poupança Sonhos | `gcSaldoPoupancaSonhos` em R$ |
| Poder de Compra | `gcPoderDeCompra` desse saldo, em % |

### Histórico

- Lista do mais recente ao mais antigo (mesmo espírito de Investimentos)
- Linha: competência · saldo · variação MoM (delta R$ / %), reusando `gcVariacaoSnapshot`
- Toque na linha → modal de edição (histórico não é só leitura — diferente de Investimentos, porque a poupança muda também via desconto ao comprar)

### Lista de itens

- Inalterada (grupos por categoria, toggle comprado, total)

### FAB

Menu contextual na rota Sonhos:

1. Novo item (fluxo atual)
2. Registrar saldo da poupança → `GcWishlistSavingsSnapshotForm` (espelho de `GcInvestmentSnapshotForm`)

### Modal de snapshot

Campos: competência, saldo, observação · salvar / excluir (se edição).

## Fluxo — marcar comprado

```
toggle comprado (false → true)
  se !preco → só toggle
  se preco → confirm("Descontar R$X da Poupança Sonhos?")
    Sim → toggle + atualizar/criar snapshot do mês atual
    Não → só toggle
desmarcar comprado (true → false)
  → só toggle (não estorna saldo automaticamente)
```

## Componentes / pontos de toque

- `gcSaldoPoupancaSonhos` (puro, junto às fórmulas de investimento)
- `GcSonhos` — props: `items`, `savingsSnapshots`, `onToggleComprado`, `onEdit`, callbacks de save/delete snapshot (ou via parent)
- `GcWishlistSavingsSnapshotForm` — novo
- `GcApp` / FAB — ramo Sonhos com menu 2 opções
- `useGcData` — estado + load + save/delete
- `GC_DEMO_DATA.wishlistSavingsSnapshots`

## Fora de escopo

- Meta mensal automática / contribuição recorrente gerada sozinha
- Somar poupança sonhos ao Poder de Compra do Dashboard
- Estorno automático ao desmarcar “comprado”
- Extrair dinheiro da poupança sonhos do Saldo em Caixa (bolsos separados; o Gui controla o que digita em cada um)
- Mudança de `firestore.rules`

## Verificação

- Demo: cards mostram saldo da poupança sonhos e Poder de Compra coerente (`saldo/1000*100`); **não** 5.177% dos investimentos
- FAB → “Registrar saldo” cria/atualiza snapshot; histórico atualiza; Poder de Compra recalcula
- Marcar item com preço → confirm → Sim reduz saldo do mês atual; Não só marca comprado
- Item sem preço → marca sem prompt
- Dashboard / Investimentos: números de Poder de Compra / Saldo em Caixa iguais aos de antes
- Modo local: writes não batem no Firebase
