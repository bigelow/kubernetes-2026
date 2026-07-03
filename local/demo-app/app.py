"""Tiny demo service that emits traces, metrics, and logs via OTel.

Instrumentation is zero-code: the container runs under
`opentelemetry-instrument` (see Dockerfile), which auto-instruments Flask
(server spans + http.server.* metrics) and attaches an OTLP handler to stdlib
logging. Logging goes through structlog rendering JSON and routed into stdlib
logging, so each event reaches Loki as a JSON body (`| json` parseable) and
stdout stays structured too. The only hand-written telemetry is one custom
child span around the simulated "work" so traces have some depth.
"""

import logging
import random
import time

import structlog
from flask import Flask, jsonify
from opentelemetry import trace

logging.basicConfig(level=logging.INFO, format="%(message)s")
logging.getLogger("werkzeug").setLevel(logging.WARNING)  # keep JSON-only logs

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)
log = structlog.get_logger("demo-app")

app = Flask(__name__)
tracer = trace.get_tracer("demo-app")

CATALOG = ["anvil", "rocket-skates", "tornado-seeds", "earthquake-pills"]


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/")
def index():
    log.info("index_hit")
    return {"service": "demo-app", "endpoints": ["/api/orders", "/healthz"]}


@app.get("/api/orders")
def orders():
    order_id = random.randint(1000, 9999)
    with tracer.start_as_current_span("process-order") as span:
        span.set_attribute("order.id", order_id)
        item = random.choice(CATALOG)
        span.set_attribute("order.item", item)
        time.sleep(random.uniform(0.02, 0.3))  # simulated downstream latency
        if random.random() < 0.1:  # ~10% simulated failures
            log.error("order_failed", order_id=order_id, reason="payment timeout")
            return jsonify(error="payment timeout", order=order_id), 500
    log.info("order_placed", order_id=order_id, item=item)
    return jsonify(order=order_id, item=item)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
