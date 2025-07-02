<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Optional,
    java.util.Map,
    java.util.HashMap,
    java.sql.SQLException,
    clasesGenericas.Area
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

    List<Area> allAreas;
    try {
        allAreas = Area.findAll();
    } catch (SQLException ex) {
        throw new RuntimeException("Error cargando áreas", ex);
    }
    int totalRows = allAreas.size();
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
    List<Area> pageList = allAreas.subList(fromIndex, toIndex);

    Map<Integer, Boolean> usedMap = new HashMap<>();
    for (Area a : pageList) {
        boolean usado = Area.isUsed(a.getId());
        usedMap.put(a.getId(), usado);
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Áreas</title>
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
      --disabled-bg: #ddd;
      --disabled-text: #888;
    }
    html, body {
      margin:0; padding:0; height:100%; overflow-y:auto;
      background: var(--bg) url('<%=cp%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size:cover; color:var(--text); font-family:'Poppins',sans-serif;
    }
    * { box-sizing:border-box; }
    .menu-container {
      max-width:960px; margin:20px auto; padding:0 16px;
    }
    .menu-box {
      background:var(--light); padding:24px; border-radius:8px;
      box-shadow:0 6px 20px var(--shadow); color:#000;
    }
    h2 {
      font-size:1.8rem; margin-bottom:20px; color:var(--text-header);
    }
    .toolbar {
      margin-bottom:16px;
    }
    .toolbar button {
      background:var(--accent); color:var(--light);
      border:none; padding:10px 16px; border-radius:6px;
      font-size:.95rem; display:inline-flex; align-items:center; gap:6px;
      cursor:pointer; transition:opacity .3s;
    }
    .toolbar button:hover { opacity:.8; }
    .docs-table {
      width:100%; border-collapse:collapse; margin-bottom:20px;
      background:var(--light); border-radius:6px; overflow:hidden;
      box-shadow:0 1px 3px rgba(0,0,0,0.08);
    }
    .docs-table th, .docs-table td {
      padding:12px; text-align:left; font-size:.9rem;
      border-bottom:1px solid var(--border-light); color:var(--text-dark);
    }
    .docs-table th {
      background:var(--header-bg); text-transform:uppercase;
      font-weight:bold; color:var(--text-header); border-bottom:2px solid var(--border-light);
    }
    .docs-table tr:hover {
      background:var(--hover-light); transition:background .2s;
    }
    .docs-table tr:last-child td { border-bottom:none; }
    .actions {
      display:flex; justify-content:flex-end; gap:6px;
    }
    .actions button {
      background:var(--accent); color:var(--light);
      border:none; padding:8px 14px; border-radius:6px;
      font-size:.9rem; display:inline-flex; align-items:center; gap:6px;
      cursor:pointer; transition:opacity .2s;
    }
    .actions button:hover { opacity:.8; }
    .actions button.disabled {
      background: var(--disabled-bg) !important;
      color: var(--disabled-text) !important;
      cursor: default;
    }
    .modal-overlay {
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(0,0,0,0.5); display:none;
      align-items:center; justify-content:center; z-index:1000;
    }
    .modal-content {
      background:var(--light); color:#000; padding:24px;
      border-radius:8px; width:90%; max-width:760px;
      box-shadow:0 6px 20px var(--shadow); position:relative;
    }
    .modal-close {
      position:absolute; top:10px; right:10px;
      background:transparent; border:none; font-size:1.5rem;
      cursor:pointer; color:#000;
    }
    .modal-iframe {
      width:100%; height:580px; border:none; border-radius:0 0 6px 6px;
    }
    .pagination {
      display:flex; justify-content:center; align-items:center;
      gap:8px; margin-top:20px; list-style:none; padding:0; flex-wrap:wrap;
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
      <h2>Gestión de Áreas</h2>
      <div class="toolbar">
        <button id="btnAdd"><i class="fas fa-plus"></i> Añadir Área</button>
      </div>
      <table class="docs-table">
        <thead>
          <tr><th>Numero</th><th>Nombre</th><th>Acciones</th></tr>
        </thead>
        <tbody>
          <%
            int seq = fromIndex + 1;
            if (pageList.isEmpty()) {
          %>
          <tr>
            <td colspan="3" style="text-align:center; color:#666;">No hay áreas para mostrar.</td>
          </tr>
          <%
            } else {
                for (Area a : pageList) {
                  boolean usado = usedMap.get(a.getId());
          %>
          <tr>
            <td><%= seq++ %></td>
            <td><%= a.getNombre() %></td>
            <td class="actions">
              <button class="btnEdit" data-id="<%=a.getId()%>">
                <i class="fas fa-edit"></i> Modificar
              </button>
              <% if (!usado) { %>
                <button onclick="if(confirm('¿Eliminar área «<%=a.getNombre()%>»?')) 
                                  location='<%=cp%>/eliminarArea.jsp?id=<%=a.getId()%>&page=<%=currentPage%>'">
                  <i class="fas fa-trash"></i> Eliminar
                </button>
              <% } else { %>
                <button class="disabled" disabled title="No se puede eliminar: área en uso">
                  <i class="fas fa-trash"></i> Eliminar
                </button>
              <% } %>
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
    </div>
  </div>

  <div class="modal-overlay" id="modal">
    <div class="modal-content">
      <button class="modal-close" id="btnClose">&times;</button>
      <iframe class="modal-iframe" id="iframe" src="about:blank"></iframe>
    </div>
  </div>
  <script>
    const cp = '<%=cp%>',
          modal = document.getElementById('modal'),
          iframe = document.getElementById('iframe'),
          btnAdd = document.getElementById('btnAdd'),
          btnClose = document.getElementById('btnClose');

    btnAdd.onclick = ()=>{
      iframe.src = cp + '/adicionarArea.jsp';
      modal.style.display = 'flex';
    };
    document.querySelectorAll('.btnEdit').forEach(btn=>{
      btn.onclick = ()=>{
        iframe.src = cp + '/modificarArea.jsp?id=' + btn.dataset.id + '&page=<%=currentPage%>';
        modal.style.display = 'flex';
      };
    });
    btnClose.onclick = ()=>{
      modal.style.display='none';
      iframe.src='about:blank';
      location.href = '?page=<%=currentPage%>';
    };
    window.onclick = e=>{
      if(e.target===modal) btnClose.onclick();
    };
  </script>
</body>
</html>
