<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Optional,
    clasesGenericas.Rol
" %>
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

    List<Rol> allRoles = Rol.findAll();
    int totalRows = allRoles.size();
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
    List<Rol> pageList = allRoles.subList(fromIndex, toIndex);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Roles</title>
  <link rel="stylesheet" href="<%=cp%>/style.css">
  <link rel="stylesheet" href="<%=cp%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;
      --text: #e0e0e0;
      --light: #fff;
      --shadow: rgba(0, 0, 0, 0.4);
      --border-light: #ddd;
      --hover-light: #fafafa;
      --table-header-bg: #f5f5f5;
      --text-dark: #222;
      --text-header: #444;
      --disabled-bg: #ccc;
      --disabled-text: #666;
    }
    html, body {
      margin: 0; padding: 0; height: 100%; overflow-y: auto;
      background: var(--bg) url('<%=cp%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
      font-family: 'Poppins', sans-serif;
    }
    * {
      box-sizing: border-box;
      color: inherit;
      font-family: inherit;
    }
    .menu-container {
      width: 100%; max-width: 960px;
      margin: 20px auto; padding: 0 10px;
    }
    .menu-box {
      background: var(--light);
      padding: 16px; border-radius: 4px;
      box-shadow: 0 4px 12px var(--shadow);
      color: #000;
    }
    h2 {
      font-size: 1.5rem; margin-bottom: 14px; color: var(--text-header);
    }
    .toolbar {
      display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 14px;
    }
    .toolbar button {
      font-size: 0.9rem; padding: 6px 10px; border-radius: 4px;
      border: none; cursor: pointer;
      background: var(--accent); color: var(--light);
      display: inline-flex; align-items: center; gap: 6px;
    }
    .toolbar button:hover {
      opacity: 0.9;
    }
    .roles-table {
      width: 100%; border-collapse: collapse; margin-bottom: 16px;
      background: var(--light);
    }
    .roles-table th, .roles-table td {
      padding: 10px 6px; border: 1px solid var(--border-light);
      font-size: 0.85rem; word-break: break-word;
      color: var(--text-dark);
    }
    .roles-table th {
      background: var(--table-header-bg); text-transform: uppercase;
      color: var(--text-header);
    }
    .roles-table tr:hover {
      background: var(--hover-light); cursor: pointer;
    }
    .roles-table tr.selected {
      background: #e6f7ff !important;
    }
    .actions {
      display: flex; justify-content: flex-end; gap: 6px; flex-wrap: wrap;
      margin-bottom: 16px;
    }
    .actions button {
      font-size: 0.85rem; padding: 6px 12px; border-radius: 4px;
      border: none; cursor: pointer;
      background: var(--accent); color: var(--light);
      display: inline-flex; align-items: center; gap: 6px;
    }
    .actions button:hover {
      opacity: 0.9;
    }
    .modal-overlay {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.5); display: none;
      align-items: center; justify-content: center; z-index: 1000;
    }
    .modal-content {
      background: var(--light); width: 90%; max-width: 760px;
      border-radius: 6px; position: relative;
      box-shadow: 0 4px 12px var(--shadow); padding: 20px;
      color: #000;
    }
    .modal-close {
      position: absolute; top: 10px; right: 10px;
      background: transparent; border: none;
      font-size: 1.4rem; cursor: pointer;
    }
    #formRol label {
      display: block; margin-bottom: 6px; font-weight: 600;
    }
    #formRol input[type="text"] {
      width: 100%; padding: 8px 10px; margin-bottom: 16px;
      border: 1px solid var(--border-light); border-radius: 4px;
      font-size: 1rem; color: #000;
    }
    #formRol button[type="submit"] {
      background: var(--accent); border: none;
      color: var(--light); padding: 10px 20px;
      font-size: 1rem; border-radius: 4px; cursor: pointer;
      display: inline-flex; align-items: center; gap: 6px;
    }
    #formRol button[type="submit"]:hover {
      opacity: 0.9;
    }
    .pagination {
      display: flex; justify-content: center; align-items: center;
      gap: 8px; margin-top: 16px; list-style: none; padding: 0; flex-wrap: wrap;
    }
    .pagination li a {
      display: inline-block; background: var(--accent); color: #fff;
      text-decoration: none; padding: 6px 10px; font-size: 0.85rem;
      border-radius: 4px; min-width: 28px; text-align: center;
      transition: background 0.3s ease;
    }
    .pagination li.disabled a { background: #ccc; color: #666; pointer-events: none; }
    .pagination li.active a {
      background: #4e32a8; font-weight: bold; border: 2px solid #fff;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Roles</h2>

      <section class="toolbar">
        <button id="btnAdd">
          <i class="fas fa-plus"></i> Añadir rol
        </button>
      </section>

      <section>
        <table class="roles-table" id="tablaRoles">
          <thead>
            <tr>
              <th>Numero</th>
              <th>Nombre</th>
            </tr>
          </thead>
          <tbody>
            <%
              int seq = fromIndex + 1;
              if (pageList.isEmpty()) {
            %>
            <tr>
              <td colspan="2" style="text-align:center; color:#666;">No hay roles para mostrar.</td>
            </tr>
            <%
              } else {
                  for (Rol r : pageList) {
                      boolean usado = Rol.isUsed(r.getId());
            %>
            <tr data-id="<%= r.getId() %>" data-usado="<%= usado %>" onclick="seleccionar(this)">
              <td><%= seq++ %></td>
              <td><%= r.getNombre() %></td>
            </tr>
            <%
                  }
              }
            %>
          </tbody>
        </table>
      </section>

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

      <section class="actions">
        <button id="btnEdit">
          <i class="fas fa-edit"></i> Modificar
        </button>
        <button id="btnDelete" title="Selecciona un rol">
          <i class="fas fa-trash-alt"></i> Eliminar
        </button>
      </section>
    </div>
  </div>

  <div class="modal-overlay" id="modal">
    <div class="modal-content">
      <button class="modal-close" id="btnClose">&times;</button>
      <form id="formRol" method="post">
        <input type="hidden" name="id" id="rolId">
        <label for="rolNombre">Nombre del rol</label>
        <input type="text" name="nombre" id="rolNombre" required>
        <button type="submit" id="submitBtn">
          <i class="fas fa-save"></i> Guardar
        </button>
      </form>
    </div>
  </div>

  <script>
    let selectedRow = null;

    function seleccionar(row) {
      document.querySelectorAll('tr.selected').forEach(r => r.classList.remove('selected'));
      row.classList.add('selected');
      selectedRow = row;

      const btnDelete = document.getElementById('btnDelete');
      btnDelete.title = "Eliminar rol";
    }

    const modal       = document.getElementById('modal'),
          form        = document.getElementById('formRol'),
          nombreInput = document.getElementById('rolNombre'),
          idInput     = document.getElementById('rolId'),
          submitBtn   = document.getElementById('submitBtn'),
          btnAdd      = document.getElementById('btnAdd'),
          btnEdit     = document.getElementById('btnEdit'),
          btnDelete   = document.getElementById('btnDelete'),
          btnClose    = document.getElementById('btnClose');

    btnAdd.onclick = () => {
      selectedRow = null;
      document.querySelectorAll('tr.selected').forEach(r => r.classList.remove('selected'));
      idInput.value = '';
      nombreInput.value = '';
      submitBtn.innerHTML = '<i class="fas fa-plus"></i> Añadir';
      form.action = 'adicionarRol.jsp';
      modal.style.display = 'flex';
    };

    btnEdit.onclick = () => {
      if (!selectedRow) {
        alert('Selecciona un rol');
        return;
      }
      idInput.value = selectedRow.dataset.id;
      nombreInput.value = selectedRow.cells[1].textContent.trim();
      submitBtn.innerHTML = '<i class="fas fa-edit"></i> Modificar';
      form.action = 'modificarRol.jsp';
      modal.style.display = 'flex';
    };

    btnDelete.onclick = () => {
      if (!selectedRow) {
        alert('Selecciona un rol');
        return;
      }
      const usado = selectedRow.getAttribute('data-usado') === 'true';
      if (usado) {
        alert('No se puede eliminar: el rol está asignado a uno o más usuarios.');
        return;
      }
      const nombre = selectedRow.cells[1].textContent.trim();
      if (confirm('¿Eliminar rol "' + nombre + '"?')) {
        window.location = 'eliminarRol.jsp?id=' + selectedRow.dataset.id + '&page=<%=currentPage%>';
      }
    };

    btnClose.onclick = () => modal.style.display = 'none';
    window.onclick = e => { if (e.target === modal) modal.style.display = 'none'; };
  </script>
</body>
</html>
