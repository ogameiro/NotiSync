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
            # Extrair user_id do payload e garantir que é um inteiro
            user_id_from_token = payload.get('sub')
            if user_id_from_token is None:
                 # Se 'sub' não estiver presente, tentar 'user_id' (caso o payload use nome diferente)
                user_id_from_token = payload.get('user_id')

            if user_id_from_token is None:
                return jsonify({'message': 'ID do usuário não encontrado no token.'}), 401
                
            try:
                request.user = int(user_id_from_token)
            except (ValueError, TypeError):
                return jsonify({'message': 'Formato do ID do usuário no token inválido.'}), 401

        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token expirou.'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token inválido.'}), 401
        except Exception as e:
             # Capturar outros erros inesperados na decodificação ou processamento do token
            return jsonify({'message': f'Erro ao processar token: {str(e)}'}), 401
            
        return f(*args, **kwargs)
    return decorated

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'message': 'Falta email ou password.',
                        'error': 'invalidInput'}), 400

    # 1) Pede ao PHP o token
    resp = requests.post(settings.PHP_AUTH_URL, json={
        'email': email,
        'password': password
    })
    if resp.status_code != 200:
        # Tentar extrair mensagem de erro do PHP se disponível
        try:
            error_body = resp.json()
            error_message = error_body.get('message', 'Credenciais inválidas.')
            error_type = error_body.get('type', 'wrongInput')
            return jsonify({'message': error_message,
                            'error': error_type}), resp.status_code
        except Exception:
            # Fallback para mensagem genérica se JSON não for válido
            return jsonify({'message': 'Credenciais inválidas.',
                            'error': 'wrongInput'}), resp.status_code

    body = resp.json()
    # Precisamos obter o user_id do payload retornado pelo PHP
    access_token_from_php = body.get('access_token')
    if not access_token_from_php:
        return jsonify({'message': 'Token não recebido do PHP.'}), 500

    # Decodifica o token do PHP SEM verificar assinatura para ler o payload
    try:
        php_payload = jwt.decode(access_token_from_php, options={"verify_signature": False})
        user_id = php_payload.get('sub') # O user_id deve estar no claim 'sub' ou similar no token do PHP
        if user_id is None:
             # Tentar outro nome de claim se 'sub' não funcionar (verificar o token do PHP)
             user_id = php_payload.get('user_id') # Exemplo, se o PHP usa 'user_id'
             
        if user_id is None:
             return jsonify({'message': 'ID do usuário não encontrado no payload do token PHP.'}), 500

    except Exception as e:
        return jsonify({'message': f'Erro ao decodificar ou ler payload do token PHP: {str(e)}'}), 500

    # 3) Re-assina localmente para controlar expiração, USANDO o user_id do PHP
    new_payload = {
        'sub': user_id, # AGORA usamos o user_id numérico
        'name': php_payload.get('name'), # Manter outros claims úteis
        'email': php_payload.get('email'), # Manter outros claims úteis
        'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=settings.ACCESS_TOKEN_EXP)
    }
    new_token = jwt.encode(new_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    # 4) Devolve cookie seguro
    resposta = make_response(jsonify({'message': 'Login efetuado.', 'user_id': user_id})) # Opcional: retornar user_id no body
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
    return jsonify({'logged_in': True, 'user': request.user})

