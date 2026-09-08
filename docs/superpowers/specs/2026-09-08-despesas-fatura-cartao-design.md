# Lançar fatura do cartão a partir de Despesas

**Data:** 2026-09-08  
**App:** Guitcoin  
**Status:** aprovado em brainstorm

## Problema

Na aba Despesas, o `+` só oferece despesa avulsa e nova recorrência. O Gui quer lançar **uma linha só** com o total de uma fatura (Nubank, BTG, etc.), escolhendo cartão e mês — como “paguei / vou pagar essa fatura neste mês” — sem digitar o valor na mão.

As compras `noCartao` já aparecem em Despesas e entram no Meu custo. Sem regra de substituição, somar o total da fatura **duplicaria** o custo de vida.

## Decisões

1. **Abordagem:** instância especial em `expense_instances` (não linha virtual, não template).
2. **Valor ao vivo:** a linha não guarda o total como fonte da verdade; UI e fórmulas leem o total atual via `gcFaturaInstances` (mesmo número do “Total da fatura” na aba Cartão).
3. **Substituição no custo:** enquanto existir o pagamento daquele par `(faturaCardId, faturaCompetencia)`, as compras cobertas por essa fatura têm **custo 0**; a linha da fatura contribui com o **total ao vivo** (soma dos `valor` das linhas da fatura, igual ao Cartão).
4. **Escolha explícita:** modal pede cartão **e** mês da fatura antes de salvar (não assume o filtro atual de Despesas).
5. **Competência da despesa** = mês da fatura escolhida (a linha aparece em Despesas naquele mês).
6. **Um pagamento por par** cartão + mês de fatura; segunda tentativa é bloqueada com aviso.
7. **Total lançado** também respeita a substituição: itens cobertos não somam `valor` nos totais do mês em que aparecem; a linha da fatura soma o total ao vivo no mês dela. Assim Dashboard / fluxo de caixa / statcards não duplicam.

## UI — FAB de Despesas

Terceira opção no `despesasFabMenu` (depois de avulsa e recorrência):

| Opção | Abre | Subtítulo sugerido |
|---|---|---|
| Fatura do cartão | `GcDespesasFaturaPicker` | Lançar o total de uma fatura (Nubank, BTG…) |

Ícone: `CreditCard` (já usado no app).

## UI — Modal `GcDespesasFaturaPicker`

Campos:

- **Cartão** — segmented / select dos `credit_card_settings` (obrigatório; se não houver cartão, empty state pedindo cadastrar na aba Cartão).
- **Fatura** — `input type="month"` (obrigatório); default = competência atual de Despesas (`despesasComp`) ou `competenciaAtual()`.
- **Total** — somente leitura, atualiza ao vivo ao mudar cartão/mês (`gcFaturaInstances` → soma de `valor`). Fatura vazia mostra R$ 0,00; Confirmar continua habilitado (o valor ao vivo sobe quando entrarem compras).

Ações: Cancelar / Confirmar.

No Confirmar: se já existir `pagamentoFatura` com o mesmo `faturaCardId` + `faturaCompetencia`, `alert` e não salva.

## Modelo de dados

Novo documento em `expense_instances` (coleção já existente; schemaless):

| Campo | Valor |
|---|---|
| `pagamentoFatura` | `true` |
| `faturaCardId` | id do cartão |
| `faturaCompetencia` | `"YYYY-MM"` da fatura |
| `competencia` | igual a `faturaCompetencia` |
| `descricao` | `"Fatura " + nome do cartão` (ex.: “Fatura Nubank”) |
| `valor` | `0` (placeholder; **nunca** é a fonte do total exibido/calculado) |
| `noCartao` | `false` |
| `pago` | `false` |
| `grupo` | id da categoria cujo `nome` (case-insensitive) é “Cartão” / “Cartao” / “cartao_fixo”, se existir; senão a primeira categoria ordenada. Editável no form slim. |
| `minhaParcelaPct` | `100` |
| `compartilhado` | `false` |
| `templateId` | `null` |

Sem coleção nova. Sem migração. Documentos antigos sem `pagamentoFatura` seguem iguais.

## Fórmulas (funções puras)

Contexto necessário além da instância: `allInstances`, `cards`.

```
gcIsPagamentoFatura(i) → !!i.pagamentoFatura && i.faturaCardId && i.faturaCompetencia

gcFaturaTotalAoVivo(instances, cards, cardId, faturaCompetencia)
  → soma valor de gcFaturaInstances(instances, faturaCompetencia, cards, cardId)

gcInstanceCobertaPorFatura(i, pagamentos, cards)
  → i.noCartao && i.cardId && existe pagamento P com
      P.faturaCardId === i.cardId &&
      gcFaturaCompetencia(i.competencia, i.diaCompra, diaFechamento(i.cardId)) === P.faturaCompetencia
    (P não cobre a si mesmo; pagamentos nunca são noCartao)

gcValorExibido(i, ctx) →
  pagamento → total ao vivo; senão → i.valor

gcCustoInstance(i, ctx) →
  se coberta por fatura → 0
  se pagamento → total ao vivo * (minhaParcelaPct/100)  // pct fixo 100
  senão → valor * pct (como hoje)

gcMonthInstancesTotal / gcCustoMes / gcCustoPorMes / gcCustoDeVidaAnual
  → passam a usar as variantes com ctx (ou helpers que filtram cobertas / expandem pagamento)
```

**Importante:** `gcCustoInstance` hoje é `(instance) => valor * pct`. Assinatura precisa aceitar contexto opcional **ou** virar `gcCustoInstanceResolved(i, ctx)` e os call sites de custo/dashboard migrarem. Preferência: manter nome `gcCustoInstance` com 2º arg opcional `ctx`; sem `ctx`, comportamento legado (não zera cobertas — só seguro se todos os call sites de agregação passarem `ctx`). **Regra de implementação:** todo agregador de custo/total de despesas passa `ctx`.

Lista em Despesas: linhas cobertas **continuam visíveis** (checkbox pago, edição). Pill discreta `Na fatura` nas cobertas. Linha de pagamento: pill `Fatura`; valor à direita = ao vivo. Subtotais de grupo (`gcGroupInstances`) usam `gcValorExibido`, não `i.valor` cru.

## Edição / exclusão

- Tocar na linha de pagamento abre form **slim**: Descrição (editável), Situação (pago), Categoria. Cartão, mês da fatura e valor **não** editáveis.
- Excluir remove o doc → compras cobertas voltam a contar no custo imediatamente.
- Não reutilizar o form avulsa completo sem guardas (evita marcar `noCartao` por engano).

## Fora de escopo

- Gerar automaticamente todo mês (recorrência de pagamento).
- Marcar em lote as compras da fatura como `pago`.
- Alterar a aba Cartão (continua listando as compras individuais).
- Importar linha a linha da fatura.

## Como verificar

1. Despesas → `+` → “Fatura do cartão” → escolher Nubank + mês atual do demo → Confirmar.
2. Aparece “Fatura Nubank” com valor = Total da fatura na aba Cartão (mesmo número).
3. Meu custo do mês **não** sobe pelo dobro: compras `noCartao` daquela fatura deixam de entrar; só a linha da fatura entra.
4. Em Cartão, adicionar/editar uma compra daquela fatura → voltar em Despesas → valor da linha fatura e Meu custo acompanham.
5. Segunda tentativa do mesmo cartão+mês → bloqueada.
6. Excluir a linha fatura → Meu custo volta a somar as compras individuais.
7. Dashboard / taxa de poupança refletem o custo sem duplicação.
