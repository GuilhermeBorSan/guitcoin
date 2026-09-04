# Melhoria da aba Investimentos (+ Poder de Compra em Sonhos)

**Data:** 2026-09-04  
**App:** Guitcoin  
**Status:** aprovado em brainstorm  
**Abordagem:** B — card “Último mês” + histórico com delta em R$ e %

## Problema

A aba Investimentos hoje é só dois statcards (Saldo / Poder de Compra), um seletor de mês + input inline confuso (`0,00` quando não há snapshot) e um histórico seco (mês + valor). O Dashboard já tem o gráfico de evolução, mas sem números nos pontos. O Poder de Compra faz mais sentido perto da Lista de Sonhos (quanto o saldo “compra” da wishlist).

## Decisões

1. **Layout Investimentos:** Saldo em Caixa + card “Último mês” · gráfico detalhado com valores · histórico com variação MoM (R$ + %)
2. **Remover** da aba: input inline de saldo, seletor de mês, card Poder de Compra
3. **Edição:** só via FAB (+) / modal `GcInvestmentSnapshotForm` existente; linhas do histórico só leitura
4. **Poder de Compra:** sai de Investimentos; vira 1 statcard no topo de Sonhos; permanece no Dashboard
5. **Dashboard:** gráfico de área continua simples; o detalhe com números fica só em Investimentos

## UI — Investimentos

### Statcards (2)

| Card | Conteúdo |
|---|---|
| Saldo em Caixa | `gcSaldoEmCaixa(snapshots)` formatado em R$ |
| Último mês | % MoM do snapshot mais recente vs o anterior (mesmo valor do topo do histórico). Se só houver 1 snapshot → “—” |

### Gráfico

- Reaproveitar `GcAreaChart` (ou variante) com **valores abreviados nos pontos** (ex.: `51,8k`)
- Série = **todos** os snapshots ordenados por competência (crescente). Só meses **com** snapshot (sem carregar saldo adiante como o Dashboard faz em `gcInvestimentosPorMes`)
- Labels de mês abaixo, como hoje no Dashboard

### Histórico

- Ordenado do mais recente ao mais antigo
- Cada linha: competência · saldo · subtítulo `+R$ X · +Y%` (ou −)
- Cores: verde (`--gc-accent`) se positivo, vermelho (`--gc-red`) se negativo, cinza se zero
- Primeiro snapshot da série (mais antigo): sem linha de variação
- Anterior = 0: mostrar delta em R$; % = “—”

### Removidos

- `gc-month-switch` nesta tela
- `Field` / input de saldo inline
- Props `competencia` / `onCompetenciaChange` / `onSaveSaldo` deixam de ser necessárias em `GcInvestimentos` (salvar só pelo modal do FAB)

## UI — Lista de Sonhos

- Statcard único no topo: **Poder de Compra** (`gcPoderDeCompra(gcSaldoEmCaixa(investmentSnapshots))`)
- Resto da tela inalterado (grupos, total)
- `GcSonhos` passa a receber `investmentSnapshots` (ou o `poderDeCompra` já calculado)

## Fórmulas

```
delta = saldoAtual - saldoAnterior
pct   = (saldoAnterior === 0) ? null : (delta / saldoAnterior) * 100
```

- Função pura sugerida: `gcVariacaoSnapshot(atual, anterior) → { delta, pct }` (`pct` null quando indefinido)
- Card “Último mês” e a 1ª linha do histórico usam o mesmo par (dois snapshots mais recentes por competência)

`GC_PODER_COMPRA_BASE = 1000` e `gcPoderDeCompra` não mudam.

## Fora de escopo

- Toque na linha do histórico para editar
- Filtro de ano em Investimentos
- Tooltips interativos no gráfico
- Mudança de schema Firestore (nenhum campo novo)
- Alterar o gráfico de área do Dashboard

## Verificação

- Demo: Saldo R$ 51.773,18; card Último mês ≈ +1,25% (Jul vs Jun)
- Histórico mostra deltas coerentes; Jan sem %; Abr vs Mar = 0,00%
- Input e seletor de mês sumiram; FAB ainda abre “Registrar saldo”
- Sonhos: Poder de Compra 5.177,32% no topo
- Investimentos não mostra mais Poder de Compra; Dashboard ainda mostra
