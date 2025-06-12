<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Usuario, clasesGenericas.Rol, clasesGenericas.Area" %>
<%@ include file="menu.jsp" %>
<%
    // Obtener id del parámetro
    String idStr = request.getParameter("id");
    if (idStr == null) {
        response.sendRedirect("usuario.jsp");
        return;
    }
    int id;
    try {
        id = Integer.parseInt(idStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("usuario.jsp");
        return;
    }
    // Buscar el usuario en findAll()
    Usuario u = Usuario.findAll().stream()
            .filter(x -> x.getId() == id)
            .findFirst().orElse(null);
    if (u == null) {
        response.sendRedirect("usuario.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Editar Usuario</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
  <style>
    :root {
      --text: #e0e0e0;
      --white: #ffffff;
      --black: #000000;
      --border: #ccc;
      --hover-bg: #2a2a3d;
      --accent: #007bff;
    }
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      background: url("images/login-bg.jpg") no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
      font-family: 'Poppins', sans-serif;
    }
    * { box-sizing: border-box; color: inherit; }
    .menu-container { max-width: 960px; margin: 40px auto; padding: 0 16px; }
    .menu-box { background: var(--white); color: var(--black); padding: 24px; border-radius: 8px; box-shadow: 0 6px 20px rgba(0, 0, 0, 0.5); }
    .menu-box * { color: var(--black); }
    h2 { margin-bottom: 20px; font-size: 1.8rem; color: var(--black); }
    label { display: block; margin-bottom: 6px; font-weight: 500; color: var(--black); }
    input[type="text"], input[type="password"], select {
      width: 100%; padding: 10px; border: 1px solid var(--border);
      border-radius: 6px; margin-bottom: 20px; font-size: 1rem; color: var(--black); background: #fff;
    }
    .info-text { font-size: 0.9rem; color: #555; margin-top: -15px; margin-bottom: 15px; }
    .actions { display: flex; justify-content: flex-end; gap: 10px; flex-wrap: wrap; }
    .actions button {
      background: var(--white); color: var(--black); border: 1.5px solid var(--black);
      padding: 8px 14px; font-size: 0.9rem; border-radius: 6px; cursor: pointer; transition: all 0.2s ease;
    }
    .actions button:hover { background: var(--black); color: var(--white); }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Editar Usuario #<%= u.getId() %></h2>
      <form method="post" action="guardarUsuario.jsp">
        <input type="hidden" name="id" value="<%= u.getId() %>"/>
        <label for="nombre">Nombre:</label>
        <input type="text" id="nombre" name="nombre" value="<%= u.getNombre() %>" required/>

        <label for="usuario">Usuario:</label>
        <input type="text" id="usuario" name="usuario" value="<%= u.getUsuario() %>" required/>

        <label for="contrasena">Contraseña:</label>
        <input type="password" id="contrasena" name="contrasena" />
        <div class="info-text">Dejar vacío para mantener la contraseña actual</div>

        <label for="rol">Rol:</label>
        <select id="rol" name="rol" required>
          <option value="">-- Seleccione --</option>
          <%
            for (Rol r : Rol.findAll()) {
              boolean sel = (u.getRol() != null && r.getId() == u.getRol().getId());
          %>
            <option value="<%= r.getId() %>" <%= sel ? "selected" : "" %>><%= r.getNombre() %></option>
          <%
            }
          %>
        </select>

        <label for="area">Área:</label>
        <select id="area" name="area">
          <option value="">-- Ninguna --</option>
          <%
            for (Area a : Area.findAll()) {
              boolean sel = (u.getIdArea() != null && a.getId() == u.getIdArea());
          %>
            <option value="<%= a.getId() %>" <%= sel ? "selected" : "" %>><%= a.getNombre() %></option>
          <%
            }
          %>
        </select>

        <div class="actions">
          <button type="submit" class="btn-guardar">Actualizar</button>
          <button type="button" class="btn-cancelar" onclick="location.href='usuario.jsp'">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
