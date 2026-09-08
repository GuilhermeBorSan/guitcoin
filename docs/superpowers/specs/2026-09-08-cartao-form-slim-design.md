# Form slim do Cartão de Crédito (avulsa / recorrente / parcelada)

**Data:** 2026-09-08  
**App:** Guitcoin  
**Status:** aprovado em brainstorm

## Problema

O FAB da aba Cartão abre o mesmo `GcExpenseInstanceForm` de Despesas, já com `defaultNoCartao: true`. No contexto do cartão isso sobra e confunde:

- Situação pendente/paga (a fatura é uma só; o checkbox “pago” na lista basta)
- Dividida com terceiro (cartão é só do Gui)
- “Pago no cartão de crédito?” (já estamos na aba Cartão)
- Só dá pra lançar avulsa; recorrente e parcelada ficam escondidas em Despesas → Recorrências
- “Dia da cobrança” (1–31) é menos claro que data + fatura explícita

## Decisões

1. **Abordagem:** menu no FAB + reuso dos forms existentes com modo `cartao` (não criar `GcCartaoForm` separado).
2. **Três entradas no +:** Avulsa | Recorrente | Parcelada (fluxos distintos; parcelada ≠ recorrente).
3. **Form slim no modo cartão:** esconde Situação, Dividida e “Pago no cartão?”.
4. **Data + fatura:** campo de data completa (`type="date"`) + seletor de competência da fatura; a fatura escolhida **manda** (sobrescreve o deslocamento automático por `diaFechamento`).
5. **Sem campo novo no Firestore:** data completa é só UX; persistem `diaCompra` (dia) + `competencia` / `dataInicio` (mês da fatura).
6. **Despesas inalterada:** form completo continua como está; slim só com prop de modo cartão.

## UI — FAB do Cartão

Espelha o menu de Despesas (`gc-fab-menu`), com três opções:

| Opção | Abre | Subtítulo sugerido |
|---|---|---|
| Despesa avulsa | `GcExpenseInstanceForm` modo cartão | Uma compra pontual nesta fatura |
| Recorrente | `GcExpenseTemplateForm` modo cartão, `parcelado` forçado false | Assinatura / cobrança mensal no cartão |
| Parcelada | `GcExpenseTemplateForm` modo cartão, `parcelado` forçado true | Compra em Nx (ex.: notebook 10x) |

Estado em `GcRoot`: `cartaoFabMenu` (boolean), no mesmo espírito de `despesasFabMenu`.

## UI — Form avulsa (`GcExpenseInstanceForm`, modo cartão)

**Visíveis:** Descrição, Categoria, Valor, Data da compra, Fatura (mês).  
**Ocultos:** Situação, Dividida com terceiro (+ campos filhos), Pago no cartão?, Dia da cobrança (número).

**Defaults (criação):**

- `noCartao = true`, `pago = false`, `compartilhado = false`, `minhaParcelaPct = 100`
- Data da compra = hoje
- Fatura = competência aberta no filtro do topbar (`cartaoComp`)

**No submit:**

- Derivar `competencia` a partir da fatura escolhida + `diaCompra` + `diaFechamento` (ver seção Modelo — anti double-shift)
- `diaCompra` = dia da data da compra (1–31)
- `noCartao = true`

**Título do modal:** “Nova despesa no cartão” / “Editar despesa no cartão” (ou manter “avulsa” se preferir consistência com Despesas — implementação pode escolher o mais curto).

## UI — Form recorrente / parcelada (`GcExpenseTemplateForm`, modo cartão)

Props sugeridas: `mode="cartao"`, `defaultParcelado` (boolean), opcional `defaultFatura` / `defaultData`.

### Recorrente (modo cartão, não parcelado)

**Visíveis:** Nome, Categoria, Tipo de valor, Valor, Frequência (mensal/anual + mês de cobrança se anual), Começa em, Data da cobrança, Fatura inicial.  
**Ocultos:** Compra parcelada?, Dividida, Pago no cartão?, Dia numérico solto, Ativa? (nova = sempre ativa).

**Defaults:** `noCartao=true`, `parcelado=false`, `ativo=true`.

### Parcelada (modo cartão)

**Visíveis:** Nome, Categoria, Tipo de valor, Valor da parcela, Quantidade de parcelas, Começa em, Data da compra, Fatura da 1ª parcela (+ hint da última parcela, como hoje).  
**Ocultos:** toggle “Compra parcelada?” (já implícito), Frequência (forçada mensal), Dividida, Pago no cartão?, Ativa?.

**Defaults:** `noCartao=true`, `parcelado=true`, `ativo=true`; `dataFim` continua calculado por `dataInicio + totalParcelas - 1`.

### Mapeamento data + fatura → template

- Data → `diaCompra` (só o dia)
- Fatura inicial / da 1ª parcela → `dataInicio` (`YYYY-MM`)
- “Começa em” no form atual já é `type="month"`; no modo cartão pode coincidir com a fatura inicial ou ser o mesmo campo — **regra:** um único seletor de mês = `dataInicio` = fatura da primeira cobrança; a data completa só alimenta `diaCompra`. Se a UI mostrar “Começa em” e “Fatura” separados, devem permanecer sincronizados ou a Fatura substitui “Começa em” no modo cartão (preferência: **Fatura substitui “Começa em”** no slim, menos campos).

## Modelo de dados / fórmulas

Sem coleção nova e sem campo `dataCompra` persistido.

| UX | Persistência |
|---|---|
| Data da compra/cobrança | `diaCompra` (number 1–31) |
| Fatura (avulsa) | seletor na UI → `competencia` **derivada** (anti double-shift) |
| Fatura inicial (template) | `expense_templates.dataInicio` |

**Semântica (UX):** o seletor mostra/escolhe o **mês da fatura**. A sugestão inicial usa `gcFaturaCompetencia(mêsDaData, dia, diaFechamento)`; o usuário pode sobrescrever.

**Persistência (anti double-shift):** `gcFaturaInstances` **não muda**. Ao salvar avulsa pelo Cartão, gravar `competencia` de compra tal que a fórmula atual devolva a fatura escolhida:

- Se há `diaCompra` e `diaFechamento` e `diaCompra > diaFechamento`: `competencia = gcShiftCompetencia(faturaEscolhida, -1)`
- Caso contrário: `competencia = faturaEscolhida`
- `diaCompra` = dia da data

Assim a fatura explícita funciona sem alterar o filtro nem o demo (Apple One dia 22 / fechamento 20).

Para templates (recorrente/parcelada): `dataInicio` = mês da fatura inicial escolhida; `diaCompra` = dia da data; a geração lazy e o shift na listagem continuam como hoje.

Teste manual obrigatório: Apple One demo intacto + avulsa nova com fatura explícita diferente da sugestão automática.

Checkbox “pago” na **lista** da fatura permanece; só some do formulário.

## Edição

- Toque numa linha da fatura → abre o form slim de avulsa (instância), como hoje abre o form de instância.
- Editar template recorrente/parcelado criado pelo Cartão continua possível pela aba Recorrências (form completo) ou, se no futuro houver atalho, pelo mesmo template form — **neste escopo não é obrigatório** abrir template a partir da fatura (instâncias geradas seguem o comportamento atual).

## Escopo

**Incluído**

- `cartaoFabMenu` com 3 opções
- Modo cartão em `GcExpenseInstanceForm` e `GcExpenseTemplateForm`
- Campos data + fatura no slim; defaults e flags forçadas
- Ajuste necessário em listagem/fórmula para não double-shift
- Demo/smoke manual na aba Cartão

**Fora**

- Persistir data completa no Firestore
- Múltiplos cartões
- Alterar o form completo de Despesas / Recorrências (exceto props/defaults compartilhados que não mudem a UI padrão)
- Remover o checkbox “pago” da lista da fatura

## Verificação

1. Cartão → + → três opções no menu.
2. Avulsa: sem Situação / Dividida / Pago no cartão; com Data + Fatura; aparece na fatura escolhida.
3. Recorrente: cria template `noCartao`, gera instâncias; entra na fatura conforme dia/fechamento ou `dataInicio`.
4. Parcelada: cria template parcelado; pill N/M na fatura; sem confundir com recorrente infinita.
5. Despesas → avulsa/recorrência: formulário completo intacto.
6. Marcar pago na lista da fatura ainda funciona.
