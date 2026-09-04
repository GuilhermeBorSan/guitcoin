# Guitcoin

Controle financeiro pessoal do Gui: dashboard, receitas, despesas (com
recorrências automáticas), investimentos e lista de desejos, substituindo a
antiga planilha de finanças.

App de arquivo único (`index.html`), sem etapa de build, React + Babel
Standalone + Firebase (Auth + Firestore) via CDN — mesma filosofia de
[Guitchelin](https://github.com/GuilhermeBorSan/guitchelin) e
[Letterborgs](https://github.com/GuilhermeBorSan/letterborgs) (que usam
Supabase; o Guitcoin foi pro Firebase por conta do limite de projetos free
do Supabase). Ver [CLAUDE.md](CLAUDE.md) para detalhes de arquitetura,
modelo de dados e roadmap.

Rodar localmente: abra `index.html` no navegador (dois cliques) — entra
automaticamente em modo demo local, sem tocar no Firebase de produção.
