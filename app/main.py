"""A minimal Flask app used to demonstrate a GitHub -> Docker -> ArgoCD -> Minikube pipeline."""

import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)

# APP_VERSION is baked into the image at build time (Dockerfile ARG -> ENV) using the git
# commit SHA, so you can see exactly which commit is running after ArgoCD rolls it out.
APP_VERSION = os.environ.get("APP_VERSION", "dev")


@app.route("/")
def hello():
    return jsonify(
        message="Hello, World from Flask on Kubernetes!",
        version=APP_VERSION,
        # Inside a pod the hostname is the pod name, which shows load-balancing across replicas.
        pod=socket.gethostname(),
    )


@app.route("/healthz")
def healthz():
    # Used by the Kubernetes liveness/readiness probes in k8s/deployment.yaml.
    return jsonify(status="ok")


if __name__ == "__main__":
    # Local development only. In the container, gunicorn serves the app (see Dockerfile).
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")), debug=True)
