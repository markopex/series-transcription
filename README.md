# Series Transcription

A full-stack platform for transcribing, indexing, and generating content from TV series. The system transcribes audio with speaker diarization, indexes transcripts for full-text and semantic search, and generates new episode scripts using LLMs.

## Architecture

```
series-transcription/
├── SeriesTranscription/              # Backend API (Spring Boot)
├── series-transcription-front/       # Frontend (React + Vite)
└── series-transcription-pipeline/    # Transcription & AI pipeline (Python)
```

### Backend — [SeriesTranscription](https://github.com/markopex/series-transcription-backend)

Spring Boot 4 (Java 21) REST API that serves as the central hub:

- **Search** — Full-text and semantic search over transcripts via Elasticsearch
- **Auth** — Firebase JWT-based authentication with role-based rate limiting
- **Episode metadata** — LLM-powered metadata generation (Gemini)
- **Analytics** — Job tracking and LLM cost analytics via DuckDB
- **Infrastructure** — PostgreSQL, Elasticsearch 9, Redis 7

Runs on port **8080**.

### Frontend — [series-transcription-front](https://github.com/markopex/series-transcription-frontend)

React 19 + TypeScript SPA built with Vite:

- Firebase authentication
- Transcript browsing and search
- Markdown rendering for generated content
- OpenAPI-generated API client

Runs on port **5173** (dev) or **3000** (Docker/nginx).

### Pipeline — [series-transcription-pipeline](https://github.com/markopex/series-transcription-pipeline)

Python-based ML pipeline with multiple tools:

- **Transcription** — WhisperX / MLX Whisper with speaker diarization (PyAnnote) and vocal separation (Demucs)
- **Episode Generator** — LangGraph-based AI episode writer using Claude / Gemini
- **Series Bible Indexer** — Elasticsearch full-text indexing of transcripts
- **Worker** — Continuous job processor that polls for transcription jobs

## Prerequisites

- **Docker** and **Docker Compose**
- **Java 21** (for local backend dev without Docker)
- **Node.js 20+** and **npm**
- **Python 3.11+** and **FFmpeg** (for pipeline)
- **HuggingFace token** (`HF_TOKEN`) for speaker diarization models

## Getting Started

### Clone with submodules

```bash
git clone --recurse-submodules https://github.com/markopex/series-transcription.git
cd series-transcription
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### Install frontend dependencies

```bash
make install-frontend
```

### Start all services

```bash
make all
```

This starts:
1. Backend + PostgreSQL + Elasticsearch + Redis (via Docker Compose)
2. Frontend dev server (Vite on :5173)
3. Pipeline worker (background job processor)

### Start services individually

```bash
make backend     # Spring Boot + Postgres + Elasticsearch + Redis
make frontend    # Vite dev server on :5173
make worker      # Pipeline job processor
```

### Stop all services

```bash
make stop
```

## CLI Tools

### Transcribe audio

```bash
make transcribe AUDIO=path/to/audio.mp3 OUT=output.json
```

Uses MLX Whisper (Apple Silicon) by default with Croatian language. Edit the Makefile to change `--asr-backend` or `--language`.

### Generate an episode

```bash
make episode CONCEPT="Two characters discuss..." CHARACTERS="char1 char2"
```

## Ports

| Service        | Port  |
|----------------|-------|
| Backend API    | 8080  |
| Frontend (dev) | 5173  |
| Elasticsearch  | 9200  |
| PostgreSQL     | 5432  |
| Redis          | 63791 |

## Environment Variables

### Backend

| Variable              | Default                    | Description                    |
|-----------------------|----------------------------|--------------------------------|
| `CORS_ALLOWED_ORIGINS`| `http://localhost:5173`    | Allowed CORS origins           |
| `LLM_PROVIDER`       | `gemini`                   | LLM provider for metadata      |
| `LLM_API_KEY`        | —                          | API key for LLM provider        |
| `DUCKDB_PATH`        | `./data/dashboard.duckdb`  | Path to DuckDB analytics DB     |
| `EPISODE_GENERATOR_URL`| `http://localhost:8001`  | Episode generator service URL   |

### Frontend

| Variable                  | Description                |
|---------------------------|----------------------------|
| `VITE_API_URL`            | Backend API URL            |
| `VITE_FIREBASE_API_KEY`   | Firebase API key           |
| `VITE_FIREBASE_AUTH_DOMAIN`| Firebase auth domain      |
| `VITE_FIREBASE_PROJECT_ID`| Firebase project ID        |

### Pipeline

| Variable          | Default     | Description                        |
|-------------------|-------------|------------------------------------|
| `HF_TOKEN`        | —           | HuggingFace token for PyAnnote     |
| `TX_ASR_BACKEND`  | `whisperx`  | ASR backend (whisperx or mlx)      |
| `WHISPER_LANGUAGE` | `hr`       | Transcription language             |
| `WHISPER_MODEL`   | `large-v3`  | Whisper model size                 |
