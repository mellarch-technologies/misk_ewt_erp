<?php
// Simple secure upload endpoint for shared hosting
// Place this at: /api/upload.php on your uploads subdomain
// Returns: JSON {"url":"https://..."} on success, or {"error":"..."}

// --- CONFIG ---
// Set a strong secret. Keep this file private in your repo or set via deployment.
const API_KEY = 'CHANGE_ME_STRONG_SECRET';
const MAX_BYTES = 3 * 1024 * 1024; // 3 MB limit
$BASE_URL = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
$UPLOADS_DIR = realpath(__DIR__ . '/../uploads'); // adjust if your uploads dir differs

header('Content-Type: application/json');

function fail($msg, $code = 400) {
  http_response_code($code);
  echo json_encode(['error' => $msg]);
  exit;
}

// Secret validation
$apiKey = $_POST['apiKey'] ?? '';
if (!$apiKey || $apiKey !== API_KEY) {
  fail('Unauthorized', 401);
}

// File validation
if (!isset($_FILES['file'])) {
  fail('Missing file');
}
$file = $_FILES['file'];
if ($file['error'] !== UPLOAD_ERR_OK) {
  fail('Upload error code: '.$file['error']);
}
if ($file['size'] > MAX_BYTES) {
  fail('File too large');
}

// Basic type check (allow jpeg/png/webp)
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($file['tmp_name']);
$ext = null;
$allowed = [
  'image/jpeg' => 'jpg',
  'image/png'  => 'png',
  'image/webp' => 'webp',
];
if (!isset($allowed[$mime])) {
  fail('Unsupported file type');
}
$ext = $allowed[$mime];

// Sanitize optional dir
$dir = $_POST['dir'] ?? '';
$dir = trim($dir);
$dir = str_replace(['\\', '..'], ['/', ''], $dir);
$dir = ltrim($dir, '/');
if ($dir === '') { $dir = 'misc'; }

// Ensure uploads base exists and is writable
if ($UPLOADS_DIR === false) {
  fail('Uploads directory not found (server misconfigured)', 500);
}
$targetDir = $UPLOADS_DIR . DIRECTORY_SEPARATOR . $dir;
if (!is_dir($targetDir)) {
  if (!mkdir($targetDir, 0755, true)) {
    fail('Failed to create target directory', 500);
  }
}

// Generate random filename
$rand = bin2hex(random_bytes(8));
$filename = $rand . '_' . time() . '.' . $ext;
$targetPath = $targetDir . DIRECTORY_SEPARATOR . $filename;

if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
  fail('Failed to move uploaded file', 500);
}

// Build public URL (assumes /uploads is web-accessible at /uploads)
$publicUrl = rtrim($BASE_URL, '/') . '/uploads/' . str_replace(DIRECTORY_SEPARATOR, '/', $dir) . '/' . $filename;

echo json_encode(['url' => $publicUrl]);

