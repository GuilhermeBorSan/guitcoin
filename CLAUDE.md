# Guitcoin — instruções para sessões futuras

## O que é
App pessoal de controle financeiro (receitas, despesas recorrentes e avulsas,
investimentos, lista de desejos), substituindo a planilha de finanças do Gui.
Estruturado seguindo literalmente o padrão de dois apps irmãos do Gui, também
de arquivo único: [Guitchelin](https://github.com/GuilhermeBorSan/guitchelin)
(crítica gastronômica) e [Letterborgs](https://github.com/GuilhermeBorSan/letterborgs)
(diário de filmes). Dono: Gui. Prefere pt-BR, pedidos curtos e iteração
rápida, e quer confirmação antes de mudanças estruturais grandes. Plano
completo de estruturação em `C:\Users\gui30\.claude\plans\c-users-gui30-downloads-finan-as-pdf-go-imperative-lamport.md`.

## Onde está o código
- App inteiro em UM arquivo estático: `index.html` na raiz. SEM etapa de
  build: React 18 + ReactDOM + Babel Standalone (`@7`, fixo) via CDN, JSX
  transpilado no navegador. Rodar = abrir o `index.html` (dois cliques) ou o
  deploy estático na Vercel.
- Persistência: Supabase, projeto **próprio e separado** do Guitchelin/
  Letterborgs (ainda não provisionado — ver Roadmap). Schema/RLS em
  `supabase/schema.sql`, rodar uma vez no SQL Editor do painel. Isolada no
  hook `useGcData(session)` — as telas só conhecem os verbos `saveX`/
  `deleteX`/`toggleXFlag` e os arrays de dados, nunca chamam `gcSupabase`
  direto. RLS por dono (`user_id = auth.uid()`, default na coluna), cada
  linha só é visível/editável por quem a criou.
- Login OBRIGATÓRIO (app de uso pessoal, mas com auth real): tela `GcLogin`
  (e-mail/senha via `gcSupabase.auth.signInWithPassword`), sessão observada
  em `useGcSession` (`onAuthStateChange` + watchdog de 6s pra nunca travar em
  "Carregando..."). Sem sessão, `GcRoot` mostra só o login; não há tela de
  cadastro (a única conta é a do Gui, criada direto no painel). "Allow new
  users to sign up" no painel deve ficar DESLIGADO depois de confirmar que o
  login funciona em produção.
- Cliente Supabase criado com `{ auth: { persistSession:true,
  autoRefreshToken:true, lock: gcAuthLock } }`, onde `gcAuthLock` é um
  passthrough (`async (_n,_t,fn) => fn()`) — workaround de um deadlock real
  do `navigator.locks` em PWA iOS (herdado do Guitchelin). Não remover.
- `GC_IS_LOCAL` (`localhost`/`127.0.0.1`): modo demo local — fabrica uma
  sessão falsa e todo `save*`/`delete*` retorna sem tocar o Supabase. Permite
  abrir o app com duplo clique sem depender de rede/credenciais.
- Sem etapa de build, então não há `import.meta.env`/`process.env`: a URL e a
  publishable key do Supabase ficam como constantes no próprio `index.html`
  (`GC_SUPABASE_URL`/`GC_SUPABASE_ANON_KEY`, hoje só placeholders — ver
  Roadmap). Isso é seguro porque é a publishable key (não a secret) e o RLS
  fica ativo — expô-la no HTML é o comportamento esperado.
- Tudo prefixado `gc`/`Gc`/`.gc-*`. As primitivas de UI genéricas (`Modal`,
  `Field`, `Segmented`, `TabBar`, `EmptyState`) usam o prefixo `lb-` herdado
  do Letterborgs (mesma família compartilhada com o Guitchelin) — foram
  copiadas de lá porque as versões desses componentes no Guitchelin são
  recortes parciais.

## Modelo de dados
Sete tabelas normalizadas (`income_sources`/`income_entries`/
`income_projections` da Fase 1, `expense_templates`/`expense_instances` da
Fase 2 e `investment_snapshots` da Fase 3 já implementadas; só
`wishlist_items` falta — ver Roadmap):
- `income_sources` — fontes de renda: `nome`, `tipo` (`work`|`extra`),
  `ativo`, `ordem`.
- `income_entries` — um lançamento por fonte por mês: `source_id`,
  `competencia` ("YYYY-MM"), `valor`.
- `income_projections` — projeção manual anual: `ano`,
  `renda_fixa_mensal_esperada`.
- `expense_templates` — definição de recorrência: `nome`, `grupo`
  (`casa`|`pessoal`|`pix`|`cartao_fixo`), `frequencia` (`mensal`|`anual`),
  `mes_cobranca`, `dia_vencimento`, `valor_padrao`, `compartilhado`,
  `compartilhado_com`, `minha_parcela_pct` (0–100), `ativo`, `data_inicio`,
  `data_fim`, `observacao`.
- `expense_instances` — uma linha por template por mês (+ compras avulsas
  sem template): `template_id`, `grupo`, `descricao`, `competencia`,
  `valor`, `pago`, `compartilhado`, `compartilhado_com`, `minha_parcela_pct`
  (campos de divisão copiados do template no momento da geração, não ao
  vivo). **Custo de vida de uma instância = `valor * minha_parcela_pct /
  100`** — é assim que uma conta dividida com terceiro (ex.: contas de casa
  divididas com o Bruno, `minha_parcela_pct = 0`) some do Custo de Vida sem
  deixar de aparecer na lista com o checkbox de "pago".
- `investment_snapshots` — saldo mensal (net worth): `competencia`, `saldo`,
  `observacao`.
- `wishlist_items` — Lista de Sonhos: `categoria` (texto livre, seed
  `CASA/LUNA/VESTUÁRIO/TECH/CARE/MISC`), `produto`, `marca`, `modelo`,
  `link`, `obs`, `preco`, `comprado`.

**Geração de instância recorrente é lazy, no carregamento dos dados**:
`gcGenerateMissingInstances(templates, instances, competenciaAtual)` calcula
todo par `(template, mês)` que falta e cria (`pago:false`, valor/divisão
copiados do template) — mensal gera todo mês desde `data_inicio` até hoje (ou
`data_fim`); anual só gera no mês `mes_cobranca` do ano corrente. Nunca gera
meses futuros adiantado (evita ter que reeditar instância por causa de
reajuste de preço, ex. Disney+ subindo mês a mês).

## Design (mesma família visual de Guitchelin/Letterborgs, paleta própria)
- Tema claro, fundo branco. Verde-dinheiro de destaque (`--gc-accent:
  #1C7A4D`), vermelho pra despesa/negativo (`--gc-red: #C23B3B`), dourado de
  realce (`--gc-gold: #B08A2E`), cinza-esverdeado suave (`--gc-line`,
  `--gc-surface-2`), texto quase-preto (`--gc-ink`).
- 3 fontes (Google Fonts), mesma combinação da família: Playfair Display
  (títulos/big numbers), EB Garamond (corpo), Space Grotesk (UI/labels e
  **números monetários**, com `font-variant-numeric: tabular-nums`).
- Marca: `GcCoin` (SVG círculo + cifrão), usada no topbar e como ícone de
  abrir/fechar a gaveta lateral (outline fechado, preenchido aberto — mesmo
  padrão do `GgFlower` do Guitchelin).
- Navegação: nav inferior (`.gc-bottomnav`) = Dashboard · + (FAB contextual)
  · Despesas (Despesas é o uso diário — marcar contas como pagas — por isso
  fica fixa; Dashboard é a tela de entrada). Gaveta lateral (`.gc-sidebar`)
  com **Financeiro** (Receitas, Recorrências, Investimentos) e **Listas**
  (Lista de Sonhos) + Sair. Rota por estado local: `subTab` (sem
  react-router).
- Telas: Dashboard (só leitura), Receitas (lista + modal), Despesas (lista
  agrupada por `grupo` com checkbox "pago" inline), Recorrências (CRUD de
  templates), Investimentos (lista + modal + gráfico), Lista de Sonhos
  (agrupada por categoria + subtotal/total).
- Gráficos: sem biblioteca, SVG/CSS puro (barras 2 séries receita×gastos,
  linha/área pra evolução de investimentos) — mesmo estilo de `GgColumns`
  (Guitchelin) e `MonthLineChart`/`PieChart` (Letterborgs).

## Fórmulas (constantes editáveis no topo do script)
- `GC_PODER_COMPRA_BASE = 1000` — **confirmado pelo Gui** (Fase 3):
  `saldoEmCaixa / 1000 * 100`, bate exatamente com a planilha (5177,32% pro
  saldo de R$51.773,18). Mantida como constante nomeada, nunca embutida
  diretamente numa função.
- `gcTaxaDePoupanca = (faturamentoAnual - custoDeVidaAnual) / faturamentoAnual`,
  `gcMediaMensalDeGastos = custoDeVidaAnual / 12`, `gcSaldoEmCaixa` = saldo do
  snapshot de investimento mais recente — todas conferidas contra os números
  da planilha original.
- Lista completa de funções puras planejadas: ver a seção "Pure Functions /
  Formulas Module" do plano de estruturação.

## Roadmap (confirmar prioridade com o Gui antes de atacar)
- **Provisionar o projeto Supabase do Guitcoin** (separado do Guitchelin) +
  criar a conta única do Gui no painel + preencher `GC_SUPABASE_URL`/
  `GC_SUPABASE_ANON_KEY` no `index.html` (hoje são placeholders). Desligar
  "Allow new users to sign up" depois de validar login em produção. Decidido
  fazer isso só no fim, depois de todas as fases prontas (até lá, só modo
  demo local).
- ~~Fase 1 — Receitas (tabelas + tela)~~ ✅ feito: `GcReceitas` (cards de
  projeção + seletor de mês + grid por fonte), `GcIncomeSourceForm`,
  `GcIncomeProjectionForm`.
- ~~Fase 2 — Despesas + Recorrências~~ ✅ feito: `GcDespesas` (lista
  agrupada por categoria + checkbox de pago inline + statcards "Total
  lançado"/"Meu custo"), `GcRecorrencias` (CRUD de templates),
  `GcExpenseInstanceForm`, `GcExpenseTemplateForm`, motor
  `gcGenerateMissingInstances` (geração lazy até o mês atual, mensal ou
  anual, respeitando pausa/data-fim).
- ~~Fase 3 — Investimentos~~ ✅ feito: `GcInvestimentos` (saldo mensal
  editável inline + histórico + statcards Saldo em Caixa/Poder de Compra),
  `GcInvestmentSnapshotForm`. **`GC_PODER_COMPRA_BASE = 1000` confirmado
  pelo Gui** como a base a usar (bate exatamente com a planilha: 5177,32%
  em modo demo).
- Fase 4 — Lista de Sonhos.
- Fase 5 — Dashboard + Análises (big numbers, fluxo de caixa, gráficos);
  confirmar `GC_PODER_COMPRA_BASE` com o Gui antes de fechar essa fase.
- Hospedar na Vercel (`guitcoin.vercel.app`), repo estático sem build. URL de
  produção precisa estar em Supabase → Authentication → URL Configuration
  pro login funcionar lá.
- Ícones reais do PWA (hoje só `assets/icon.svg` placeholder; faltam os PNGs
  32/180/192/512 referenciados pelo padrão do Guitchelin).

## Migrações do Supabase (colunas novas)
Sem etapa de build, o write manda todas as colunas — coluna nova no objeto
exige coluna nova na tabela ANTES de publicar, senão o upsert falha. O
`schema.sql` guarda cada `alter table ... add column if not exists ...`
comentado; rodar a linha uma vez no SQL Editor. Última coluna adicionada:
nenhuma ainda desde o schema inicial da Fase 3 (`investment_snapshots` já
nasceu com todas as colunas).

## Como verificar mudanças
Abra o `index.html` no navegador — entra direto em modo demo local
(`GC_IS_LOCAL`), sem tela de login. Fora do localhost (produção), sem sessão
o app mostra só a tela de login (ainda sem credenciais reais até o Supabase
ser provisionado).

- **Shell (Fase 0)**: navegue entre Dashboard/Despesas pela nav inferior e
  pela gaveta lateral (Recorrências/Investimentos/Lista de Sonhos ainda
  mostram `EmptyState` de "em construção"). O FAB central abre um aviso
  contextual nessas telas ainda não implementadas.
- **Receitas (Fase 1)**: abra Receitas pela gaveta — deve mostrar os cards
  "Renda Fixa Anual (Garantida)"/"Extra Acumulado (YTD)"/"Projeção Total"
  batendo com os números da planilha original (R$57.600 / R$235 / R$57.835
  em modo demo), o seletor de mês começando no último mês com lançamento
  (Jul/2026 no demo) e a lista de fontes (WriteChoice "Fixa", Cambridge
  "Extra") com o valor daquele mês editável inline. Edite um valor (deve
  atualizar o "Total do mês" ao sair do campo), navegue pra outro mês e
  volte (o valor deve persistir), toque no card de projeção pra editar
  `renda_fixa_mensal_esperada`, e toque no FAB pra cadastrar uma fonte nova
  (Fixa ou Extra) — deve aparecer na lista imediatamente.

- **Despesas + Recorrências (Fase 2)**: abra Recorrências pela gaveta —
  deve listar as 17 recorrências de demo (Casa/Pessoal/PIX/Cartão fixo),
  mostrando "Anual · <mês>" pras assinaturas anuais (PSN/Nintendo Online em
  Jan, Google One em Jul, TickTick em Out), "pausada" na Cerâmica (parou em
  Jul/2026) e "0% minha parte" nas 4 contas de Casa (CAESB/NEOENERGIA/
  SuperGás/Internet, divididas com o Bruno). Abra Despesas — o mês atual já
  deve ter as instâncias geradas sozinhas pra cada recorrência ativa
  (confirme que a Cerâmica NÃO aparece mais e que nenhuma anual fora do seu
  mês aparece); confirme que "Total lançado" soma tudo mas "Meu custo (após
  divisão)" é menor exatamente pelo valor das 4 contas do Bruno. Marque uma
  despesa como paga (checkbox inline, sem abrir modal) e confirme que
  persiste ao trocar de mês e voltar. Toque numa linha pra abrir o formulário
  de edição (confirme os campos de divisão pré-preenchidos) e no FAB em
  Despesas (deve abrir um menu com "Despesa avulsa" e "Nova recorrência") e
  em Recorrências (deve abrir direto o formulário de nova recorrência, com o
  campo "Mês de cobrança" aparecendo só quando a frequência é Anual).

- **Investimentos (Fase 3)**: abra Investimentos pela gaveta — em modo demo
  deve mostrar Saldo em Caixa R$51.773,18 e Poder de Compra 5.177,32%
  (mesmos números da planilha), com o histórico de Jan a Jul/2026. Edite o
  campo "Saldo em <mês atual>" (ele começa vazio, já que o demo só tem dado
  até julho) e confirme que, ao sair do campo, o valor aparece no topo do
  histórico e que Saldo em Caixa/Poder de Compra recalculam imediatamente
  (o snapshot mais recente por competência manda, não por ordem de
  cadastro). Toque no FAB — deve abrir "Registrar saldo" pré-preenchido com
  o mês atual e o valor já salvo dele.

A partir da Fase 4, cada fase acrescenta seu próprio roteiro de verificação
(ver a seção "Verification Plan" do plano de estruturação) — recarregar e
confirmar persistência via Supabase (depois que o projeto for provisionado).

## Convenções de trabalho
- Responder e escrever UI sempre em pt-BR.
- Pedidos curtos, iteração rápida; confirmar antes de mudanças estruturais
  grandes (ex.: trocar de arquitetura, introduzir build step, mudar
  persistência).
