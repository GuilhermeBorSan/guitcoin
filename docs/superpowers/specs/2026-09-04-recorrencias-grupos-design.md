# Reorganização de grupos de despesas + valor fixo/variável

**Data:** 2026-09-04  
**App:** Guitcoin  
**Status:** aprovado em brainstorm

## Problema

Os grupos atuais (`casa`, `pessoal`, `pix`, `cartao_fixo`) misturam forma de pagamento com área da vida. Na prática:

- `cartao_fixo` = assinaturas automáticas no cartão, valor fixo
- `casa` = contas mensais com valor variável
- Cartão de crédito e Cerâmica = mensais variáveis (hoje em grupos diferentes)
- MEI, Plano de Saúde e Psicóloga = mensais fixos (hoje misturados com Cerâmica em PIX)

## Decisões

1. **Eixo principal:** área da vida (grupos)
2. **Segundo eixo:** flag `valorTipo` fixo | variável em cada template
3. **Comportamento no mês:** variáveis nascem com valor estimado + estado “a confirmar”; fixas já entram confirmadas
4. **Escopo de UI:** Recorrências **e** Despesas usam os mesmos grupos; despesas avulsas escolhem entre as mesmas áreas (some o grupo fixo `compras`)

## Modelo de dados

### `expense_categories` (seed)

| id | nome | ordem |
|---|---|---|
| `casa` | Casa | 0 |
| `saude` | Saúde | 1 |
| `assinaturas` | Assinaturas | 2 |
| `pessoal` | Pessoal | 3 |
| `trabalho` | Trabalho | 4 |

Remover do seed: `pix`, `cartao_fixo`, `compras`.

Categorias continuam editáveis pela UI existente de categorias (como hoje).

### `expense_templates` — campo novo

- `valorTipo`: `"fixo"` | `"variavel"`
- Documentos antigos sem o campo: tratar como `"fixo"` (default seguro — não pedem confirmação extra)

### `expense_instances` — campo novo

- `valorConfirmado`: `boolean`
- Na geração lazy (`gcGenerateMissingInstances`):
  - template `fixo` → `valorConfirmado: true`, `valor` = `valorPadrao`
  - template `variavel` → `valorConfirmado: false`, `valor` = `valorPadrao` (estimado)
- Avulsas (sem `templateId`): `valorConfirmado: true` na criação
- Ao salvar edição de valor de uma instância variável → `valorConfirmado: true`
- Documentos antigos sem o campo: tratar como `true` (já “existiam” como dados finais)

### Custo de Vida / Dashboard

Continua somando todas as instâncias pelo valor atual (incluindo estimados não confirmados). Não subestimar o mês por causa de pendências de confirmação.

## UI — Recorrências

- Lista **agrupada por grupo** (mesmo padrão visual de Despesas: cabeçalho de seção + linhas)
- Em cada linha: **nome** + pill `Fixo`/`Variável` **depois do nome**; subtítulo (frequência / pausa / parcela); valor à direita
- Formulário: Segmented `Fixo` / `Variável`; label do valor = “Valor padrão” (fixo) ou “Valor estimado” (variável)

## UI — Despesas

- Agrupamento pelos mesmos 5 grupos
- Variáveis não confirmadas: badge “a confirmar” (e subtítulo opcional “estimado”)
- Statcard adicional no mês: contagem “A confirmar” (além de Total lançado / Meu custo)
- Checkbox “pago” permanece independente de `valorConfirmado`
- Formulário de avulsa: select de grupo com as 5 áreas (sem `compras`)
- Editar valor (blur/salvar no form) de variável → marca `valorConfirmado: true`

## Seed / remapeamento demo

| Item | Grupo | valorTipo |
|---|---|---|
| CAESB, NEOENERGIA, SuperGás, Internet | `casa` | `variavel` |
| Plano de Saúde, Psicóloga | `saude` | `fixo` |
| Apple One, iCloud+, Youtube Premium, Disney+, PSN, Nintendo Online, Google One, TickTick | `assinaturas` | `fixo` |
| Cartão de crédito, Cerâmica | `pessoal` | `variavel` |
| MEI | `trabalho` | `fixo` |
| Avulsas demo “Compras” | `pessoal` | — (`valorConfirmado: true`) |

## Fora de escopo

- Script de migração automática no Firestore de produção (se já houver dados com grupos antigos: reimportar ou ajustar na UI)
- Mudança de fórmulas do Dashboard além do agrupamento visual
- Filtro dedicado fixo/variável (pode vir depois; o badge basta nesta rodada)

## Verificação manual

1. Recorrências: seções Casa / Saúde / Assinaturas / Pessoal / Trabalho; pills depois do nome
2. Despesas (mês atual): contas de casa e Cartão com “a confirmar”; assinaturas/saúde/MEI sem badge
3. Editar valor de uma variável → badge some; persiste ao trocar de mês e voltar
4. Avulsa nova: só as 5 áreas no select
5. Demo: Totais do Dashboard não “furam” por causa de estimados (ainda somam)
6. Modo local: seed novo carrega sem grupos órfãos (`pix` / `cartao_fixo`)
