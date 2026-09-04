# Tema dark liquid glass + hub de navegação

**Data:** 2026-09-04  
**App:** Guitcoin  
**Status:** aprovado em brainstorm  
**Abordagem:** B — tokens dark/gold + camada `.gc-glass` + shell (hub sheet + FAB)

## Problema

O app está no tema claro da família Gg (fundo branco, accent verde). O Gui quer visual **liquid glass escuro**, alinhado a uma referência de nav flutuante glass, e reorganizar a navegação: unificar a topbar na marca **Guitcoin** (hoje ícone abre sidebar + nome leva ao dashboard) e deixar embaixo **só o FAB (+)**.

## Decisões

1. **Alcance:** app inteiro dark + glass (não só a nav)
2. **Paleta:** accent principal **dourado**; verde só em deltas/positivos; vermelho em despesa/negativo
3. **Tema claro:** removido (sem toggle)
4. **Navegação:** topbar = marca abre hub; bottom = só `+`; sidebar removida
5. **Hub:** bottom sheet glass com ícones (não fullscreen nem dropdown)
6. **Implementação:** CSS tokens + utilitário glass; layouts das telas e lógica de dados intactos
7. **Fontes:** mantém Playfair Display / EB Garamond / Space Grotesk

## Sistema visual

### Tokens (`:root`)

| Token | Direção |
|---|---|
| `--gc-bg` | quase preto (`#0A0A0A` ou próximo) |
| `--gc-surface` / `--gc-surface-2` | translúcidos claros sobre o fundo (ex. `rgba(255,255,255,.04–.08)`) |
| `--gc-line` | borda clara fina (`rgba(255,255,255,.10–.14)`) |
| `--gc-ink` | texto claro (`#E8E8E8` / off-white) |
| `--gc-ink-soft` | texto secundário acinzentado |
| `--gc-accent` | dourado (`#D4B45A` ou afinação próxima) |
| `--gc-accent-deep` | dourado mais escuro p/ hover |
| `--gc-red` | vermelho legível no dark |
| (positivo) | verde luminoso só em deltas/`gc-delta-up` / indicadores positivos — **não** reusa o accent principal |

Hardcoded `#fff` / fundos claros em CSS e componentes devem passar a usar tokens (ou equivalentes dark), incluindo login, modais, botões ghost, campos e footers de form.

### Utilitário glass

Classe (ou mixin CSS) `.gc-glass`:

- `background` semi-transparente escuro
- `backdrop-filter` / `-webkit-backdrop-filter: blur(...)` (≈16–24px)
- `border: 1px solid` clara com baixa opacidade
- `border-radius` coerente com o componente

Aplicar em: topbar, hub sheet, statcards, listas, totais, modais, segmented, login card, FAB container se necessário.

### Gráficos

- Labels/eixos em tom claro
- Barras receita × gastos: **dourado** × **vermelho** (não verde × vermelho)
- Área de investimentos: preenchimento/linha em dourado suave

## Shell / navegação

### Topbar

- Remover o botão `gc-sidebar-toggle` / `GcCoin` que abria a sidebar
- Centro (ou único controle de marca): botão **Guitcoin** (com indicador ▾/▴) que abre/fecha o hub
- Na prática a marca fica à **esquerda** da topbar (evita ficar atrás do Dynamic Island no preview iPhone); filtro de mês/ano permanece à direita

### Hub (`GcHub` / substituto da sidebar)

- Bottom sheet glass + backdrop escurecido
- Fecha ao: tocar backdrop, tocar de novo em Guitcoin, ou escolher um destino
- Grid de destinos com ícone + label, cobrindo **tudo** que hoje está em `GC_NAV_ITEMS` + ações da sidebar:
  - Dashboard, Despesas, Receitas, Recorrências, Investimentos, Lista de Sonhos, Conta (Ferramentas)
  - **Importar dados iniciais** (mesmo verbo atual; em modo local/demo pode permanecer desabilitado ou oculto conforme regra atual)
  - **Sair** (sign-out; em `GC_IS_LOCAL` comportamento igual ao atual)
- Rota ativa (`subTab`) destacada em dourado
- Estado: `hubOpen` no lugar de `sidebarOpen`

### Bottom

- Remover botões Dashboard e Despesas da `.gc-bottomnav`
- Permanecer **apenas** o FAB `+` (mesmo `onClick` contextual por `subTab`)
- FAB flutuante no **canto inferior direito**, com safe-area; a pill de nav completa some
- Ajustar padding inferior de `.gc-main` para o FAB não cobrir conteúdo

### Removidos

- `.gc-sidebar`, `.gc-sidebar-backdrop`, links/grupos da sidebar
- Nav inferior com 3 slots (Dash · + · Despesas)

## Superfícies (skin)

| Peça | Tratamento |
|---|---|
| Statcards | glass; números em dourado (ou verde se forem delta positivo explícito) |
| Listas / rows | glass ou superfície escura; divisórias `--gc-line` |
| Modais / forms | glass ou painel escuro; inputs sem fundo branco |
| Segmented / pills | trilho escuro; ativo em dourado ou glass mais opaco |
| Login | mesma família visual dark/glass |
| Empty states / hints | `--gc-ink-soft` |

## Fora de escopo

- Mudança de Firestore, auth, fórmulas, geração de recorrências, modo demo
- Redesign de layout/conteúdo das 6 telas (só skin + shell)
- PWA icons, deploy Vercel, projeto Firebase de produção
- Toggle claro/escuro
- Biblioteca de gráficos nova

## Critérios de aceite

1. Abrir `index.html` em localhost: app dark, sem tela clara residual óbvia (modais/inputs inclusos)
2. Topbar: um toque em Guitcoin abre o sheet; segundo toque ou backdrop fecha
3. Hub leva a todas as rotas atuais da sidebar + Conta; Sair e Importar preservam comportamento
4. Embaixo só o `+`; FAB continua abrindo o fluxo certo por tela
5. Accent dourado nos números principais; verde só em positivo; vermelho em despesa/negativo
6. Dashboard/Receitas/Despesas/etc. mostram os mesmos dados de demo de antes (só visual mudou)
