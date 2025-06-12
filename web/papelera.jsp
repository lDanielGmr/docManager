<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.util.ArrayList,
    java.util.List,
    java.util.HashMap,
    java.util.Map,
    java.net.URLEncoder,
    javax.servlet.http.HttpServletResponse,
    ConexionBD.conexionBD,
    clasesGenericas.Usuario
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>

<%

    String ajaxField = request.getParameter("ajaxField");
    String term = request.getParameter("term");
    if (ajaxField != null && term != null) {
        Usuario usuarioAJAX = (Usuario) session.getAttribute("user");
        if (usuarioAJAX == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json; charset=UTF-8");
            out.write("[]");
            return;
        }
        int userIdAJAX = usuarioAJAX.getId();
        term = term.trim();
        List<String> results = new ArrayList<>();
        if (!term.isEmpty()) {
            String sql = null;
            if ("titulo".equals(ajaxField)) {
                sql = "SELECT DISTINCT d.titulo "
                    + "FROM documento d "
                    + "WHERE d.eliminado = 1 "
                    + "  AND (d.radicado_a = ? OR d.recibido_por = ?) "
                    + "  AND d.titulo COLLATE utf8mb4_unicode_ci LIKE ? "
                    + "ORDER BY d.titulo ASC LIMIT 10";
            } else if ("numeroRadicado".equals(ajaxField)) {
                sql = "SELECT DISTINCT d.numero_radicado "
                    + "FROM documento d "
                    + "WHERE d.eliminado = 1 "
                    + "  AND (d.radicado_a = ? OR d.recibido_por = ?) "
                    + "  AND d.numero_radicado COLLATE utf8mb4_unicode_ci LIKE ? "
                    + "ORDER BY d.numero_radicado ASC LIMIT 10";
            }
            if (sql != null) {
                try (Connection conn = conexionBD.conectar();
                     PreparedStatement pst = conn.prepareStatement(sql)) {
                    pst.setInt(1, userIdAJAX);
                    pst.setInt(2, userIdAJAX);
                    pst.setString(3, term + "%"); // sugerencias que comienzan con term
                    try (ResultSet rs = pst.executeQuery()) {
                        while (rs.next()) {
                            String v = ("titulo".equals(ajaxField))
                                         ? rs.getString("titulo")
                                         : rs.getString("numero_radicado");
                            if (v != null) results.add(v);
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        response.setContentType("application/json; charset=UTF-8");
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        for (int i = 0; i < results.size(); i++) {
            String s = results.get(i).replace("\"", "\\\"");
            sb.append("\"").append(s).append("\"");
            if (i < results.size() - 1) sb.append(",");
        }
        sb.append("]");
        out.write(sb.toString());
        return;
    }
%>

<%@ include file="menu.jsp" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    int userId = usuarioSesion.getId();
    int userRolId = usuarioSesion.getRol().getId();

    boolean puedeRestaurar = false;
    try (Connection connPerm = conexionBD.conectar();
         PreparedStatement pstPerm = connPerm.prepareStatement(
             "SELECT 1 FROM rol_permiso rp JOIN permiso p ON rp.permiso_id = p.id "
           + "WHERE rp.rol_id = ? AND p.nombre = ?"
         )) {
        pstPerm.setInt(1, userRolId);
        pstPerm.setString(2, "restaurar_documento"); 
        try (ResultSet rs = pstPerm.executeQuery()) {
            if (rs.next()) puedeRestaurar = true;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    out.println("<!-- DEBUG: puedeRestaurar=" + puedeRestaurar + " para rolId=" + userRolId + " -->");

    String nombreFiltro = request.getParameter("nombre");
    nombreFiltro = (nombreFiltro != null ? nombreFiltro.trim() : "");

    String numeroRadicadoFiltro = request.getParameter("numeroRadicado");
    numeroRadicadoFiltro = (numeroRadicadoFiltro != null ? numeroRadicadoFiltro.trim() : "");

    boolean chkTitulo = "on".equals(request.getParameter("chkTitulo"));
    boolean chkNumeroRadicado = "on".equals(request.getParameter("chkNumeroRadicado"));

    final int PAGE_SIZE = 10;
    int currentPage = 1;
    try {
        String p = request.getParameter("page");
        if (p != null) currentPage = Integer.parseInt(p);
    } catch (NumberFormatException ignored) {}
    if (currentPage < 1) currentPage = 1;

    int totalRows = 0;
    StringBuilder countSQL = new StringBuilder(
      "SELECT COUNT(*) FROM papelera p JOIN documento d ON p.doc_id = d.id "
    + "WHERE d.eliminado = 1 AND (d.radicado_a = ? OR d.recibido_por = ?)"
    );
    if (chkTitulo && !nombreFiltro.isEmpty()) {
        countSQL.append(" AND d.titulo = ?");
    } else if (chkNumeroRadicado && !numeroRadicadoFiltro.isEmpty()) {
        countSQL.append(" AND d.numero_radicado = ?");
    }
    try (Connection c = conexionBD.conectar();
         PreparedStatement ps = c.prepareStatement(countSQL.toString())) {
        int idx = 1;
        ps.setInt(idx++, userId);
        ps.setInt(idx++, userId);
        if (chkTitulo && !nombreFiltro.isEmpty()) {
            ps.setString(idx, nombreFiltro);
        } else if (chkNumeroRadicado && !numeroRadicadoFiltro.isEmpty()) {
            ps.setString(idx, numeroRadicadoFiltro);
        }
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalRows = rs.getInt(1);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    int totalPages = Math.max(1, (int)Math.ceil((double)totalRows / PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;
    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize/2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }
    int offset = (currentPage - 1) * PAGE_SIZE;

    List<Map<String,Object>> papeles = new ArrayList<>();
    StringBuilder fetchSQL = new StringBuilder(
      "SELECT p.id AS papelId, d.id AS docId, d.titulo, d.numero_radicado, "
    + "DATE(p.fecha_elim) AS fechaElim, u.nombre AS autor "
    + "FROM papelera p JOIN documento d ON p.doc_id = d.id "
    + "JOIN usuario u ON d.recibido_por = u.id "
    + "WHERE d.eliminado = 1 AND (d.radicado_a = ? OR d.recibido_por = ?)"
    );
    if (chkTitulo && !nombreFiltro.isEmpty()) {
        fetchSQL.append(" AND d.titulo = ?");
    } else if (chkNumeroRadicado && !numeroRadicadoFiltro.isEmpty()) {
        fetchSQL.append(" AND d.numero_radicado = ?");
    }
    fetchSQL.append(" ORDER BY p.fecha_elim DESC LIMIT ?, ?");
    try (Connection c = conexionBD.conectar();
         PreparedStatement ps = c.prepareStatement(fetchSQL.toString())) {
        int idx = 1;
        ps.setInt(idx++, userId);
        ps.setInt(idx++, userId);
        if (chkTitulo && !nombreFiltro.isEmpty()) {
            ps.setString(idx++, nombreFiltro);
        } else if (chkNumeroRadicado && !numeroRadicadoFiltro.isEmpty()) {
            ps.setString(idx++, numeroRadicadoFiltro);
        }
        ps.setInt(idx++, offset);
        ps.setInt(idx, PAGE_SIZE);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                String num = rs.getString("numero_radicado");
                row.put("numeroRadicado", num != null ? num : "");
                row.put("papelId", rs.getInt("papelId"));
                row.put("docId", rs.getInt("docId"));
                row.put("titulo", rs.getString("titulo"));
                row.put("fechaElim", rs.getDate("fechaElim"));
                row.put("autor", rs.getString("autor"));
                papeles.add(row);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    String contexto = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Papelera</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e; --accent: #007bff; --btn-hover: #0056b3;
      --text: #e0e0e0; --light: #fff;
    }
    body {
      margin:0; padding:0; font-family:'Poppins',sans-serif;
      background: var(--bg) url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size:cover; color:var(--text);
    }
    .menu-container { max-width:960px; margin:20px auto; padding:0 10px; }
    .menu-box {
      background:var(--light); color:#000; padding:16px;
      border-radius:6px; box-shadow:0 4px 12px rgba(0,0,0,0.1);
    }
    h2 { margin-top:0; color:#333; }
    .toolbar {
      display:flex; flex-wrap:wrap; gap:10px; margin-bottom:16px; align-items:center;
    }
    .search-group {
      position: relative;
      display:flex; align-items:center; gap:6px;
    }
    .search-group input[type=text] {
      padding:6px 10px; border:1px solid #ccc; border-radius:4px;
      font-size:0.9rem; width:200px;
    }
    .autocomplete-items {
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background-color: #fff;
      border: 1px solid #ccc;
      z-index: 1000;
      max-height: 200px;
      overflow-y: auto;
    }
    .autocomplete-items div {
      padding: 8px 10px;
      cursor: pointer;
      font-size: 0.9rem;
      color: #333;
    }
    .autocomplete-items div:hover {
      background-color: #f0f0f0;
    }
    .toolbar button {
      display:flex; align-items:center; gap:6px;
      background:var(--accent); color:var(--light);
      border:none; border-radius:4px; padding:6px 12px;
      font-size:0.9rem; cursor:pointer;
    }
    .toolbar button:hover { background:var(--btn-hover); }
    .docs-table {
      width:100%; border-collapse:collapse; margin-bottom:16px;
      background:var(--light); color:#000;
    }
    .docs-table th, .docs-table td {
      padding:10px 8px; border:1px solid #ddd; font-size:0.85rem; word-break:break-word;
    }
    .docs-table th { background:#f5f5f5; text-transform:uppercase; }
    .docs-table tr:hover { background:#fafafa; }
    .docs-table .actions button {
      display:flex; align-items:center; gap:4px;
      background:var(--accent); color:var(--light);
      border:none; border-radius:4px; padding:4px 8px;
      font-size:0.85rem; cursor:pointer;
    }
    .docs-table .actions button:hover { background:var(--btn-hover); }
    .pagination {
      display:flex; justify-content:center; gap:8px;
      list-style:none; padding:0; margin-top:20px; flex-wrap:wrap;
    }
    .pagination li a {
      display:inline-block; padding:8px 14px;
      background:var(--accent); color:var(--light);
      border-radius:4px; text-decoration:none; min-width:36px; text-align:center;
    }
    .pagination li.disabled a {
      background:#ccc; color:#666; pointer-events:none;
    }
    .pagination li.active a {
      background:#4e32a8; font-weight:bold; border:2px solid #fff;
    }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Papelera</h2>

      <section class="toolbar">
        <div class="search-group">
          <input id="chkTitulo" type="checkbox" name="chkTitulo" <%= chkTitulo ? "checked" : "" %>/>
          <label for="chkTitulo">Título</label>
          <input type="text" id="nombre" name="nombre"
                 placeholder="Buscar por título"
                 value="<%= nombreFiltro %>" autocomplete="off"/>
          <div id="autocomplete-titulo" class="autocomplete-items"></div>
        </div>

        <div class="search-group">
          <input id="chkNumeroRadicado" type="checkbox" name="chkNumeroRadicado" <%= chkNumeroRadicado ? "checked" : "" %>/>
          <label for="chkNumeroRadicado">Radicado</label>
          <input type="text" id="numeroRadicado" name="numeroRadicado"
                 placeholder="Buscar por radicado"
                 value="<%= numeroRadicadoFiltro %>" autocomplete="off"/>
          <div id="autocomplete-numero" class="autocomplete-items"></div>
        </div>

        <button id="btnBuscar"><i class="fas fa-search"></i> Buscar</button>
        <button id="btnLimpiar"><i class="fas fa-eraser"></i> Limpiar</button>
      </section>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Número Radicado</th>
            <th>Nombre Documento</th>
            <th>Fecha Eliminación</th>
            <th>Autor</th>
            <% if (puedeRestaurar) { %><th>Restaurar</th><% } %>
          </tr>
        </thead>
        <tbody>
          <% if (papeles.isEmpty()) { %>
            <tr>
              <td colspan="<%= puedeRestaurar?5:4 %>" style="text-align:center;color:#666;">
                No hay documentos en la papelera
              </td>
            </tr>
          <% } else {
               for (Map<String,Object> p : papeles) { %>
            <tr>
              <td><%= p.get("numeroRadicado") %></td>
              <td><%= p.get("titulo") %></td>
              <td><%= p.get("fechaElim") %></td>
              <td><%= p.get("autor") %></td>
              <% if (puedeRestaurar) { %>
              <td class="actions">
                <button onclick="restaurar(<%= p.get("docId") %>)">
                  <i class="fas fa-undo"></i> Restaurar
                </button>
              </td>
              <% } %>
            </tr>
          <%   } } %>
        </tbody>
      </table>

      <ul class="pagination">
        <li class="<%= currentPage==1?"disabled":"" %>">
          <a href="papelera.jsp?page=1<%= (chkTitulo&&!nombreFiltro.isEmpty())?"&chkTitulo=on&nombre="+URLEncoder.encode(nombreFiltro,"UTF-8"):(chkNumeroRadicado&&!numeroRadicadoFiltro.isEmpty())?"&chkNumeroRadicado=on&numeroRadicado="+URLEncoder.encode(numeroRadicadoFiltro,"UTF-8"): "" %>">
            <i class="fas fa-angle-double-left"></i>
          </a>
        </li>
        <li class="<%= currentPage==1?"disabled":"" %>">
          <a href="papelera.jsp?page=<%= currentPage-1 %><%= (chkTitulo&&!nombreFiltro.isEmpty())?"&chkTitulo=on&nombre="+URLEncoder.encode(nombreFiltro,"UTF-8"):(chkNumeroRadicado&&!numeroRadicadoFiltro.isEmpty())?"&chkNumeroRadicado=on&numeroRadicado="+URLEncoder.encode(numeroRadicadoFiltro,"UTF-8"): "" %>">
            <i class="fas fa-angle-left"></i>
          </a>
        </li>
        <% for(int p=startPage; p<=endPage; p++){ %>
        <li class="<%= p==currentPage?"active":"" %>">
          <a href="papelera.jsp?page=<%=p%><%= (chkTitulo&&!nombreFiltro.isEmpty())?"&chkTitulo=on&nombre="+URLEncoder.encode(nombreFiltro,"UTF-8"):(chkNumeroRadicado&&!numeroRadicadoFiltro.isEmpty())?"&chkNumeroRadicado=on&numeroRadicado="+URLEncoder.encode(numeroRadicadoFiltro,"UTF-8"): "" %>">
            <%=p%>
          </a>
        </li>
        <% } %>
        <li class="<%= currentPage==totalPages?"disabled":"" %>">
          <a href="papelera.jsp?page=<%= currentPage+1 %><%= (chkTitulo&&!nombreFiltro.isEmpty())?"&chkTitulo=on&nombre="+URLEncoder.encode(nombreFiltro,"UTF-8"):(chkNumeroRadicado&&!numeroRadicadoFiltro.isEmpty())?"&chkNumeroRadicado=on&numeroRadicado="+URLEncoder.encode(numeroRadicadoFiltro,"UTF-8"): "" %>">
            <i class="fas fa-angle-right"></i>
          </a>
        </li>
        <li class="<%= currentPage==totalPages?"disabled":"" %>">
          <a href="papelera.jsp?page=<%= totalPages %><%= (chkTitulo&&!nombreFiltro.isEmpty())?"&chkTitulo=on&nombre="+URLEncoder.encode(nombreFiltro,"UTF-8"):(chkNumeroRadicado&&!numeroRadicadoFiltro.isEmpty())?"&chkNumeroRadicado=on&numeroRadicado="+URLEncoder.encode(numeroRadicadoFiltro,"UTF-8"): "" %>">
            <i class="fas fa-angle-double-right"></i>
          </a>
        </li>
      </ul>

      <script>
        const contexto = '<%= contexto %>';
        const chkTitulo = document.getElementById('chkTitulo'),
              chkNumeroRadicado = document.getElementById('chkNumeroRadicado'),
              inputTitulo = document.getElementById('nombre'),
              inputNumero = document.getElementById('numeroRadicado'),
              contTitulo = document.getElementById('autocomplete-titulo'),
              contNumero = document.getElementById('autocomplete-numero'),
              btnBuscar = document.getElementById('btnBuscar'),
              btnLimpiar = document.getElementById('btnLimpiar');

        function activateOnly(chk) {
          [chkTitulo, chkNumeroRadicado].forEach(cb => {
            if (cb && cb !== chk) cb.checked = false;
            else if (cb === chk) cb.checked = true;
          });
        }
        if (chkTitulo) chkTitulo.onchange = () => { if (chkTitulo.checked) activateOnly(chkTitulo); };
        if (chkNumeroRadicado) chkNumeroRadicado.onchange = () => { if (chkNumeroRadicado.checked) activateOnly(chkNumeroRadicado); };

        document.addEventListener('click', function(e) {
          if (!inputTitulo.contains(e.target) && !contTitulo.contains(e.target)) {
            contTitulo.innerHTML = '';
          }
          if (!inputNumero.contains(e.target) && !contNumero.contains(e.target)) {
            contNumero.innerHTML = '';
          }
        });

        inputTitulo.addEventListener('input', () => {
          activateOnly(chkTitulo);
          const term = inputTitulo.value.trim();
          if (term.length < 2) {
            contTitulo.innerHTML = '';
            return;
          }
          const urlTit = contexto + '/papelera.jsp?ajaxField=titulo&term=' + encodeURIComponent(term);
          fetch(urlTit)
            .then(res => res.ok ? res.json() : Promise.reject())
            .then(json => {
              contTitulo.innerHTML = '';
              if (Array.isArray(json)) {
                json.forEach(t => {
                  const div = document.createElement('div');
                  div.textContent = t;
                  div.addEventListener('click', () => {
                    inputTitulo.value = t;
                    contTitulo.innerHTML = '';
                    buscar();
                  });
                  contTitulo.appendChild(div);
                });
              }
            })
            .catch(() => { contTitulo.innerHTML = ''; });
        });

        inputNumero.addEventListener('input', () => {
          activateOnly(chkNumeroRadicado);
          const term = inputNumero.value.trim();
          if (term.length < 2) {
            contNumero.innerHTML = '';
            return;
          }
          const urlRad = contexto + '/papelera.jsp?ajaxField=numeroRadicado&term=' + encodeURIComponent(term);
          fetch(urlRad)
            .then(res => res.ok ? res.json() : Promise.reject())
            .then(json => {
              contNumero.innerHTML = '';
              if (Array.isArray(json)) {
                json.forEach(r => {
                  const div = document.createElement('div');
                  div.textContent = r;
                  div.addEventListener('click', () => {
                    inputNumero.value = r;
                    contNumero.innerHTML = '';
                    buscar();
                  });
                  contNumero.appendChild(div);
                });
              }
            })
            .catch(() => { contNumero.innerHTML = ''; });
        });

        btnBuscar.onclick = e => { e.preventDefault(); buscar(); };
        btnLimpiar.onclick = e => { e.preventDefault(); window.location = contexto + '/papelera.jsp'; };

        function buscar() {
          let params = [];
          if (chkTitulo.checked && inputTitulo.value.trim()) {
            params.push("chkTitulo=on", "nombre=" + encodeURIComponent(inputTitulo.value.trim()));
          } else if (chkNumeroRadicado.checked && inputNumero.value.trim()) {
            params.push("chkNumeroRadicado=on", "numeroRadicado=" + encodeURIComponent(inputNumero.value.trim()));
          }
          const target = contexto + '/papelera.jsp' + (params.length ? ('?' + params.join('&')) : '');
          window.location = target;
        }

        [inputTitulo, inputNumero].forEach(inp => {
          inp.addEventListener('keydown', e => {
            if (e.key === 'Enter') {
              e.preventDefault();
              buscar();
            }
          });
        });

        function restaurar(id) {
          window.location = contexto + '/restaurarDocumento.jsp?id=' + id;
        }
      </script>
    </div>
  </div>
</body>
</html>
