<%@page import="java.io.StringWriter"%>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.net.URLEncoder,
    java.io.PrintWriter,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.io.StringWriter,
    java.util.HashSet,
    java.util.HashMap,
    java.util.Set,
    clasesGenericas.Usuario,
    clasesGenericas.Menu,
    clasesGenericas.RolPermiso,
    clasesGenericas.Permiso,
    ConexionBD.conexionBD
" %>
<%@ include file="menu.jsp" %>
<%
    String errorMsg = null;
    String infoMsg = null;

    Object ua = session.getAttribute("user");
    Usuario usuario = ua instanceof Usuario
                      ? (Usuario) ua
                      : ua instanceof String
                        ? Usuario.findByUsuario((String) ua)
                        : null;
    if (usuario == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String fullPath = request.getServletPath();
    String pageName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
    Menu.recordUse(usuario.getId(), pageName);

    Set<Integer> permisoIds = new HashSet<>();
    Map<String,Integer> permisosMap = new HashMap<>();
    for (RolPermiso rp : RolPermiso.findByRolId(usuario.getRol().getId())) {
        permisoIds.add(rp.getPermisoId());
    }
    for (Permiso p : Permiso.findAll()) {
        permisosMap.put(p.getNombre(), p.getId());
    }
    boolean puedeVerPlantillas    = permisoIds.contains(permisosMap.get("ver_plantillas"));
    boolean puedeBuscarPlantillas = permisoIds.contains(permisosMap.get("ver_busquedas"));
    boolean puedeSubirPlantilla   = permisoIds.contains(permisosMap.get("crear_documento"));
    boolean puedeEditarPlantilla  = permisoIds.contains(permisosMap.get("subir_version"));
    boolean puedeEliminarPlantilla= permisoIds.contains(permisosMap.get("eliminar_documento"));

    final int PAGE_SIZE = 8;
    int currentPage = 1;
    String sp = request.getParameter("page");
    if (sp != null) {
        try { currentPage = Integer.parseInt(sp); }
        catch (NumberFormatException ignore) {}
    }
    if (currentPage < 1) currentPage = 1;

    String termParam = request.getParameter("term");
    if (termParam == null) termParam = "";
    termParam = termParam.trim();
    String likeTerm = "%" + termParam + "%";

    if (request.getParameter("errorMsg") != null) {
        errorMsg = request.getParameter("errorMsg");
    }
    if (request.getParameter("infoMsg") != null) {
        infoMsg = request.getParameter("infoMsg");
    }

    String deleteIdParam = request.getParameter("deleteId");
    if (deleteIdParam != null && puedeEliminarPlantilla) {
        int plantillaId = -1;
        try {
            plantillaId = Integer.parseInt(deleteIdParam);
        } catch (NumberFormatException e) {
            plantillaId = -1;
        }
        if (plantillaId > 0) {
            try (Connection conn = conexionBD.conectar()) {
                conn.setAutoCommit(false);
                boolean ok = true;
                try (PreparedStatement pstUpd = conn.prepareStatement(
                        "UPDATE documento SET eliminado = 1 WHERE id = ? AND es_plantilla = TRUE"
                    )) {
                    pstUpd.setInt(1, plantillaId);
                    int updated = pstUpd.executeUpdate();
                    if (updated == 0) {
                        ok = false;
                    }
                } catch (SQLException e) {
                    ok = false;
                    StringWriter sw = new StringWriter();
                    e.printStackTrace(new PrintWriter(sw));
                    System.err.println("Error al marcar eliminado plantilla: " + sw.toString());
                }
                if (ok) {
                    try (PreparedStatement pstAudit = conn.prepareStatement(
                            "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)"
                        )) {
                        pstAudit.setInt(1, usuario.getId());
                        pstAudit.setInt(2, plantillaId);
                        pstAudit.setString(3, "ELIMINAR_PLANTILLA");
                        pstAudit.executeUpdate();
                    } catch (SQLException e) {
                        ok = false;
                        StringWriter sw = new StringWriter();
                        e.printStackTrace(new PrintWriter(sw));
                        System.err.println("Error al insertar en audit_log (plantilla): " + sw.toString());
                    }
                }
                if (ok) {
                    conn.commit();
                    infoMsg = "Plantilla eliminada correctamente.";
                } else {
                    conn.rollback();
                    errorMsg = "No se pudo eliminar la plantilla.";
                }
            } catch (SQLException e) {
                StringWriter sw = new StringWriter();
                e.printStackTrace(new PrintWriter(sw));
                System.err.println("Error en transacción eliminación plantilla: " + sw.toString());
                errorMsg = "Error al eliminar la plantilla.";
            }
        } else {
            errorMsg = "ID de plantilla inválido.";
        }
        String redirectURL = request.getRequestURI() + "?page=" + currentPage;
        if (!termParam.isEmpty()) {
            redirectURL += "&term=" + URLEncoder.encode(termParam, "UTF-8");
        }
        if (infoMsg != null) {
            redirectURL += "&infoMsg=" + URLEncoder.encode(infoMsg, "UTF-8");
        }
        if (errorMsg != null) {
            redirectURL += "&errorMsg=" + URLEncoder.encode(errorMsg, "UTF-8");
        }
        response.sendRedirect(redirectURL);
        return;
    }

    int totalRows = 0;
    StringBuilder countSb = new StringBuilder();
    countSb.append("SELECT COUNT(*) FROM documento WHERE es_plantilla = TRUE AND eliminado = 0");
    if (!termParam.isEmpty()) {
        countSb.append(" AND titulo LIKE ?");
    }
    String countSQL = countSb.toString();
    try (Connection conn = conexionBD.conectar();
         PreparedStatement psCount = conn.prepareStatement(countSQL)) {
        if (!termParam.isEmpty()) {
            psCount.setString(1, likeTerm);
        }
        try (ResultSet rsCount = psCount.executeQuery()) {
            if (rsCount.next()) {
                totalRows = rsCount.getInt(1);
            }
        }
    } catch (Exception e) {
        totalRows = 0;
    }
    int totalPages = Math.max(1, (int) Math.ceil((double) totalRows / PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;

    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize/2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    StringBuilder sb = new StringBuilder();
    sb.append("SELECT d.id, d.titulo, d.tipo, a.nombre AS area, ");
    sb.append("u.nombre AS usuario_nombre, d.fecha_creacion ");
    sb.append("FROM documento d ");
    sb.append("LEFT JOIN area a ON d.id_area = a.id ");
    sb.append("LEFT JOIN usuario u ON d.recibido_por = u.id ");
    sb.append("WHERE d.es_plantilla = TRUE AND d.eliminado = 0");
    if (!termParam.isEmpty()) {
        sb.append(" AND d.titulo LIKE ?");
    }
    sb.append(" ORDER BY d.fecha_creacion DESC ");
    sb.append("LIMIT ?, ?");
    String sql = sb.toString();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Plantillas</title>
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;
      --text: #eaeaea;
      --light: #fff;
      --shadow: rgba(0, 0, 0, 0.5);
    }
    html, body {
      margin: 0; padding: 0; height: 100%; overflow-y: auto;
      background: var(--bg); color: var(--text);
      background: url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
    }
    * {
      box-sizing: border-box;
      font-family: 'Poppins', sans-serif;
      color: inherit;
    }
    .menu-container {
      max-width: 960px; margin: 20px auto; padding: 0 10px;
    }
    .menu-box {
      background: #fff; color: #000;
      padding: 16px; border-radius: 4px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    h2 {
      font-size: 1.5rem; margin-bottom: 14px; color: #333;
    }
    .toolbar {
      display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 14px; position: relative;
    }
    .toolbar input[type="text"] {
      flex: 1; border: 1px solid #ccc;
      font-size: 0.9rem; padding: 6px 10px; border-radius: 4px;
    }
    .toolbar button {
      font-size: 0.9rem; padding: 6px 10px; border-radius: 4px;
      background: var(--accent); color: #fff; border: none; cursor: pointer;
    }
    .toolbar button:hover { opacity: 0.9; }

    .suggestions {
      position: absolute; top: 40px; left: 0; right: 100px;
      background: #fff; border: 1px solid #ccc; border-top: none;
      max-height: 200px; overflow-y: auto; z-index: 100;
    }
    .suggestion-item {
      padding: 8px 10px; cursor: pointer; font-size: 0.9rem; color: #333;
    }
    .suggestion-item:hover {
      background: #f0f0f0;
    }

    .docs-table {
      width: 100%; border-collapse: collapse; margin-bottom: 16px;
    }
    .docs-table th, .docs-table td {
      padding: 10px 6px; border: 1px solid #ddd;
      font-size: 0.85rem; word-break: break-word;
    }
    .docs-table th {
      background: #f5f5f5; text-transform: uppercase;
    }
    .docs-table tr:hover {
      background: #efefef; cursor: pointer;
    }
    .selected { background: #e6f7ff !important; }

    .actions {
      display: flex; justify-content: flex-end; gap: 6px; flex-wrap: wrap;
    }
    .actions button {
      font-size: 0.85rem; padding: 6px 12px; border-radius: 4px;
      background: var(--accent); color: #fff; border: none; cursor: pointer;
    }
    .actions button:hover { opacity: 0.9; }

    .modal-overlay {
      position: fixed; top: 0; left: 0; width: 100%; height: 100%;
      background: rgba(0,0,0,0.5); display: none;
      align-items: center; justify-content: center; z-index: 1000;
    }
    .modal-content {
      background: #fff; width: 90%; max-width: 760px; border-radius: 6px;
      position: relative; box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    }
    .modal-close {
      position: absolute; top: 10px; right: 10px;
      background: var(--accent); color: var(--light);
      border: none; padding: 8px; border-radius: 50%;
      font-size: 1.4rem; cursor: pointer;
    }
    .modal-close:hover {
      background: #0056b3;
    }
    .modal-iframe {
      width: 100%; height: 580px; border: none; border-radius: 0 0 6px 6px;
    }

    .pagination {
      display: flex; justify-content: center; align-items: center;
      gap: 8px; margin-top: 20px; list-style: none; padding: 0; flex-wrap: wrap;
    }
    .pagination li a {
      display: inline-block; background: var(--accent); color: #fff;
      text-decoration: none; padding: 10px 16px; font-size: 1rem;
      border-radius: 4px; min-width: 44px; text-align: center;
      transition: background 0.3s ease;
    }
    .pagination li a:hover:not(.disabled) { background: #7f5af0; }
    .pagination li.disabled a {
      background: #ccc; color: #666; pointer-events: none; cursor: default;
    }
    .pagination li.active a {
      background: #4e32a8; font-weight: bold; border: 2px solid #fff;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Plantillas</h2>

      <% if (errorMsg != null) { %>
      <div style="background:#f8d7da;color:#842029;padding:10px;border:1px solid #f5c2c7;border-radius:4px;margin-bottom:16px;">
        <strong>Error:</strong> <%= errorMsg %>
      </div>
      <% } %>
      <% if (infoMsg != null) { %>
      <div style="background:#d1e7dd;color:#0f5132;padding:10px;border:1px solid #badbcc;border-radius:4px;margin-bottom:16px;">
        <strong>Info:</strong> <%= infoMsg %>
      </div>
      <% } %>

      <section class="toolbar">
        <% if (puedeSubirPlantilla) { %>
          <button id="btnOpenModal"><i class="fas fa-upload"></i> Subir plantilla</button>
        <% } %>
        <% if (puedeBuscarPlantillas) { %>
          <input id="filtroTitulo"
                 type="text"
                 placeholder="Buscar por título…"
                 autocomplete="off"
                 value="<%= termParam %>">
          <div id="suggestions" class="suggestions" style="display:none;"></div>
          <button id="btnBuscar"><i class="fas fa-search"></i> Buscar</button>
          <button id="btnLimpiar"><i class="fas fa-eraser"></i> Limpiar</button>
        <% } %>
      </section>

      <section>
        <table id="tablaDocs" class="docs-table">
          <thead>
            <tr>
              <th>Numero</th>
              <th>Título</th>
              <th>Tipo</th>
              <th>Área</th>
              <th>Subido por</th>
              <th>Fecha</th>
              <th>Respuesta</th>
            </tr>
          </thead>
          <tbody>
            <%
              int idx = (currentPage - 1) * PAGE_SIZE + 1;
              try (Connection conn = conexionBD.conectar();
                   PreparedStatement ps = conn.prepareStatement(sql)) {

                  int paramIndex = 1;
                  if (!termParam.isEmpty()) {
                      ps.setString(paramIndex++, likeTerm);
                  }
                  ps.setInt(paramIndex++, (currentPage - 1) * PAGE_SIZE);
                  ps.setInt(paramIndex++, PAGE_SIZE);

                  try (ResultSet rs = ps.executeQuery()) {
                      while (rs.next()) {
            %>
            <tr data-id="<%= rs.getInt("id") %>" onclick="seleccionarFila(this)">
              <td><%= idx++ %></td>
              <td><%= rs.getString("titulo") %></td>
              <td><%= rs.getString("tipo") %></td>
              <td><%= rs.getString("area") != null ? rs.getString("area") : "-" %></td>
              <td><%= rs.getString("usuario_nombre") != null ? rs.getString("usuario_nombre") : "Desconocido" %></td>
              <td><%= rs.getTimestamp("fecha_creacion").toLocalDateTime().toLocalDate() %></td>
              <td>N/A</td>
            </tr>
            <%
                      }
                  }
              } catch (Exception e) {
            %>
            <tr>
              <td colspan="7" style="color:red;"><pre><%= new StringWriter() {{
                  e.printStackTrace(new PrintWriter(this));
              }}.toString() %></pre></td>
            </tr>
            <%
              }
            %>
          </tbody>
        </table>
      </section>

      <ul class="pagination">
        <li class="<%= currentPage == 1 ? "disabled" : "" %>">
          <a href="?page=1<%= termParam.isEmpty() ? "" : "&term=" + URLEncoder.encode(termParam, "UTF-8") %>">&laquo;</a>
        </li>
        <li class="<%= currentPage == 1 ? "disabled" : "" %>">
          <a href="?page=<%= currentPage - 1 %><%= termParam.isEmpty() ? "" : "&term=" + URLEncoder.encode(termParam, "UTF-8") %>">&lt;</a>
        </li>
        <% for (int p = startPage; p <= endPage; p++) { %>
          <li class="<%= p == currentPage ? "active" : "" %>">
            <a href="?page=<%= p %><%= termParam.isEmpty() ? "" : "&term=" + URLEncoder.encode(termParam, "UTF-8") %>"><%= p %></a>
          </li>
        <% } %>
        <li class="<%= currentPage == totalPages ? "disabled" : "" %>">
          <a href="?page=<%= currentPage + 1 %><%= termParam.isEmpty() ? "" : "&term=" + URLEncoder.encode(termParam, "UTF-8") %>">&gt;</a>
        </li>
        <li class="<%= currentPage == totalPages ? "disabled" : "" %>">
          <a href="?page=<%= totalPages %><%= termParam.isEmpty() ? "" : "&term=" + URLEncoder.encode(termParam, "UTF-8") %>">&raquo;</a>
        </li>
      </ul>

      <section class="actions">
        <button onclick="vistaPreviaSeleccionado()"><i class="fas fa-eye"></i> Vista previa</button>
        <% if (puedeEditarPlantilla) { %>
          <button onclick="editarSeleccionado()"><i class="fas fa-edit"></i> Editar</button>
        <% } %>
        <% if (puedeEliminarPlantilla) { %>
          <button onclick="eliminarSeleccionado()"><i class="fas fa-trash"></i> Eliminar</button>
        <% } %>
        <button onclick="descargarSeleccionado()"><i class="fas fa-download"></i> Descargar</button>
      </section>
    </div>
  </div>

  <div id="modal" class="modal-overlay">
    <div class="modal-content">
      <button id="btnCloseModal" class="modal-close"><i class="fas fa-times"></i></button>
      <iframe id="modalIframe" class="modal-iframe" src="about:blank"></iframe>
    </div>
  </div>

  <form id="deleteForm" method="get" action="documentoPlantilla.jsp" style="display:none;">
    <input type="hidden" name="deleteId" id="deleteIdInput" value=""/>
    <input type="hidden" name="page" value="<%= currentPage %>"/>
    <% if (!termParam.isEmpty()) { %>
      <input type="hidden" name="term" value="<%= termParam %>"/>
    <% } %>
  </form>

  <script>
    const ctx          = '<%= request.getContextPath() %>';
    const modal        = document.getElementById('modal'),
          iframe       = document.getElementById('modalIframe'),
          filtroTitulo = document.getElementById('filtroTitulo'),
          suggestions  = document.getElementById('suggestions'),
          btnBuscar    = document.getElementById('btnBuscar'),
          btnLimpiar   = document.getElementById('btnLimpiar'),
          openBtn      = document.getElementById('btnOpenModal'),
          closeBtn     = document.getElementById('btnCloseModal');

    if (openBtn) {
      openBtn.onclick = () => {
            iframe.src = ctx + '/adicionarDocumento.jsp?origin=plantilla';
        modal.style.display = 'flex';
      };
    }
    if (closeBtn) {
      closeBtn.onclick = () => {
        modal.style.display = 'none';
        iframe.src = 'about:blank';
        window.location.reload();
      };
    }
    window.onclick = e => {
      if (e.target === modal) {
        closeBtn.onclick();
      }
    };

    if (filtroTitulo) {
      filtroTitulo.addEventListener('input', function() {
        const term = this.value.trim();
        if (term.length < 2) {
          suggestions.style.display = 'none';
          return;
        }
        fetch(ctx + '/buscarTitulos.jsp?term=' + encodeURIComponent(term) + '&scope=plantilla')
          .then(res => res.json())
          .then(json => {
            suggestions.innerHTML = '';
            if (json.length === 0) {
              suggestions.style.display = 'none';
              return;
            }
            json.forEach(itemObj => {
              const divItem = document.createElement('div');
              divItem.className = 'suggestion-item';
              let texto = itemObj.titulo;
              if (itemObj.tipo && itemObj.tipo.trim().length > 0) {
                texto += " (" + itemObj.tipo + ")";
              }
              texto += " (plantilla)";
              divItem.textContent = texto;
              divItem.addEventListener('mousedown', function() {
                filtroTitulo.value = itemObj.titulo;
                suggestions.style.display = 'none';
              });
              suggestions.appendChild(divItem);
            });
            suggestions.style.display = 'block';
          })
          .catch(err => {
            console.error('Error buscando títulos:', err);
            suggestions.style.display = 'none';
          });
      });
      filtroTitulo.addEventListener('blur', function() {
        setTimeout(() => suggestions.style.display = 'none', 100);
      });
      filtroTitulo.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          if (btnBuscar) btnBuscar.click();
        }
      });
    }

    if (btnBuscar) {
      btnBuscar.addEventListener('click', function() {
        const term = filtroTitulo.value.trim();
        if (term !== '') {
          window.location.href = ctx + '/documentoPlantilla.jsp?page=1&term=' + encodeURIComponent(term);
        } else {
          window.location.href = ctx + '/documentoPlantilla.jsp?page=1';
        }
      });
    }
    if (btnLimpiar) {
      btnLimpiar.addEventListener('click', function() {
        window.location.href = ctx + '/documentoPlantilla.jsp';
      });
    }

    function seleccionarFila(r) {
      document.querySelectorAll('#tablaDocs tbody tr.selected')
              .forEach(x => x.classList.remove('selected'));
      r.classList.add('selected');
    }
    function getSelectedId() {
      const sel = document.querySelector('#tablaDocs tbody tr.selected');
      return sel ? sel.dataset.id : null;
    }
    function vistaPreviaSeleccionado() {
      const id = getSelectedId();
      if (!id) return alert('Selecciona una plantilla.');
      iframe.src = ctx + '/vistaPreviaDocumento.jsp?id=' + id;
      modal.style.display = 'flex';
    }
    function editarSeleccionado() {
      const id = getSelectedId();
      if (!id) return alert('Selecciona una plantilla.');
      location.href = 'editarDocumento.jsp?id=' + id + '&plantilla=true';
    }
    function eliminarSeleccionado() {
      const id = getSelectedId();
      if (!id) return alert('Selecciona una plantilla.');
      if (confirm('¿Eliminar plantilla?')) {
        document.getElementById('deleteIdInput').value = id;
        document.getElementById('deleteForm').submit();
      }
    }
    function descargarSeleccionado() {
      const id = getSelectedId();
      if (!id) return alert('Selecciona una plantilla.');
      window.open(ctx + '/descargarDocumento.jsp?id=' + id, '_blank');
    }
  </script>
</body>
</html>