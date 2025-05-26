<?php
session_start();
require 'db.php';

if (isset($_GET['id']) && isset($_SESSION['user_id'])) {
    $task_id = $_GET['id'];
    $user_id = $_SESSION['user_id'];

    $stmt = $pdo->prepare("DELETE FROM todos WHERE id = ? AND user_id = ?");
    $stmt->execute([$task_id, $user_id]);
}

header("Location: index.php");
exit;
