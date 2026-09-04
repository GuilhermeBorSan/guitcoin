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
**As 6 fases do plano (shell/auth, Receitas, Despesas+Recorrências,
Investimentos, Lista de Sonhos, Dashboard) estão todas implementadas e
testadas em modo demo** — falta só criar o projeto Firebase de produção (ver
Roadmap) pra sair do modo demo local.

**Backend: Firebase, não Supabase.** O plano original (e os apps irmãos)
usava Supabase, mas o Gui bateu no limite de projetos free da conta
Supabase — em vez de criar organização nova ou reaproveitar um projeto
existente, decidiu trocar de provedor. Guitcoin é o único dos três apps
("Gg" family) que roda em Firebase; Guitchelin e Letterborgs continuam no
Supabase. Ver "Onde está o código" abaixo pro que muda na prática.

## Onde está o código
- App inteiro em UM arquivo estático: `index.html` na raiz. SEM etapa de
  build: React 18 + ReactDOM + Babel Standalone (`@7`, fixo) via CDN, JSX
  transpilado no navegador. Rodar = abrir o `index.html` (dois cliques) ou o
  deploy estático na Vercel.
- Persistência: **Firebase** (Authentication + Firestore), projeto próprio
  do Guitcoin (ainda não criado — ver Roadmap). SDK "compat" via CDN
  (`firebase-app-compat.js`/`firebase-auth-compat.js`/
  `firebase-firestore-compat.js`, mesmo espírito UMD do `supabase-js` —
  expõe um objeto global `firebase`, sem precisar de `<script type="module">`
  nem import). Regras de segurança em `firebase/firestore.rules`, colar no
  console (Firestore Database → Regras → Publicar; não tem CLI/build no
  fluxo, é só colar e publicar). Isolada no hook `useGcData(session)` — as
  telas só conhecem os verbos `saveX`/`deleteX`/`toggleXFlag` e os arrays de
  dados, nunca chamam `gcFirestore` direto.
- **Modelo de dados no Firestore**: cada "tabela" do plano original virou
  uma subcoleção em `users/{uid}/<colecao>/{id}` (`income_sources`,
  `income_entries`, `income_projections`, `expense_templates`,
  `expense_instances`, `investment_snapshots`, `wishlist_items`) — o próprio
  caminho do documento já escopa os dados por usuário, substituindo o RLS
  por `user_id = auth.uid()` do Postgres. Uma ÚNICA regra recursiva em
  `firestore.rules` (`match /users/{uid}/{document=**}`) cobre as 7
  coleções, em vez de 4 políticas por tabela. Sem mapeadores
  `gcRowToX`/`gcXToRow` (diferença do Guitchelin/Postgres): o Firestore não
  impõe snake_case, os documentos já nascem no mesmo formato camelCase que
  o resto do app usa (`mesCobranca`, `minhaParcelaPct`, etc.).
  `gcCollectionRef`/`gcFetchAll`/`gcUpsertOne`/`gcUpsertMany`/`gcDeleteOne`/
  `gcUpdateFields` (topo do script) são os únicos pontos que tocam
  `gcFirestore` — todo verbo do `useGcData` passa por eles.
- Login OBRIGATÓRIO (app de uso pessoal, mas com auth real): tela `GcLogin`
  (e-mail/senha via `gcAuth.signInWithEmailAndPassword`), sessão observada
  em `useGcSession` (`onAuthStateChanged` + watchdog de 6s pra nunca travar
  em "Carregando..."). Sem sessão, `GcRoot` mostra só o login; não há tela
  de cadastro — como o app NUNCA chama `createUserWithEmailAndPassword`,
  simplesmente não existe caminho de auto-cadastro (diferente do Supabase,
  não precisa de um toggle "Allow new users to sign up" pra desligar). A
  única conta é a do Gui, criada direto no console (Authentication → Users →
  Add user).
- `GC_IS_LOCAL` (`localhost`/`127.0.0.1`): modo demo local — fabrica uma
  sessão falsa e todo `save*`/`delete*` retorna sem tocar o Firebase. Permite
  abrir o app com duplo clique sem depender de rede/credenciais.
- Sem etapa de build, então não há `import.meta.env`/`process.env`: a config
  do Firebase fica como constante no próprio `index.html`
  (`GC_FIREBASE_CONFIG`, hoje só placeholders — ver Roadmap). Isso é seguro
  porque essa config (apiKey/authDomain/projectId/...) é pública por
  natureza no Firebase — quem protege os dados são as Security Rules, não o
  sigilo da config (mesmo raciocínio da anon key do Supabase + RLS).
- Tudo prefixado `gc`/`Gc`/`.gc-*`. As primitivas de UI genéricas (`Modal`,
  `Field`, `Segmented`, `TabBar`, `EmptyState`) usam o prefixo `lb-` herdado
  do Letterborgs (mesma família compartilhada com o Guitchelin) — foram
  copiadas de lá porque as versões desses componentes no Guitchelin são
  recortes parciais.

## Modelo de dados
As sete coleções do plano de estruturação (adaptadas de "tabela" pra
"subcoleção do Firestore", campos em camelCase direto, sem equivalente
snake_case) estão todas implementadas: `income_sources`/`income_entries`/
`income_projections` (Fase 1), `expense_templates`/`expense_instances`
(Fase 2), `investment_snapshots` (Fase 3) e `wishlist_items` (Fase 4):
- `income_sources` — fontes de renda: `nome`, `tipo` (`work`|`extra`),
  `ativo`, `ordem`.
- `income_entries` — um lançamento por fonte por mês: `sourceId`,
  `competencia` ("YYYY-MM"), `valor`.
- `income_projections` — projeção manual anual: `ano`,
  `rendaFixaMensalEsperada`.
- `expense_templates` — definição de recorrência: `nome`, `grupo`
  (`casa`|`pessoal`|`pix`|`cartao_fixo`), `frequencia` (`mensal`|`anual`),
  `mesCobranca`, `diaVencimento`, `valorPadrao`, `compartilhado`,
  `compartilhadoCom`, `minhaParcelaPct` (0–100), `ativo`, `dataInicio`,
  `dataFim`, `observacao`.
- `expense_instances` — uma linha por template por mês (+ compras avulsas
  sem template): `templateId`, `grupo`, `descricao`, `competencia`,
  `valor`, `pago`, `compartilhado`, `compartilhadoCom`, `minhaParcelaPct`
  (campos de divisão copiados do template no momento da geração, não ao
  vivo). **Custo de vida de uma instância = `valor * minhaParcelaPct /
  100`** — é assim que uma conta dividida com terceiro (ex.: contas de casa
  divididas com o Bruno, `minhaParcelaPct = 0`) some do Custo de Vida sem
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
- `.gc-app` é flex-column e `.gc-main` é `flex:1; overflow-y:auto`
  (descoberto faltando na Fase 5, quando o Dashboard passou a ter conteúdo
  mais alto que a tela) — é o que deixa a topbar/nav inferior fixas
  enquanto só o conteúdo rola, mesmo padrão do `.gg-main` do Guitchelin.
  Não remover: sem isso, telas compridas (Despesas com muitas linhas,
  Dashboard) ficam cortadas sem aviso dentro do preview local de iPhone
  (em produção real o `body` ainda rola, mas o efeito visual de
  topbar/nav fixos se perde).
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
- **Criar o projeto Firebase do Guitcoin**: console.firebase.google.com →
  Criar projeto (plano Spark, gratuito) → Authentication → Sign-in method →
  ativar "E-mail/senha" → Authentication → Users → Add user (a conta única
  do Gui) → Firestore Database → Criar banco de dados (modo produção) →
  Regras → colar o conteúdo de `firebase/firestore.rules` → Publicar →
  Configurações do projeto → Seus apps → Adicionar app Web → copiar o objeto
  `firebaseConfig` gerado pra dentro de `GC_FIREBASE_CONFIG` no
  `index.html` (hoje são placeholders). Sem toggle de "permitir cadastro"
  pra desligar (ver "Onde está o código"). Decidido fazer isso só no fim,
  depois de todas as fases prontas (até lá, só modo demo local).
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
- ~~Fase 4 — Lista de Sonhos~~ ✅ feito: `GcSonhos` (agrupada por categoria,
  subtotal + total só dos itens não comprados), `GcWishlistItemForm`
  (categoria como texto livre com sugestões via `<datalist>`).
- ~~Fase 5 — Dashboard + Análises~~ ✅ feito: `GcDashboard` (6 statcards,
  gráfico de barras 2 séries Receita×Gastos via `GcColumnsGrouped`, gráfico
  de área "Evolução dos Investimentos" via `GcAreaChart`, tabela de Fluxo de
  Caixa 12 meses + Total Anual com 1ª coluna sticky), seletor de ano,
  funções puras `gcReceitaPorMes`/`gcCustoPorMes`/`gcFaturamentoAnual`/
  `gcCustoDeVidaAnual`/`gcTaxaDePoupanca`/`gcMediaMensalDeGastos`/
  `gcInvestimentosPorMes`. **Todas as 6 fases do plano de estruturação estão
  completas.**

## Próximos passos (pós-plano original, sugestões — confirmar com o Gui)
- Editar/excluir um lançamento de receita específico (`deleteIncomeEntry` já
  existe no hook, falta UI).
- Exportar/importar dados (backup em JSON, ou importar extrato bancário).
- Fechar o mês (marcar competências passadas como "conferidas").
- Filtro de categoria/período na tela de Despesas (hoje só filtra por mês).
- Hospedar na Vercel (`guitcoin.vercel.app`), repo estático sem build. URL de
  produção precisa estar em Firebase → Authentication → Settings →
  Authorized domains pro login funcionar lá (o Firebase bloqueia
  `signInWithEmailAndPassword` de domínios não autorizados, mesmo com a
  config certa).
- Ícones reais do PWA (hoje só `assets/icon.svg` placeholder; faltam os PNGs
  32/180/192/512 referenciados pelo padrão do Guitchelin).

## Campos novos no Firestore (sem "migração" de verdade)
Firestore é schemaless: um campo novo num objeto salvo simplesmente aparece
no documento, sem precisar preparar nada antes (diferente do Postgres do
Guitchelin, que exige a coluna existir antes do upsert). Documentos antigos
sem esse campo continuam existindo — a tela precisa tratar o valor ausente
como "falsy"/default (mesmo cuidado de `row.campo || default` que os
mapeadores `gcRowToX` faziam antes; sem eles agora, quem lê o dado direto do
Firestore é quem tem essa responsabilidade). Vale a pena manter, aqui, o
registro do que foi o último campo adicionado — hoje nenhum ainda, schema
inicial completo desde a troca de Supabase pra Firebase.

## Como verificar mudanças
Abra o `index.html` no navegador — entra direto em modo demo local
(`GC_IS_LOCAL`), sem tela de login. Fora do localhost (produção), sem sessão
o app mostra só a tela de login (ainda sem credenciais reais até o projeto
Firebase ser criado).

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

- **Lista de Sonhos (Fase 4)**: abra Lista de Sonhos pela gaveta — em modo
  demo deve mostrar TECH (R$0,00, os 3 itens sem preço) e MISC (R$1.000,00,
  os 2 vinis a R$500), Total R$1.000,00, batendo com a planilha. Marque um
  item como comprado (ícone à esquerda da linha) e confirme que ele some da
  lista e o subtotal/total recalculam. Toque numa linha pra editar (confirme
  os campos pré-preenchidos) e no FAB pra criar um item novo (o campo
  Categoria sugere as 6 categorias seed via autocomplete, mas aceita
  qualquer texto).

- **Dashboard (Fase 5)**: abra o Dashboard (tela padrão de entrada) — em
  modo demo/2026 deve mostrar Faturamento Anual R$38.335,00, Saldo em Caixa
  R$51.773,18 e Poder de Compra 5.177,32% batendo exatamente com a
  planilha original (Custo de Vida/Taxa de Poupança/Média Mensal de Gastos
  vão divergir um pouco da planilha porque os valores de despesas do modo
  demo são ilustrativos, não uma cópia byte a byte — mas as FÓRMULAS batem:
  confira que Taxa de Poupança = (Faturamento − Custo de Vida) / Faturamento
  e Média Mensal = Custo de Vida / 12). Confira o gráfico de barras
  Receita×Gastos (verde/vermelho, só até o último mês com dado) e o gráfico
  de área de investimentos (sobe até julho e depois estabiliza — confirma
  que `gcInvestimentosPorMes` carrega o último saldo conhecido adiante nos
  meses sem snapshot novo). Role a tabela de Fluxo de Caixa até o fim
  (rótulo da linha deve ficar fixo/sticky enquanto os meses rolam
  horizontalmente) e confirme que "Investimentos" também carrega o saldo
  adiante ali. Troque o ano com as setas.
- **Persistência (todas as fases)**: depois que o projeto Firebase for
  criado (ver Roadmap), recarregue a página inteira e confirme que tudo
  sobrevive — teste definitivo de que o ciclo load/upsert do `useGcData`
  está certo pras 7 coleções. Confira também que a regra de
  `firestore.rules` está publicada (sem ela, toda leitura/escrita retorna
  "Missing or insufficient permissions" e `gcWriteErrorMsg` deveria
  traduzir isso pro banner pt-BR de sessão expirada).

## Convenções de trabalho
- Responder e escrever UI sempre em pt-BR.
- Pedidos curtos, iteração rápida; confirmar antes de mudanças estruturais
  grandes (ex.: trocar de arquitetura, introduzir build step, mudar
  persistência).
