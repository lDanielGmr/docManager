<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Area" %>
<%
    String nombre = request.getParameter("nombre");
    if (nombre != null) {
        Area a = new Area();
        a.setNombre(nombre);
        a.save();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Guardando Área...</title>
</head>
<body>
  <script>
    if (window.parent && typeof window.parent.closeParentModal === 'function') {
      window.parent.closeParentModal();
      window.parent.location.reload();
    } else {
      window.close();
    }
  </script>
</body>
</html>
<%
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Añadir Área</title>

  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/all.min.css">

  <style>
    :root {
      --bg: #1f1f2e;
      --text: #e0e0e0;
    }
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      background-color: var(--bg);
      background-image: url("${pageContext.request.contextPath}/images/login-bg.jpg");
      background-size: cover;
      background-position: center;
      background-repeat: no-repeat;
      color: var(--text);
      font-family: 'Segoe UI', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .form-container {
      width: 90%;
      max-width: 400px;
      background: rgba(255,255,255,0.95);
      padding: 20px;
      border-radius: 6px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    h2 {
      font-size: 1.5rem;
      margin-bottom: 16px;
      text-align: center;
      color: #333;
    }
    form {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    label {
      font-weight: bold;
      color: #333;
    }
    input[type="text"] {
      padding: 8px;
      border: 1px solid #ccc;
      border-radius: 4px;
      font-size: 1rem;
    }
    .buttons {
      display: flex;
      justify-content: space-between;
      margin-top: 16px;
    }
    .buttons button {
      padding: 8px 16px;
      border: none;
      border-radius: 4px;
      font-size: .95rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .buttons .cancel {
      background: #6c757d;
      color: #fff;
    }
    .buttons .save {
      background: #007bff;
      color: #fff;
    }
  </style>

  <script>
    function closeModal() {
      if (window.parent && typeof window.parent.closeParentModal === 'function') {
        window.parent.closeParentModal();
      } else {
        window.close();
      }
    }
    function closeAndRefresh() {
      if (window.parent && typeof window.parent.closeParentModal === 'function') {
        window.parent.closeParentModal();
        window.parent.location.reload();
      } else {
        window.close();
      }
    }
  </script>
</head>
<body>
  <div class="form-container">
    <h2>Añadir Nueva Área</h2>
    <form method="post" onsubmit="setTimeout(closeAndRefresh, 100);">
      <label for="nombre">Nombre del Área</label>
      <input type="text" id="nombre" name="nombre" placeholder="Ej. Contabilidad" required autofocus>
      <div class="buttons">
        <button type="button" class="cancel" onclick="closeModal()">
          <i class="fas fa-times"></i> Cerrar
        </button>
        <button type="submit" class="save">
          <i class="fas fa-save"></i> Guardar
        </button>
      </div>
    </form>
  </div>
</body>
</html>
