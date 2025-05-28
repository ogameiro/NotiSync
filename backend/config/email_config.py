from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content
import os
from dotenv import load_dotenv

# Carrega variáveis de ambiente
load_dotenv()

# Configurações do SendGrid
SENDGRID_API_KEY = os.getenv('SENDGRID_API_KEY')
SENDGRID_FROM_EMAIL = os.getenv('SENDGRID_FROM_EMAIL', 'noreply@notisync.com')
SENDGRID_FROM_NAME = os.getenv('SENDGRID_FROM_NAME', 'NotiSync')

def verify_sendgrid_config():
    """
    Verifica se as configurações do SendGrid estão corretas
    
    Returns:
        tuple: (bool, str) - (configuração válida, mensagem de erro)
    """
    if not SENDGRID_API_KEY:
        return False, "SENDGRID_API_KEY não configurada no arquivo .env"
    
    if not SENDGRID_FROM_EMAIL:
        return False, "SENDGRID_FROM_EMAIL não configurada no arquivo .env"
    
    # Tenta criar uma instância do cliente para verificar se a API key é válida
    try:
        sg = SendGridAPIClient(SENDGRID_API_KEY)
        # Faz uma requisição simples para verificar a API key
        sg.client.api_keys.get()
        return True, "Configuração do SendGrid válida"
    except Exception as e:
        return False, f"Erro ao validar API key do SendGrid: {str(e)}"

def get_sendgrid_client():
    """Retorna uma instância do cliente SendGrid"""
    is_valid, error_message = verify_sendgrid_config()
    if not is_valid:
        raise ValueError(error_message)
    return SendGridAPIClient(SENDGRID_API_KEY)

def send_email(to_email, subject, content, content_type="text/html"):
    """
    Envia um email usando SendGrid
    
    Args:
        to_email (str): Email do destinatário
        subject (str): Assunto do email
        content (str): Conteúdo do email
        content_type (str): Tipo do conteúdo (text/html ou text/plain)
    
    Returns:
        tuple: (bool, str) - (sucesso, mensagem de erro)
    """
    try:
        # Validação básica dos parâmetros
        if not to_email or not subject or not content:
            return False, "Parâmetros inválidos: email, assunto e conteúdo são obrigatórios"
        
        if len(content) > 1000000:  # Limite de 1MB para o conteúdo
            return False, "Conteúdo do email muito grande (máximo 1MB)"
        
        sg = get_sendgrid_client()
        
        from_email = Email(SENDGRID_FROM_EMAIL, SENDGRID_FROM_NAME)
        to_email = To(to_email)
        content = Content(content_type, content)
        
        mail = Mail(from_email, to_email, subject, content)
        
        response = sg.send(mail)
        if response.status_code == 202:
            return True, "Email enviado com sucesso"
        else:
            return False, f"Erro ao enviar email: status code {response.status_code}"
        
    except ValueError as e:
        return False, str(e)
    except Exception as e:
        return False, f"Erro ao enviar email: {str(e)}" 