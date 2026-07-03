# Built locally and imported into k3d as
#   registry.internal.example.com/demo-app:<tag>
# so it satisfies the reference image-registry admission policy as written
# (security-policy/validatingadmissionpolicy-image-registry.yaml).
FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Non-root to satisfy a runAsNonRoot pod securityContext.
USER 1000:1000

# Zero-code OTel instrumentation wrapper; exporters/endpoints come from
# OTEL_* env vars set in the Deployment.
CMD ["opentelemetry-instrument", "python", "app.py"]
