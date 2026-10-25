# Orion ED: pipeline de dados para RAG

Pipeline de engenharia de dados que coleta documentos (PDFs e páginas web), guarda o dado bruto em um data lake, transforma o texto em partes (chunks) e vetores e grava tudo em bancos de dados, para consulta por um agente de IA com RAG (Retrieval-Augmented Generation).

Projeto desenvolvido no **Grupo de Estudos em Engenharia de Dados do Orion – Laboratório de Ciência de Dados Aplicada a Cidades Inteligentes (UFAL)**, de fevereiro a junho de 2026, em etapas orientadas pelo laboratório.

## Arquitetura

```
 PDFs (arXiv) e páginas web
            │  scripts em shell (curl)
            ▼
  MinIO: data lake, padrão S3 (camada bronze, dado bruto)
            │
            ▼
  Python: extração e limpeza do texto
            │
            ▼
  Divisão em chunks + vetorização (modelo BGE-M3)
            │
            ├──► PostgreSQL (texto de cada chunk)
            └──► Qdrant     (vetor de cada chunk, mesmo id)

  API FastAPI (/pdf e /site): faz o mesmo processamento sob demanda

  Agente de RAG (Agno + Gemini): conversa usando a sua base de conhecimento
```

## Etapas

1. **Ingestão.** `05-baixar-pdfs.sh` baixa 20 artigos do arXiv (categoria cs.IR, recuperação de informação). `04-coletar-repo.sh` envia os PDFs ao MinIO pela API S3, com a requisição assinada (HMAC-SHA1): a senha não trafega pela rede.
2. **Transformação e vetorização.** `transformar.py` lê os PDFs do MinIO, extrai o texto (pypdf), limpa caracteres de controle e linhas em excesso, divide em chunks de 1.200 caracteres com sobreposição de 200, gera vetores de 1.024 posições com o modelo BGE-M3 e grava o texto no PostgreSQL e o vetor no Qdrant, ligados pelo mesmo id.
3. **API.** `app.py` (FastAPI) recebe um PDF em `POST /pdf` ou o endereço de um site em `POST /site` e aplica o mesmo processamento.
4. **Agente.** A pasta `rag-agno/` sobe um agente com o framework Agno, usando o Gemini como modelo de linguagem e de embeddings, busca híbrida no Qdrant e histórico da conversa no PostgreSQL, servido pelo AgentOS na porta 8008.

Os scripts `01`, `02` e `03` e o `teste_vetor.py` são da etapa inicial (subir o MinIO, baixar uma página e enviá-la ao data lake) e ficam no repositório como registro do percurso.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Linguagens | Python, Bash |
| Armazenamento de objetos | MinIO (padrão S3) |
| Extração de texto | pypdf, BeautifulSoup |
| Vetorização | sentence-transformers (BGE-M3) |
| Bancos | PostgreSQL, Qdrant |
| API | FastAPI, Uvicorn |
| Agente | Agno, Gemini |
| Infraestrutura | Docker, Docker Compose, uv |

## Como executar

Pré-requisitos: Docker e Docker Compose. Para rodar `transformar.py` fora do Docker, Python 3.12.

```bash
# 1. Credenciais
cp .env.example .env        # troque usuário e senha

# 2. MinIO, PostgreSQL, Qdrant e a API
docker compose up -d --build
# API: http://localhost:8000/docs  |  painel do MinIO: http://localhost:9001

# 3. Ingestão
bash 05-baixar-pdfs.sh
bash 04-coletar-repo.sh

# 4. Transformação e vetorização
pip install -r requirements.txt
set -a; source .env; set +a
python transformar.py
```

Agente de RAG (suba um conjunto por vez, porque os dois usam as portas 5432 e 6333):

```bash
cd rag-agno
cp .env.example .env
cp agno-rag/.env.example agno-rag/.env   # chave do Gemini, modelos e prompt
docker compose up -d --build
# http://localhost:8008
```

## Estrutura

```
├── 01-subir-minio.sh    # etapa inicial: sobe o MinIO sozinho
├── 02-baixar.sh         # etapa inicial: baixa uma página web
├── 03-enviar.sh         # etapa inicial: envia um arquivo ao MinIO
├── 04-coletar-repo.sh   # envia os PDFs ao MinIO
├── 05-baixar-pdfs.sh    # baixa artigos do arXiv
├── transformar.py       # extração, limpeza, chunks, vetores, PostgreSQL e Qdrant
├── app.py               # API FastAPI (/pdf e /site)
├── limpar-minio.py      # remove do bucket o que não for PDF
├── teste_vetor.py       # etapa inicial: teste do modelo BGE-M3
├── docker-compose.yml   # MinIO, PostgreSQL, Qdrant e API
├── Dockerfile           # imagem da API
└── rag-agno/            # agente de RAG com Agno e Gemini
```

## O que aprendi

- Subir e gerenciar serviços com Docker e Docker Compose: containers, portas e volumes.
- Armazenamento de objetos e o padrão S3: buckets, objetos e autenticação por assinatura.
- A diferença entre API (máquina com máquina) e painel web (para pessoas).
- As etapas de um pipeline de dados: coleta, armazenamento bruto, transformação e carga.
- Divisão de texto em chunks, vetorização e busca por similaridade em banco vetorial.
- Separar credenciais do código com variáveis de ambiente.

## Créditos

Etapas propostas e orientadas pelo laboratório Orion (UFAL). Implementação de Rafaela Urtiga Malta.
