#!/bin/bash
# Script para gerar múltiplos artigos de uma vez
# Uso: ./generate_batch.sh
# Requer: GEMINI_API_KEY configurada

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Lista de artigos para gerar (título | palavra-chave)
ARTICLES=(
    "Como Usar o Google Gemini: Guia Completo para Iniciantes|google gemini como usar"
    "10 Sites com IA para Criar Logo Grátis|criar logo ia gratis"
    "Como a IA Pode Ajudar no Seu Trabalho em 2026|ia no trabalho produtividade"
    "ChatGPT vs Gemini vs Claude: Qual é Melhor em 2026|chatgpt vs gemini vs claude"
    "Como Usar IA para Escrever Emails Profissionais|ia escrever emails"
    "5 Ferramentas de IA para Editar Fotos Grátis|editar fotos ia gratis"
    "Como Criar um Currículo Perfeito com IA|curriculo com ia"
    "IA para Programadores Iniciantes: Por Onde Começar|ia programacao iniciantes"
    "Como Usar IA para Criar Apresentações Incríveis|ia criar apresentacoes"
    "Melhores Extensões de IA para Chrome em 2026|extensoes ia chrome"
)

echo "📝 Gerando ${#ARTICLES[@]} artigos em lote..."
echo "---"

SUCCESS=0
FAIL=0

for article in "${ARTICLES[@]}"; do
    TITLE=$(echo "$article" | cut -d'|' -f1)
    KEYWORD=$(echo "$article" | cut -d'|' -f2)
    
    echo ""
    echo "📄 [$((SUCCESS + FAIL + 1))/${#ARTICLES[@]}] $TITLE"
    
    if "$SCRIPT_DIR/generate_article.sh" "$TITLE" "$KEYWORD"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAIL=$((FAIL + 1))
        echo "   ⚠️ Falhou, continuando..."
    fi
    
    # Esperar 5 segundos entre requisições (rate limit da API gratuita)
    echo "   ⏳ Aguardando 5s (rate limit)..."
    sleep 5
done

echo ""
echo "=== RESULTADO ==="
echo "✅ Sucesso: $SUCCESS"
echo "❌ Falhas: $FAIL"
echo "📊 Total: ${#ARTICLES[@]}"
