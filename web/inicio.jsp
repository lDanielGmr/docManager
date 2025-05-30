<%@ page import="
    java.sql.*,
    java.util.*,
    clasesGenericas.Documento,
    clasesGenericas.Metadata,
    clasesGenericas.Usuario,
    clasesGenericas.Menu
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>

<%
    final int pageSize = 5;
    String pageParam = request.getParameter("page");
    int currentPage = 1;
    try {
        if (pageParam != null) currentPage = Math.max(1, Integer.parseInt(pageParam));
    } catch (NumberFormatException e) { currentPage = 1; }

    int totalDocs = 0, totalToRespond = 0, totalPages = 1, offset = 0;
    List<Documento> documentosResp = Collections.emptyList();
    List<Map<String,String>> atajos     = Collections.emptyList();
    List<Map<String,Object>> etiquetas  = Collections.emptyList();

    try {
        totalDocs      = Documento.countAll();
        totalToRespond = Documento.countRequireResponse();
        totalPages     = (int)Math.ceil((double)totalToRespond / pageSize);
        if (totalPages < 1) totalPages = 1;
        currentPage    = Math.min(currentPage, totalPages);
        offset         = (currentPage - 1) * pageSize;

        documentosResp = Documento.findRequireResponse(offset, pageSize);

        Collections.sort(documentosResp, new Comparator<Documento>() {
            @Override
            public int compare(Documento d1, Documento d2) {
                return d2.getFechaCreacion().compareTo(d1.getFechaCreacion());
            }
        });

        atajos    = Menu.findTopShortcuts();
        etiquetas = Metadata.findCommonTags();
    } catch (Exception e) {
        e.printStackTrace();
    }

    int windowSize = 5;
    int startPage = Math.max(1, currentPage - windowSize/2);
    int endPage   = startPage + windowSize - 1;
    if (endPage > totalPages) {
        endPage   = totalPages;
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    Usuario usuario = (Usuario) session.getAttribute("user");
    String nombreUsuarioLogueado = usuario != null ? usuario.getNombre() : "Usuario";
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Página de Inicio</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <style>
  :root {
    --bg: #1f1f2e;
    --accent: #9d7aed;
    --text: #e0e0e0;
    --light: #fff;
    --shadow: rgba(0, 0, 0, 0.4);
  }
  html, body {
    margin: 0;
    padding: 0;
    height: 100%;
    overflow-y: auto;
  }
  * {
    box-sizing: border-box;
    font-family: 'Poppins', sans-serif;
  }

  .menu-container {
    width: 100%;
    max-width: 960px; 
    margin: 20px auto;
    padding: 0 10px;
  }

  .menu-box {
    background: #fff;
    padding: 16px; 
    border-radius: 4px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    line-height: 1.5;
  }

  h2 {
    font-size: 1.5rem; 
    margin-bottom: 14px;
    color: #333;
  }

  .toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-bottom: 14px;
  }

  .toolbar button,
  .toolbar input {
    font-size: 0.9rem;
    padding: 6px 10px; 
    border-radius: 4px;
  }

  .toolbar input {
    flex: 1;
    border: 1px solid #ccc;
  }

  .docs-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 16px;
  }

  .docs-table th,
  .docs-table td {
    padding: 10px 6px; 
    border: 1px solid #ddd;
    font-size: 0.85rem;
    word-break: break-word;
  }

  .docs-table th {
    background: #f5f5f5;
    text-transform: uppercase;
  }

  .docs-table tr:hover {
    background: #fafafa;
    cursor: pointer;
  }

  .actions {
    display: flex;
    justify-content: flex-end;
    gap: 6px;
    flex-wrap: wrap;
  }

  .actions button {
    font-size: 0.85rem;
    padding: 6px 12px;
    border-radius: 4px;
  }

  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal-content {
    background: #fff;
    width: 90%;
    max-width: 760px; 
    height: auto;
    border-radius: 6px;
    position: relative;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }

  .modal-close {
    position: absolute;
    top: 10px;
    right: 10px;
    background: transparent;
    border: none;
    font-size: 1.4rem;
    cursor: pointer;
  }

  .modal-iframe {
    width: 100%;
    height: 580px;
    border: none;
    border-radius: 0 0 6px 6px;
  }

  tr.select    background: #e6f7ff !important;
  }
  html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  overflow-y: auto;
  background: var(--bg);
  color: var(--text); 
}

* {
  box-sizing: border-box;
  font-family: 'Poppins', sans-serif;
  color: inherit; 
}

.menu-box {
  background: #fff;
  color: #000;
}

.shortcut-tags {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.shortcut-tags .card {
  flex: 1 1 45%; 
  background: #fdfdfd;
  border: 1px solid #ddd;
  border-radius: 6px;
  padding: 16px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.05);
}

.shortcut-tags .card h2 {
  font-size: 1.2rem;
  margin-bottom: 10px;
  color: #444;
}

.shortcut-tags ul {
  list-style: none;
  padding-left: 0;
  margin: 0;
}

.shortcut-tags li {
  margin-bottom: 8px;
  font-size: 0.95rem;
  color: #222;
  display: flex;
  align-items: center;	
}

.shortcut-tags li i {
  margin-right: 6px;
  color: var(--accent);
}

    .pagination {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 8px;
      margin-top: 20px;
      flex-wrap: wrap;
    }
    .pagination button {
      background-color: var(--accent);
      color: #fff;
      border: none;
      padding: 10px 16px;
      font-size: 1rem;
      border-radius: 4px;
      cursor: pointer;
      transition: background 0.3s ease;
      min-width: 44px;
    }
    .pagination button:hover:not([disabled]) { background-color: #7f5af0; }
    .pagination button[disabled] { background-color: #ccc; color: #666; cursor: default; }
    .pagination button.current {
      background-color: #4e32a8;
      font-weight: bold;
      border: 2px solid #fff;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">

      <div class="header">
        <img src="${pageContext.request.contextPath}/images/mini-logo.png" alt="Logo" class="logo">
        <span class="header-text">Terminal de Pasto</span>
      </div>

      <h1>¡Bienvenido, <%= nombreUsuarioLogueado %>!</h1>
      <div class="stats"><strong>Total documentos:</strong> <%= totalDocs %></div>

      <div class="shortcut-tags">
        <div class="card">
          <h2>Atajos más usados</h2>
          <ul>
            <% if (atajos.isEmpty()) { %>
              <li>No hay atajos aún.</li>
            <% } else {
                 for (Map<String,String> at : atajos) {
                   String url   = at.get("url");
                   String label = at.get("label");
            %>
                <li><i class="fas fa-link"></i> <a href="<%=url%>"><%=label%></a></li>
            <% } } %>
          </ul>
        </div>
        <div class="card">
          <h2>Etiquetas más comunes</h2>
          <ul>
            <% if (etiquetas.isEmpty()) { %>
              <li>Sin etiquetas aún.</li>
            <% } else {
                 for (Map<String,Object> tagInfo : etiquetas) {
                   String tag = tagInfo.get("nombre").toString();
                   int cnt    = ((Number)tagInfo.get("cnt")).intValue();
            %>
                <li><i class="fas fa-tag"></i> <%=tag%> <span>(<%=cnt%>)</span></li>
            <% } } %>
          </ul>
        </div>
      </div>

      <section class="to-respond">
        <h2>Documentos que requieren respuesta</h2>
        <table class="docs-table">
          <thead>
            <tr>
              <th>#</th><th>Título</th><th>Tipo</th><th>Área</th><th>Fecha creación</th><th>Acción</th>
            </tr>
          </thead>
          <tbody>
            <% if (documentosResp.isEmpty()) { %>
              <tr><td colspan="6">No hay documentos pendientes.</td></tr>
            <% } else {
                 int numero = offset + 1;
                 for (Documento d : documentosResp) {
            %>
              <tr>
                <td><%= numero++ %></td>
                <td><%= d.getTitulo() %></td>
                <td><%= d.getTipo() %></td>
                <td><%= d.getAreaNombre() %></td>
                <td><%= d.getFechaCreacion().toLocalDateTime().toLocalDate() %></td>
                <td>
                  <a href="responderDocumento.jsp?id=<%=d.getId()%>">
                    <i class="fas fa-reply"></i> Responder
                  </a>
                </td>
              </tr>
            <% } } %>
          </tbody>
        </table>

        <div class="pagination">
          <button onclick="location.href='inicio.jsp?page=1'"
                  <%= currentPage==1?"disabled":"" %>>
            <i class="fas fa-angle-double-left"></i>
          </button>
          <button onclick="location.href='inicio.jsp?page=<%=currentPage-1%>'"
                  <%= currentPage==1?"disabled":"" %>>
            <i class="fas fa-chevron-left"></i>
          </button>
          <% for (int p = startPage; p <= endPage; p++) {
               boolean isCur = (p==currentPage);
          %>
            <button class="<%= isCur?"current":"" %>"
                    onclick="location.href='inicio.jsp?page=<%=p%>'"
                    <%= isCur?"disabled":"" %>>
              <%= p %>
            </button>
          <% } %>
          <button onclick="location.href='inicio.jsp?page=<%=currentPage+1%>'"
                  <%= currentPage==totalPages?"disabled":"" %>>
            <i class="fas fa-chevron-right"></i>
          </button>
          <button onclick="location.href='inicio.jsp?page=<%=totalPages%>'"
                  <%= currentPage==totalPages?"disabled":"" %>>
            <i class="fas fa-angle-double-right"></i>
          </button>
        </div>
      </section>
    </div>
  </div>
</body>
</html>
