#!/bin/bash
# Script para gerar artigos automaticamente usando IA (Gemini API gratuita)
# Uso: ./generate_article.sh "titulo do artigo" "palavra-chave principal"

set -e

CONTENT_DIR="content/posts"
DATE=$(date +%Y-%m-%dT%H:%M:%S-03:00)
SLUG=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')

# Verificar se GEMINI_API_KEY está configurada
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ Erro: Configure GEMINI_API_KEY"
    echo "   Obtenha grátis em: https://aistudio.google.com/app/apikey"
    echo "   export GEMINI_API_KEY='sua-chave-aqui'"
    exit 1
fi

TITLE="$1"
KEYWORD="$2"

if [ -z "$TITLE" ] || [ -z "$KEYWORD" ]; then
    echo "Uso: $0 \"Título do Artigo\" \"palavra-chave principal\""
    echo "Exemplo: $0 \"Como Usar o Gemini para Trabalhar\" \"gemini ia trabalho\""
    exit 1
fi

echo "🤖 Gerando artigo: $TITLE"
echo "   Palavra-chave: $KEYWORD"
echo "   Arquivo: $CONTENT_DIR/$SLUG.md"

# Prompt para gerar o artigo
PROMPT="Escreva um artigo completo de blog em português brasileiro sobre: \"$TITLE\".

Requisitos:
- Palavra-chave principal: \"$KEYWORD\" (use naturalmente no texto 3-5 vezes)
- Mínimo 1200 palavras
- Use headers H2 e H3 para estruturar
- Inclua listas, exemplos práticos e dicas
- Tom: informal mas informativo, como se estivesse conversando com um amigo
- Inclua uma introdução engajante e uma conclusão com call-to-action
- NÃO inclua o título principal (H1) no corpo - apenas H2 e H3
- Foco em ser útil e prático para o leitor

Retorne APENAS o conteúdo do artigo em Markdown, sem front matter, sem bloco de código envolvendo tudo."

# Chamar API do Gemini
RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{
    \"contents\": [{
      \"parts\":[{\"text\": $(echo "$PROMPT" | jq -Rs .)}]
    }],
    \"generationConfig\": {
      \"temperature\": 0.8,
      \"maxOutputTokens\": 4096
    }
  }")

# Extrair texto da resposta
ARTICLE_BODY=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [ -z "$ARTICLE_BODY" ]; then
    echo "❌ Erro ao gerar artigo. Resposta da API:"
    echo "$RESPONSE" | jq .
    exit 1
fi

# Gerar description curta
DESCRIPTION=$(echo "$ARTICLE_BODY" | head -5 | tr '\n' ' ' | cut -c1-155)

# Criar arquivo com front matter
cat > "$CONTENT_DIR/$SLUG.md" << EOF
---
title: "$TITLE"
date: $DATE
description: "$DESCRIPTION"
tags: [$(echo "$KEYWORD" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')]
categorias: ["tutoriais-ia"]
keywords: ["$KEYWORD", "$TITLE"]
draft: false
---

$ARTICLE_BODY
EOF

echo "✅ Artigo gerado com sucesso: $CONTENT_DIR/$SLUG.md"
echo "   $(echo "$ARTICLE_BODY" | wc -w) palavras"
