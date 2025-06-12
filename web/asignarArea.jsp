<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, java.util.Optional, clasesGenericas.Usuario, clasesGenericas.Area" %>
<%@ include file="menu.jsp" %>
<%
    String cp = request.getContextPath();

    final int PAGE_SIZE = 7;
    int currentPage = Optional.ofNullable(request.getParameter("page"))
        .flatMap(s -> {
            try { return Optional.of(Integer.parseInt(s)); }
            catch (Exception e) { return Optional.empty(); }
        })
        .orElse(1);
    if (currentPage < 1) currentPage = 1;

    List<Usuario> allUsuarios = Usuario.findAll();
    List<Area> areas = Area.findAll();

    int totalRows = allUsuarios.size();
    int totalPages = Math.max(1, (int)Math.ceil((double)totalRows / PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;

    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize/2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    int fromIndex = (currentPage - 1) * PAGE_SIZE;
    int toIndex = Math.min(fromIndex + PAGE_SIZE, totalRows);
    List<Usuario> pageList = allUsuarios.subList(fromIndex, toIndex);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Asignar Área a Usuario</title>
  <link rel="stylesheet" href="<%=cp%>/style.css">
  <link rel="stylesheet" href="<%=cp%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;      
      --text: #e0e0e0;
      --white: #fff;
      --black: #000;
      --border: #ccc;
      --hover-bg: #2a2a3d;
      --table-header: #f5f5f5;
      --table-row-hover: #fafafa;
      --shadow: rgba(0,0,0,0.4);
    }
    html, body {
      margin:0; padding:0; height:100%; overflow-y:auto;
      background: var(--bg) url('<%=cp%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
      font-family: 'Poppins', sans-serif;
    }
    * { box-sizing:border-box; }
    .menu-container {
      max-width:960px; margin:40px auto; padding:0 16px;
    }
    .menu-box {
      background: var(--white); color: var(--black);
      padding:24px; border-radius:8px;
      box-shadow:0 6px 20px var(--shadow);
    }
    h2 {
      font-size:1.8rem; margin-bottom:20px; color: var(--black);
    }
    table.assign-table {
      width:100%; border-collapse:collapse; margin-bottom:20px;
      background: var(--white); border-radius:6px; overflow:hidden;
      box-shadow:0 1px 3px rgba(0,0,0,0.1);
    }
    .assign-table th, .assign-table td {
      padding:12px; border:1px solid var(--border);
      font-size:.95rem; color: var(--black); text-align:left;
    }
    .assign-table th {
      background: var(--table-header); text-transform:uppercase;
    }
    .assign-table tr:hover {
      background: var(--table-row-hover); transition:background .2s;
    }
    .assign-table tr:last-child td {
      border-bottom:none;
    }
    select {
      padding:6px 8px; border:1px solid var(--border);
      border-radius:4px; font-size:.9rem; color: var(--black);
      background: var(--white);
    }
    .actions {
      display:flex; gap:10px; justify-content:flex-end; margin-top: 12px;
    }
    .actions button {
      display:inline-flex; align-items:center; gap:6px;
      background: var(--accent); color: var(--white);
      border:none; padding:8px 14px; border-radius:6px;
      font-size:.9rem; cursor:pointer; transition:opacity .2s;
    }
    .actions button.cancel {
      background:#f0f0f0; color:#333; border:1px solid #bbb;
    }
    .actions button:hover {
      opacity:.8;
    }
    .pagination {
      display:flex; justify-content:center; align-items:center;
      gap:8px; margin-top:16px; list-style:none; padding:0; flex-wrap:wrap;
    }
    .pagination li a {
      display:inline-block; background:var(--accent); color:#fff;
      text-decoration:none; padding:8px 12px; font-size:.9rem;
      border-radius:4px; min-width:32px; text-align:center;
      transition:background 0.3s ease;
    }
    .pagination li.disabled a { background:#ccc; color:#666; pointer-events:none; }
    .pagination li.active a {
      background:#4e32a8; font-weight:bold; border:2px solid #fff;
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
            <%
               int idx = fromIndex + 1;
               if (pageList.isEmpty()) {
            %>
            <tr>
              <td colspan="4" style="text-align:center; color:#666;">No hay usuarios para mostrar.</td>
            </tr>
            <%
               } else {
                 for (Usuario u : pageList) {
                   String areaAct = u.getArea() != null ? u.getArea() : "-";
            %>
            <tr>
              <td><%= idx++ %></td>
              <td><%= u.getNombre() %> (<%= u.getUsuario() %>)</td>
              <td><%= areaAct %></td>
              <td>
                <select name="area_<%=u.getId()%>">
                  <option value="">-- Ninguna --</option>
                  <% for (Area a : areas) {
                       String sel = a.getNombre().equals(u.getArea()) ? "selected" : "";
                  %>
                  <option value="<%=a.getId()%>" <%= sel %>><%=a.getNombre()%></option>
                  <% } %>
                </select>
              </td>
            </tr>
            <%
                 }
               }
            %>
          </tbody>
        </table>

        <ul class="pagination">
          <li class="<%= currentPage == 1 ? "disabled" : "" %>">
            <a href="?page=1">&laquo;&laquo;</a>
          </li>
          <li class="<%= currentPage == 1 ? "disabled" : "" %>">
            <a href="?page=<%= currentPage - 1 %>">&laquo;</a>
          </li>
          <%
            for (int p = startPage; p <= endPage; p++) {
          %>
          <li class="<%= p == currentPage ? "active" : "" %>">
            <a href="?page=<%= p %>"><%= p %></a>
          </li>
          <%
            }
          %>
          <li class="<%= currentPage == totalPages ? "disabled" : "" %>">
            <a href="?page=<%= currentPage + 1 %>">&rsaquo;</a>
          </li>
          <li class="<%= currentPage == totalPages ? "disabled" : "" %>">
            <a href="?page=<%= totalPages %>">&raquo;&raquo;</a>
          </li>
        </ul>

        <div class="actions">
          <button type="submit">
            <i class="fas fa-save"></i> Guardar Asignaciones
          </button>
          <button type="button" class="cancel" onclick="history.back()">
            <i class="fas fa-times"></i> Cancelar
          </button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
