# routes/sessions.py
from flask import Blueprint, request, jsonify, make_response
import requests, jwt, datetime
from functools import wraps
import config.settings as settings

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.cookies.get('jwt_token')
        if not token:
            return jsonify({'message': 'Token em falta.'}), 401
        try:
            payload = jwt.decode(
                token,
                settings.JWT_SECRET,
                algorithms=[settings.JWT_ALGORITHM]
            )
            # Ajusta conforme a claim usada (sub/email)
            request.user = payload.get('sub') or payload.get('email')
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token expirou.'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token inválido.'}), 401
        return f(*args, **kwargs)
    return decorated

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'message': 'Falta email ou password.'}), 400

    # 1) Pede ao PHP o token
    resp = requests.post(settings.PHP_AUTH_URL, json={
        'email': email,
        'password': password
    })
    if resp.status_code != 200:
        return jsonify({'message': 'Credenciais inválidas.'}), 401

    body = resp.json()
    access_token = body.get('access_token')
    if not access_token:
        return jsonify({'message': 'Token não recebido do PHP.'}), 500

    # 2) Decodifica sem verificar assinatura, só para ler payload
    try:
        orig = jwt.decode(access_token, options={"verify_signature": False})
    except Exception:
        return jsonify({'message': 'Token PHP corrompido.'}), 500

    # 3) Re-assina localmente para controlar expiração
    new_payload = {
        'sub': orig.get('sub'),
        'name': orig.get('name'),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=settings.ACCESS_TOKEN_EXP)
    }
    new_token = jwt.encode(new_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    # 4) Devolve cookie seguro
    resposta = make_response(jsonify({'message': 'Login efetuado.'}))
    resposta.set_cookie(
        'jwt_token',
        new_token,
        httponly=True,
        secure=True,
        samesite='Lax'
    )
    return resposta

@auth_bp.route('/logout', methods=['POST'])
def logout():
    resposta = make_response(jsonify({'message': 'Logout efetuado.'}))
    resposta.set_cookie('jwt_token', '', expires=0)
    return resposta

@auth_bp.route('/protected', methods=['GET'])
@token_required
def protected():
    return jsonify({'message': f'Olá, {request.user}!'} )

@auth_bp.route('/status', methods=['GET'])
@token_required
def status():
    """
    Verifica se o cookie JWT é válido.
    Se válido, devolve 200; se não, o decorator já devolve 401.
    """
    return jsonify({'logged_in': True, 'user': request.user})

