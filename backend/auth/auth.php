<?php
// auth.php
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Europe/Lisbon');

// Carrega ligação à BD e .env
require_once(__DIR__ . '/../config/connection.php');

// Função para gerar JWT HS256
function create_jwt(array $payload, string $secret): string {
    $header = ['alg'=>'HS256','typ'=>'JWT'];
    $encode = function($data) {
        return rtrim(strtr(base64_encode(json_encode($data)), '+/', '-_'), '=');
    };
    $header_b64  = $encode($header);
    $payload_b64 = $encode($payload);
    $signature   = hash_hmac('sha256', "$header_b64.$payload_b64", $secret, true);
    $sig_b64     = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    return "$header_b64.$payload_b64.$sig_b64";
}

// Função principal de autenticação
function authenticate(string $email, string $password): array {
    global $pdo;
    // validação de inputs
    if (trim($email)==='' || $password==='') {
        http_response_code(400);
        return ['type'=>'invalidInput'];
    }

    // consulta ao utilizador
    $stmt = $pdo->prepare('SELECT user_id, password, name FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        return ['type'=>'wrongEmail'];
    }

    if (!password_verify($password, $user['password'])) {
        http_response_code(401);
        return ['type'=>'wrongPassword'];
    }

    // carrega segredos e expirações do .env
    $now            = time();
    $access_exp     = intval($_ENV['ACCESS_TOKEN_EXPIRY']  ?? 3600);
    $refresh_exp    = intval($_ENV['REFRESH_TOKEN_EXPIRY'] ?? 604800);
    $jwt_secret     = $_ENV['JWT_SECRET']                  ?? 'muda_isto';

    // payload do access token
    $access_payload = [
        'iat'   => $now,
        'exp'   => $now + $access_exp,
        'sub'   => $user['user_id'],
        'name'  => $user['name'],
        'email' => $email
    ];

    // gera access token e refresh token
    $access_token  = create_jwt($access_payload, $jwt_secret);
    $refresh_token = bin2hex(random_bytes(32));
    $issued_at     = date('Y-m-d H:i:s', $now);
    $expires_at    = date('Y-m-d H:i:s', $now + $refresh_exp);

    // grava refresh token na BD
    $ins = $pdo->prepare('INSERT INTO refreshtokens (user_id, jwt, issued_at, expires_at) VALUES (?, ?, ?, ?)');
    $ins->execute([$user['user_id'], $refresh_token, $issued_at, $expires_at]);

    // devolve resposta de sucesso
    return [
        'type'               => 'success',
        'access_token'       => $access_token,
        'access_expires_in'  => $access_exp,
        'refresh_token'      => $refresh_token,
        'refresh_expires_in' => $refresh_exp
    ];
}
