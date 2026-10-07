"""Minimal inventory API used as the target of the DevSecOps pipeline."""

from flask import Flask

from . import db, routes


def create_app(database: str = ":memory:") -> Flask:
    app = Flask(__name__)
    app.config["DATABASE"] = database
    db.init_app(app)
    app.register_blueprint(routes.bp)
    return app
