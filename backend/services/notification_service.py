from datetime import datetime
from config.settings import db
from config.email_config import send_email, verify_sendgrid_config
from routes.dashboard import NotificationLog, Notification, NotificationStatus, Channel
import re

class NotificationService:
    @staticmethod
    def validate_email(email):
        """Valida se um email é válido"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))

    @staticmethod
    def validate_phone(phone):
        """Valida se um número de telefone é válido"""
        # Remove caracteres não numéricos
        phone = re.sub(r'\D', '', phone)
        # Verifica se tem entre 10 e 15 dígitos
        return 10 <= len(phone) <= 15

    @staticmethod
    def verify_configuration():
        """
        Verifica se todas as configurações necessárias estão presentes
        
        Returns:
            tuple: (bool, str) - (configuração válida, mensagem de erro)
        """
        # Verificar configuração do SendGrid
        is_valid, error_message = verify_sendgrid_config()
        if not is_valid:
            return False, f"Configuração de email inválida: {error_message}"
        
        # Verificar canais no banco de dados
        email_channel = Channel.query.filter_by(name='Email').first()
        sms_channel = Channel.query.filter_by(name='SMS').first()
        
        if not email_channel:
            return False, "Canal 'Email' não encontrado no banco de dados"
        if not sms_channel:
            return False, "Canal 'SMS' não encontrado no banco de dados"
        
        # Verificar status no banco de dados
        status_pendente = NotificationStatus.query.filter_by(name='Pendente').first()
        status_enviado = NotificationStatus.query.filter_by(name='Enviado').first()
        status_erro = NotificationStatus.query.filter_by(name='Erro').first()
        
        if not all([status_pendente, status_enviado, status_erro]):
            return False, "Status de notificação não encontrados no banco de dados"
        
        return True, "Configuração válida"

    @staticmethod
    def process_notification(notification_id, channels, recipients):
        """
        Processa o envio de uma notificação
        
        Args:
            notification_id (int): ID da notificação
            channels (list): Lista de canais de envio ('email', 'sms')
            recipients (list): Lista de destinatários
            
        Returns:
            tuple: (bool, str) - (sucesso, mensagem de erro)
        """
        try:
            # Verificar configuração
            is_valid, error_message = NotificationService.verify_configuration()
            if not is_valid:
                return False, error_message

            notification = Notification.query.get(notification_id)
            if not notification:
                return False, "Notificação não encontrada"

            # Separar destinatários por tipo
            email_recipients = [r for r in recipients if NotificationService.validate_email(r)]
            phone_recipients = [r for r in recipients if NotificationService.validate_phone(r)]

            # Verificar se há destinatários válidos para cada canal
            if 'email' in channels and not email_recipients:
                return False, "Nenhum email válido fornecido para o canal de email"
            if 'sms' in channels and not phone_recipients:
                return False, "Nenhum telefone válido fornecido para o canal de SMS"

            # Obter IDs dos canais e status
            email_channel = Channel.query.filter_by(name='Email').first()
            sms_channel = Channel.query.filter_by(name='SMS').first()
            status_pendente = NotificationStatus.query.filter_by(name='Pendente').first()
            status_enviado = NotificationStatus.query.filter_by(name='Enviado').first()
            status_erro = NotificationStatus.query.filter_by(name='Erro').first()

            # Criar logs para cada canal e destinatário
            for channel in channels:
                channel_id = email_channel.channel_id if channel == 'email' else sms_channel.channel_id
                recipients_list = email_recipients if channel == 'email' else phone_recipients

                for recipient in recipients_list:
                    # Criar log de notificação
                    log = NotificationLog(
                        notification_id=notification_id,
                        channel_id=channel_id,
                        recipient_id=recipient,
                        status_id=status_pendente.status_id,
                        attempted_at=datetime.utcnow()
                    )
                    db.session.add(log)

                    # Tentar enviar a notificação
                    try:
                        if channel == 'email':
                            success, message = send_email(
                                to_email=recipient,
                                subject=f"Notificação #{notification_id}",
                                content=notification.content_override
                            )
                            
                            if success:
                                log.status_id = status_enviado.status_id
                            else:
                                log.status_id = status_erro.status_id
                                log.error_message = message
                        else:  # SMS
                            # TODO: Implementar integração com Twilio
                            log.status_id = status_erro.status_id
                            log.error_message = "Canal SMS não implementado"

                    except Exception as e:
                        log.status_id = status_erro.status_id
                        log.error_message = str(e)

            db.session.commit()
            return True, "Notificação processada com sucesso"

        except Exception as e:
            db.session.rollback()
            return False, f"Erro ao processar notificação: {str(e)}" 