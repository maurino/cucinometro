FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

EXPOSE 8080

ENV CUCINOMETRO_API_BASE_URL=http://host.docker.internal:8000/api
ENV REQUEST_TIMEOUT_SECONDS=10
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8080
ENV MCP_HTTP_PATH=/mcp

CMD ["mcp", "run", "server.py", "--transport", "streamable-http"]
