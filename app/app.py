from flask import Flask, jsonify
import os

app = Flask(__name__)

environment = os.getenv("APP_ENV", "local")
version = os.getenv("APP_VERSION", "0.1.0")


@app.route("/")
def index():
    return jsonify(
        service="platform-ops-lab",
        environment=environment,
        version=version
    )


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
