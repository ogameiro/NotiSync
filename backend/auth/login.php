<?php
// login.php
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Europe/Lisbon');

// Carrega a lógica de autenticação
require_once(__DIR__ . '/auth.php');

// Lê input JSON
$input    = json_decode(file_get_contents('php://input'), true);
$email    = $input['email']    ?? '';
$password = $input['password'] ?? '';

// Executa autenticação
$result = authenticate($email, $password);

// Mostra o resultado em JSON
echo json_encode($result);
