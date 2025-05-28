from flask import Blueprint, request, jsonify
from sqlalchemy import desc
from datetime import datetime
from config.settings import db
from routes.sessions import token_required
from routes.dashboard import NotificationType  # Importando o modelo NotificationType

templates_bp = Blueprint('templates', __name__, url_prefix='/templates')

# Modelo de Template
class Template(db.Model):
    __tablename__ = 'templates'
    template_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    type_id = db.Column(db.Integer, db.ForeignKey('notificationtypes.type_id'))
    category = db.Column(db.String(50))
    content = db.Column(db.Text, nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey('users.user_id'))
    usage_count = db.Column(db.Integer, default=0)

# Listar templates
@templates_bp.route('/', methods=['GET'])
@token_required
def listar_templates():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    categoria = request.args.get('categoria')
    tipo = request.args.get('tipo')
    status = request.args.get('status')

    query = db.session.query(
        Template,
        NotificationType
    ).join(
        NotificationType, Template.type_id == NotificationType.type_id
    )

    # Aplicar filtros
    if categoria:
        query = query.filter(Template.category == categoria)
    if tipo:
        query = query.filter(Template.type_id == tipo)
    if status:
        query = query.filter(Template.is_active == (status.lower() == 'ativo'))

    # Ordenar e paginar
    total = query.count()
    templates = query.order_by(desc(Template.updated_at))\
        .offset((page - 1) * per_page)\
        .limit(per_page)\
        .all()

    resultado = []
    for template, tipo in templates:
        resultado.append({
            'id': template.template_id,
            'nome': template.name,
            'descricao': template.description,
            'tipo': tipo.name,
            'categoria': template.category,
            'ativo': template.is_active,
            'uso': template.usage_count,
            'ultima_atualizacao': template.updated_at.strftime('%Y-%m-%d %H:%M:%S')
        })

    return jsonify({
        'templates': resultado,
        'total': total,
        'pagina': page,
        'por_pagina': per_page,
        'total_paginas': (total + per_page - 1) // per_page
    })

# Obter detalhes de um template
@templates_bp.route('/<int:template_id>', methods=['GET'])
@token_required
def obter_template(template_id):
    template = db.session.query(
        Template,
        NotificationType
    ).join(
        NotificationType, Template.type_id == NotificationType.type_id
    ).filter(Template.template_id == template_id).first()

    if not template:
        return jsonify({'message': 'Template não encontrado'}), 404

    template, tipo = template
    return jsonify({
        'id': template.template_id,
        'nome': template.name,
        'descricao': template.description,
        'tipo': tipo.name,
        'tipo_id': template.type_id,
        'categoria': template.category,
        'conteudo': template.content,
        'ativo': template.is_active,
        'uso': template.usage_count,
        'criado_em': template.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'atualizado_em': template.updated_at.strftime('%Y-%m-%d %H:%M:%S')
    })

# Criar novo template
@templates_bp.route('/', methods=['POST'])
@token_required
def criar_template():
    data = request.get_json()
    
    # Validar dados obrigatórios
    campos_obrigatorios = ['nome', 'tipo_id', 'conteudo']
    for campo in campos_obrigatorios:
        if campo not in data:
            return jsonify({'message': f'Campo obrigatório ausente: {campo}'}), 400

    try:
        novo_template = Template(
            name=data['nome'],
            description=data.get('descricao'),
            type_id=data['tipo_id'],
            category=data.get('categoria'),
            content=data['conteudo'],
            is_active=data.get('ativo', True),
            created_by=request.user  # ID do usuário atual
        )
        
        db.session.add(novo_template)
        db.session.commit()
        
        return jsonify({
            'message': 'Template criado com sucesso',
            'template_id': novo_template.template_id
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao criar template: {str(e)}'}), 500

# Atualizar template
@templates_bp.route('/<int:template_id>', methods=['PUT'])
@token_required
def atualizar_template(template_id):
    template = Template.query.get(template_id)
    if not template:
        return jsonify({'message': 'Template não encontrado'}), 404

    data = request.get_json()
    
    try:
        # Atualizar campos
        if 'nome' in data:
            template.name = data['nome']
        if 'descricao' in data:
            template.description = data['descricao']
        if 'tipo_id' in data:
            template.type_id = data['tipo_id']
        if 'categoria' in data:
            template.category = data['categoria']
        if 'conteudo' in data:
            template.content = data['conteudo']
        if 'ativo' in data:
            template.is_active = data['ativo']
        
        template.updated_at = datetime.utcnow()
        
        db.session.commit()
        return jsonify({'message': 'Template atualizado com sucesso'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao atualizar template: {str(e)}'}), 500

# Excluir template
@templates_bp.route('/<int:template_id>', methods=['DELETE'])
@token_required
def excluir_template(template_id):
    template = Template.query.get(template_id)
    if not template:
        return jsonify({'message': 'Template não encontrado'}), 404

    try:
        db.session.delete(template)
        db.session.commit()
        return jsonify({'message': 'Template excluído com sucesso'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao excluir template: {str(e)}'}), 500

# Duplicar template
@templates_bp.route('/<int:template_id>/duplicar', methods=['POST'])
@token_required
def duplicar_template(template_id):
    template = Template.query.get(template_id)
    if not template:
        return jsonify({'message': 'Template não encontrado'}), 404

    try:
        novo_template = Template(
            name=f'Cópia de {template.name}',
            description=template.description,
            type_id=template.type_id,
            category=template.category,
            content=template.content,
            is_active=True,
            created_by=request.user
        )
        
        db.session.add(novo_template)
        db.session.commit()
        
        return jsonify({
            'message': 'Template duplicado com sucesso',
            'template_id': novo_template.template_id
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao duplicar template: {str(e)}'}), 500

# Obter estatísticas de uso do template
@templates_bp.route('/<int:template_id>/estatisticas', methods=['GET'])
@token_required
def estatisticas_template(template_id):
    template = Template.query.get(template_id)
    if not template:
        return jsonify({'message': 'Template não encontrado'}), 404

    # TODO: Implementar estatísticas mais detalhadas
    # Por enquanto, retorna apenas o contador de uso
    return jsonify({
        'template_id': template.template_id,
        'nome': template.name,
        'total_uso': template.usage_count,
        'ultimo_uso': template.updated_at.strftime('%Y-%m-%d %H:%M:%S') if template.usage_count > 0 else None
    }) 