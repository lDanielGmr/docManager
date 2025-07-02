<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.io.File,
    java.io.InputStream,
    java.io.FileOutputStream,
    java.io.OutputStream,
    java.io.StringWriter,
    java.io.PrintWriter,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.util.HashMap,
    java.util.List,
    java.util.Map
" %>
<%@ page import="
    org.apache.commons.fileupload.FileItem,
    org.apache.commons.fileupload.disk.DiskFileItemFactory,
    org.apache.commons.fileupload.servlet.ServletFileUpload
" %>
<%@ page import="clasesGenericas.Usuario, ConexionBD.conexionBD" %>

<%
    Usuario user = (Usuario) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!ServletFileUpload.isMultipartContent(request)) {
        out.println("<p style='color:red;'>El formulario debe usar enctype=\"multipart/form-data\"</p>");
        return;
    }

    DiskFileItemFactory factory = new DiskFileItemFactory();
    ServletFileUpload upload = new ServletFileUpload(factory);
    upload.setHeaderEncoding("UTF-8");
    List<FileItem> items = upload.parseRequest(request);
    Map<String, FileItem> fields = new HashMap<>();
    for (FileItem fi : items) {
        fields.put(fi.getFieldName(), fi);
    }

    String numeroRadicadoStr = getParameter(fields, "numero_radicado");
    String idStr             = getParameter(fields, "id");
    String idAreaStr         = getParameter(fields, "id_area");
    String titulo            = getParameter(fields, "titulo");
    String tipo              = getParameter(fields, "tipo");
    String esPlantillaStr    = getParameter(fields, "esPlantilla");
    String radicadoAStr      = getParameter(fields, "radicadoA");
    String requiereRespStr   = getParameter(fields, "requiere_respuesta");
    String etiquetasCsv      = getParameter(fields, "etiquetas");
    String origin            = getParameter(fields, "origin");
    FileItem fileItem        = fields.get("file");

    boolean isPlantilla  = "true".equalsIgnoreCase(esPlantillaStr);
    boolean requiereResp = "true".equalsIgnoreCase(requiereRespStr);

    System.out.println("DEBUG guardarDocumento: esPlantillaStr=\"" + esPlantillaStr + "\", isPlantilla=" + isPlantilla);
    System.out.println("DEBUG guardarDocumento: numero_radicado recibido=\"" + numeroRadicadoStr + "\"");

    if (isPlantilla) {
        numeroRadicadoStr = "N/A";
    } else {
        if (numeroRadicadoStr == null || numeroRadicadoStr.trim().isEmpty() || "N/A".equalsIgnoreCase(numeroRadicadoStr.trim())) {
            out.println("<p style='color:red;'>El campo <strong>Número de radicado</strong> es obligatorio para documentos (no plantillas).</p>");
            return;
        }
    }

    if (titulo == null || titulo.trim().isEmpty()) {
        out.println("<p style='color:red;'>El campo <strong>Título</strong> es obligatorio.</p>");
        return;
    }

    boolean modoCrear = (idStr == null || idStr.trim().isEmpty());
    if (modoCrear && (fileItem == null || fileItem.getSize() == 0)) {
        out.println("<p style='color:red;'>Debes seleccionar un archivo para crear el documento.</p>");
        return;
    }

    Integer idArea    = null;
    Integer radicadoA = null;
    try {
        if (idAreaStr != null && !idAreaStr.isEmpty()) {
            idArea = Integer.parseInt(idAreaStr);
        }
    } catch(Exception ignore) {}
    try {
        if (!isPlantilla && radicadoAStr != null && !radicadoAStr.isEmpty() && !"NA".equalsIgnoreCase(radicadoAStr.trim())) {
            radicadoA = Integer.parseInt(radicadoAStr);
        }
    } catch(Exception ignore) {}

    String nombreArchivo = null;
    boolean huboArchivoNuevo = false;
    if (fileItem != null && fileItem.getSize() > 0) {
        huboArchivoNuevo = true;

        String uploadsDirPath = System.getenv("UPLOADS_DIR");
        if (uploadsDirPath == null || uploadsDirPath.trim().isEmpty()) {
            String userHome = System.getProperty("user.home");
            uploadsDirPath = userHome + File.separator + "uploads_app";
        }
        File uploadsDir = new File(uploadsDirPath);
        if (!uploadsDir.exists()) {
            if (!uploadsDir.mkdirs()) {
                uploadsDir = new File(application.getRealPath("/") + File.separator + "uploads");
                if (!uploadsDir.exists()) {
                    uploadsDir.mkdirs();
                }
            }
        }

        String originalName = new File(fileItem.getName()).getName().replaceAll("\\s+", "_");
        String uniqueName = System.currentTimeMillis() + "_" + originalName;
        File targetFile = new File(uploadsDir, uniqueName);
        try (InputStream in = fileItem.getInputStream();
             OutputStream outStream = new FileOutputStream(targetFile)) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                outStream.write(buffer, 0, bytesRead);
            }
        }
        nombreArchivo = uniqueName;
    }

    try (Connection conn = conexionBD.conectar()) {
        conn.setAutoCommit(false);
        int docId;
        String tituloAnterior = null;

        if (modoCrear) {
            String insertSQL =
                "INSERT INTO documento " +
                "(numero_radicado, titulo, tipo, id_area, es_plantilla, recibido_por, radicado_a, requiere_respuesta, respondido, nombre_archivo) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, FALSE, ?)";
            try (PreparedStatement ps = conn.prepareStatement(insertSQL, PreparedStatement.RETURN_GENERATED_KEYS)) {
                int idx = 1;
                ps.setString(idx++, numeroRadicadoStr.trim());
                ps.setString(idx++, titulo.trim());
                ps.setString(idx++, (tipo != null ? tipo.trim() : ""));
                if (idArea != null) {
                    ps.setInt(idx++, idArea);
                } else {
                    Integer userArea = user.getIdArea();
                    if (userArea != null) {
                        ps.setInt(idx++, userArea);
                    } else {
                        ps.setNull(idx++, java.sql.Types.INTEGER);
                    }
                }
                ps.setBoolean(idx++, isPlantilla);
                ps.setInt(idx++, user.getId());
                if (isPlantilla) {
                    ps.setNull(idx++, java.sql.Types.INTEGER);
                } else if (radicadoA != null) {
                    ps.setInt(idx++, radicadoA);
                } else {
                    ps.setNull(idx++, java.sql.Types.INTEGER);
                }
                ps.setBoolean(idx++, requiereResp);
                ps.setString(idx++, nombreArchivo);
                ps.executeUpdate();

                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        docId = rs.getInt(1);
                    } else {
                        throw new SQLException("No se obtuvo ID al crear documento.");
                    }
                }
            }

            try (PreparedStatement psAudit = conn.prepareStatement(
                    "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)"
                )) {
                psAudit.setInt(1, user.getId());
                psAudit.setInt(2, docId);
                psAudit.setString(3, "ADICIONAR_DOCUMENTO");
                psAudit.executeUpdate();
            }

            if (nombreArchivo != null) {
                try (PreparedStatement pv = conn.prepareStatement(
                        "INSERT INTO version (doc_id, numero, ruta) VALUES (?, 1, ?)"
                    )) {
                    pv.setInt(1, docId);
                    pv.setString(2, nombreArchivo);
                    pv.executeUpdate();
                }
            }

            try (PreparedStatement del = conn.prepareStatement(
                    "DELETE FROM docu_etiqueta WHERE doc_id = ?"
                )) {
                del.setInt(1, docId);
                del.executeUpdate();
            }
            if (etiquetasCsv != null && !etiquetasCsv.trim().isEmpty()) {
                String[] arr = etiquetasCsv.split(",");
                try (PreparedStatement insEt = conn.prepareStatement(
                        "INSERT INTO docu_etiqueta (doc_id, etq_id) VALUES (?, ?)"
                    )) {
                    for (String sId : arr) {
                        try {
                            int etqId = Integer.parseInt(sId.trim());
                            insEt.setInt(1, docId);
                            insEt.setInt(2, etqId);
                            insEt.addBatch();
                        } catch (NumberFormatException ignore) {}
                    }
                    insEt.executeBatch();
                }
            }

            session.setAttribute("globalMessage",
                isPlantilla
                ? "Plantilla \"" + titulo + "\" creada correctamente."
                : "Documento \"" + titulo + "\" creado correctamente."
            );

        } else {
            docId = Integer.parseInt(idStr);
            try (PreparedStatement ps0 = conn.prepareStatement(
                    "SELECT titulo, nombre_archivo FROM documento WHERE id = ?"
                )) {
                ps0.setInt(1, docId);
                try (ResultSet rs0 = ps0.executeQuery()) {
                    if (rs0.next()) {
                        tituloAnterior = rs0.getString("titulo");
                        if (!huboArchivoNuevo) {
                            nombreArchivo = rs0.getString("nombre_archivo");
                        }
                    }
                }
            }

            String updateSQL =
                "UPDATE documento SET " +
                " numero_radicado = ?, " +
                " titulo = ?, " +
                " tipo = ?, " +
                " id_area = ?, " +
                " es_plantilla = ?, " +
                " recibido_por = ?, " +
                " radicado_a = ?, " +
                " requiere_respuesta = ?, " +
                " nombre_archivo = ? " +
                "WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updateSQL)) {
                int idx = 1;
                ps.setString(idx++, numeroRadicadoStr.trim());
                ps.setString(idx++, titulo.trim());
                ps.setString(idx++, (tipo != null ? tipo.trim() : ""));
                if (idArea != null) {
                    ps.setInt(idx++, idArea);
                } else {
                    Integer userArea = user.getIdArea();
                    if (userArea != null) {
                        ps.setInt(idx++, userArea);
                    } else {
                        ps.setNull(idx++, java.sql.Types.INTEGER);
                    }
                }
                ps.setBoolean(idx++, isPlantilla);
                ps.setInt(idx++, user.getId());
                if (isPlantilla) {
                    ps.setNull(idx++, java.sql.Types.INTEGER);
                } else if (radicadoA != null) {
                    ps.setInt(idx++, radicadoA);
                } else {
                    ps.setNull(idx++, java.sql.Types.INTEGER);
                }
                ps.setBoolean(idx++, requiereResp);
                ps.setString(idx++, nombreArchivo);
                ps.setInt(idx++, docId);
                ps.executeUpdate();
            }

            try (PreparedStatement psAudit = conn.prepareStatement(
                    "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)"
                )) {
                psAudit.setInt(1, user.getId());
                psAudit.setInt(2, docId);
                psAudit.setString(3, "EDITAR_DOCUMENTO");
                psAudit.executeUpdate();
            }

            if (huboArchivoNuevo && nombreArchivo != null) {
                int siguienteNumero = 1;
                try (PreparedStatement pm = conn.prepareStatement(
                        "SELECT COALESCE(MAX(numero), 0) AS max_num FROM version WHERE doc_id = ?"
                    )) {
                    pm.setInt(1, docId);
                    try (ResultSet rm = pm.executeQuery()) {
                        if (rm.next()) {
                            siguienteNumero = rm.getInt("max_num") + 1;
                        }
                    }
                }
                try (PreparedStatement pv = conn.prepareStatement(
                        "INSERT INTO version (doc_id, numero, ruta) VALUES (?, ?, ?)"
                    )) {
                    pv.setInt(1, docId);
                    pv.setInt(2, siguienteNumero);
                    pv.setString(3, nombreArchivo);
                    pv.executeUpdate();
                }
            }

            try (PreparedStatement del = conn.prepareStatement(
                    "DELETE FROM docu_etiqueta WHERE doc_id = ?"
                )) {
                del.setInt(1, docId);
                del.executeUpdate();
            }
            if (etiquetasCsv != null && !etiquetasCsv.trim().isEmpty()) {
                String[] arr = etiquetasCsv.split(",");
                try (PreparedStatement insEt = conn.prepareStatement(
                        "INSERT INTO docu_etiqueta (doc_id, etq_id) VALUES (?, ?)"
                    )) {
                    for (String sId : arr) {
                        try {
                            int etqId = Integer.parseInt(sId.trim());
                            insEt.setInt(1, docId);
                            insEt.setInt(2, etqId);
                            insEt.addBatch();
                        } catch (NumberFormatException ignore) {}
                    }
                    insEt.executeBatch();
                }
            }

            session.setAttribute("globalMessage",
                isPlantilla
                ? "Plantilla \"" + (tituloAnterior != null ? (tituloAnterior + "\" actualizada a \"" + titulo) : titulo) + "\" correctamente."
                : "Documento \"" + (tituloAnterior != null ? (tituloAnterior + "\" actualizado a \"" + titulo) : titulo) + "\" correctamente."
            );
        }

        conn.commit();
        if ("plantilla".equals(origin)) {
            response.sendRedirect("documentoPlantilla.jsp");
        } else {
            response.sendRedirect("documento.jsp");
        }
        return;

    } catch (SQLException sq) {
        out.println("<h3 style='color:red;'>Error SQL: "
                    + sq.getMessage()
                    + " (Estado: " + sq.getSQLState()
                    + ", Código: " + sq.getErrorCode() + ")</h3>");
    } catch (Exception ex) {
        StringWriter sw = new StringWriter();
        ex.printStackTrace(new PrintWriter(sw));
        out.println("<pre style='color:red;'>" + sw.toString() + "</pre>");
    }
%>

<%!
    private String getParameter(Map<String, FileItem> fields, String name) throws Exception {
        FileItem fi = fields.get(name);
        return (fi == null) ? null : fi.getString("UTF-8");
    }
%>
