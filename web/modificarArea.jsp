<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Area" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) {
        response.sendRedirect("area.jsp");
        return;
    }
    int id = Integer.parseInt(idParam);
    Area area = Area.findById(id);
    if (area == null) {
        response.sendRedirect("area.jsp");
        return;
    }

    boolean updated = false;
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String nuevoNombre = request.getParameter("nombre");
        if (nuevoNombre != null && !nuevoNombre.trim().isEmpty()) {
            try {
                area.setNombre(nuevoNombre.trim());
                area.update();
                updated = true;
            } catch (Exception e) {
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Modificar Área</title>
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
      margin: 0; padding: 0; height: 100%;
      background-color: var(--bg);
      background-image: url("${pageContext.request.contextPath}/images/login-bg.jpg");
      background-size: cover;
      background-position: center;
      background-repeat: no-repeat;
      color: var(--text);
      font-family: var(--font);
      display: flex; align-items: center; justify-content: center;
    }
    .form-container {
      width: 90%; max-width: 400px;
      background: rgba(255,255,255,0.95);
      padding: 20px;
      border-radius: var(--radius);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      position: relative;
    }
    h2 {
      font-size: 1.5rem; margin-bottom: 16px;
      text-align: center; color: #333;
    }
    .message {
      padding: 10px; margin-bottom: 16px;
      border-radius: 4px; font-size: 0.95rem;
    }
    .message.success {
      background: #d4edda; color: #155724; border: 1px solid #c3e6cb;
    }
    .message.error {
      background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb;
    }
    form {
      display: flex; flex-direction: column; gap: 12px;
    }
    label {
      font-weight: bold; color: #333;
    }
    input[type="text"] {
      padding: 8px; border: 1px solid #ccc;
      border-radius: 4px; font-size: 1rem;
    }
    .buttons {
      display: flex; justify-content: space-between; margin-top: 16px;
    }
    button {
      padding: 8px 16px; border: none;
      border-radius: 4px; font-size: .95rem;
      cursor: pointer; display: flex;
      align-items: center; gap: 6px;
    }
    button.save {
      background: var(--accent); color: #fff;
    }
    button.cancel {
      background: var(--danger); color: #fff;
    }
  </style>

  <script>
    window.resizeTo(620, 440);

    function closeModalOrWindow() {
      try {
        var modal = window.parent && window.parent.document.getElementById('modal');
        if (modal) {
          modal.style.display = 'none';
        } else {
          window.open('', '_self');
          window.close();
        }
      } catch(e) {
        try { window.open('', '_self'); window.close(); } catch(e){}
      }
    }
  </script>
</head>
<body>
  <div class="form-container">
    <h2>Modificar Área</h2>

    <% if (updated) { %>
      <div class="message success">
        ¡Área modificada correctamente!
      </div>
    <% } %>

    <form method="post" action="">
      <input type="hidden" name="id" value="<%= area.getId() %>">

      <label for="nombre">Nombre del Área</label>
      <input
        type="text"
        id="nombre"
        name="nombre"
        value="<%= area.getNombre() %>"
        required
        autofocus
      />

      <div class="buttons">
        <button type="button" class="cancel" onclick="closeModalOrWindow()">
          <i class="fas fa-times"></i> Cancelar
        </button>
        <button type="submit" class="save">
          <i class="fas fa-save"></i> Guardar Cambios
        </button>
      </div>
    </form>
  </div>
</body>
</html>
