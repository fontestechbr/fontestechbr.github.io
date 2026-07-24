#!/bin/bash
# Script para gerar artigos automaticamente usando IA (Gemini API gratuita)
# Uso: ./generate_article.sh "titulo do artigo" "palavra-chave principal"

set -e

CONTENT_DIR="content/posts"
DATE=$(date -u +%Y-%m-%dT%H:%M:%S+00:00)
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

# Preparar o body da requisição
REQUEST_BODY=$(jq -n --arg prompt "$PROMPT" '{
  "contents": [{"parts":[{"text": $prompt}]}],
  "generationConfig": {
    "temperature": 0.8,
    "maxOutputTokens": 4096
  }
}')

# Tentar múltiplos modelos em ordem de preferência
MODELS=("gemini-3.1-flash-lite" "gemini-2.0-flash" "gemini-2.0-flash-lite")
MAX_RETRIES=3
SUCCESS=false
RESPONSE=""

for MODEL in "${MODELS[@]}"; do
    echo "   🔍 Tentando modelo: $MODEL"
    RETRY_DELAY=30
    
    for i in $(seq 1 $MAX_RETRIES); do
        RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=$GEMINI_API_KEY" \
          -H 'Content-Type: application/json' \
          -d "$REQUEST_BODY")
        
        ERROR_CODE=$(echo "$RESPONSE" | jq -r '.error.code // empty')
        
        # Se não houve erro, sucesso!
        if [ -z "$ERROR_CODE" ]; then
            echo "   ✅ Modelo $MODEL funcionou!"
            SUCCESS=true
            break 2
        fi
        
        # Se 429 (rate limit), tentar novamente com delay
        if [ "$ERROR_CODE" = "429" ]; then
            echo "   ⏳ Rate limit ($MODEL). Tentativa $i/$MAX_RETRIES. Aguardando ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
            RETRY_DELAY=$((RETRY_DELAY * 2))
        else
            # Se 404 ou outro erro, tentar próximo modelo
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // "unknown"')
            echo "   ⚠️ Modelo $MODEL erro $ERROR_CODE: $ERROR_MSG"
            echo "   ➡️ Tentando próximo modelo..."
            break
        fi
    done
done

if [ "$SUCCESS" != "true" ]; then
    echo "❌ Todos os modelos falharam. Última resposta:"
    echo "$RESPONSE" | jq .
    exit 1
fi

# Extrair texto da resposta
ARTICLE_BODY=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [ -z "$ARTICLE_BODY" ]; then
    echo "❌ Erro ao extrair texto da resposta:"
    echo "$RESPONSE" | jq .
    exit 1
fi

# Gerar description curta (escapar aspas para não quebrar YAML)
DESCRIPTION=$(echo "$ARTICLE_BODY" | head -5 | tr '\n' ' ' | cut -c1-155 | sed 's/"//g')

# Escapar aspas no título também
SAFE_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')

# Criar arquivo com front matter
cat > "$CONTENT_DIR/$SLUG.md" << EOF
---
title: "$SAFE_TITLE"
date: $DATE
description: "$DESCRIPTION"
tags: [$(echo "$KEYWORD" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')]
categorias: ["tutoriais-ia"]
keywords: ["$KEYWORD", "$SAFE_TITLE"]
draft: false
---

$ARTICLE_BODY
EOF

echo "✅ Artigo gerado com sucesso: $CONTENT_DIR/$SLUG.md"
echo "   $(echo "$ARTICLE_BODY" | wc -w) palavras"
