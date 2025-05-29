## Planeamento do Frontend - Projeto NotiSync ##

- **Página de Autenticação:**  
  - **Login:** Formulário com campos para e-mail e palavra-passe.  

- **Dashboard Principal:**  
  - **Visão Geral:** Resumo do estado das notificações, alertas recentes e estatísticas (número de notificações enviadas, pendentes, erros, etc.).  
  - **Widgets Dinâmicos:** Pequenos blocos informativos que podem ser atualizados em tempo real.

- **Gestão de Notificações:**  
  - **Listagem de Notificações:** Tabela ou cartões com a informação essencial de cada notificação (tipo, canal, estado, data de envio/agendamento).  
  - **Filtros e Pesquisa:** Opção para filtrar por tipo (lembrete, alerta, confirmação) e canal (e-mail, SMS, push), assim como uma funcionalidade de pesquisa.

- **Criação e Edição de Notificações:**  
  - **Formulário de Criação:** Interface para definir o conteúdo, selecionar o template, escolher os canais de envio e definir a data/hora de envio (agendamento).  
  - **Validação e Feedback:** Validação dos campos com feedback em tempo real (ex.: mensagens de erro, campos obrigatórios).

- **Templates de Notificações:**  
  - **Gestão de Templates:** Área para criar, editar e remover templates que poderão ser usados nas notificações.  
  - **Preview do Template:** Visualização prévia para garantir que o template está corretamente configurado.

- **Histórico e Rastreamento:**  
  - **Log de Envio:** Secção onde o utilizador pode visualizar o histórico das notificações enviadas, com detalhes sobre o estado de entrega, erros, etc.  
  - **Detalhes da Notificação:** Ao clicar numa notificação, exibição de mais detalhes (ex.: logs de envio, feedback do sistema).

- **Integração com Serviços Externos:**  
  - **Indicadores de Integração:** Se necessário, exibir o estado atual das integrações com serviços como SMTP, SendGrid, Twilio ou Firebase.  
  - **Alertas e Mensagens de Erro:** Notificações em tempo real em caso de falhas nas integrações.