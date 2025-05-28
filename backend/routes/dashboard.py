from flask import Blueprint, jsonify
from sqlalchemy import func, desc
from datetime import datetime
from config.settings import db
from routes.sessions import token_required

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/dashboard')

# Modelos da base de dados
class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False) # Note: storing hash, not plain password
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class NotificationLog(db.Model):
    __tablename__ = 'notificationlogs'
    log_id = db.Column(db.Integer, primary_key=True)
    status_id = db.Column(db.Integer, db.ForeignKey('notificationstatus.status_id'))
    channel_id = db.Column(db.Integer, db.ForeignKey('channels.channel_id'))
    notification_id = db.Column(db.Integer, db.ForeignKey('notifications.notification_id'))
    recipient_id = db.Column(db.Integer) # This might also be a FK to users if recipients are users
    error_message = db.Column(db.Text)
    attempted_at = db.Column(db.DateTime)

class NotificationStatus(db.Model):
    __tablename__ = 'notificationstatus'
    status_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)

class Notification(db.Model):
    __tablename__ = 'notifications'
    notification_id = db.Column(db.Integer, primary_key=True)
    type_id = db.Column(db.Integer, db.ForeignKey('notificationtypes.type_id'))
    sender_id = db.Column(db.Integer, db.ForeignKey('users.user_id'))
    template_id = db.Column(db.Integer, db.ForeignKey('templates.template_id'), nullable=True)
    content_override = db.Column(db.Text)
    priority = db.Column(db.String(20), default='Normal')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class NotificationType(db.Model):
    __tablename__ = 'notificationtypes'
    type_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255))
    description = db.Column(db.Text)

class Channel(db.Model):
    __tablename__ = 'channels'
    channel_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255))
    description = db.Column(db.Text)

# Rota de resumo estatístico da dashboard
@dashboard_bp.route('/resumo', methods=['GET'])
@token_required
def obter_resumo_dashboard():
    total = db.session.query(func.count(NotificationLog.log_id)).scalar()

    status_counts = db.session.query(
        NotificationStatus.name,
        func.count(NotificationLog.log_id)
    ).join(NotificationLog, NotificationLog.status_id == NotificationStatus.status_id)\
     .group_by(NotificationStatus.name).all()

    pendentes = erros = sucesso = 0
    for nome, contagem in status_counts:
        if nome.lower() == 'pendente':
            pendentes = contagem
        elif nome.lower() == 'erro':
            erros = contagem
        elif nome.lower() == 'sucesso':
            sucesso = contagem

    taxa_sucesso = (sucesso / total) * 100 if total > 0 else 0

    return jsonify({
        'total_enviadas': total,
        'pendentes': pendentes,
        'erros': erros,
        'taxa_sucesso': round(taxa_sucesso, 2)
    })

# Rota para listar as notificações mais recentes
@dashboard_bp.route('/recentes', methods=['GET'])
@token_required
def notificacoes_recentes():
    logs = db.session.query(
        NotificationLog,
        Notification,
        NotificationType,
        NotificationStatus,
        Channel
    ).join(Notification, NotificationLog.notification_id == Notification.notification_id)\
     .join(NotificationType, Notification.type_id == NotificationType.type_id)\
     .join(NotificationStatus, NotificationLog.status_id == NotificationStatus.status_id)\
     .join(Channel, NotificationLog.channel_id == Channel.channel_id)\
     .order_by(desc(NotificationLog.attempted_at))\
     .limit(5).all()

    recentes = []
    for log, notif, tipo, status, canal in logs:
        recentes.append({
            'tipo': tipo.name,
            'mensagem': notif.content_override or f'Notif #{notif.notification_id}',
            'categoria': 'Alerta' if 'alerta' in tipo.name.lower() else 'Aviso',
            'estado': status.name,
            'canais': canal.name,
            'data': log.attempted_at.strftime('%Y-%m-%d %H:%M:%S') if log.attempted_at else '---'
        })

    return jsonify(recentes)

# Rota para listar tipos de notificação
@dashboard_bp.route('/notificationtypes/', methods=['GET'])
@token_required
def listar_tipos_notificacao():
    tipos = NotificationType.query.all()
    resultado = []
    for tipo in tipos:
        resultado.append({
            'type_id': tipo.type_id,
            'name': tipo.name,
            'description': tipo.description
        })
    return jsonify(resultado)
