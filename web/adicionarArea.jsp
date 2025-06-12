<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Area" %>
<%
    String nombre = request.getParameter("nombre");
    if (nombre != null) {
        try {
            Area a = new Area();
            a.setNombre(nombre.trim());
            a.save();
        } catch (Exception e) {
        }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Cerrando...</title>
</head>
<body>
  <script>
    try {
      if (window.parent) {
        var modal = window.parent.document.getElementById('modal');
        if (modal) {
          modal.style.display = 'none';
        }
        window.parent.location.reload();
      }
    } catch(e){}
    try {
      window.open('', '_self');
      window.close();
    } catch(e){}
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
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e;
      --text: #e0e0e0;
      --accent: #007bff;
      --danger: #dc3545;
      --radius: 6px;
      --font: 'Segoe UI', sans-serif;
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
      font-family: var(--font);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .form-container {
      width: 90%;
      max-width: 400px;
      background: rgba(255,255,255,0.95);
      padding: 20px;
      border-radius: var(--radius);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      position: relative;
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
      background: var(--danger);
      color: var(--light);
      font-weight: bold;
      box-shadow: 0 2px 6px rgba(0,0,0,0.2);
      transition: background 0.2s ease, transform 0.2s ease;
    }
    .buttons .cancel:hover {
      background: #bd2130;
      transform: scale(1.05);
    }
    .buttons .save {
      background: var(--accent);
      color: var(--light);
    }
  </style>

  <script>
    function closeModalOrWindow() {
      try {
        var modal = window.parent.document.getElementById('modal');
        if (modal) {
          modal.style.display = 'none';
        } else {
          window.open('', '_self');
          window.close();
        }
      } catch(e){
        try { window.open('', '_self'); window.close(); } catch(e){}
      }
    }
  </script>
</head>
<body>
  <div class="form-container">
    <h2>Añadir Nueva Área</h2>
    <form method="post">
      <label for="nombre">Nombre del Área</label>
      <input type="text" id="nombre" name="nombre" placeholder="Ej. Contabilidad" required autofocus>
      <div class="buttons">
        <button type="button" class="cancel" onclick="closeModalOrWindow()">
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
