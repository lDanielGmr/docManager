<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Usuario, clasesGenericas.Rol, clasesGenericas.Area" %>
<%@ include file="menu.jsp" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Agregar Usuario</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
  <style>
    :root {
      --text: #e0e0e0;
      --accent: #007bff;
      --white: #ffffff;
      --black: #000000;
      --border: #ccc;
      --hover-bg: #2a2a3d;
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
    * {
      box-sizing: border-box;
      color: inherit;
    }
    .menu-container {
      max-width: 960px;
      margin: 40px auto;
      padding: 0 16px;
    }
    .menu-box {
      background: var(--white);
      color: var(--black);
      padding: 24px;
      border-radius: 8px;
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.5);
    }
    .menu-box * {
      color: var(--black);
    }
    h2 {
      margin-bottom: 20px;
      font-size: 1.8rem;
      color: var(--black);
    }
    .actions {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
      flex-wrap: wrap;
    }
    .actions button {
      background: var(--white);
      color: var(--black);
      border: 1.5px solid var(--black);
      padding: 8px 14px;
      font-size: 0.9rem;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .actions button:hover {
      background: var(--black);
      color: var(--white);
    }
    label {
      display: block;
      margin-bottom: 6px;
      font-weight: 500;
      color: var(--black);
    }
    input[type="text"], input[type="password"], select {
      width: 100%;
      padding: 10px;
      border: 1px solid var(--border);
      border-radius: 6px;
      margin-bottom: 20px;
      font-size: 1rem;
      color: var(--black);
      background: #fff;
    }
    button[type="submit"] {
      background: var(--white);
      color: var(--black);
      border: 1.5px solid var(--black);
      padding: 10px 20px;
      font-size: 1rem;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.3s ease;
    }
    button[type="submit"]:hover {
      background: var(--black);
      color: var(--white);
    }
    .success-message {
      background-color: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
      padding: 10px 15px;
      border-radius: 6px;
      margin-bottom: 20px;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Agregar Usuario</h2>
      <form method="post" action="guardarUsuario.jsp">
        <label for="nombre">Nombre:</label>
        <input type="text" id="nombre" name="nombre" required/>

        <label for="usuario">Usuario:</label>
        <input type="text" id="usuario" name="usuario" required/>

        <label for="contrasena">Contraseña:</label>
        <input type="password" id="contrasena" name="contrasena" required/>

        <label for="rol">Rol:</label>
        <select id="rol" name="rol" required>
          <option value="">-- Seleccione --</option>
          <%
            for (Rol r : Rol.findAll()) {
          %>
            <option value="<%= r.getId() %>"><%= r.getNombre() %></option>
          <%
            }
          %>
        </select>

        <label for="area">Área:</label>
        <select id="area" name="area">
          <option value="">-- Ninguna --</option>
          <%
            for (Area a : Area.findAll()) {
          %>
            <option value="<%= a.getId() %>"><%= a.getNombre() %></option>
          <%
            }
          %>
        </select>

        <div class="actions">
          <button type="submit" class="btn-guardar">Crear</button>
          <button type="button" class="btn-cancelar" onclick="location.href='usuario.jsp'">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
