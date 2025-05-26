<?php
session_start();
require 'db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['task'])) {
    $task = $_POST['task'];
    $user_id = $_SESSION['user_id'];

    $stmt = $pdo->prepare("INSERT INTO todos (user_id, task, status) VALUES (?, ?, 'todo')");
    $stmt->execute([$user_id, $task]);
}

header("Location: index.php");
exit;
?>
