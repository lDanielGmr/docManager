<%@ page import="
         java.net.URLEncoder,
         java.sql.Connection,
         java.sql.PreparedStatement,
         java.sql.ResultSet,
         java.util.HashSet,
         java.util.HashMap,
         java.util.Set,
         java.util.List,
         java.util.ArrayList,
         java.util.Map,
         clasesGenericas.Usuario,
         clasesGenericas.Menu,
         clasesGenericas.RolPermiso,
         clasesGenericas.Permiso,
         ConexionBD.conexionBD
         " %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>


<%
    // -------------------------
    // BLOQUE AJAX: autocompletar
    String ajaxField = request.getParameter("ajaxField");
    String termParam = request.getParameter("term");
    if (ajaxField != null && termParam != null) {
        Object ua = session.getAttribute("user");
        Usuario usuarioAJAX = ua instanceof Usuario
                ? (Usuario) ua
                : ua instanceof String
                        ? Usuario.findByUsuario((String) ua)
                        : null;
        if (usuarioAJAX == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json; charset=UTF-8");
            out.write("[]");
            return;
        }
        int userIdAJAX = usuarioAJAX.getId();
        termParam = termParam.trim();
        String termLike = "%" + termParam + "%";
        response.setContentType("application/json; charset=UTF-8");
        List<String> simpleResults = new ArrayList<>();
        class Item {

            String titulo;
            String tipo;
            boolean esPlantilla;
        }
        List<Item> complexResults = new ArrayList<>();
        if ("titulo".equals(ajaxField)) {
            String sql
                    = "SELECT DISTINCT d.titulo, d.tipo, d.es_plantilla "
                    + "FROM documento d "
                    + "WHERE IFNULL(d.eliminado,0)=0 "
                    + "  AND d.titulo COLLATE utf8mb4_unicode_ci LIKE ? "
                    + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                    + "ORDER BY d.titulo ASC LIMIT 10";
            try (Connection conn = conexionBD.conectar(); PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, termLike);
                pst.setInt(2, userIdAJAX);
                pst.setInt(3, userIdAJAX);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        Item it = new Item();
                        it.titulo = rs.getString("titulo");
                        it.tipo = rs.getString("tipo");
                        it.esPlantilla = rs.getBoolean("es_plantilla");
                        complexResults.add(it);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            StringBuilder sb = new StringBuilder();
            sb.append("[");
            for (int i = 0; i < complexResults.size(); i++) {
                Item it = complexResults.get(i);
                String tit = it.titulo != null ? it.titulo.replace("\"", "\\\"") : "";
                String tip = it.tipo != null ? it.tipo.replace("\"", "\\\"") : "";
                sb.append("{");
                sb.append("\"titulo\":\"").append(tit).append("\",");
                sb.append("\"tipo\":\"").append(tip).append("\",");
                sb.append("\"esPlantilla\":").append(it.esPlantilla);
                sb.append("}");
                if (i < complexResults.size() - 1) {
                    sb.append(",");
                }
            }
            sb.append("]");
            out.write(sb.toString());
            return;
        } else if ("numeroRadicado".equals(ajaxField)) {
            String sql
                    = "SELECT DISTINCT d.numero_radicado "
                    + "FROM documento d "
                    + "WHERE IFNULL(d.eliminado,0)=0 "
                    + "  AND d.numero_radicado COLLATE utf8mb4_unicode_ci LIKE ? "
                    + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                    + "ORDER BY d.numero_radicado ASC LIMIT 10";
            try (Connection conn = conexionBD.conectar(); PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, termLike);
                pst.setInt(2, userIdAJAX);
                pst.setInt(3, userIdAJAX);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        String nr = rs.getString("numero_radicado");
                        if (nr != null) {
                            simpleResults.add(nr);
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            StringBuilder sb = new StringBuilder();
            sb.append("[");
            for (int i = 0; i < simpleResults.size(); i++) {
                String s = simpleResults.get(i).replace("\"", "\\\"");
                sb.append("\"").append(s).append("\"");
                if (i < simpleResults.size() - 1) {
                    sb.append(",");
                }
            }
            sb.append("]");
            out.write(sb.toString());
            return;
        } else {
            out.write("[]");
            return;
        }
    }
    // -------------------------
%>

<%@ include file="menu.jsp" %>

<%
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
    boolean puedeBuscar = permisoIds.contains(permisosMap.get("ver_busquedas"));
    boolean puedeRestaurar = permisoIds.contains(permisosMap.get("restaurar_documento"));

    String nombreParam = request.getParameter("nombre");
    if (nombreParam != null) {
        nombreParam = nombreParam.trim();
    } else {
        nombreParam = "";
    }

    String numeroRadicadoParam2 = request.getParameter("numeroRadicado");
    if (numeroRadicadoParam2 != null) {
        numeroRadicadoParam2 = numeroRadicadoParam2.trim();
    }

    boolean chkNumeroRadicado2 = "on".equals(request.getParameter("chkNumeroRadicado"));
    boolean chkTitulo2 = "on".equals(request.getParameter("chkTitulo"));

    // NUEVO: detectar exact match
    boolean exactMatch = "on".equals(request.getParameter("exact"));

    final int PAGE_SIZE = 6;
    int currentPage = 1;
    try {
        currentPage = Integer.parseInt(request.getParameter("page"));
    } catch (Exception ignore) {
    }
    if (currentPage < 1) {
        currentPage = 1;
    }

    int totalRows = 0;
    if (puedeBuscar) {
        if (chkNumeroRadicado2 && numeroRadicadoParam2 != null && !numeroRadicadoParam2.isEmpty()) {
            String countSql;
            if (exactMatch) {
                countSql = "SELECT COUNT(*) FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.numero_radicado COLLATE utf8mb4_unicode_ci = ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?)";
            } else {
                countSql = "SELECT COUNT(*) FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.numero_radicado LIKE ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?)";
            }
            try (Connection con = conexionBD.conectar(); PreparedStatement pst = con.prepareStatement(countSql)) {
                if (exactMatch) {
                    pst.setString(1, numeroRadicadoParam2);
                } else {
                    pst.setString(1, "%" + numeroRadicadoParam2 + "%");
                }
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    if (rs.next()) {
                        totalRows = rs.getInt(1);
                    }
                }
            } catch (Exception e) {
                totalRows = 0;
            }
        } else if (chkTitulo2 && !nombreParam.isEmpty()) {
            String countSql;
            if (exactMatch) {
                countSql = "SELECT COUNT(*) FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.titulo COLLATE utf8mb4_unicode_ci = ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?)";
            } else {
                countSql = "SELECT COUNT(*) FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.titulo LIKE ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?)";
            }
            try (Connection con = conexionBD.conectar(); PreparedStatement pst = con.prepareStatement(countSql)) {
                if (exactMatch) {
                    pst.setString(1, nombreParam);
                } else {
                    pst.setString(1, "%" + nombreParam + "%");
                }
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    if (rs.next()) {
                        totalRows = rs.getInt(1);
                    }
                }
            } catch (Exception e) {
                totalRows = 0;
            }
        }
    }
    int totalPages = Math.max(1, (int) Math.ceil((double) totalRows / PAGE_SIZE));
    if (currentPage > totalPages) {
        currentPage = totalPages;
    }

    int windowSize = 5;
    int startPage = Math.max(1, currentPage - windowSize / 2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) {
        startPage = Math.max(1, endPage - windowSize + 1);
    }

    List<Map<String, Object>> docs = new ArrayList<>();
    if (puedeBuscar) {
        if (chkNumeroRadicado2 && numeroRadicadoParam2 != null && !numeroRadicadoParam2.isEmpty()) {
            String sqlDocs;
            if (exactMatch) {
                sqlDocs = "SELECT id, titulo, numero_radicado FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.numero_radicado COLLATE utf8mb4_unicode_ci = ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                        + "ORDER BY d.fecha_creacion DESC LIMIT ?, ?";
            } else {
                sqlDocs = "SELECT id, titulo, numero_radicado FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.numero_radicado LIKE ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                        + "ORDER BY d.fecha_creacion DESC LIMIT ?, ?";
            }
            try (Connection con = conexionBD.conectar(); PreparedStatement pst = con.prepareStatement(sqlDocs)) {
                if (exactMatch) {
                    pst.setString(1, numeroRadicadoParam2);
                } else {
                    pst.setString(1, "%" + numeroRadicadoParam2 + "%");
                }
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                pst.setInt(4, (currentPage - 1) * PAGE_SIZE);
                pst.setInt(5, PAGE_SIZE);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> d = new HashMap<>();
                        d.put("id", rs.getInt("id"));
                        d.put("titulo", rs.getString("titulo"));
                        d.put("numero_radicado", rs.getString("numero_radicado"));
                        docs.add(d);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else if (chkTitulo2 && !nombreParam.isEmpty()) {
            String sqlDocs;
            if (exactMatch) {
                sqlDocs = "SELECT id, titulo, numero_radicado FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.titulo COLLATE utf8mb4_unicode_ci = ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                        + "ORDER BY d.fecha_creacion DESC LIMIT ?, ?";
            } else {
                sqlDocs = "SELECT id, titulo, numero_radicado FROM documento d "
                        + "WHERE IFNULL(d.eliminado,0)=0 AND d.titulo LIKE ? "
                        + "  AND (d.es_plantilla=1 OR d.radicado_a=? OR d.recibido_por=?) "
                        + "ORDER BY d.fecha_creacion DESC LIMIT ?, ?";
            }
            try (Connection con = conexionBD.conectar(); PreparedStatement pst = con.prepareStatement(sqlDocs)) {
                if (exactMatch) {
                    pst.setString(1, nombreParam);
                } else {
                    pst.setString(1, "%" + nombreParam + "%");
                }
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                pst.setInt(4, (currentPage - 1) * PAGE_SIZE);
                pst.setInt(5, PAGE_SIZE);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> d = new HashMap<>();
                        d.put("id", rs.getInt("id"));
                        d.put("titulo", rs.getString("titulo"));
                        d.put("numero_radicado", rs.getString("numero_radicado"));
                        docs.add(d);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    String docIdStr = request.getParameter("docId");
    Integer docId = null;
    List<Map<String, Object>> versiones = new ArrayList<>();
    if (docIdStr != null) {
        try {
            docId = Integer.valueOf(docIdStr);
        } catch (NumberFormatException ignore) {
        }
    }
    if (docId != null) {
        String sqlVer
                = "SELECT id, numero, DATE(timestamp) AS fecha, ruta "
                + "FROM version WHERE doc_id=? ORDER BY numero ASC";
        try (Connection con = conexionBD.conectar(); PreparedStatement pst = con.prepareStatement(sqlVer)) {
            pst.setInt(1, docId);
            try (ResultSet rs = pst.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> v = new HashMap<>();
                    v.put("id", rs.getInt("id"));
                    v.put("numero", "V" + rs.getInt("numero"));
                    v.put("fecha", rs.getDate("fecha"));
                    v.put("ruta", rs.getString("ruta"));
                    versiones.add(v);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    String contexto = request.getContextPath();
%>
<%  // ——— PAGINACIÓN DE VERSIONES ———
    final int VERSIONS_PAGE_SIZE = 5;
    int versionsPage = 1;
    try {
        versionsPage = Integer.parseInt(request.getParameter("vpage"));
    } catch (Exception ignore) {
    }
    if (versionsPage < 1) {
        versionsPage = 1;
    }

    // Contar total de versiones
    int totalVersions = 0;
    if (docId != null) {
        try (Connection c = conexionBD.conectar(); PreparedStatement cnt = c.prepareStatement(
                "SELECT COUNT(*) FROM version WHERE doc_id = ?"
        )) {
            cnt.setInt(1, docId);
            try (ResultSet rs = cnt.executeQuery()) {
                if (rs.next()) {
                    totalVersions = rs.getInt(1);
                }
            }
        }
    }
    int totalVPages = Math.max(1,
            (int) Math.ceil((double) totalVersions / VERSIONS_PAGE_SIZE));
    if (versionsPage > totalVPages) {
        versionsPage = totalVPages;
    }

    // Cargar sólo las versiones de esta página
    versiones.clear();
    if (docId != null) {
        try (Connection c = conexionBD.conectar(); PreparedStatement ps = c.prepareStatement(
                "SELECT id, numero, DATE(timestamp) AS fecha, ruta "
                + "FROM version WHERE doc_id=? ORDER BY numero ASC "
                + "LIMIT ? OFFSET ?"
        )) {
            ps.setInt(1, docId);
            ps.setInt(2, VERSIONS_PAGE_SIZE);
            ps.setInt(3, (versionsPage - 1) * VERSIONS_PAGE_SIZE);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> v = new HashMap<>();
                    v.put("id", rs.getInt("id"));
                    v.put("numero", "V" + rs.getInt("numero"));
                    v.put("fecha", rs.getDate("fecha"));
                    v.put("ruta", rs.getString("ruta"));
                    versiones.add(v);
                }
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>Versiones de Documento</title>
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
                margin: 0;
                padding: 0;
                height: 100%;
                overflow-y: auto;
                background: url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
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
                padding: 16px;
                border-radius: 4px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                color: #000;
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
                position: relative;
            }
            .search-group {
                display: flex;
                align-items: center;
                gap: 4px;
                position: relative;
            }
            .search-group input[type="text"] {
                border: 1px solid #ccc;
                font-size: 0.9rem;
                padding: 6px 10px;
                border-radius: 4px;
            }
            .search-group .autocomplete-items {
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                background-color: #fff;
                border: 1px solid #ccc;
                z-index: 9999;
                max-height: 200px;
                overflow-y: auto;
            }
            .search-group .autocomplete-items div {
                padding: 8px 10px;
                cursor: pointer;
                font-size: 0.9rem;
                color: #333;
            }
            .search-group .autocomplete-items div:hover {
                background-color: #f0f0f0;
            }
            .toolbar button {
                font-size: 0.9rem;
                padding: 6px 10px;
                border-radius: 4px;
                background: var(--accent);
                color: #fff;
                border: none;
                cursor: pointer;
            }
            .toolbar button:hover {
                opacity: 0.9;
            }
            .docs-table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 16px;
            }
            .docs-table th, .docs-table td {
                padding: 10px 6px;
                border: 1px solid #000;
                font-size: 0.85rem;
                word-break: break-word;
                color: #000;
            }
            .docs-table th {
                background: #f5f5f5;
                text-transform: uppercase;
            }
            .docs-table tr:hover {
                background: #fafafa;
                cursor: pointer;
            }
            .docs-table tr.selected {
                background: #e6f7ff !important;
            }
            .docs-table button {
                font-size: 1rem;
                padding: 8px 14px;
                border-radius: 4px;
                background: var(--accent);
                color: #fff;
                border: none;
                cursor: pointer;
            }
            .docs-table button:hover {
                opacity: 0.9;
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
                background: var(--accent);
                color: #fff;
                border: none;
                cursor: pointer;
            }
            .actions button:hover {
                opacity: 0.9;
            }
            .pagination {
                display: flex;
                justify-content: center;
                align-items: center;
                gap: 8px;
                margin-top: 20px;
                list-style: none;
                padding: 0;
                flex-wrap: wrap;
            }
            .pagination li a {
                display: inline-block;
                background: var(--accent);
                color: #fff;
                text-decoration: none;
                padding: 8px 12px;
                font-size: 0.9rem;
                border-radius: 4px;
                min-width: 36px;
                text-align: center;
                transition: background 0.3s ease;
            }
            .pagination li a:hover:not(.disabled) {
                background: #0056b3;
            }
            .pagination li.disabled a {
                background: #ccc;
                color: #666;
                pointer-events: none;
                cursor: default;
            }
            .pagination li.active a {
                background: #004085;
                font-weight: bold;
                border: 2px solid #fff;
            }
        </style>
    </head>
    <body>
        <div class="menu-container">
            <div class="menu-box">
                <h2><i class="fas fa-file-alt"></i> Versiones de Documento</h2>

                <% if (puedeBuscar) {%>
                <form id="searchForm" action="versionDocumento.jsp" method="get" class="toolbar" autocomplete="off">
                    <div class="search-group">
                        <input id="chkNumeroRadicado" type="checkbox" name="chkNumeroRadicado" <%= chkNumeroRadicado2 ? "checked" : ""%> >
                        <label for="chkNumeroRadicado">Por número radicado</label>
                        <input
                            id="inputNumeroRadicado"
                            type="text"
                            name="numeroRadicado"
                            placeholder="Escribe número radicado..."
                            value="<%= numeroRadicadoParam2 != null ? numeroRadicadoParam2 : ""%>"
                            autocomplete="off"
                            >
                        <div id="autocomplete-list-numero" class="autocomplete-items"></div>
                    </div>
                    <div class="search-group" style="flex:1;">
                        <input id="chkTitulo" type="checkbox" name="chkTitulo" <%= chkTitulo2 ? "checked" : ""%> >
                        <label for="chkTitulo">Por título</label>
                        <input
                            id="inputTitulo"
                            type="text"
                            name="nombre"
                            placeholder="Escribe título..."
                            value="<%= nombreParam%>"
                            autocomplete="off"
                            >
                        <div id="autocomplete-list-titulo" class="autocomplete-items"></div>
                    </div>

                    <input type="hidden" id="exactMatchField" name="exact" value="">

                    <button type="submit">
                        <i class="fas fa-search"></i> Buscar
                    </button>
                    <button type="button" onclick="limpiar()">
                        <i class="fas fa-eraser"></i> Limpiar
                    </button>
                </form>
                <% } %>

                <div class="section-box">
                    <h3>Documentos encontrados</h3>
                    <table class="docs-table">
                        <thead>
                            <tr>
                                <th>Número radicado</th>
                                <th>Documento</th>
                                <th>Seleccionar</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (!puedeBuscar) { %>
                            <tr>
                                <td colspan="3" class="mensaje">No tienes permiso para buscar documentos.</td>
                            </tr>
                            <% } else if (!chkNumeroRadicado2 && !chkTitulo2) { %>
                            <tr>
                                <td colspan="3" class="mensaje">Selecciona un filtro y escribe término.</td>
                            </tr>
                            <% } else if (docs.isEmpty()) { %>
                            <tr>
                                <td colspan="3" class="mensaje">No hay documentos que coincidan.</td>
                            </tr>
                            <% } else {
                                for (Map<String, Object> d : docs) {%>
                            <tr>
                                <td><%= d.get("numero_radicado") != null ? d.get("numero_radicado") : ""%></td>
                                <td><%= d.get("titulo")%></td>
                                <td>
                                    <button type="button" onclick="mostrarVersiones(<%= d.get("id")%>)">
                                        <i class="fas fa-history"></i> Versiones
                                    </button>
                                </td>
                            </tr>
                            <%   }
                                } %>
                        </tbody>
                    </table>

                    <% if (puedeBuscar
                                && ((chkNumeroRadicado2 && numeroRadicadoParam2 != null && !numeroRadicadoParam2.isEmpty())
                                || (chkTitulo2 && !nombreParam.isEmpty()))
                                && totalPages > 1) {
                            String extraParam = "";
                            if (chkNumeroRadicado2 && numeroRadicadoParam2 != null && !numeroRadicadoParam2.isEmpty()) {
                                extraParam += "&chkNumeroRadicado=on&numeroRadicado=" + URLEncoder.encode(numeroRadicadoParam2, "UTF-8");
                            }
                            if (chkTitulo2 && !nombreParam.isEmpty()) {
                                extraParam += "&chkTitulo=on&nombre=" + URLEncoder.encode(nombreParam, "UTF-8");
                            }
                    %>
                    <ul class="pagination">
                        <li class="<%= currentPage == 1 ? "disabled" : ""%>">
                            <a href="versionDocumento.jsp?page=1<%= extraParam%>">&laquo;&laquo;</a>
                        </li>
                        <li class="<%= currentPage == 1 ? "disabled" : ""%>">
                            <a href="versionDocumento.jsp?page=<%= currentPage - 1%><%= extraParam%>">&laquo;</a>
                        </li>

                        <% for (int p = startPage; p <= endPage; p++) {%>
                        <li class="<%= p == currentPage ? "active" : ""%>">
                            <a href="versionDocumento.jsp?page=<%= p%><%= extraParam%>"><%= p%></a>
                        </li>
                        <% }%>

                        <li class="<%= currentPage == totalPages ? "disabled" : ""%>">
                            <a href="versionDocumento.jsp?page=<%= currentPage + 1%><%= extraParam%>">&rsaquo;</a>
                        </li>
                        <li class="<%= currentPage == totalPages ? "disabled" : ""%>">
                            <a href="versionDocumento.jsp?page=<%= totalPages%><%= extraParam%>">&raquo;&raquo;</a>
                        </li>
                    </ul>
                    <% } %>
                </div>

                <div class="section-box">
                    <h3>Versiones del documento</h3>
                    <table class="docs-table">
                        <thead>
                            <tr>
                                <th>Numero</th>
                                <th>Versión</th>
                                <th>Fecha</th>
                                <th>Ruta</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (docId == null) { %>
                            <tr>
                                <td colspan="5" class="mensaje">Selecciona un documento.</td>
                            </tr>
                            <% } else if (versiones.isEmpty()) { %>
                            <tr>
                                <td colspan="5" class="mensaje">Sin versiones.</td>
                            </tr>
                            <% } else {
                                int j = 1;
                                for (Map<String, Object> v : versiones) {%>
                            <tr>
                                <td><%= j++%></td>
                                <td><%= v.get("numero")%></td>
                                <td><%= v.get("fecha")%></td>
                                <td><%= v.get("ruta")%></td>
                                <td class="actions">
                                    <% if (puedeRestaurar) {%>
                                    <button type="button" onclick="restaurar(<%= v.get("id")%>)">
                                        <i class="fas fa-undo"></i> Restaurar
                                    </button>
                                    <% }%>
                                    <button type="button" onclick="descargarVer(<%= v.get("id")%>)">
                                        <i class="fas fa-download"></i> Descargar
                                    </button>
                                </td>
                            </tr>
                            <%   }
                                } %>
                        </tbody>
                    </table>
                </div>
                <% if (totalVPages > 1) {%>
                <ul class="pagination">
                    <li class="<%= versionsPage == 1 ? "disabled" : ""%>">
                        <a href="versionDocumento.jsp?docId=<%=docId%>&vpage=1">&laquo;&laquo;</a>
                    </li>
                    <li class="<%= versionsPage == 1 ? "disabled" : ""%>">
                        <a href="versionDocumento.jsp?docId=<%=docId%>&vpage=<%=versionsPage - 1%>">&laquo;</a>
                    </li>
                    <% for (int vp = 1; vp <= totalVPages; vp++) {%>
                    <li class="<%= vp == versionsPage ? "active" : ""%>">
                        <a href="versionDocumento.jsp?docId=<%=docId%>&vpage=<%=vp%>"><%=vp%></a>
                    </li>
                    <% }%>
                    <li class="<%= versionsPage == totalVPages ? "disabled" : ""%>">
                        <a href="versionDocumento.jsp?docId=<%=docId%>&vpage=<%=versionsPage + 1%>">&rsaquo;</a>
                    </li>
                    <li class="<%= versionsPage == totalVPages ? "disabled" : ""%>">
                        <a href="versionDocumento.jsp?docId=<%=docId%>&vpage=<%=totalVPages%>">&raquo;&raquo;</a>
                    </li>
                </ul>
                <% }%>

            </div>
        </div>

        <script>
            const contexto = '<%= contexto%>';

            function fetchSuggestions(field, term) {
                if (!term || term.length < 2) {
                    closeList(field);
                    return;
                }
                const url = contexto + '/versionDocumento.jsp?ajaxField=' + encodeURIComponent(field)
                        + '&term=' + encodeURIComponent(term);
                fetch(url)
                        .then(res => {
                            if (!res.ok) {
                                return Promise.reject('status ' + res.status);
                            }
                            return res.json();
                        })
                        .then(data => {
                            let listContainer = null;
                            if (field === 'titulo') {
                                listContainer = document.getElementById("autocomplete-list-titulo");
                            } else if (field === 'numeroRadicado') {
                                listContainer = document.getElementById("autocomplete-list-numero");
                            }
                            if (!listContainer) {
                                return;
                            }
                            listContainer.innerHTML = "";
                            if (!Array.isArray(data) || data.length === 0) {
                                return;
                            }
                            data.forEach(itemObj => {
                                const option = document.createElement("div");
                                let texto;
                                if (field === 'titulo') {
                                    texto = itemObj.titulo;
                                    if (itemObj.tipo && itemObj.tipo.trim().length > 0) {
                                        texto += " (" + itemObj.tipo + ")";
                                    }
                                    if (itemObj.esPlantilla) {
                                        texto += " (plantilla)";
                                    }
                                } else {
                                    texto = itemObj;
                                }
                                option.textContent = texto;
                                option.addEventListener("click", function () {
                                    const form = document.getElementById("searchForm");
                                    if (field === 'titulo') {
                                        document.getElementById("inputTitulo").value = itemObj.titulo;
                                        if (form) {
                                            document.getElementById("exactMatchField").value = "on";
                                        }
                                        closeList('titulo');
                                    } else {
                                        document.getElementById("inputNumeroRadicado").value = texto;
                                        if (form) {
                                            document.getElementById("exactMatchField").value = "on";
                                        }
                                        closeList('numeroRadicado');
                                    }
                                    if (form) {
                                        form.submit();
                                    }
                                });
                                listContainer.appendChild(option);
                            });
                        })
                        .catch(err => {
                        });
            }

            function closeList(field) {
                if (field === 'titulo') {
                    const cont = document.getElementById("autocomplete-list-titulo");
                    if (cont)
                        cont.innerHTML = "";
                } else if (field === 'numeroRadicado') {
                    const cont2 = document.getElementById("autocomplete-list-numero");
                    if (cont2)
                        cont2.innerHTML = "";
                }
            }

            document.addEventListener("DOMContentLoaded", function () {
                const inputTitulo = document.getElementById("inputTitulo");
                const inputNumero = document.getElementById("inputNumeroRadicado");
                const chkTitulo = document.getElementById("chkTitulo");
                const chkNumeroRadicado = document.getElementById("chkNumeroRadicado");

                function activateOnly(chk) {
                    [chkTitulo, chkNumeroRadicado].forEach(cb => {
                        if (cb && cb !== chk)
                            cb.checked = false;
                    });
                    if (chk)
                        chk.checked = true;
                    const exactFld = document.getElementById("exactMatchField");
                    if (exactFld)
                        exactFld.value = "";
                }

                if (chkTitulo) {
                    chkTitulo.addEventListener("change", () => {
                        if (chkTitulo.checked)
                            activateOnly(chkTitulo);
                    });
                }
                if (chkNumeroRadicado) {
                    chkNumeroRadicado.addEventListener("change", () => {
                        if (chkNumeroRadicado.checked)
                            activateOnly(chkNumeroRadicado);
                    });
                }

                if (inputTitulo) {
                    inputTitulo.addEventListener("input", function () {
                        activateOnly(chkTitulo);
                        fetchSuggestions('titulo', this.value.trim());
                    });
                    inputTitulo.addEventListener("blur", function () {
                        setTimeout(() => closeList('titulo'), 100);
                    });
                    inputTitulo.addEventListener("keydown", function (e) {
                        if (e.key === 'Enter') {
                            e.preventDefault();
                            activateOnly(chkTitulo);
                            document.getElementById("exactMatchField").value = "";
                            if (this.form)
                                this.form.submit();
                        }
                    });
                }
                if (inputNumero) {
                    inputNumero.addEventListener("input", function () {
                        activateOnly(chkNumeroRadicado);
                        fetchSuggestions('numeroRadicado', this.value.trim());
                    });
                    inputNumero.addEventListener("blur", function () {
                        setTimeout(() => closeList('numeroRadicado'), 100);
                    });
                    inputNumero.addEventListener("keydown", function (e) {
                        if (e.key === 'Enter') {
                            e.preventDefault();
                            activateOnly(chkNumeroRadicado);
                            document.getElementById("exactMatchField").value = "";
                            if (this.form)
                                this.form.submit();
                        }
                    });
                }
            });

            function limpiar() {
                window.location = '<%= contexto%>' + '/versionDocumento.jsp';
            }

            function mostrarVersiones(id) {
                let params = [];
                if (document.getElementById("chkNumeroRadicado")?.checked) {
                    const val = document.getElementById("inputNumeroRadicado").value.trim();
                    if (val) {
                        params.push("chkNumeroRadicado=on");
                        params.push("numeroRadicado=" + encodeURIComponent(val));
                    }
                } else if (document.getElementById("chkTitulo")?.checked) {
                    const val = document.getElementById("inputTitulo").value.trim();
                    if (val) {
                        params.push("chkTitulo=on");
                        params.push("nombre=" + encodeURIComponent(val));
                    }
                }
                let url = '<%= contexto%>' + '/versionDocumento.jsp?docId=' + id;
                if (params.length) {
                    url += '&' + params.join('&');
                }
                window.location = url;
            }

            function restaurar(vid) {
                window.location = '<%= contexto%>' + '/restaurarVersion.jsp?vid=' + vid;
            }

            function descargarVer(vid) {
                window.location = '<%= contexto%>' + '/descargarDocumento.jsp?vid=' + vid;
            }
        </script>
    </body>
</html>
