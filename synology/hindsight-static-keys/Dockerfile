# Hindsight with the static-keys tenant extension. Ships without third-party
# dependencies: the extension only uses the server's own interfaces.
ARG HINDSIGHT_IMAGE=ghcr.io/vectorize-io/hindsight:1.2.0
FROM ${HINDSIGHT_IMAGE}

COPY hindsight_ext_static_keys_tenant /app/extensions/hindsight_ext_static_keys_tenant
ENV PYTHONPATH=/app/extensions

# Fail the build, not the first authenticated request, if the extension is not
# importable by the interpreter the server actually runs.
RUN /app/api/.venv/bin/python -c "import hindsight_ext_static_keys_tenant"
