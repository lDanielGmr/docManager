<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.util.ArrayList,
    java.util.HashMap,
    java.util.HashSet,
    java.util.List,
    java.util.Map,
    java.util.Set,
    java.text.SimpleDateFormat,
    java.net.URLEncoder,
    ConexionBD.conexionBD,
    clasesGenericas.Usuario
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    int userRolId = usuarioSesion.getRol().getId();

    boolean puedeBuscar = false;
    String claveVer = "ver_busquedas";
    try (Connection connPerm = conexionBD.conectar();
         PreparedStatement pstPerm = connPerm.prepareStatement(
             "SELECT 1 FROM rol_permiso rp JOIN permiso p ON rp.permiso_id = p.id " +
             "WHERE rp.rol_id = ? AND p.nombre = ?"
         )) {
        pstPerm.setInt(1, userRolId);
        pstPerm.setString(2, claveVer);
        try (ResultSet rsPerm = pstPerm.executeQuery()) {
            if (rsPerm.next()) {
                puedeBuscar = true;
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    if (!puedeBuscar) {
        out.write("<h3 style='color:red;text-align:center;'>No tienes permiso para ver auditoría.</h3>");
        return;
    }

    String nombre     = request.getParameter("nombre");
    String usuarioId  = request.getParameter("usuario");
    String fechaDesde = request.getParameter("fechaDesde");
    String fechaHasta = request.getParameter("fechaHasta");
    int    pagina     = 1;
    try {
        String pParam = request.getParameter("pagina");
        if (pParam != null) {
            pagina = Integer.parseInt(pParam);
            if (pagina < 1) pagina = 1;
        }
    } catch (NumberFormatException ignored) { }

    List<Map<String,Object>> usuarios = new ArrayList<>();
    try (Connection con = conexionBD.conectar();
         PreparedStatement pst = con.prepareStatement("SELECT id, nombre FROM usuario ORDER BY nombre");
         ResultSet rs = pst.executeQuery()) {
        while (rs.next()) {
            Map<String,Object> u = new HashMap<>();
            u.put("id",     rs.getInt("id"));
            u.put("nombre", rs.getString("nombre"));
            usuarios.add(u);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    StringBuilder sqlBase = new StringBuilder(
        "FROM audit_log al " +
        "JOIN usuario u ON al.usuario_id = u.id " +
        "JOIN documento d ON al.documento_id = d.id " +
        "WHERE 1=1"
    );
    List<Object> params = new ArrayList<>();
    if (nombre != null && !nombre.trim().isEmpty()) {
        sqlBase.append(" AND d.titulo = ?");
        params.add(nombre.trim());
    }
    if (usuarioId != null && !"todos".equals(usuarioId)) {
        sqlBase.append(" AND u.id = ?");
        params.add(Integer.valueOf(usuarioId));
    }
    if (fechaDesde != null && !fechaDesde.isEmpty()) {
        sqlBase.append(" AND al.timestamp >= ?");
        params.add(fechaDesde + " 00:00:00");
    }
    if (fechaHasta != null && !fechaHasta.isEmpty()) {
        sqlBase.append(" AND al.timestamp <= ?");
        params.add(fechaHasta + " 23:59:59");
    }

    int limite = 10;
    int offset = (pagina - 1) * limite;
    int totalRegistros = 0;
    try (Connection con = conexionBD.conectar();
         PreparedStatement pstCount = con.prepareStatement("SELECT COUNT(*) " + sqlBase.toString())) {
        for (int i = 0; i < params.size(); i++) {
            pstCount.setObject(i + 1, params.get(i));
        }
        try (ResultSet rsCount = pstCount.executeQuery()) {
            if (rsCount.next()) {
                totalRegistros = rsCount.getInt(1);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    int totalPaginas = (int) Math.ceil(totalRegistros / (double) limite);
    if (pagina > totalPaginas) pagina = totalPaginas > 0 ? totalPaginas : 1;

    List<Map<String,String>> logs = new ArrayList<>();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss a");
    String fetchSQL =
        "SELECT u.nombre AS usuario, d.titulo AS documento, al.accion, al.timestamp " +
        sqlBase.toString() + " ORDER BY al.timestamp DESC LIMIT ? OFFSET ?";
    try (Connection con = conexionBD.conectar();
         PreparedStatement pstLogs = con.prepareStatement(fetchSQL)) {
        int idx = 1;
        for (Object p : params) {
            pstLogs.setObject(idx++, p);
        }
        pstLogs.setInt(idx++, limite);
        pstLogs.setInt(idx   , offset);
        try (ResultSet rsLogs = pstLogs.executeQuery()) {
            while (rsLogs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("usuario",   rsLogs.getString("usuario"));
                r.put("documento", rsLogs.getString("documento"));
                r.put("accion",    rsLogs.getString("accion"));
                java.sql.Timestamp ts = rsLogs.getTimestamp("timestamp");
                r.put("fechaHora", ts != null ? sdf.format(ts) : "");
                logs.add(r);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    int windowSize = 3;
    int startPage = Math.max(1, pagina - windowSize/2);
    int endPage   = Math.min(totalPaginas, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Auditoría</title>

  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;
      --text: #e0e0e0;
      --input-bg: #f8f9fa;
      --hover-row: #f0f0f0;
    }
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      overflow-y: auto;
      background: url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
    }
    * {
      box-sizing: border-box;
      font-family: 'Poppins', sans-serif;
      color: inherit;
    }
    .menu-container {
      width: 100%;
      max-width: 960px;
      margin: 20px auto;
      padding: 0 10px;
    }
    .menu-box {
      background: #fff;
      padding: 24px;
      border-radius: 8px;
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
      color: #000;
    }
    h2 {
      font-size: 1.5rem;
      margin-bottom: 14px;
      color: #333;
    }
    .toolbar-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 16px;
      position: relative;
    }
    .toolbar-row input,
    .toolbar-row select {
      padding: 8px;
      border: 1px solid #ccc;
      border-radius: 4px;
      background: var(--input-bg);
      flex: 1;
      min-width: 160px;
      font-size: 0.9rem;
      position: relative;
      z-index: 1;
    }
    .toolbar-row button {
      padding: 6px 14px;
      border: none;
      background: var(--accent);
      color: #fff;
      border-radius: 4px;
      cursor: pointer;
      transition: background .2s;
      font-size: 0.9rem;
    }
    .toolbar-row button:hover {
      background: #0056b3;
    }

    #suggestions {
      position: absolute;
      top: 38px;
      left: 0;
      right: 0;
      background: #fff;
      border: 1px solid #ccc;
      border-top: none;
      max-height: 150px;
      overflow-y: auto;
      z-index: 1000;
      list-style: none;
      margin: 0;
      padding: 0;
      display: none;
    }
    #suggestions li {
      padding: 6px 10px;
      cursor: pointer;
      font-size: 0.9rem;
      color: #333;
    }
    #suggestions li:hover {
      background: #f0f0f0;
    }

    .docs-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      margin-bottom: 16px;
    }
    .docs-table th,
    .docs-table td {
      padding: 10px 6px;
      border: 1px solid #e0e0e0;
      text-align: left;
      font-size: 0.85rem;
      word-break: break-word;
      color: #333;
    }
    .docs-table th {
      background: #f1f1f1;
      text-transform: uppercase;
    }
    .docs-table tr:hover {
      background: var(--hover-row);
    }
    .pagination {
      display: flex;
      justify-content: center;
      gap: 8px;
      margin-top: 20px;
    }
    .pagination a {
      text-decoration: none;
    }
    .pagination button {
      padding: 10px 16px;
      border: none;
      border-radius: 4px;
      background: var(--accent);
      color: #fff;
      cursor: pointer;
    }
    .pagination button[disabled] {
      background: #ccc;
      cursor: default;
    }
    .pagination .current {
      background: #0056b3;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Auditoría</h2>

      <div class="toolbar-row">
        <input type="text" id="nombre" autocomplete="off" placeholder="Título documento"
               value="<%= nombre != null ? nombre : "" %>">
        <ul id="suggestions"></ul>

        <select id="usuario">
          <option value="todos">Usuario: todos</option>
          <% for (Map<String,Object> u : usuarios) { %>
            <option value="<%= u.get("id") %>"
              <%= (usuarioId != null && usuarioId.equals(u.get("id").toString())) ? "selected" : "" %>>
              <%= u.get("nombre") %>
            </option>
          <% } %>
        </select>

        <input type="date" id="fechaDesde" value="<%= fechaDesde != null ? fechaDesde : "" %>">
        <input type="date" id="fechaHasta" value="<%= fechaHasta != null ? fechaHasta : "" %>">
        <button onclick="aplicarFiltro()"><i class="fas fa-filter"></i> Aplicar</button>
        <button onclick="limpiarFiltro()"><i class="fas fa-eraser"></i> Limpiar</button>
      </div>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Usuario</th>
            <th>Documento</th>
            <th>Acción</th>
            <th>Fecha / Hora</th>
          </tr>
        </thead>
        <tbody>
          <% if (logs.isEmpty()) { %>
            <tr>
              <td colspan="4" style="text-align:center;">No hay registros</td>
            </tr>
          <% } else {
               for (Map<String,String> r : logs) { %>
            <tr>
              <td><%= r.get("usuario") %></td>
              <td><%= r.get("documento") %></td>
              <td><%= r.get("accion") %></td>
              <td><%= r.get("fechaHora") %></td>
            </tr>
          <%   }
             } %>
        </tbody>
      </table>

      <div class="pagination">
        <% String baseUrl = "auditoria.jsp"; %>
        <% 
          StringBuilder qsBase = new StringBuilder();
          if (nombre != null && !nombre.trim().isEmpty()) {
            qsBase.append("&nombre=").append(URLEncoder.encode(nombre, "UTF-8"));
          }
          if (usuarioId != null && !"todos".equals(usuarioId)) {
            qsBase.append("&usuario=").append(usuarioId);
          }
          if (fechaDesde != null && !fechaDesde.isEmpty()) {
            qsBase.append("&fechaDesde=").append(fechaDesde);
          }
          if (fechaHasta != null && !fechaHasta.isEmpty()) {
            qsBase.append("&fechaHasta=").append(fechaHasta);
          }
        %>

        <a href="<%= baseUrl + "?pagina=1" + qsBase.toString() %>">
          <button <%= (pagina == 1) ? "disabled" : "" %>><i class="fas fa-angle-double-left"></i></button>
        </a>
        <a href="<%= baseUrl + "?pagina=" + (pagina > 1 ? pagina - 1 : 1) + qsBase.toString() %>">
          <button <%= (pagina == 1) ? "disabled" : "" %>><i class="fas fa-angle-left"></i></button>
        </a>

        <% for (int p = startPage; p <= endPage; p++) {
             String url = baseUrl + "?pagina=" + p + qsBase.toString(); %>
          <a href="<%= url %>">
            <button class="<%= (p == pagina) ? "current" : "" %>"><%= p %></button>
          </a>
        <% } %>

        <a href="<%= baseUrl + "?pagina=" + (pagina < totalPaginas ? pagina + 1 : totalPaginas) + qsBase.toString() %>">
          <button <%= (pagina == totalPaginas) ? "disabled" : "" %>><i class="fas fa-angle-right"></i></button>
        </a>
        <a href="<%= baseUrl + "?pagina=" + totalPaginas + qsBase.toString() %>">
          <button <%= (pagina == totalPaginas) ? "disabled" : "" %>><i class="fas fa-angle-double-right"></i></button>
        </a>
      </div>
    </div>
  </div>

  <script>
    function createSuggestionItem(text) {
      const li = document.createElement('li');
      li.textContent = text;
      return li;
    }

    document.addEventListener('DOMContentLoaded', function() {
      const input = document.getElementById('nombre');
      const suggestionBox = document.getElementById('suggestions');

      let debounceTimeout;
      input.addEventListener('input', function() {
        const term = this.value.trim();
        clearTimeout(debounceTimeout);
        if (term.length < 2) {
          suggestionBox.style.display = 'none';
          return;
        }
        debounceTimeout = setTimeout(function() {
          fetch('buscarAuditoria.jsp?term=' + encodeURIComponent(term))
            .then(response => response.json())
            .then(data => {
              suggestionBox.innerHTML = '';
              if (data.length === 0) {
                suggestionBox.style.display = 'none';
                return;
              }
              data.forEach(item => {
                const li = createSuggestionItem(item.titulo);
                li.addEventListener('click', function() {
                  input.value = item.titulo;
                  suggestionBox.style.display = 'none';
                  aplicarFiltro();
                });
                suggestionBox.appendChild(li);
              });
              suggestionBox.style.display = 'block';
            })
            .catch(err => {
              console.error('Error al obtener sugerencias:', err);
              suggestionBox.style.display = 'none';
            });
        }, 300);
      });

      document.addEventListener('click', function(e) {
        if (!input.contains(e.target) && !suggestionBox.contains(e.target)) {
          suggestionBox.style.display = 'none';
        }
      });
    });

    function aplicarFiltro() {
      const params = new URLSearchParams();
      const nombreVal = document.getElementById('nombre').value.trim();
      const usuarioVal = document.getElementById('usuario').value;
      const desdeVal   = document.getElementById('fechaDesde').value;
      const hastaVal   = document.getElementById('fechaHasta').value;

      if (nombreVal) {
        params.set('nombre', nombreVal);
      }
      if (usuarioVal && usuarioVal !== 'todos') {
        params.set('usuario', usuarioVal);
      }
      if (desdeVal) {
        params.set('fechaDesde', desdeVal);
      }
      if (hastaVal) {
        params.set('fechaHasta', hastaVal);
      }
      params.set('pagina', '1');

      window.location = 'auditoria.jsp?' + params.toString();
    }

    function limpiarFiltro() {
      window.location = 'auditoria.jsp';
    }
  </script>
</body>
</html>
