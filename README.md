# FontesTech - Blog de IA e Tecnologia

Blog automatizado sobre Inteligência Artificial e Tecnologia, otimizado para SEO e monetização com Google AdSense.

🌐 **URL:** https://fontesrubens4.github.io

## Como Funciona

1. **Geração de conteúdo:** Scripts usam a API gratuita do Gemini para gerar artigos otimizados para SEO
2. **Publicação automática:** GitHub Actions publica artigos diariamente
3. **Deploy:** Hugo gera o site estático, GitHub Pages serve gratuitamente
4. **Monetização:** Google AdSense (configurar após ter tráfego)

## Estrutura

```
├── content/posts/       # Artigos do blog
├── layouts/             # Templates HTML
├── static/css/          # Estilos
├── scripts/             # Scripts de geração de conteúdo
├── .github/workflows/   # Automações (deploy + geração)
└── hugo.toml            # Configuração do Hugo
```

## Gerar Artigos Manualmente

```bash
# Configurar chave da API (grátis em https://aistudio.google.com/app/apikey)
export GEMINI_API_KEY="sua-chave-aqui"

# Gerar um artigo
./scripts/generate_article.sh "Título do Artigo" "palavra-chave"

# Gerar vários artigos
./scripts/generate_batch.sh
```

## Geração Automática

O GitHub Actions gera e publica 1 artigo por dia automaticamente.
Para funcionar, configure o secret `GEMINI_API_KEY` em:
Settings → Secrets → Actions → New repository secret

## Próximos Passos

1. [x] Setup inicial do site
2. [ ] Configurar GEMINI_API_KEY no GitHub Secrets
3. [ ] Registrar no Google Search Console
4. [ ] Submeter sitemap
5. [ ] Após 3-6 meses: aplicar para Google AdSense
