from twilio.rest import Client
import os
from dotenv import load_dotenv

# Carrega variáveis de ambiente
load_dotenv()

# Configurações do Twilio
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN')
TWILIO_PHONE_NUMBER = os.getenv('TWILIO_PHONE_NUMBER')

def verify_twilio_config():
    """
    Verifica se as configurações do Twilio estão corretas
    
    Returns:
        tuple: (bool, str) - (configuração válida, mensagem de erro)
    """
    if not TWILIO_ACCOUNT_SID:
        return False, "TWILIO_ACCOUNT_SID não configurada no arquivo .env"
    
    if not TWILIO_AUTH_TOKEN:
        return False, "TWILIO_AUTH_TOKEN não configurada no arquivo .env"
    
    if not TWILIO_PHONE_NUMBER:
        return False, "TWILIO_PHONE_NUMBER não configurada no arquivo .env"
    
    # Tenta criar uma instância do cliente para verificar se as credenciais são válidas
    try:
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        # Faz uma requisição simples para verificar as credenciais
        client.api.accounts(TWILIO_ACCOUNT_SID).fetch()
        return True, "Configuração do Twilio válida"
    except Exception as e:
        return False, f"Erro ao validar credenciais do Twilio: {str(e)}"

def get_twilio_client():
    """
    Retorna uma instância do cliente Twilio
    
    Returns:
        Client: Instância do cliente Twilio
    """
    return Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

def send_sms(to_phone, content):
    """
    Envia um SMS usando Twilio
    
    Args:
        to_phone (str): Número de telefone do destinatário
        content (str): Conteúdo da mensagem
    
    Returns:
        tuple: (bool, str) - (sucesso, mensagem de erro)
    """
    try:
        # Validação básica dos parâmetros
        if not to_phone or not content:
            return False, "Parâmetros inválidos: número de telefone e conteúdo são obrigatórios"
        
        # Limpa o número de telefone (remove caracteres não numéricos)
        to_phone = ''.join(filter(str.isdigit, to_phone))
        
        # Adiciona o código do país se não estiver presente
        if not to_phone.startswith('55') and len(to_phone) <= 11:
            to_phone = '55' + to_phone
        
        # Adiciona o + no início
        to_phone = '+' + to_phone
        
        # Verifica o tamanho do conteúdo (limite de 120 caracteres para conta trial)
        if len(content) > 120:
            return False, "Conteúdo do SMS muito grande (máximo 120 caracteres para conta trial do Twilio)"
        
        client = get_twilio_client()
        
        message = client.messages.create(
            body=content,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        
        if message.status in ['queued', 'sent']:
            return True, "SMS enviado com sucesso"
        else:
            return False, f"Erro ao enviar SMS: status {message.status}"
        
    except Exception as e:
        return False, f"Erro ao enviar SMS: {str(e)}" 