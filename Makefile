.PHONY: all backend frontend pipeline worker stop stop-backend stop-frontend stop-pipeline stop-worker install-frontend

# Run all services
all: backend frontend worker

# Backend: Spring Boot + Elasticsearch + Redis via Docker Compose
backend:
	cd SeriesTranscription && docker compose up -d

# Frontend: Vite dev server
frontend:
	cd series-transcription-front/frontend && npm run dev &

# Pipeline worker: continuous job processor
worker:
	cd series-transcription-pipeline && PYTHONPATH=. python -m src.worker &

# Pipeline CLI (usage: make transcribe AUDIO=input.mp3 OUT=output.json)
transcribe:
	cd series-transcription-pipeline && PYTHONPATH=. python -m src.transcripts_pipeline.cli \
		--audio $(AUDIO) \
		--out $(OUT) \
		--asr-backend mlx \
		--language hr

# Episode generator (usage: make episode CONCEPT="..." CHARACTERS="char1 char2")
episode:
	cd series-transcription-pipeline && PYTHONPATH=. python -m episode_generator.main \
		--concept "$(CONCEPT)" \
		--characters $(CHARACTERS)

# Install frontend dependencies
install-frontend:
	cd series-transcription-front/frontend && npm install

# Stop all services
stop: stop-backend stop-frontend stop-worker

stop-backend:
	cd SeriesTranscription && docker compose down

stop-frontend:
	@pkill -f "vite" 2>/dev/null || true

stop-worker:
	@pkill -f "src.worker" 2>/dev/null || true
