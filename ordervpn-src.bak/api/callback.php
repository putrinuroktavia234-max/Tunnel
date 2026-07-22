<?php
// OrderVPN — Callback API (Tripay / manual topup)
require_once __DIR__ . '/../includes/config.php';

header('Content-Type: application/json');

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid payload']);
    exit;
}

// TODO: validate signature with Tripay private key / merchant code
// $signature = hash_hmac('sha256', $input, env('TRIPAY_PRIVATE_KEY', ''));

$ref = $data['reference'] ?? '';
$status = $data['status'] ?? '';

if ($ref && $status === 'PAID') {
    // Update transaction / topup logic
    echo json_encode(['status' => 'success', 'message' => 'Payment received']);
} else {
    echo json_encode(['status' => 'ignored']);
}
