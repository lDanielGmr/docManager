<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Optional,
    clasesGenericas.Etiqueta
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

    List<Etiqueta> allEtiquetas = Etiqueta.findAll();
    int totalRows = allEtiquetas.size();
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
    List<Etiqueta> pageList = allEtiquetas.subList(fromIndex, toIndex);
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Etiquetas</title>
  <link rel="stylesheet" href="<%=cp%>/style.css">
  <link rel="stylesheet" href="<%=cp%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;
      --text: #e0e0e0;
      --light: #fff;
      --shadow: rgba(0,0,0,0.4);
      --border-light: #ccc;
      --hover-light: #fafafa;
      --header-bg: #f5f5f5;
      --text-dark: #222;
      --text-header: #444;
    }
    html, body {
      margin:0; padding:0; height:100%; overflow-y:auto;
      background: var(--bg) url('<%=cp%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size:cover; color: var(--text);
      font-family: 'Poppins', sans-serif;
    }
    * { box-sizing: border-box; color: inherit; }
    .menu-container {
      max-width:960px; margin:40px auto; padding:0 16px;
    }
    .menu-box {
      background: var(--light); color: var(--text-dark);
      padding:24px; border-radius:8px;
      box-shadow:0 6px 20px var(--shadow);
    }
    h2 {
      font-size:1.8rem; margin-bottom:20px; color: var(--text-header);
    }
    .toolbar {
      display:flex; gap:10px; margin-bottom:16px;
    }
    .toolbar button {
      background: var(--accent); color: var(--light);
      border:none; padding:10px 16px; border-radius:6px;
      font-size:.95rem; display:inline-flex; align-items:center; gap:6px;
      cursor:pointer; transition:opacity .3s;
    }
    .toolbar button:hover { opacity:.8; }
    table.etq-table {
      width:100%; border-collapse:collapse; margin-bottom:20px;
      background: var(--light);
    }
    .etq-table th, .etq-table td {
      padding:12px; border:1px solid var(--border-light);
      font-size:.95rem; color: var(--text-dark);
    }
    .etq-table th {
      background: var(--header-bg); text-transform:uppercase;
      color: var(--text-header);
    }
    .etq-table tr:hover { background: var(--hover-light); cursor:pointer; }
    .etq-table tr.selected { background: #e6f7ff !important; }
    .actions {
      display:flex; gap:10px; justify-content:flex-end; flex-wrap:wrap;
      margin-bottom:16px;
    }
    .actions button {
      background: var(--accent); color: var(--light);
      border:none; padding:8px 14px; border-radius:6px;
      font-size:.9rem; display:inline-flex; align-items:center; gap:6px;
      cursor:pointer; transition:opacity .2s;
    }
    .actions button:hover { opacity:.8; }
    .modal-overlay {
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(0,0,0,0.7); display:none;
      align-items:center; justify-content:center; z-index:1000;
    }
    .modal-content {
      background: var(--light); color: var(--text-dark);
      padding:24px; border-radius:8px; width:90%; max-width:480px;
      box-shadow:0 6px 20px var(--shadow); position:relative;
    }
    .modal-close {
      position:absolute; top:10px; right:10px;
      background:transparent; border:none; font-size:1.5rem;
      cursor:pointer; color: var(--text-dark);
    }
    #formEtq label {
      display:block; margin-bottom:6px; font-weight:500;
    }
    #formEtq input[type="text"] {
      width:100%; padding:10px; margin-bottom:20px;
      border:1px solid var(--border-light); border-radius:6px;
      font-size:1rem; color: var(--text-dark);
    }
    #formEtq button[type="submit"] {
      background: var(--accent); color: var(--light);
      border:none; padding:10px 20px; border-radius:6px;
      font-size:1rem; display:inline-flex; align-items:center; gap:6px;
      cursor:pointer; transition:opacity .3s;
    }
    #formEtq button[type="submit"]:hover { opacity:.8; }
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
      <h2>Gestión de Etiquetas</h2>
      <section class="toolbar">
        <button id="btnAdd"><i class="fas fa-plus"></i> Añadir etiqueta</button>
      </section>
      <section>
        <table class="etq-table" id="tablaEtq">
          <thead>
            <tr><th>Numero</th><th>Nombre</th></tr>
          </thead>
          <tbody>
            <%
              int seq = fromIndex + 1;
              if (pageList.isEmpty()) {
            %>
            <tr>
              <td colspan="2" style="text-align:center; color:#666;">No hay etiquetas para mostrar.</td>
            </tr>
            <%
              } else {
                  for (Etiqueta e : pageList) {
            %>
            <tr data-id="<%=e.getId()%>" onclick="seleccionar(this)">
              <td><%= seq++ %></td>
              <td><%= e.getNombre() %></td>
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
        <button id="btnEdit"><i class="fas fa-edit"></i> Modificar</button>
        <button id="btnDelete"><i class="fas fa-trash-alt"></i> Eliminar</button>
      </section>
    </div>
  </div>

  <div class="modal-overlay" id="modal">
    <div class="modal-content">
      <button class="modal-close" id="btnClose">&times;</button>
      <form id="formEtq" method="post">
        <input type="hidden" name="id" id="etqId">
        <label for="etqNombre">Nombre etiqueta</label>
        <input type="text" name="nombre" id="etqNombre" required>
        <button type="submit" id="submitBtn"><i class="fas fa-save"></i> Guardar</button>
      </form>
    </div>
  </div>

  <script>
    let selectedRow = null;
    function seleccionar(r) {
      document.querySelectorAll('tr.selected').forEach(x => x.classList.remove('selected'));
      r.classList.add('selected');
      selectedRow = r;
    }
    const modal = document.getElementById('modal'),
          form = document.getElementById('formEtq'),
          nombreInput = document.getElementById('etqNombre'),
          idInput = document.getElementById('etqId'),
          submitBtn = document.getElementById('submitBtn'),
          btnAdd = document.getElementById('btnAdd'),
          btnEdit = document.getElementById('btnEdit'),
          btnDelete = document.getElementById('btnDelete'),
          btnClose = document.getElementById('btnClose');

    btnAdd.onclick = () => {
      selectedRow = null;
      document.querySelectorAll('tr.selected').forEach(x => x.classList.remove('selected'));
      idInput.value = '';
      nombreInput.value = '';
      submitBtn.innerHTML = '<i class="fas fa-plus"></i> Añadir';
      form.action = 'adicionarEtiqueta.jsp';
      modal.style.display = 'flex';
    };

    btnEdit.onclick = () => {
      if (!selectedRow) return alert('Selecciona una etiqueta');
      idInput.value = selectedRow.dataset.id;
      nombreInput.value = selectedRow.cells[1].textContent.trim();
      submitBtn.innerHTML = '<i class="fas fa-edit"></i> Modificar';
      form.action = 'modificarEtiqueta.jsp';
      modal.style.display = 'flex';
    };

    btnDelete.onclick = () => {
      if (!selectedRow) return alert('Selecciona una etiqueta');
      if (confirm('¿Eliminar etiqueta "' + selectedRow.cells[1].textContent + '"?')) {
        window.location = 'eliminarEtiqueta.jsp?id=' + selectedRow.dataset.id + '&page=<%=currentPage%>';
      }
    };

    btnClose.onclick = () => modal.style.display = 'none';
    window.onclick = e => { if (e.target === modal) modal.style.display = 'none'; };
  </script>
</body>
</html>
