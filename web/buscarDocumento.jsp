<%@ page import="
         java.net.URLEncoder,
         java.sql.Connection,
         java.sql.PreparedStatement,
         java.sql.ResultSet,
         java.util.ArrayList,
         java.util.HashMap,
         java.util.List,
         java.util.Map,
         clasesGenericas.Usuario,
         ConexionBD.conexionBD
         " %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>

<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    int userId = usuarioSesion.getId();


    String numeroRadicadoParam = request.getParameter("numeroRadicado");
    String tituloParam = request.getParameter("titulo");
    String fechaDesdeParam = request.getParameter("fechaDesde");
    String fechaHastaParam = request.getParameter("fechaHasta");
    String tipoParam = request.getParameter("tipo");
    String etiquetaParam = request.getParameter("etiqueta");
    boolean soloPlantillas = "on".equals(request.getParameter("soloPlantillas"));

    boolean exactNumeroRadicado = "on".equals(request.getParameter("exactNumeroRadicado"));
    boolean exactTitulo = "on".equals(request.getParameter("exactTitulo"));
    boolean exactTipo = "on".equals(request.getParameter("exactTipo"));
    boolean exactEtiqueta = "on".equals(request.getParameter("exactEtiqueta"));

    boolean chkNumeroRadicado = "on".equals(request.getParameter("chkNumeroRadicado"));
    boolean chkTitulo = "on".equals(request.getParameter("chkTitulo"));
    boolean chkFecha = "on".equals(request.getParameter("chkFecha"));
    boolean chkTipo = "on".equals(request.getParameter("chkTipo"));
    boolean chkEtiqueta = "on".equals(request.getParameter("chkEtiqueta"));

    boolean filtroActivo = soloPlantillas
            || (chkNumeroRadicado && numeroRadicadoParam != null && !numeroRadicadoParam.trim().isEmpty())
            || (chkTitulo && tituloParam != null && !tituloParam.trim().isEmpty())
            || (chkFecha && ((fechaDesdeParam != null && !fechaDesdeParam.isEmpty()) || (fechaHastaParam != null && !fechaHastaParam.isEmpty())))
            || (chkTipo && tipoParam != null && !tipoParam.trim().isEmpty())
            || (chkEtiqueta && etiquetaParam != null && !etiquetaParam.trim().isEmpty());

    final int PAGE_SIZE = 10;
    int currentPage = 1;
    String sp = request.getParameter("page");
    if (sp != null) {
        try {
            currentPage = Integer.parseInt(sp);
        } catch (NumberFormatException ignore) {
        }
    }
    if (currentPage < 1) {
        currentPage = 1;
    }

    int totalRows = 0;
    int totalPages = 1;

    if (filtroActivo) {
        StringBuilder countSb = new StringBuilder(
                "SELECT COUNT(DISTINCT d.id) "
                + "FROM documento d "
                + "LEFT JOIN docu_etiqueta de ON d.id = de.doc_id "
                + "LEFT JOIN etiqueta e ON de.etq_id = e.id "
                + "WHERE IFNULL(d.eliminado,0) = 0"
        );
        List<Object> countParams = new ArrayList<>();

        if (soloPlantillas) {
            countSb.append(" AND d.es_plantilla = TRUE");
        } else {
            // Mostrar plantillas o documentos relacionados al usuario
            countSb.append(" AND (d.es_plantilla = TRUE OR d.radicado_a = ? OR d.recibido_por = ?)");
            countParams.add(userId);
            countParams.add(userId);

            if (chkNumeroRadicado && numeroRadicadoParam != null && !numeroRadicadoParam.trim().isEmpty()) {
                if (exactNumeroRadicado) {
                    countSb.append(" AND d.numero_radicado = ?");
                    countParams.add(numeroRadicadoParam.trim());
                } else {
                    countSb.append(" AND d.numero_radicado LIKE ?");
                    countParams.add("%" + numeroRadicadoParam.trim() + "%");
                }
            }
            if (chkTitulo && tituloParam != null && !tituloParam.trim().isEmpty()) {
                if (exactTitulo) {
                    countSb.append(" AND d.titulo = ?");
                    countParams.add(tituloParam.trim());
                } else {
                    countSb.append(" AND d.titulo LIKE ?");
                    countParams.add("%" + tituloParam.trim() + "%");
                }
            }
            if (chkFecha) {
                if (fechaDesdeParam != null && !fechaDesdeParam.isEmpty()) {
                    countSb.append(" AND d.fecha_creacion >= ?");
                    countParams.add(fechaDesdeParam + " 00:00:00");
                }
                if (fechaHastaParam != null && !fechaHastaParam.isEmpty()) {
                    countSb.append(" AND d.fecha_creacion <= ?");
                    countParams.add(fechaHastaParam + " 23:59:59");
                }
            }
            if (chkTipo && tipoParam != null && !tipoParam.trim().isEmpty()) {
                if (exactTipo) {
                    countSb.append(" AND d.tipo = ?");
                    countParams.add(tipoParam.trim());
                } else {
                    countSb.append(" AND d.tipo LIKE ?");
                    countParams.add("%" + tipoParam.trim() + "%");
                }
            }
            if (chkEtiqueta && etiquetaParam != null && !etiquetaParam.trim().isEmpty()) {
                if (exactEtiqueta) {
                    countSb.append(" AND e.nombre = ?");
                    countParams.add(etiquetaParam.trim());
                } else {
                    countSb.append(" AND e.nombre LIKE ?");
                    countParams.add("%" + etiquetaParam.trim() + "%");
                }
            }
        }

        try (Connection conn = conexionBD.conectar(); PreparedStatement pstCount = conn.prepareStatement(countSb.toString())) {
            for (int i = 0; i < countParams.size(); i++) {
                pstCount.setObject(i + 1, countParams.get(i));
            }
            try (ResultSet rsCount = pstCount.executeQuery()) {
                if (rsCount.next()) {
                    totalRows = rsCount.getInt(1);
                }
            }
        } catch (Exception e) {
            totalRows = 0;
            e.printStackTrace();
        }

        totalPages = Math.max(1, (int) Math.ceil((double) totalRows / PAGE_SIZE));
        if (currentPage > totalPages) {
            currentPage = totalPages;
        }
    }

    List<Map<String, Object>> resultados = new ArrayList<>();
    if (filtroActivo) {
        StringBuilder sbq = new StringBuilder(
                "SELECT d.id, d.titulo, d.numero_radicado, d.tipo, DATE(d.fecha_creacion) AS fecha, d.es_plantilla "
                + "FROM documento d "
                + "LEFT JOIN docu_etiqueta de ON d.id = de.doc_id "
                + "LEFT JOIN etiqueta e ON de.etq_id = e.id "
                + "WHERE IFNULL(d.eliminado,0) = 0"
        );
        List<Object> queryParams = new ArrayList<>();

        if (soloPlantillas) {
            sbq.append(" AND d.es_plantilla = TRUE");
        } else {
            sbq.append(" AND (d.es_plantilla = TRUE OR d.radicado_a = ? OR d.recibido_por = ?)");
            queryParams.add(userId);
            queryParams.add(userId);

            if (chkNumeroRadicado && numeroRadicadoParam != null && !numeroRadicadoParam.trim().isEmpty()) {
                if (exactNumeroRadicado) {
                    sbq.append(" AND d.numero_radicado = ?");
                    queryParams.add(numeroRadicadoParam.trim());
                } else {
                    sbq.append(" AND d.numero_radicado LIKE ?");
                    queryParams.add("%" + numeroRadicadoParam.trim() + "%");
                }
            }
            if (chkTitulo && tituloParam != null && !tituloParam.trim().isEmpty()) {
                if (exactTitulo) {
                    sbq.append(" AND d.titulo = ?");
                    queryParams.add(tituloParam.trim());
                } else {
                    sbq.append(" AND d.titulo LIKE ?");
                    queryParams.add("%" + tituloParam.trim() + "%");
                }
            }
            if (chkFecha) {
                if (fechaDesdeParam != null && !fechaDesdeParam.isEmpty()) {
                    sbq.append(" AND d.fecha_creacion >= ?");
                    queryParams.add(fechaDesdeParam + " 00:00:00");
                }
                if (fechaHastaParam != null && !fechaHastaParam.isEmpty()) {
                    sbq.append(" AND d.fecha_creacion <= ?");
                    queryParams.add(fechaHastaParam + " 23:59:59");
                }
            }
            if (chkTipo && tipoParam != null && !tipoParam.trim().isEmpty()) {
                if (exactTipo) {
                    sbq.append(" AND d.tipo = ?");
                    queryParams.add(tipoParam.trim());
                } else {
                    sbq.append(" AND d.tipo LIKE ?");
                    queryParams.add("%" + tipoParam.trim() + "%");
                }
            }
            if (chkEtiqueta && etiquetaParam != null && !etiquetaParam.trim().isEmpty()) {
                if (exactEtiqueta) {
                    sbq.append(" AND e.nombre = ?");
                    queryParams.add(etiquetaParam.trim());
                } else {
                    sbq.append(" AND e.nombre LIKE ?");
                    queryParams.add("%" + etiquetaParam.trim() + "%");
                }
            }
        }

        sbq.append(" GROUP BY d.id ORDER BY d.id DESC LIMIT ?, ?");
        int offset = (currentPage - 1) * PAGE_SIZE;
        queryParams.add(offset);
        queryParams.add(PAGE_SIZE);

        try (Connection conn = conexionBD.conectar(); PreparedStatement pst = conn.prepareStatement(sbq.toString())) {
            for (int i = 0; i < queryParams.size(); i++) {
                pst.setObject(i + 1, queryParams.get(i));
            }
            try (ResultSet rs = pst.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("titulo", rs.getString("titulo"));
                    row.put("numero_radicado", rs.getString("numero_radicado"));
                    row.put("tipo", rs.getString("tipo"));
                    row.put("fecha", rs.getDate("fecha"));
                    row.put("es_plantilla", rs.getBoolean("es_plantilla"));
                    resultados.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>Búsqueda Avanzada</title>
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
                background-image: url('<%=request.getContextPath()%>/images/login-bg.jpg');
                background-repeat: no-repeat;
                background-position: center center;
                background-size: cover;
                background-attachment: fixed;
                background-color: var(--bg);
                color: var(--text);
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
                color: #000;
                position: relative;
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
            .toolbar label {
                font-size: 0.9rem;
                margin-right: 4px;
                align-self: center;
                color: #333;
            }
            .toolbar input[type="text"],
            .toolbar input[type="date"] {
                font-size: 0.9rem;
                padding: 6px 10px;
                border-radius: 4px;
                border: 1px solid #ccc;
            }
            .autocomplete-wrapper {
                position: relative;
                display: flex;
                align-items: center;
                gap: 4px;
                flex: 1;
            }
            .autocomplete-wrapper.num-radicado {
                flex: none;
            }
            .toolbar button,
            .actions button,
            .pagination li a {
                font-size: 0.9rem;
                padding: 6px 10px;
                border-radius: 4px;
                background: var(--accent);
                color: #fff;
                border: none;
                cursor: pointer;
            }
            .toolbar button:hover,
            .actions button:hover,
            .pagination li a:hover:not(.disabled) {
                opacity: 0.9;
            }
            .docs-table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 16px;
                background: #fff;
                color: #000;
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
            .suggestions {
                position: absolute;
                top: 100%;
                left: 0;
                width: 100%;
                background: #fff;
                border: 1px solid #ccc;
                border-top: none;
                max-height: 200px;
                overflow-y: auto;
                z-index: 100;
                color: #000;
                display: none;
            }
            .suggestion-item {
                padding: 8px 10px;
                cursor: pointer;
                font-size: 0.9rem;
            }
            .suggestion-item:hover {
                background: #f0f0f0;
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
                <h2>Búsqueda Avanzada</h2>

                <section class="toolbar">
                    <div class="autocomplete-wrapper num-radicado">
                        <input id="chkNumeroRadicado" type="checkbox" name="chkNumeroRadicado" <%= chkNumeroRadicado ? "checked" : ""%>>
                        <label for="chkNumeroRadicado">Por número radicado</label>
                        <input
                            id="inputNumeroRadicado"
                            type="text"
                            name="numeroRadicado"
                            placeholder="Escribe número radicado..."
                            value="<%= numeroRadicadoParam != null ? numeroRadicadoParam : ""%>"
                            autocomplete="off">
                        <div id="suggestionsNumeroRadicado" class="suggestions"></div>
                    </div>

                    <div class="autocomplete-wrapper">
                        <input id="chkTitulo" type="checkbox" name="chkTitulo" <%= chkTitulo ? "checked" : ""%>>
                        <label for="chkTitulo">Por título</label>
                        <input
                            id="inputTitulo"
                            type="text"
                            name="titulo"
                            placeholder="Escribe título..."
                            value="<%= tituloParam != null ? tituloParam : ""%>"
                            autocomplete="off">
                        <div id="suggestionsTitulo" class="suggestions"></div>
                    </div>

                    <div class="autocomplete-wrapper" style="flex: none;">
                        <input id="chkFecha" type="checkbox" name="chkFecha" <%= chkFecha ? "checked" : ""%>>
                        <label for="chkFecha">Por fecha</label>
                        <label for="fechaDesde">Desde:</label>
                        <input
                            id="fechaDesde"
                            type="date"
                            name="fechaDesde"
                            value="<%= fechaDesdeParam != null ? fechaDesdeParam : ""%>">
                        <label for="fechaHasta">Hasta:</label>
                        <input
                            id="fechaHasta"
                            type="date"
                            name="fechaHasta"
                            value="<%= fechaHastaParam != null ? fechaHastaParam : ""%>">
                    </div>

                    <div class="autocomplete-wrapper">
                        <input id="chkTipo" type="checkbox" name="chkTipo" <%= chkTipo ? "checked" : ""%>>
                        <label for="chkTipo">Por tipo</label>
                        <input
                            id="inputTipo"
                            type="text"
                            name="tipo"
                            placeholder="Escribe tipo..."
                            value="<%= tipoParam != null ? tipoParam : ""%>"
                            autocomplete="off">
                        <div id="suggestionsTipo" class="suggestions"></div>
                    </div>

                    <div class="autocomplete-wrapper">
                        <input id="chkEtiqueta" type="checkbox" name="chkEtiqueta" <%= chkEtiqueta ? "checked" : ""%>>
                        <label for="chkEtiqueta">Por etiqueta</label>
                        <input
                            id="inputEtiqueta"
                            type="text"
                            name="etiqueta"
                            placeholder="Escribe etiqueta..."
                            value="<%= etiquetaParam != null ? etiquetaParam : ""%>"
                            autocomplete="off">
                        <div id="suggestionsEtiqueta" class="suggestions"></div>
                    </div>

                    <div style="display: flex; align-items: center; gap: 4px; flex: none;">
                        <input
                            id="chkSoloPlantillas"
                            type="checkbox"
                            name="soloPlantillas"
                            <%= soloPlantillas ? "checked" : ""%>>
                        <label for="chkSoloPlantillas">Sólo plantillas</label>
                    </div>

                    <button id="btnBuscar">
                        <i class="fas fa-search"></i> Buscar
                    </button>
                    <button id="btnLimpiar">
                        <i class="fas fa-eraser"></i> Limpiar
                    </button>
                </section>

                <table class="docs-table" id="tablaDocs">
                    <thead>
                        <tr>
                            <th>Número radicado</th>
                            <th>Documento</th>
                            <th>Tipo</th>
                            <th>Fecha</th>
                            <th>Plantilla</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (!filtroActivo) { %>
                        <% } else if (resultados.isEmpty()) { %>
                        <tr>
                            <td colspan="6" style="text-align: center;">No se encontraron documentos</td>
                        </tr>
                        <% } else {
                            for (Map<String, Object> d : resultados) { %>
                        <tr>
                            <td><%= d.get("numero_radicado") != null ? d.get("numero_radicado") : ""%></td>
                            <td><%= d.get("titulo")%></td>
                            <td><%= d.get("tipo")%></td>
                            <td><%= d.get("fecha")%></td>
                            <td><%= ((Boolean) d.get("es_plantilla")) ? "Sí" : "No"%></td>
                            <td class="actions">
                                <button onclick="ver(<%= d.get("id")%>)">
                                    <i class="fas fa-eye"></i> Ver
                                </button>
                                <button onclick="descargar(<%= d.get("id")%>)">
                                    <i class="fas fa-download"></i> Descargar
                                </button>
                                <!-- Botón Editar siempre visible; elimina si no quieres mostrarlo -->
                                <button onclick="editar(<%= d.get("id")%>)">
                                    <i class="fas fa-edit"></i> Editar
                                </button>
                            </td>
                        </tr>
                        <%   }
                        } %>
                    </tbody>
                </table>

                <% if (filtroActivo && totalPages > 1) { %>
                <ul class="pagination">
                    <%
                        String baseParams = "";
                        if (soloPlantillas) {
                            baseParams += "&soloPlantillas=on";
                        } else {
                            if (chkNumeroRadicado && numeroRadicadoParam != null && !numeroRadicadoParam.trim().isEmpty()) {
                                baseParams += "&chkNumeroRadicado=on&numeroRadicado="
                                        + URLEncoder.encode(numeroRadicadoParam.trim(), "UTF-8");
                                if (exactNumeroRadicado) {
                                    baseParams += "&exactNumeroRadicado=on";
                                }
                            }
                            if (chkTitulo && tituloParam != null && !tituloParam.trim().isEmpty()) {
                                baseParams += "&chkTitulo=on&titulo="
                                        + URLEncoder.encode(tituloParam.trim(), "UTF-8");
                                if (exactTitulo) {
                                    baseParams += "&exactTitulo=on";
                                }
                            }
                            if (chkFecha && fechaDesdeParam != null && !fechaDesdeParam.isEmpty()) {
                                baseParams += "&chkFecha=on&fechaDesde=" + fechaDesdeParam;
                            }
                            if (chkFecha && fechaHastaParam != null && !fechaHastaParam.isEmpty()) {
                                baseParams += "&fechaHasta=" + fechaHastaParam;
                            }
                            if (chkTipo && tipoParam != null && !tipoParam.trim().isEmpty()) {
                                baseParams += "&chkTipo=on&tipo="
                                        + URLEncoder.encode(tipoParam.trim(), "UTF-8");
                                if (exactTipo) {
                                    baseParams += "&exactTipo=on";
                                }
                            }
                            if (chkEtiqueta && etiquetaParam != null && !etiquetaParam.trim().isEmpty()) {
                                baseParams += "&chkEtiqueta=on&etiqueta="
                                        + URLEncoder.encode(etiquetaParam.trim(), "UTF-8");
                                if (exactEtiqueta) {
                                    baseParams += "&exactEtiqueta=on";
                                }
                            }
                        }
                    %>
                    <li class="<%= currentPage == 1 ? "disabled" : ""%>">
                        <a href="?page=1<%= baseParams%>">&laquo;</a>
                    </li>
                    <li class="<%= currentPage == 1 ? "disabled" : ""%>">
                        <a href="?page=<%= currentPage - 1%><%= baseParams%>">&lsaquo;</a>
                    </li>

                    <%
                        int windowSize = 5;
                        int startPage = Math.max(1, currentPage - windowSize / 2);
                        int endPage = Math.min(totalPages, startPage + windowSize - 1);
                        if (endPage - startPage < windowSize - 1) {
                            startPage = Math.max(1, endPage - windowSize + 1);
                        }
                        for (int p = startPage; p <= endPage; p++) {
                    %>
                    <li class="<%= p == currentPage ? "active" : ""%>">
                        <a href="?page=<%= p%><%= baseParams%>"><%= p%></a>
                    </li>
                    <% } %>

                    <li class="<%= currentPage == totalPages ? "disabled" : ""%>">
                        <a href="?page=<%= currentPage + 1%><%= baseParams%>">&rsaquo;</a>
                    </li>
                    <li class="<%= currentPage == totalPages ? "disabled" : ""%>">
                        <a href="?page=<%= totalPages%><%= baseParams%>">&raquo;</a>
                    </li>
                </ul>
                <% } %>
            </div>
        </div>

        <script>
      const ctx = '<%= request.getContextPath()%>';

      const chkNumeroRadicado = document.getElementById('chkNumeroRadicado');
      const inputNumeroRadicado = document.getElementById('inputNumeroRadicado');
      const suggestionsNumeroRadicado = document.getElementById('suggestionsNumeroRadicado');

      const chkTitulo = document.getElementById('chkTitulo');
      const inputTitulo = document.getElementById('inputTitulo');
      const suggestionsTitulo = document.getElementById('suggestionsTitulo');

      const chkFecha = document.getElementById('chkFecha');
      const fechaDesdeInput = document.getElementById('fechaDesde');
      const fechaHastaInput = document.getElementById('fechaHasta');

      const chkTipo = document.getElementById('chkTipo');
      const inputTipo = document.getElementById('inputTipo');
      const suggestionsTipo = document.getElementById('suggestionsTipo');

      const chkEtiqueta = document.getElementById('chkEtiqueta');
      const inputEtiqueta = document.getElementById('inputEtiqueta');
      const suggestionsEtiqueta = document.getElementById('suggestionsEtiqueta');

      const chkSoloPlantillas = document.getElementById('chkSoloPlantillas');

      const btnBuscar = document.getElementById('btnBuscar');
      const btnLimpiar = document.getElementById('btnLimpiar');

      function activateOnly(chk) {
          [chkNumeroRadicado, chkTitulo, chkFecha, chkTipo, chkEtiqueta, chkSoloPlantillas].forEach(cb => {
              if (cb !== chk) {
                  cb.checked = false;
              }
          });
          chk.checked = true;
      }

      chkSoloPlantillas.addEventListener('change', () => {
          if (chkSoloPlantillas.checked) {
              activateOnly(chkSoloPlantillas);
          }
      });
      [chkNumeroRadicado, chkTitulo, chkFecha, chkTipo, chkEtiqueta].forEach(chk => {
          chk.addEventListener('change', () => {
              if (chk.checked) {
                  activateOnly(chk);
              }
          });
      });

      function executeSearch() {
          let qs = [];
          qs.push('page=1');
          if (chkSoloPlantillas.checked) {
              qs.push('soloPlantillas=on');
          } else {
              if (chkNumeroRadicado.checked) {
                  let val = inputNumeroRadicado.value.trim();
                  if (val !== '') {
                      qs.push('chkNumeroRadicado=on');
                      qs.push('numeroRadicado=' + encodeURIComponent(val));
                  }
              }
              if (chkTitulo.checked) {
                  let val = inputTitulo.value.trim();
                  if (val !== '') {
                      qs.push('chkTitulo=on');
                      qs.push('titulo=' + encodeURIComponent(val));
                  }
              }
              if (chkFecha.checked) {
                  const fd = fechaDesdeInput.value;
                  const fh = fechaHastaInput.value;
                  qs.push('chkFecha=on');
                  if (fd)
                      qs.push('fechaDesde=' + encodeURIComponent(fd));
                  if (fh)
                      qs.push('fechaHasta=' + encodeURIComponent(fh));
              }
              if (chkTipo.checked) {
                  let val = inputTipo.value.trim();
                  if (val !== '') {
                      qs.push('chkTipo=on');
                      qs.push('tipo=' + encodeURIComponent(val));
                  }
              }
              if (chkEtiqueta.checked) {
                  let val = inputEtiqueta.value.trim();
                  if (val !== '') {
                      qs.push('chkEtiqueta=on');
                      qs.push('etiqueta=' + encodeURIComponent(val));
                  }
              }
          }
          const queryString = qs.join('&');
          const url = queryString
                  ? ctx + '/buscarDocumento.jsp?' + queryString
                  : ctx + '/buscarDocumento.jsp';
          window.location.href = url;
      }

      function executeSearchExact(field, value) {
          let qs = [];
          qs.push('page=1');
          if (field === 'numeroRadicado') {
              activateOnly(chkNumeroRadicado);
              qs.push('chkNumeroRadicado=on');
              qs.push('numeroRadicado=' + encodeURIComponent(value));
              qs.push('exactNumeroRadicado=on');
          } else if (field === 'titulo') {
              activateOnly(chkTitulo);
              qs.push('chkTitulo=on');
              qs.push('titulo=' + encodeURIComponent(value));
              qs.push('exactTitulo=on');
          } else if (field === 'tipo') {
              activateOnly(chkTipo);
              qs.push('chkTipo=on');
              qs.push('tipo=' + encodeURIComponent(value));
              qs.push('exactTipo=on');
          } else if (field === 'etiqueta') {
              activateOnly(chkEtiqueta);
              qs.push('chkEtiqueta=on');
              qs.push('etiqueta=' + encodeURIComponent(value));
              qs.push('exactEtiqueta=on');
          }
          const queryString = qs.join('&');
          const url = ctx + '/buscarDocumento.jsp?' + queryString;
          window.location.href = url;
      }

      btnBuscar.addEventListener('click', (e) => {
          e.preventDefault();
          executeSearch();
      });
      btnLimpiar.addEventListener('click', (e) => {
          e.preventDefault();
          window.location.href = ctx + '/buscarDocumento.jsp';
      });

      function fetchSuggestions(field, term, suggestionContainer, inputElement) {
          if (!term || term.length < 1) {
              suggestionContainer.style.display = 'none';
              return;
          }
          fetch(ctx + '/buscador.jsp?term=' + encodeURIComponent(term) + '&field=' + encodeURIComponent(field))
                  .then(res => res.json())
                  .then(json => {
                      suggestionContainer.innerHTML = '';
                      if (!Array.isArray(json) || json.length === 0) {
                          const divNo = document.createElement('div');
                          divNo.className = 'suggestion-item';
                          divNo.textContent = 'No hay coincidencias';
                          suggestionContainer.appendChild(divNo);
                          suggestionContainer.style.display = 'block';
                          return;
                      }
                      json.forEach(item => {
                          const div = document.createElement('div');
                          div.className = 'suggestion-item';
                          div.textContent = item;
                          div.addEventListener('click', () => {
                              executeSearchExact(field, item);
                          });
                          suggestionContainer.appendChild(div);
                      });
                      suggestionContainer.style.display = 'block';
                  })
                  .catch(err => {
                      console.error('Error al buscar sugerencias:', err);
                      suggestionContainer.style.display = 'none';
                  });
      }

      inputNumeroRadicado.addEventListener('input', function () {
          activateOnly(chkNumeroRadicado);
          fetchSuggestions('numeroRadicado', this.value.trim(), suggestionsNumeroRadicado, inputNumeroRadicado);
      });
      inputNumeroRadicado.addEventListener('blur', () => {
          setTimeout(() => suggestionsNumeroRadicado.style.display = 'none', 100);
      });
      inputNumeroRadicado.addEventListener('keydown', function (e) {
          if (e.key === 'Enter') {
              e.preventDefault();
              activateOnly(chkNumeroRadicado);
              executeSearch();
          }
      });

      inputTitulo.addEventListener('input', function () {
          activateOnly(chkTitulo);
          fetchSuggestions('titulo', this.value.trim(), suggestionsTitulo, inputTitulo);
      });
      inputTitulo.addEventListener('blur', () => {
          setTimeout(() => suggestionsTitulo.style.display = 'none', 100);
      });
      inputTitulo.addEventListener('keydown', function (e) {
          if (e.key === 'Enter') {
              e.preventDefault();
              activateOnly(chkTitulo);
              executeSearch();
          }
      });

      inputTipo.addEventListener('input', function () {
          activateOnly(chkTipo);
          fetchSuggestions('tipo', this.value.trim(), suggestionsTipo, inputTipo);
      });
      inputTipo.addEventListener('blur', () => {
          setTimeout(() => suggestionsTipo.style.display = 'none', 100);
      });
      inputTipo.addEventListener('keydown', function (e) {
          if (e.key === 'Enter') {
              e.preventDefault();
              activateOnly(chkTipo);
              executeSearch();
          }
      });

      inputEtiqueta.addEventListener('input', function () {
          activateOnly(chkEtiqueta);
          fetchSuggestions('etiqueta', this.value.trim(), suggestionsEtiqueta, inputEtiqueta);
      });
      inputEtiqueta.addEventListener('blur', () => {
          setTimeout(() => suggestionsEtiqueta.style.display = 'none', 100);
      });
      inputEtiqueta.addEventListener('keydown', function (e) {
          if (e.key === 'Enter') {
              e.preventDefault();
              activateOnly(chkEtiqueta);
              executeSearch();
          }
      });

      fechaDesdeInput.addEventListener('change', function () {
          activateOnly(chkFecha);
      });
      fechaHastaInput.addEventListener('change', function () {
          activateOnly(chkFecha);
      });
      [fechaDesdeInput, fechaHastaInput].forEach(el => {
          el.addEventListener('keydown', function (e) {
              if (e.key === 'Enter') {
                  e.preventDefault();
                  if (chkFecha.checked) {
                      executeSearch();
                  }
              }
          });
      });

      function ver(id) {
          window.open(ctx + '/vistaPreviaDocumento.jsp?id=' + id, '_blank');
      }
      function descargar(id) {
          window.location.href = ctx + '/descargarDocumento.jsp?id=' + id;
      }
      function editar(id) {
          window.location.href = ctx + '/editarDocumento.jsp?id=' + id;
      }
        </script>
    </body>
</html>
