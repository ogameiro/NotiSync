# app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import config.settings as settings
from routes.sessions import auth_bp
from routes.dashboard import dashboard_bp
from routes.notifications import notifications_bp

def create_app():
    app = Flask(__name__)

    # configura a URI do SQLAlchemy
    app.config['SQLALCHEMY_DATABASE_URI'] = (
        f"{settings.DB_CONNECTION}://{settings.DB_USERNAME}:{settings.DB_PASSWORD}"
        f"@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_DATABASE}"
    )
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # inicializa o db com a app
    settings.db.init_app(app)

    app.config['SECRET_KEY'] = settings.JWT_SECRET
    app.config.from_object(settings)

    # --- ATIVA O CORS ---
    # Permite todas as rotas da API para o IP do servidor
    CORS(app,
         supports_credentials=True,
         origins=["http://130.61.232.251", "http://130.61.232.251:5050"],
         allow_headers=["Content-Type", "Authorization"],
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
         expose_headers=["Content-Type", "Authorization"]
    )

    app.register_blueprint(dashboard_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(notifications_bp)

    @app.route('/', methods=['GET'])
    def home():
        return jsonify({
            'status': 'OK',
            'mensagem': 'Servidor Flask do NotiSync a funcionar!'
        })

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='127.0.0.1', port=5050, debug=True)
