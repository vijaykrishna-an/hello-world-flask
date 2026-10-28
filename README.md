# Hello World Flask — CI/CD Demo

A minimal Flask application demonstrating a complete GitOps pipeline:

**GitHub → Docker Hub → ArgoCD → Minikube**

## Pipeline Flow
1. Push code → GitHub Actions triggers
2. `test` job → pytest runs inside Docker
3. `build-and-push` job → image pushed to `anvk1729/hello-world-flask:<git-sha>`
4. `update-k8s-tag` job → commits new image tag to `k8s/kustomization.yaml`
5. ArgoCD detects the change → deploys to minikube automatically

## Run Locally
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
python -m app.main        # http://localhost:8080
pytest -v                 # run tests
```
