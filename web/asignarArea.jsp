<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, clasesGenericas.Usuario, clasesGenericas.Area" %>
<%@ include file="menu.jsp" %>
<%
    List<Usuario> usuarios = Usuario.findAll();
    List<Area>   areas    = Area.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Asignar Área a Usuario</title>
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
    background: rgba(0, 0, 0, 0.03); /
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
      <h2>Asignar Área a Usuario</h2>
      <form action="procesarAsignacionArea.jsp" method="post">
        <table class="assign-table">
          <thead>
            <tr>
              <th>Numero</th>
              <th>Usuario</th>
              <th>Área Actual</th>
              <th>Asignar Área</th>
            </tr>
          </thead>
          <tbody>
            <% int idx = 1;
               for (Usuario u : usuarios) {
                   String areaActual = u.getArea();
                   if (areaActual == null) areaActual = "-";
            %>
            <tr>
              <td><%= idx++ %></td>
              <td><%= u.getNombre() %> (<%= u.getUsuario() %>)</td>
              <td><%= areaActual %></td>
              <td>
                <select name="area_<%= u.getId() %>">
                  <option value="">-- Ninguna --</option>
                  <% for (Area a : areas) {
                       String sel = a.getNombre().equals(u.getArea()) ? "selected" : "";
                  %>
                  <option value="<%= a.getId() %>" <%= sel %>>
                    <%= a.getNombre() %>
                  </option>
                  <% } %>
                </select>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
        <div class="actions">
          <button type="submit" class="save">Guardar Asignaciones</button>
          <button type="button" class="cancel" onclick="history.back()">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
