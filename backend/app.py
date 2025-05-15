# app.py
from flask import Flask, jsonify, request
from flask_cors import CORS
import config.settings as settings
from routes.sessions import auth_bp

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = settings.JWT_SECRET
    app.config.from_object(settings)

    # --- ATIVA O CORS ---
    # Allow http://localhost a aceder, com cookies (credentials)
    CORS(app,
         supports_credentials=True,
         resources={
           r"/auth/*": {
             "origins": "http://localhost"
           }
         }
    )

    app.register_blueprint(auth_bp)

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
