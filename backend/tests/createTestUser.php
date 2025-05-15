<?php
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Europe/Lisbon');

// 1. Inclui a ligação à BD (e o carregamento do .env)
require_once __DIR__ . '/../config/connection.php';  // define $pdo

// 2. Dados do utilizador de teste
$testName     = 'Admin NotiSync';
$testEmail    = 'admin@notisync.pt';
$testPassword = 'admin';

// 3. Verifica se já existe
try {
    $stmt = $pdo->prepare('SELECT user_id FROM users WHERE email = ?');
    $stmt->execute([$testEmail]);
    if ($stmt->fetch()) {
        echo json_encode([
            'status'  => 'exists',
            'message' => 'O utilizador de teste já existe.',
            'email'   => $testEmail
        ]);
        exit;
    }

    // 4. Insere o novo utilizador
    $hashedPwd = password_hash($testPassword, PASSWORD_DEFAULT);
    $ins = $pdo->prepare('INSERT INTO users (name, email, password) VALUES (?, ?, ?)');
    $ins->execute([$testName, $testEmail, $hashedPwd]);

    echo json_encode([
        'status'   => 'created',
        'message'  => 'Utilizador de teste criado com sucesso!',
        'user_id'  => $pdo->lastInsertId(),
        'email'    => $testEmail,
        'password' => $testPassword
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Erro ao criar utilizador de teste: ' . $e->getMessage()
    ]);
}
