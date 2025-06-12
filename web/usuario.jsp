<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Optional,
    clasesGenericas.Usuario
" %>
<%@ include file="menu.jsp" %>
<%
    String cp = request.getContextPath();

    final int PAGE_SIZE = 8;
    int currentPage = Optional.ofNullable(request.getParameter("page"))
        .flatMap(s -> {
            try { return Optional.of(Integer.parseInt(s)); }
            catch (Exception e) { return Optional.empty(); }
        })
        .orElse(1);
    if (currentPage < 1) currentPage = 1;

    List<Usuario> lista = Usuario.findAll();
    int totalRows = lista.size();
    int totalPages = Math.max(1, (int) Math.ceil((double) totalRows / PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;

    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize / 2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    int fromIndex = (currentPage - 1) * PAGE_SIZE;
    int toIndex = Math.min(fromIndex + PAGE_SIZE, totalRows);
    List<Usuario> pageList = lista.subList(fromIndex, toIndex);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Listado de Usuarios</title>
  <link rel="stylesheet" href="<%=cp%>/style.css">
  <link rel="stylesheet" href="<%=cp%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg-color: #1f1f2e;
      --accent: #007bff;
      --text: #e0e0e0;
      --light: #fff;
      --shadow: rgba(0, 0, 0, 0.4);
      --border-light: #ccc;
      --table-text: #333;
      --bg: #12121c;
    }
    html, body {
      margin: 0; padding: 0; height: 100%; overflow-y: auto;
      background: var(--bg-color) url('<%=cp%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
    }
    * {
      box-sizing: border-box;
      font-family: 'Poppins', sans-serif;
      color: inherit;
    }
    .menu-container {
      width: 100%; max-width: 960px;
      margin: 20px auto; padding: 0 10px;
    }
    .menu-box {
      background: #fff; padding: 16px; border-radius: 4px;
      box-shadow: 0 4px 12px var(--shadow); line-height: 1.5;
    }
    h2 {
      font-size: 1.5rem; margin-bottom: 14px; color: #333;
    }
    .toolbar {
      display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 14px;
    }
    .toolbar button,
    .actions button {
      font-size: 0.9rem; padding: 6px 10px; border-radius: 4px;
      border: none; cursor: pointer;
      background: var(--accent); color: var(--light);
      display: inline-flex; align-items: center; gap: 6px;
    }
    .toolbar button:hover,
    .actions button:hover {
      opacity: 0.9;
    }
    .docs-table {
      width: 100%; border-collapse: collapse; margin-bottom: 16px;
      background: var(--light);
    }
    .docs-table th,
    .docs-table td {
      padding: 10px 6px;
      border: 1px solid var(--border-light);
      font-size: 0.85rem; word-break: break-word;
      color: var(--table-text);
    }
    .docs-table th {
      background: #f5f5f5; text-transform: uppercase;
    }
    .docs-table tr:hover {
      background: #fafafa; cursor: pointer;
    }

    .pagination {
      display:flex; justify-content:center; align-items:center;
      gap:8px; margin-top:20px; list-style:none; padding:0; flex-wrap:wrap;
    }
    .pagination li a {
      display:inline-block; background:var(--accent); color:#fff;
      text-decoration:none; padding:10px 16px; font-size:1rem;
      border-radius:4px; min-width:44px; text-align:center;
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
      <h2>Usuarios</h2>
      <div class="toolbar">
        <button onclick="location.href='adicionarUsuario.jsp'">
          <i class="fas fa-user-plus"></i> Agregar Usuario
        </button>
      </div>
      <table class="docs-table">
        <thead>
          <tr>
            <th>Numero</th>
            <th>Nombre</th>
            <th>Usuario</th>
            <th>Rol</th>
            <th>Área</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
        <%
          for (Usuario u : pageList) {
        %>
          <tr>
            <td><%= u.getId() %></td>
            <td><%= u.getNombre() %></td>
            <td><i class="fas fa-user-circle"></i> <%= u.getUsuario() %></td>
            <td><i class="fas fa-user-tag"></i> <%= u.getRol().getNombre() %></td>
            <td><i class="fas fa-building"></i> <%= u.getArea() != null ? u.getArea() : "-" %></td>
            <td class="actions">
              <button onclick="location.href='modificarUsuario.jsp?id=<%=u.getId()%>'">
                <i class="fas fa-edit"></i> Editar
              </button>
              <button onclick="location.href='eliminarUsuario.jsp?id=<%=u.getId()%>'">
                <i class="fas fa-trash-alt"></i> Eliminar
              </button>
            </td>
          </tr>
        <%
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

    </div>
  </div>
</body>
</html>
