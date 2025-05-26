<?php
session_start();
require 'db.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$user_id = $_SESSION['user_id'];

$stmt = $pdo->prepare("SELECT * FROM todos WHERE user_id = ?");
$stmt->execute([$user_id]);
$todos = $stmt->fetchAll();

$columns = ['todo' => 'To Do', 'doing' => 'Doing', 'done' => 'Done'];
$grouped = ['todo' => [], 'doing' => [], 'done' => []];

foreach ($todos as $todo) {
    $grouped[$todo['status']][] = $todo;
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <title>Scrum To-Do</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light p-4">
    <div class="container">
        <h2 class="mb-4">مرحبًا، <?= htmlspecialchars($_SESSION['username']) ?> 👋</h2>

        <form action="add.php" method="POST" class="mb-4 d-flex gap-2">
            <input type="text" name="task" class="form-control" placeholder="مهمة جديدة" required>
            <button class="btn btn-primary">إضافة</button>
            <a href="logout.php" class="btn btn-secondary">تسجيل الخروج</a>
        </form>

        <div class="row">
            <?php foreach ($columns as $key => $label): ?>
                <div class="col-md-4">
                    <div class="card border-<?= $key === 'todo' ? 'secondary' : ($key === 'doing' ? 'warning' : 'success') ?>">
                        <div class="card-header bg-<?= $key === 'todo' ? 'secondary' : ($key === 'doing' ? 'warning' : 'success') ?> text-white">
                            <?= $label ?>
                        </div>
                        <ul class="list-group list-group-flush">
                            <?php foreach ($grouped[$key] as $task): ?>
                                <li class="list-group-item d-flex justify-content-between align-items-center">
                                    <?= htmlspecialchars($task['task']) ?>
                                    <div>
                                        <?php if ($key !== 'todo'): ?>
                                            <a href="move.php?id=<?= $task['id'] ?>&status=todo" class="btn btn-sm btn-outline-secondary">To Do</a>
                                        <?php endif; ?>
                                        <?php if ($key !== 'doing'): ?>
                                            <a href="move.php?id=<?= $task['id'] ?>&status=doing" class="btn btn-sm btn-outline-warning">Doing</a>
                                        <?php endif; ?>
                                        <?php if ($key !== 'done'): ?>
                                            <a href="move.php?id=<?= $task['id'] ?>&status=done" class="btn btn-sm btn-outline-success">Done</a>
                                        <?php endif; ?>
                                          <a href="delete.php?id=<?= $task['id'] ?>" class="btn btn-sm btn-outline-danger" onclick="return confirm('هل أنت متأكد من حذف المهمة؟')">حذف</a>
                                    </div>
                                </li>
                                
                            <?php endforeach; ?>
                        </ul>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</body>
</html>