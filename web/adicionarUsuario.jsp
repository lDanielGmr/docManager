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
  <style>
  :root {
    --text: #e0e0e0;
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

  .toolbar {
    display: flex;
    justify-content: flex-start;
    margin-bottom: 16px;
    gap: 10px;
  }

  .toolbar button {
    background: var(--white);
    color: var(--black);
    border: 1.5px solid var(--black);
    padding: 10px 16px;
    border-radius: 6px;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .toolbar button:hover {
    background: var(--black);
    color: var(--white);
  }

  table.etq-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
  }

  .etq-table th, .etq-table td {
    padding: 12px;
    border: 1px solid var(--border);
    text-align: left;
    font-size: 0.95rem;
    background: rgba(0, 0, 0, 0.03); 
    color: var(--black);
  }

  .etq-table th {
    background-color: rgba(0, 0, 0, 0.05);
    text-transform: uppercase;
  }

  .etq-table tr:hover {
    background-color: rgba(0, 0, 0, 0.08);
    cursor: pointer;
  }

  .etq-table tr.selected {
    background-color: rgba(0, 0, 0, 0.15) !important;
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

  .modal-overlay {
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal-content {
    background: var(--white);
    color: var(--black);
    padding: 24px;
    border-radius: 8px;
    max-width: 480px;
    width: 90%;
    position: relative;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
  }

  .modal-close {
    position: absolute;
    top: 10px; right: 10px;
    background: transparent;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    color: var(--black);
  }

  #formEtq label {
    display: block;
    margin-bottom: 6px;
    font-weight: 500;
    color: var(--black);
  }

  #formEtq input[type="text"] {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--border);
    border-radius: 6px;
    margin-bottom: 20px;
    font-size: 1rem;
    color: var(--black);
  }

  #formEtq button[type="submit"] {
    background: var(--white);
    color: var(--black);
    border: 1.5px solid var(--black);
    padding: 10px 20px;
    font-size: 1rem;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  #formEtq button[type="submit"]:hover {
    background: var(--black);
    color: var(--white);
  }
</style>

</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Agregar Usuario</h2>
      <form method="post" action="adicionarUsuarios.jsp">
        <label>Nombre:</label>
        <input type="text" name="nombre" required/>

        <label>Usuario:</label>
        <input type="text" name="usuario" required/>

        <label>Contraseña:</label>
        <input type="password" name="contraseña" required/>

        <label>Rol:</label>
        <select name="rol" required>
          <option value="">-- Seleccione --</option>
          <%
            for (Rol r : Rol.findAll()) {
          %>
            <option value="<%=r.getId()%>"><%=r.getNombre()%></option>
          <%
            }
          %>
        </select>

        <label>Área:</label>
        <select name="area">
          <option value="">-- Ninguna --</option>
          <%
            for (Area a : Area.findAll()) {
          %>
            <option value="<%=a.getId()%>"><%=a.getNombre()%></option>
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
<%
  if ("POST".equalsIgnoreCase(request.getMethod())) {
    Usuario u = new Usuario();
    u.setNombre(request.getParameter("nombre"));
    u.setUsuario(request.getParameter("usuario"));
    u.setContraseña(request.getParameter("contraseña"));
    u.setRol(Rol.findById(Integer.parseInt(request.getParameter("rol"))));
    String area = request.getParameter("area");
    if (area!=null && !area.isEmpty()) u.setIdArea(Integer.parseInt(area));
    u.saveOrUpdate();
    response.sendRedirect("usuario.jsp");
  }
%>
</body>
</html>
