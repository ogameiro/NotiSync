# config/settings.py
import os
from pathlib import Path
from dotenv import load_dotenv
from flask_sqlalchemy import SQLAlchemy

# encontra o .env na raiz do projecto
BASE_DIR = Path(__file__).parent.parent
load_dotenv(BASE_DIR / '.env')

# instancia o SQLAlchemy
db = SQLAlchemy()


# --- Configuração da Base de Dados (se precisares noutros módulos) ---
DB_CONNECTION     = os.getenv('DB_CONNECTION', 'mysql')
DB_HOST           = os.getenv('DB_HOST', '127.0.0.1')
DB_PORT           = os.getenv('DB_PORT', '3306')
DB_DATABASE       = os.getenv('DB_DATABASE')
DB_USERNAME       = os.getenv('DB_USERNAME')
DB_PASSWORD       = os.getenv('DB_PASSWORD')

# --- Configuração de JWT ---
JWT_SECRET        = os.getenv('JWT_SECRET')
ACCESS_TOKEN_EXP   = int(os.getenv('ACCESS_TOKEN_EXPIRY'))
REFRESH_TOKEN_EXP  = int(os.getenv('REFRESH_TOKEN_EXPIRY'))
JWT_ALGORITHM     = 'HS256'
PHP_AUTH_URL      = os.getenv('PHP_AUTH_URL')
