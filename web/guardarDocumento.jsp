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
    java.util.HashSet,
    java.util.List,
    java.util.Map,
    java.util.Set
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

    String idStr           = getParameter(fields, "id");        
    String idAreaStr       = getParameter(fields, "id_area");
    String titulo          = getParameter(fields, "titulo");
    String tipo            = getParameter(fields, "tipo");
    String esPlantillaStr  = getParameter(fields, "esPlantilla");
    String radicadoAStr    = getParameter(fields, "radicadoA");
    String requiereRespStr = getParameter(fields, "requiere_respuesta");
    String etiquetasCsv    = getParameter(fields, "etiquetas");
    FileItem fileItem      = fields.get("file"); 

    if (numeroRadicadoStr == null || numeroRadicadoStr.trim().isEmpty()) {
        out.println("<p style='color:red;'>El campo \"Número de radicado\" es obligatorio.</p>");
        return;
    }
    if (titulo == null || titulo.trim().isEmpty()) {
        out.println("<p style='color:red;'>El campo \"Título\" es obligatorio.</p>");
        return;
    }

    boolean modoCrear = (idStr == null || idStr.trim().isEmpty());
    if (modoCrear && (fileItem == null || fileItem.getSize() == 0)) {
        out.println("<p style='color:red;'>Debes seleccionar un archivo para crear el documento.</p>");
        return;
    }

    boolean isPlantilla  = "true".equalsIgnoreCase(esPlantillaStr);
    boolean requiereResp = "true".equalsIgnoreCase(requiereRespStr) || "on".equalsIgnoreCase(requiereRespStr);
    Integer idArea       = null;
    Integer radicadoA    = null;
    try {
        if (idAreaStr != null && !idAreaStr.isEmpty()) {
            idArea = Integer.parseInt(idAreaStr);
        }
    } catch(Exception ignore) {}
    try {
        if (radicadoAStr != null && !radicadoAStr.isEmpty() && !isPlantilla) {
            radicadoA = Integer.parseInt(radicadoAStr);
        }
    } catch(Exception ignore) {}

    String nombreArchivo = null;
    boolean huboArchivoNuevo = false;
    if (fileItem != null && fileItem.getSize() > 0) {
        huboArchivoNuevo = true;
        String uploadsDirPath = application.getRealPath("/") + File.separator + "uploads";
        File uploadsDir = new File(uploadsDirPath);
        if (!uploadsDir.exists()) uploadsDir.mkdirs();

        String originalName = new File(fileItem.getName()).getName();
        File targetFile = new File(uploadsDir, originalName);
        if (targetFile.exists()) {
            targetFile.delete();
        }
        try (InputStream in = fileItem.getInputStream();
             OutputStream outStream = new FileOutputStream(targetFile)) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                outStream.write(buffer, 0, bytesRead);
            }
        }
        nombreArchivo = originalName;
    }

    try (Connection conn = conexionBD.conectar()) {
        conn.setAutoCommit(false);
        int docId;
        String accion;
        String tituloAnterior = null;

        if (modoCrear) {
            String insertSQL =
                "INSERT INTO documento " +
                "(numero_radicado, titulo, tipo, id_area, es_plantilla, recibido_por, radicado_a, requiere_respuesta, respondido, nombre_archivo) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, FALSE, ?)";
            try (PreparedStatement ps = conn.prepareStatement(insertSQL, PreparedStatement.RETURN_GENERATED_KEYS)) {
                int idx = 1;
                ps.setString(idx++, numeroRadicadoStr);
                ps.setString(idx++, titulo);
                ps.setString(idx++, (tipo != null ? tipo : ""));
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
            accion = isPlantilla
                ? "CREAR_PLANTILLA: " + titulo
                : "CREAR_DOCUMENTO: " + titulo;

            String insertVerSQL = "INSERT INTO version (doc_id, numero, ruta) VALUES (?, 1, ?)";
            try (PreparedStatement pv = conn.prepareStatement(insertVerSQL)) {
                pv.setInt(1, docId);
                pv.setString(2, nombreArchivo);
                pv.executeUpdate();
            }

            session.setAttribute("globalMessage",
                "Documento “" + titulo + "” creado correctamente."
            );

        } else {
            docId = Integer.parseInt(idStr);

            String selTituloSQL = "SELECT titulo FROM documento WHERE id = ?";
            try (PreparedStatement ps0 = conn.prepareStatement(selTituloSQL)) {
                ps0.setInt(1, docId);
                try (ResultSet rs0 = ps0.executeQuery()) {
                    if (rs0.next()) {
                        tituloAnterior = rs0.getString("titulo");
                    }
                }
            }

            if (!huboArchivoNuevo) {
                String selArchivoSQL = "SELECT nombre_archivo FROM documento WHERE id = ?";
                try (PreparedStatement ps1 = conn.prepareStatement(selArchivoSQL)) {
                    ps1.setInt(1, docId);
                    try (ResultSet rs1 = ps1.executeQuery()) {
                        if (rs1.next()) {
                            nombreArchivo = rs1.getString("nombre_archivo");
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
                ps.setString(idx++, numeroRadicadoStr);               
                ps.setString(idx++, titulo);
                ps.setString(idx++, (tipo != null ? tipo : ""));
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

            accion = isPlantilla
                ? "EDITAR_PLANTILLA: " + (tituloAnterior != null ? (tituloAnterior + " → " + titulo) : titulo)
                : "EDITAR_DOCUMENTO: " + (tituloAnterior != null ? (tituloAnterior + " → " + titulo) : titulo);

            if (huboArchivoNuevo) {
                int siguienteNumero = 1;
                String selMaxSQL = "SELECT COALESCE(MAX(numero), 0) AS max_num FROM version WHERE doc_id = ?";
                try (PreparedStatement pm = conn.prepareStatement(selMaxSQL)) {
                    pm.setInt(1, docId);
                    try (ResultSet rm = pm.executeQuery()) {
                        if (rm.next()) {
                            siguienteNumero = rm.getInt("max_num") + 1;
                        }
                    }
                }
                String insertVerSQL = "INSERT INTO version (doc_id, numero, ruta) VALUES (?, ?, ?)";
                try (PreparedStatement pv = conn.prepareStatement(insertVerSQL)) {
                    pv.setInt(1, docId);
                    pv.setInt(2, siguienteNumero);
                    pv.setString(3, nombreArchivo);
                    pv.executeUpdate();
                }
            }

            session.setAttribute("globalMessage",
                "Documento “" + (tituloAnterior != null ? (tituloAnterior + " → " + titulo) : titulo) + "” actualizado correctamente."
            );
        }


        conn.commit();
        response.sendRedirect("documento.jsp");
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
