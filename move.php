<?php
session_start();
require 'db.php';

if (isset($_GET['id']) && isset($_GET['status'])) {
    $task_id = $_GET['id'];
    $new_status = $_GET['status'];
    $user_id = $_SESSION['user_id'];

    $allowed = ['todo', 'doing', 'done'];

    if (in_array($new_status, $allowed)) {
        $stmt = $pdo->prepare("UPDATE todos SET status = ? WHERE id = ? AND user_id = ?");
        $stmt->execute([$new_status, $task_id, $user_id]);
    }
}

header("Location: index.php");
exit;
?>