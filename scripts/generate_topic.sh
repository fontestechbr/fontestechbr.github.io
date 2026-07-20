#!/bin/bash
# Script autônomo: a IA escolhe o tema e gera o artigo
# A Gemini analisa os artigos existentes e sugere um tema novo e relevante

set -e

CONTENT_DIR="content/posts"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ Erro: GEMINI_API_KEY não configurada"
    exit 1
fi

# Listar artigos já publicados para evitar repetição
EXISTING_TITLES=$(ls "$CONTENT_DIR"/*.md 2>/dev/null | xargs grep "^title:" | sed 's/.*title: "//;s/"$//' | tr '\n' '|')

echo "📋 Artigos existentes: $(echo "$EXISTING_TITLES" | tr '|' '\n' | wc -l | tr -d ' ')"

# Passo 1: Pedir para a IA sugerir um tema novo
TOPIC_PROMPT="Você é um especialista em SEO e marketing de conteúdo para um blog brasileiro chamado FontesTech, focado em inteligência artificial e tecnologia para iniciantes.

Artigos já publicados (NÃO repita estes temas):
$EXISTING_TITLES

Sua tarefa: sugira UM novo artigo que:
1. Seja sobre IA, ferramentas de tecnologia, produtividade com IA, ou tutoriais práticos
2. Tenha alto potencial de busca no Google Brasil
3. Seja diferente dos artigos já publicados
4. Seja útil e prático para iniciantes
5. Tenha uma palavra-chave de cauda longa

Responda APENAS neste formato exato (sem mais nada):
TITULO: [título otimizado para SEO, máximo 60 caracteres]
KEYWORD: [palavra-chave principal de cauda longa, 3-5 palavras]"

echo "🧠 Pedindo tema para a IA..."

REQUEST_BODY=$(jq -n --arg prompt "$TOPIC_PROMPT" '{
  "contents": [{"parts":[{"text": $prompt}]}],
  "generationConfig": {
    "temperature": 1.0,
    "maxOutputTokens": 200
  }
}')

# Chamar API para gerar tema
MODELS=("gemini-3.1-flash-lite" "gemini-2.0-flash" "gemini-2.0-flash-lite")
TOPIC_RESPONSE=""

for MODEL in "${MODELS[@]}"; do
    TOPIC_RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=$GEMINI_API_KEY" \
      -H 'Content-Type: application/json' \
      -d "$REQUEST_BODY")
    
    ERROR_CODE=$(echo "$TOPIC_RESPONSE" | jq -r '.error.code // empty')
    if [ -z "$ERROR_CODE" ]; then
        break
    fi
    echo "   ⚠️ Modelo $MODEL falhou ($ERROR_CODE), tentando próximo..."
    sleep 5
done

# Extrair título e keyword da resposta
TOPIC_TEXT=$(echo "$TOPIC_RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')

if [ -z "$TOPIC_TEXT" ]; then
    echo "❌ Não conseguiu gerar tema. Resposta:"
    echo "$TOPIC_RESPONSE" | jq .
    exit 1
fi

echo "📝 Resposta da IA: $TOPIC_TEXT"

# Parsear TITULO e KEYWORD
TITLE=$(echo "$TOPIC_TEXT" | grep -i "^TITULO:" | sed 's/^TITULO: *//i' | tr -d '\r')
KEYWORD=$(echo "$TOPIC_TEXT" | grep -i "^KEYWORD:" | sed 's/^KEYWORD: *//i' | tr -d '\r')

# Fallback se o parsing falhar
if [ -z "$TITLE" ] || [ -z "$KEYWORD" ]; then
    echo "⚠️ Parsing falhou, tentando extrair de forma alternativa..."
    TITLE=$(echo "$TOPIC_TEXT" | head -1 | sed 's/.*: *//' | tr -d '\r')
    KEYWORD=$(echo "$TOPIC_TEXT" | tail -1 | sed 's/.*: *//' | tr -d '\r')
fi

if [ -z "$TITLE" ] || [ -z "$KEYWORD" ]; then
    echo "❌ Não foi possível extrair título e keyword da resposta:"
    echo "$TOPIC_TEXT"
    exit 1
fi

echo ""
echo "✅ Tema escolhido pela IA:"
echo "   Título: $TITLE"
echo "   Keyword: $KEYWORD"
echo ""

# Passo 2: Gerar o artigo com o tema escolhido
# Esperar 3 segundos para não bater rate limit
sleep 3

"$SCRIPT_DIR/generate_article.sh" "$TITLE" "$KEYWORD"
