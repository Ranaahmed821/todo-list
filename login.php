<?php
session_start();
require 'db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'];

    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if (!$user) {
        $stmt = $pdo->prepare("INSERT INTO users (username) VALUES (?)");
        $stmt->execute([$username]);
        $user_id = $pdo->lastInsertId();
    } else {
        $user_id = $user['id'];
    }

    $_SESSION['user_id'] = $user_id;
    $_SESSION['username'] = $username;

    header("Location: index.php");
    exit;
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <title>تسجيل الدخول</title>
    <style>
        body {
            background: linear-gradient(to bottom right, #ffe0f0, #ffd6ec);
            font-family: 'Cairo', sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-image: url('photo.png'); /* صورة فراشات كيوت */
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
        }

        form {
            background-color: rgba(255, 255, 255, 0.9);
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
            text-align: center;
            width: 300px;
            position: relative;
        }

        label {
            font-size: 18px;
            color: #d63384;
            display: block;
            margin-bottom: 10px;
        }

        input[type="text"] {
            padding: 10px;
            width: 100%;
            border: 2px solid #f8bbd0;
            border-radius: 10px;
            margin-bottom: 15px;
            font-size: 16px;
        }

        button {
            background-color: #f06292;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 12px;
            font-size: 16px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        button:hover {
            background-color: #ec407a;
        }

        form::before {
            content: "🦋";
            font-size: 40px;
            position: absolute;
            top: -20px;
            right: -20px;
            animation: flutter 3s infinite alternate ease-in-out;
        }

        @keyframes flutter {
            0% { transform: translateY(0); }
            100% { transform: translateY(10px) rotate(10deg); }
        }
    </style>
</head>
<body>
    <form method="POST">
        <label>اسم المستخدم:</label>
        <input type="text" name="username" required>
        <button type="submit">دخول</button>
    </form>
</body>
</html>
