<%@ page import="
         java.net.URLEncoder,
         java.io.PrintWriter,
         java.sql.Connection,
         java.sql.PreparedStatement,
         java.sql.ResultSet,
         java.sql.SQLException,
         java.time.LocalDate,
         java.io.StringWriter,
         java.util.HashSet,
         java.util.HashMap,
         java.util.Set,
         java.util.List,
         java.util.Map,
         clasesGenericas.Usuario,
         clasesGenericas.Menu,
         clasesGenericas.RolPermiso,
         clasesGenericas.Permiso,
         clasesGenericas.Metadata,
         ConexionBD.conexionBD
         " %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
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
    int userId = usuario.getId();
    String currentPathInfo = request.getServletPath();
    String pageFileName = currentPathInfo.substring(currentPathInfo.lastIndexOf('/') + 1);
    Menu.recordUse(usuario.getId(), pageFileName);

    Set<Integer> permisoIds = new HashSet<>();
    Map<String, Integer> permisosMap = new HashMap<>();
    for (RolPermiso rp : RolPermiso.findByRolId(usuario.getRol().getId())) {
        permisoIds.add(rp.getPermisoId());
    }
    for (Permiso p : Permiso.findAll()) {
        permisosMap.put(p.getNombre(), p.getId());
    }
    boolean puedeVerPlantillas = permisoIds.contains(permisosMap.get("ver_plantillas"));
    boolean puedeSubirDocumento = permisoIds.contains(permisosMap.get("crear_documento"));
    boolean puedeEditarDocumento = permisoIds.contains(permisosMap.get("subir_version"));
    boolean puedeEliminarDocumento = permisoIds.contains(permisosMap.get("eliminar_documento"));

    final int PAGE_SIZE = 3;
    int currentPage = 1;
    try {
        String pParam = request.getParameter("page");
        if (pParam != null) {
            currentPage = Integer.parseInt(pParam);
        }
    } catch (Exception ignore) {}
    if (currentPage < 1) {
        currentPage = 1;
    }

    if (request.getParameter("errorMsg") != null) {
        errorMsg = request.getParameter("errorMsg");
    }
    if (request.getParameter("infoMsg") != null) {
        infoMsg = request.getParameter("infoMsg");
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String deleteIdParam = request.getParameter("deleteId");
        if (deleteIdParam != null) {
            if (puedeEliminarDocumento) {
                int docIdToDelete = -1;
                try {
                    docIdToDelete = Integer.parseInt(deleteIdParam);
                } catch (NumberFormatException e) {
                    docIdToDelete = -1;
                }
                if (docIdToDelete > 0) {
                    try (Connection conn = conexionBD.conectar()) {
                        conn.setAutoCommit(false);
                        boolean ok = true;
                        try (PreparedStatement pstUpd = conn.prepareStatement(
                                "UPDATE documento SET eliminado = 1 WHERE id = ?"
                            )) {
                            pstUpd.setInt(1, docIdToDelete);
                            int updated = pstUpd.executeUpdate();
                            if (updated == 0) {
                                ok = false;
                            }
                        } catch (SQLException e) {
                            ok = false;
                            StringWriter sw = new StringWriter();
                            e.printStackTrace(new PrintWriter(sw));
                            System.err.println("Error al marcar eliminado documento: " + sw.toString());
                        }
                        if (ok) {
                            try (PreparedStatement pstIns = conn.prepareStatement(
                                    "INSERT INTO papelera (doc_id) VALUES (?)"
                                )) {
                                pstIns.setInt(1, docIdToDelete);
                                pstIns.executeUpdate();
                            } catch (SQLException e) {
                                ok = false;
                                StringWriter sw = new StringWriter();
                                e.printStackTrace(new PrintWriter(sw));
                                System.err.println("Error al insertar en papelera: " + sw.toString());
                            }
                        }
                        if (ok) {
                            try (PreparedStatement pstAudit = conn.prepareStatement(
                                    "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)"
                                )) {
                                pstAudit.setInt(1, userId);
                                pstAudit.setInt(2, docIdToDelete);
                                pstAudit.setString(3, "ELIMINAR_DOCUMENTO");
                                pstAudit.executeUpdate();
                            } catch (SQLException e) {
                                ok = false;
                                StringWriter sw = new StringWriter();
                                e.printStackTrace(new PrintWriter(sw));
                                System.err.println("Error al insertar en audit_log: " + sw.toString());
                            }
                        }
                        if (ok) {
                            conn.commit();
                            infoMsg = "Documento eliminado correctamente.";
                        } else {
                            conn.rollback();
                            errorMsg = "No se pudo eliminar el documento.";
                        }
                    } catch (SQLException e) {
                        StringWriter sw = new StringWriter();
                        e.printStackTrace(new PrintWriter(sw));
                        System.err.println("Error en transacción de eliminación: " + sw.toString());
                        errorMsg = "Error al eliminar el documento.";
                    }
                } else {
                    errorMsg = "ID de documento inválido.";
                }
            } else {
                errorMsg = "No tienes permiso para eliminar.";
            }
        }
        String redirectURL = request.getRequestURI() + "?page=" + currentPage;
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
    countSb.append("SELECT COUNT(*) FROM documento d WHERE ");
    if (puedeVerPlantillas) {
        countSb.append("(d.recibido_por=? OR d.radicado_a=?)");
    } else {
        countSb.append("d.es_plantilla = 0 AND (d.recibido_por=? OR d.radicado_a=?)");
    }
    countSb.append(" AND d.eliminado = 0");
    String countSQL = countSb.toString();
    try (Connection conn = conexionBD.conectar(); PreparedStatement pst = conn.prepareStatement(countSQL)) {
        pst.setInt(1, usuario.getId());
        pst.setInt(2, usuario.getId());
        try (ResultSet rs = pst.executeQuery()) {
            if (rs.next()) {
                totalRows = rs.getInt(1);
            }
        }
    } catch (Exception e) {
        totalRows = 0;
    }

    int totalPages = Math.max(1, (int) Math.ceil((double) totalRows / PAGE_SIZE));
    if (currentPage > totalPages) {
        currentPage = totalPages;
    }
    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize / 2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    StringBuilder sb = new StringBuilder();
    sb.append("SELECT d.id, d.numero_radicado, d.titulo, a.nombre AS area, ")
            .append("d.tipo, d.es_plantilla, d.recibido_por, d.radicado_a, ")
            .append("d.requiere_respuesta, d.respondido, ")
            .append("u_rem.nombre AS remitente, u_dest.nombre AS destinatario, d.fecha_creacion ")
            .append("FROM documento d ")
            .append("LEFT JOIN area a ON d.id_area = a.id ")
            .append("LEFT JOIN usuario u_rem ON d.recibido_por = u_rem.id ")
            .append("LEFT JOIN usuario u_dest ON d.radicado_a = u_dest.id ")
            .append("WHERE ");
    if (puedeVerPlantillas) {
        sb.append("(d.recibido_por=? OR d.radicado_a=?)");
    } else {
        sb.append("d.es_plantilla = 0 AND (d.recibido_por=? OR d.radicado_a=?)");
    }
    sb.append(" AND d.eliminado = 0 ")
            .append("ORDER BY d.fecha_creacion DESC ")
            .append("LIMIT ?, ?");
    String dataSQL = sb.toString();
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>Página de Inicio</title>
        <link rel="stylesheet" href="style.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
        <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
        <style>
            :root {
                --bg: #1f1f2e;
                --accent: #007bff;
                --text: #e0e0e0;
                --light: #fff;
                --shadow: rgba(0, 0, 0, 0.4);
            }
            html, body {
                margin:0;
                padding:0;
                height:100%;
                overflow-y:auto;
                background: var(--bg) url('<%= request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
                background-size:cover;
                color:var(--text);
            }
            * {
                box-sizing:border-box;
                font-family:'Poppins',sans-serif;
            }
            .menu-container {
                width:100%;
                max-width:960px;
                margin:20px auto;
                padding:0 10px;
            }
            .menu-box {
                background:#fff;
                color:#000;
                padding:16px;
                border-radius:4px;
                box-shadow:0 4px 12px rgba(0,0,0,0.1);
                line-height:1.5;
            }
            h1 {
                margin-top:0;
                color:#333;
            }
            .stats {
                margin-bottom:1em;
            }
            .shortcut-tags {
                display:flex;
                gap:20px;
                flex-wrap:wrap;
                margin-bottom:20px;
            }
            .shortcut-tags .card {
                flex:1 1 45%;
                background:#fdfdfd;
                border:1px solid #ddd;
                border-radius:6px;
                padding:16px;
                box-shadow:0 2px 6px rgba(0,0,0,0.05);
            }
            .shortcut-tags .card h2 {
                font-size:1.2rem;
                margin-bottom:10px;
                color:#444;
            }
            .shortcut-tags ul {
                list-style:none;
                padding-left:0;
                margin:0;
            }
            .shortcut-tags li {
                margin-bottom:8px;
                font-size:0.95rem;
                color:#222;
                display:flex;
                align-items:center;
            }
            .shortcut-tags li i {
                margin-right:6px;
                color:var(--accent);
            }
            .docs-table {
                width:100%;
                border-collapse:collapse;
                margin-bottom:16px;
            }
            .docs-table th, .docs-table td {
                padding:10px 6px;
                border:1px solid #ddd;
                font-size:0.85rem;
                word-break:break-word;
                color:#000;
            }
            .docs-table th {
                background:#f5f5f5;
                text-transform:uppercase;
            }
            .docs-table tr:hover {
                background:#fafafa;
                cursor:pointer;
            }
            .docs-table tr.selected {
                background:rgba(157,122,237,0.2)!important;
            }
            .pendiente {
                background:#ffeb99!important;
                color:#000!important;
            }
            .respondido {
                background:#89b4f8!important;
                color:#000!important;
            }
            .checkbox-label {
                display:inline-flex;
                align-items:center;
                gap:4px;
                font-size:0.85rem;
                cursor:pointer;
                user-select:none;
            }
            .checkbox-label input {
                width:16px;
                height:16px;
                margin:0;
            }
            .pagination {
                display:flex;
                justify-content:center;
                align-items:center;
                gap:8px;
                margin-top:20px;
                list-style:none;
                padding:0;
                flex-wrap:wrap;
            }
            .pagination li a {
                display:inline-block;
                background:var(--accent);
                color:#fff;
                text-decoration:none;
                padding:10px 16px;
                font-size:1rem;
                border-radius:4px;
                min-width:44px;
                text-align:center;
                transition:background 0.3s ease;
            }
            .pagination li.disabled a {
                background:#ccc;
                color:#666;
                pointer-events:none;
            }
            .pagination li.active a {
                background:#4e32a8;
                font-weight:bold;
                border:2px solid #fff;
            }
            .actions {
                display:flex;
                justify-content:flex-end;
                gap:6px;
                flex-wrap:wrap;
                margin-top:16px;
            }
            .actions button {
                font-size:0.85rem;
                padding:6px 12px;
                border-radius:4px;
                background:var(--accent);
                color:#fff;
                border:none;
                cursor:pointer;
            }
            .actions button:hover {
                opacity:0.9;
            }
            .modal-overlay {
                position:fixed;
                top:0;
                left:0;
                width:100%;
                height:100%;
                background:rgba(0,0,0,0.5);
                display:none;
                align-items:center;
                justify-content:center;
                z-index:1000;
            }
            .modal-content {
                background:#fff;
                width:90%;
                max-width:760px;
                border-radius:6px;
                position:relative;
                box-shadow:0 4px 12px rgba(0,0,0,0.2);
            }
            .modal-close {
                position:absolute;
                top:10px;
                right:10px;
                background:var(--accent);
                color:#fff;
                border:none;
                padding:8px;
                border-radius:50%;
                font-size:1.4rem;
                cursor:pointer;
            }
            .modal-close:hover {
                background:#0056b3;
            }
            .modal-iframe {
                width:100%;
                height:580px;
                border:none;
                border-radius:0 0 6px 6px;
            }

            #modalAdjuntar .modal-content form#formAdjuntar button[type="submit"] {
                background: #007bff;
                color: #fff;
                border: none;
                padding: 8px 16px;
                font-size: 0.95rem;
                border-radius: 4px;
                cursor: pointer;
                transition: background 0.2s ease;
            }
            #modalAdjuntar .modal-content form#formAdjuntar button[type="submit"]:hover {
                background: #0056b3;
            }
        </style>
    </head>
    <body>
        <div class="menu-container">
            <div class="menu-box">
                <h1>¡Bienvenido, <%= usuario.getNombre()%>!</h1>
                <div class="stats">
                    <strong>Total de documentos encontrados:</strong> <%= totalRows%>
                </div>
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

                <div class="shortcut-tags">
                    <div class="card">
                        <h2>Atajos más usados</h2>
                        <ul>
                            <%
                                List<Map<String, String>> atajos = Menu.findTopShortcutsByUser(usuario.getId());
                                if (atajos == null || atajos.isEmpty()) {
                            %>
                            <li>No tienes atajos guardados.</li>
                                <% } else {
                                    for (Map<String, String> at : atajos) {%>
                            <li><i class="fas fa-link"></i>
                                <a href="<%= at.get("url")%>"><%= at.get("label")%></a>
                            </li>
                            <% }
                                } %>
                        </ul>
                    </div>
                    <div class="card">
                        <h2>Etiquetas más comunes</h2>
                        <ul>
                            <%
                                List<Map<String, Object>> etiquetas;
                                try {
                                    etiquetas = Metadata.findCommonTagsByUser(usuario.getId());
                                } catch (Exception e) {
                                    etiquetas = null;
                                }
                                if (etiquetas == null || etiquetas.isEmpty()) {
                            %>
                            <li>Sin etiquetas aún.</li>
                                <% } else {
                                    for (Map<String, Object> tag : etiquetas) {%>
                            <li><i class="fas fa-tag"></i>
                                <%= tag.get("nombre")%> (<%= tag.get("cnt")%>)
                            </li>
                            <% }
                                } %>
                        </ul>
                    </div>
                </div>

                <table id="tablaDocs" class="docs-table">
                    <thead>
                        <tr>
                            <th>Numero de radicado</th>
                            <th>Nombre</th><th>Tipo</th><th>Área</th>
                            <th>Remitente</th><th>Destinatario</th><th>Fecha</th>
                            <th>Estado</th><th>Respondido</th><th>Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try (Connection conn = conexionBD.conectar(); PreparedStatement ps = conn.prepareStatement(dataSQL)) {
                                int pi = 1;
                                ps.setInt(pi++, usuario.getId());
                                ps.setInt(pi++, usuario.getId());
                                ps.setInt(pi++, (currentPage - 1) * PAGE_SIZE);
                                ps.setInt(pi++, PAGE_SIZE);
                                try (ResultSet rs = ps.executeQuery()) {
                                    while (rs.next()) {
                                        boolean esPlantilla = rs.getBoolean("es_plantilla");
                                        boolean soyRem = rs.getInt("recibido_por") == usuario.getId();
                                        boolean soyDest = rs.getInt("radicado_a") == usuario.getId();
                                        boolean req = rs.getBoolean("requiere_respuesta");
                                        boolean resp = rs.getBoolean("respondido");
                                        if (!(soyRem || soyDest)) {
                                            continue;
                                        }
                                        LocalDate f = rs.getTimestamp("fecha_creacion")
                                                .toLocalDateTime().toLocalDate();
                        %>
                        <tr data-id="<%=rs.getInt("id")%>" onclick="seleccionarFila(this)">
                            <%
                                String numeroRadicado = rs.getString("numero_radicado");
                                if (numeroRadicado != null) {
                                    numeroRadicado = numeroRadicado.trim();
                                    if (numeroRadicado.isEmpty()) {
                                        numeroRadicado = null;
                                    }
                                }
                                String textoMostrar = (numeroRadicado != null) ? numeroRadicado : "";
                            %>
                            <td><%= textoMostrar%></td>
                            <td><%=rs.getString("titulo")%></td>
                            <td><%=rs.getString("tipo")%> <%=esPlantilla ? "(plantilla)" : ""%></td>
                            <td><%=rs.getString("area")%></td>
                            <td><%=rs.getString("remitente")%></td>
                            <td>
                                <% if (esPlantilla) { %>No aplica
                                <% } else {
                                        String d = rs.getString("destinatario");
                                        out.print(d != null ? d : "No aplica");
                                    }%>
                            </td>
                            <td><%=f%></td>
                            <td>
                                <% if (soyRem) {%>Enviado
                                <% } else if (soyDest && req) {%>
                                <%=resp ? "Respondido" : "Pendiente"%>
                                <% } else { %>&mdash;<% }%>
                            </td>
                            <td class="<%=soyDest && req && !esPlantilla
                                        ? (resp ? "respondido" : "pendiente") : ""%>">
                                <% if (soyDest && req && !esPlantilla) {%>
                                <label class="checkbox-label">
                                    <input type="checkbox"
                                           <%=resp ? "checked" : ""%>
                                           onchange="toggleRespondido(<%=rs.getInt("id")%>)">
                                    <i class="fas fa-check-circle"></i>
                                    <span><%=resp ? "Marcado" : "Marcar como respondido"%></span>
                                </label>
                                <% } else { %>&mdash;<% } %>
                            </td>
                            <td>
                                <% if (soyDest && req && !esPlantilla) {
                                        String s = URLEncoder.encode(rs.getString("titulo"), "UTF-8");
                                %>
                                <a href="https://mail.google.com/mail/?view=cm&su=<%=s%>"
                                   target="_blank" class="checkbox-label" style="margin-right:8px;">
                                    <i class="fas fa-reply"></i> Responder
                                </a>
                                <button type="button"
                                        class="checkbox-label"
                                        onclick="abrirModalAdjuntar(<%=rs.getInt("id")%>)">
                                    <i class="fas fa-paperclip"></i> Adjuntar
                                </button>
                                <% } else { %>&mdash;<% } %>
                            </td>
                        </tr>
                        <%       }
                                }
                            } catch (Exception e) {
                                StringWriter sw = new StringWriter();
                                e.printStackTrace(new PrintWriter(sw));
                                out.println("<tr><td colspan='10'><pre style='color:red;'>"
                                        + sw + "</pre></td></tr>");
                            }
                        %>
                    </tbody>
                </table>

                <ul class="pagination">
                    <li class="<%=currentPage == 1 ? "disabled" : ""%>">
                        <a href="<%=request.getContextPath()%>/inicio.jsp?page=1">&laquo;&laquo;</a>
                    </li>
                    <li class="<%=currentPage == 1 ? "disabled" : ""%>">
                        <a href="<%=request.getContextPath()%>/inicio.jsp?page=<%=currentPage - 1%>">&laquo;</a>
                    </li>
                    <% for (int p = startPage; p <= endPage; p++) {%>
                    <li class="<%=p == currentPage ? "active" : ""%>">
                        <a href="<%=request.getContextPath()%>/inicio.jsp?page=<%=p%>"><%=p%></a>
                    </li>
                    <% }%>
                    <li class="<%=currentPage == totalPages ? "disabled" : ""%>">
                        <a href="<%=request.getContextPath()%>/inicio.jsp?page=<%=currentPage + 1%>">&raquo;</a>
                    </li>
                    <li class="<%=currentPage == totalPages ? "disabled" : ""%>">
                        <a href="<%=request.getContextPath()%>/inicio.jsp?page=<%=totalPages%>">&raquo;&raquo;</a>
                    </li>
                </ul>

                <section class="actions">
                    <button onclick="vistaPreviaSeleccionado()"><i class="fas fa-eye"></i> Vista previa</button>
                    <% if (puedeEditarDocumento) { %>
                    <button onclick="editarSeleccionado()"><i class="fas fa-edit"></i> Editar</button>
                    <% } %>
                    <% if (puedeEliminarDocumento) { %>
                    <button onclick="eliminarSeleccionado()"><i class="fas fa-trash"></i> Eliminar</button>
                    <% }%>
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

        <div id="modalAdjuntar" class="modal-overlay">
            <div class="modal-content">
                <button class="modal-close" onclick="cerrarModalAdjuntar()">
                    <i class="fas fa-times"></i>
                </button>
                <form id="formAdjuntar" action="subirRespuesta.jsp"
                      method="post" enctype="multipart/form-data"
                      style="padding:16px;">
                    <input type="hidden" name="documentoId" id="inputDocId">
                    <h3>Adjuntar respuesta</h3>
                    <input type="file" name="archivoRespuesta" required><br><br>
                    <button type="submit">Subir</button>
                </form>
            </div>
        </div>

        <form id="deleteForm" method="post" action="inicio.jsp" style="display:none;">
            <input type="hidden" name="deleteId" id="deleteIdInput" value=""/>
        </form>

        <script>
            const ctx = '<%= request.getContextPath()%>';
            const modal = document.getElementById('modal'),
                    iframe = document.getElementById('modalIframe'),
                    closeBtn = document.getElementById('btnCloseModal');

            if (closeBtn) {
                closeBtn.onclick = () => {
                    modal.style.display = 'none';
                    iframe.src = 'about:blank';
                    window.location.reload();
                };
            }
            window.onclick = e => {
                if (e.target === modal)
                    closeBtn.onclick();
            };

            function abrirModalAdjuntar(id) {
                document.getElementById('inputDocId').value = id;
                document.getElementById('modalAdjuntar').style.display = 'flex';
            }
            function cerrarModalAdjuntar() {
                document.getElementById('modalAdjuntar').style.display = 'none';
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
            function toggleRespondido(id) {
                fetch('marcarRespondido.jsp?id=' + id, {method: 'POST'})
                        .then(r => r.ok ? location.reload() : alert('Error al actualizar estado'));
            }
            function vistaPreviaSeleccionado() {
                const id = getSelectedId();
                if (!id)
                    return alert('Selecciona un documento.');
                iframe.src = ctx + '/vistaPreviaDocumento.jsp?id=' + id;
                modal.style.display = 'flex';
                iframe.onerror = () => window.location.href = ctx + '/descargarDocumento.jsp?id=' + id;
            }
            function editarSeleccionado() {
                const id = getSelectedId();
                if (!id)
                    return alert('Selecciona un documento.');
                location.href = 'editarDocumento.jsp?id=' + id;
            }
            function eliminarSeleccionado() {
                const id = getSelectedId();
                if (!id)
                    return alert('Selecciona un documento.');
                if (confirm('¿Eliminar?')) {
                    document.getElementById('deleteIdInput').value = id;
                    document.getElementById('deleteForm').submit();
                }
            }
            function descargarSeleccionado() {
                const id = getSelectedId();
                if (!id)
                    return alert('Selecciona un documento.');
                window.open(ctx + '/descargarDocumento.jsp?id=' + id, '_blank');
            }
        </script>
    </body>
</html>
