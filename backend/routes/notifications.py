from flask import Blueprint, request, jsonify, current_app
from sqlalchemy import desc
from datetime import datetime
from config.settings import db
from routes.sessions import token_required
from services.notification_service import NotificationService
import traceback

notifications_bp = Blueprint('notifications', __name__, url_prefix='/notifications')

# Modelos da base de dados
from routes.dashboard import Notification, NotificationLog, NotificationType, NotificationStatus, Channel, User
from routes.templates import Template  # Importando Template do arquivo correto

# Listar notificações
@notifications_bp.route('/', methods=['GET'])
@token_required
def listar_notificacoes():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    status = request.args.get('status')
    tipo = request.args.get('tipo')
    data_inicio = request.args.get('data_inicio')
    data_fim = request.args.get('data_fim')

    query = db.session.query(
        NotificationLog,
        Notification,
        NotificationType,
        NotificationStatus,
        Channel
    ).join(
        Notification, NotificationLog.notification_id == Notification.notification_id
    ).join(
        NotificationType, Notification.type_id == NotificationType.type_id
    ).join(
        NotificationStatus, NotificationLog.status_id == NotificationStatus.status_id
    ).join(
        Channel, NotificationLog.channel_id == Channel.channel_id
    )

    # Aplicar filtros
    if status:
        query = query.filter(NotificationStatus.name == status)
    if tipo:
        query = query.filter(NotificationType.name == tipo)
    if data_inicio:
        query = query.filter(NotificationLog.attempted_at >= datetime.strptime(data_inicio, '%Y-%m-%d'))
    if data_fim:
        query = query.filter(NotificationLog.attempted_at <= datetime.strptime(data_fim, '%Y-%m-%d'))

    # Ordenar e paginar
    total = query.count()
    notificacoes = query.order_by(desc(NotificationLog.attempted_at))\
        .offset((page - 1) * per_page)\
        .limit(per_page)\
        .all()

    resultado = []
    for log, notif, tipo, status, canal in notificacoes:
        resultado.append({
            'id': log.log_id,
            'tipo': tipo.name,
            'mensagem': notif.content_override or f'Notificação #{notif.notification_id}',
            'categoria': 'Alerta' if 'alerta' in tipo.name.lower() else 'Aviso',
            'estado': status.name,
            'canais': canal.name,
            'data': log.attempted_at.strftime('%Y-%m-%d %H:%M:%S') if log.attempted_at else '---',
            'erro': log.error_message
        })

    return jsonify({
        'notificacoes': resultado,
        'total': total,
        'pagina': page,
        'por_pagina': per_page,
        'total_paginas': (total + per_page - 1) // per_page
    })

# Obter detalhes de uma notificação
@notifications_bp.route('/<int:notification_id>', methods=['GET'])
@token_required
def obter_notificacao(notification_id):
    log = db.session.query(
        NotificationLog,
        Notification,
        NotificationType,
        NotificationStatus,
        Channel
    ).join(
        Notification, NotificationLog.notification_id == Notification.notification_id
    ).join(
        NotificationType, Notification.type_id == NotificationType.type_id
    ).join(
        NotificationStatus, NotificationLog.status_id == NotificationStatus.status_id
    ).join(
        Channel, NotificationLog.channel_id == Channel.channel_id
    ).filter(NotificationLog.log_id == notification_id).first()

    if not log:
        return jsonify({'message': 'Notificação não encontrada'}), 404

    log, notif, tipo, status, canal = log
    return jsonify({
        'id': log.log_id,
        'tipo': tipo.name,
        'mensagem': notif.content_override or f'Notificação #{notif.notification_id}',
        'categoria': 'Alerta' if 'alerta' in tipo.name.lower() else 'Aviso',
        'estado': status.name,
        'canais': canal.name,
        'data': log.attempted_at.strftime('%Y-%m-%d %H:%M:%S') if log.attempted_at else '---',
        'erro': log.error_message,
        'template_id': notif.template_id if hasattr(notif, 'template_id') else None,
        'prioridade': notif.priority if hasattr(notif, 'priority') else 'Normal',
        'tentativas': log.attempts if hasattr(log, 'attempts') else 1
    })

# Criar nova notificação
@notifications_bp.route('/', methods=['POST'])
@token_required
def criar_notificacao():
    try:
        data = request.get_json()
        current_app.logger.info(f"Dados recebidos: {data}")
        current_app.logger.info(f"User ID do token: {request.user}")
        
        # Validar dados obrigatórios
        campos_obrigatorios = ['tipo_id', 'conteudo', 'canais', 'destinatarios']
        for campo in campos_obrigatorios:
            if campo not in data:
                current_app.logger.warning(f"Campo obrigatório ausente: {campo}")
                return jsonify({'message': f'Campo obrigatório ausente: {campo}'}), 400

        # Verificar se o usuário (sender) existe usando user_id
        sender = db.session.query(User).filter_by(user_id=request.user).first()
        if not sender:
            current_app.logger.error(f"Usuário não encontrado no banco de dados com ID: {request.user}")
            return jsonify({'message': 'Usuário não encontrado'}), 400

        # Verificar se o tipo_id existe
        tipo = db.session.query(NotificationType).filter_by(type_id=data['tipo_id']).first()
        if not tipo:
            current_app.logger.warning(f"Tipo de notificação não encontrado: {data['tipo_id']}")
            return jsonify({'message': f'Tipo de notificação com ID {data["tipo_id"]} não encontrado'}), 400

        # Verificar se o template_id existe, se fornecido
        if 'template_id' in data and data['template_id']:
            current_app.logger.info(f"Verificando template_id: {data['template_id']}")
            try:
                template_id = int(data['template_id'])
                template = db.session.query(Template).filter_by(template_id=template_id).first()
                if not template:
                    current_app.logger.warning(f"Template não encontrado: {template_id}")
                    return jsonify({'message': f'Template com ID {template_id} não encontrado'}), 400
                current_app.logger.info(f"Template encontrado: {template.name}")
            except (ValueError, TypeError) as e:
                current_app.logger.error(f"Erro ao converter template_id: {e}")
                return jsonify({'message': 'ID do template inválido'}), 400

        # Preparar dados da notificação
        notification_data = {
            'type_id': data['tipo_id'],
            'sender_id': sender.user_id,  # Usar o user_id do usuário verificado
            'content_override': data['conteudo'],
            'priority': data.get('prioridade', 'Normal')
        }

        # Adicionar template_id apenas se fornecido e existir
        if 'template_id' in data and data['template_id']:
            notification_data['template_id'] = int(data['template_id'])

        current_app.logger.info(f"Dados da notificação: {notification_data}")

        # Criar notificação
        try:
            nova_notificacao = Notification(**notification_data)
            db.session.add(nova_notificacao)
            db.session.flush()  # Para obter o ID da notificação
            current_app.logger.info(f"Notificação criada com ID: {nova_notificacao.notification_id}")

            # Processar envio da notificação
            success, message = NotificationService.process_notification(
                notification_id=nova_notificacao.notification_id,
                channels=data['canais'],
                recipients=data['destinatarios']
            )

            if not success:
                current_app.logger.error(f"Erro no processamento: {message}")
                db.session.rollback()
                return jsonify({'message': message}), 400

            db.session.commit()
            current_app.logger.info("Notificação salva com sucesso")

            return jsonify({
                'message': 'Notificação criada e enviada com sucesso',
                'notification_id': nova_notificacao.notification_id
            }), 201

        except Exception as e:
            current_app.logger.error(f"Erro ao criar notificação: {str(e)}")
            current_app.logger.error(traceback.format_exc())
            db.session.rollback()
            return jsonify({'message': f'Erro ao criar notificação: {str(e)}'}), 500

    except Exception as e:
        current_app.logger.error(f"Erro não tratado: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return jsonify({'message': f'Erro interno do servidor: {str(e)}'}), 500

# Reenviar notificação
@notifications_bp.route('/<int:notification_id>/reenviar', methods=['POST'])
@token_required
def reenviar_notificacao(notification_id):
    log = NotificationLog.query.get(notification_id)
    if not log:
        return jsonify({'message': 'Notificação não encontrada'}), 404

    try:
        # Atualizar status para pendente
        log.status_id = 1  # Status: Pendente
        log.attempted_at = datetime.utcnow()
        log.error_message = None
        
        db.session.commit()
        return jsonify({'message': 'Notificação agendada para reenvio'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao reenviar notificação: {str(e)}'}), 500

# Excluir notificação
@notifications_bp.route('/<int:notification_id>', methods=['DELETE'])
@token_required
def excluir_notificacao(notification_id):
    log = NotificationLog.query.get(notification_id)
    if not log:
        return jsonify({'message': 'Notificação não encontrada'}), 404

    try:
        db.session.delete(log)
        db.session.commit()
        return jsonify({'message': 'Notificação excluída com sucesso'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao excluir notificação: {str(e)}'}), 500

# Exportar histórico
@notifications_bp.route('/exportar', methods=['GET'])
@token_required
def exportar_historico():
    formato = request.args.get('formato', 'csv')
    if formato not in ['csv', 'json', 'xlsx']:
        return jsonify({'message': 'Formato de exportação inválido'}), 400

    # Obter dados para exportação
    logs = db.session.query(
        NotificationLog,
        Notification,
        NotificationType,
        NotificationStatus,
        Channel
    ).join(
        Notification, NotificationLog.notification_id == Notification.notification_id
    ).join(
        NotificationType, Notification.type_id == NotificationType.type_id
    ).join(
        NotificationStatus, NotificationLog.status_id == NotificationStatus.status_id
    ).join(
        Channel, NotificationLog.channel_id == Channel.channel_id
    ).order_by(desc(NotificationLog.attempted_at)).all()

    dados = []
    for log, notif, tipo, status, canal in logs:
        dados.append({
            'ID': log.log_id,
            'Tipo': tipo.name,
            'Mensagem': notif.content_override or f'Notificação #{notif.notification_id}',
            'Estado': status.name,
            'Canal': canal.name,
            'Data': log.attempted_at.strftime('%Y-%m-%d %H:%M:%S') if log.attempted_at else '---',
            'Erro': log.error_message
        })

    # TODO: Implementar lógica de exportação para diferentes formatos
    # Por enquanto, retorna JSON
    return jsonify(dados) 