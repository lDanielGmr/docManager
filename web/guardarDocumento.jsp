<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.io.File,
    java.io.PrintWriter,
    java.io.StringWriter,
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
    Map<String,FileItem> map = new HashMap<>();
    for (FileItem fi : items) map.put(fi.getFieldName(), fi);

    String idStr          = map.get("id")       != null ? map.get("id").getString("UTF-8") : null;
    String titulo         = map.get("titulo").getString("UTF-8").trim();
    String tipo           = map.get("tipo").getString("UTF-8").trim();
    String recibidoPorStr = map.get("recibidoPor").getString("UTF-8").trim();
    String radicadoAStr   = map.get("radicadoA").getString("UTF-8").trim();
    String etiquetasCsv   = map.get("etiquetas").getString("UTF-8").trim();
    FileItem fileItem     = map.get("file") != null ? map.get("file") : map.get("nuevoArchivo");

    if (titulo.isEmpty()) {
        out.println("<p style='color:red;'>El título es obligatorio.</p>");
        return;
    }

    String filename = null;
    if (fileItem != null && fileItem.getSize() > 0) {
        File uploadsDir = new File(application.getRealPath("/") + File.separator + "uploads");
        if (!uploadsDir.exists()) uploadsDir.mkdirs();
        String baseName = new File(fileItem.getName()).getName();
        File target = new File(uploadsDir, baseName);
        if (target.exists()) {
            target.delete();  
        }
        fileItem.write(target);
        filename = baseName;
    }

    Integer recibidoPor = null, radicadoA = null;
    try { if (!recibidoPorStr.isEmpty()) recibidoPor = Integer.parseInt(recibidoPorStr); } catch(Exception ignore){}
    try { if (!radicadoAStr.isEmpty())   radicadoA   = Integer.parseInt(radicadoAStr);   } catch(Exception ignore){}

    try (Connection conn = conexionBD.conectar()) {
        conn.setAutoCommit(false);

        int docId;
        String accion;

        if (idStr != null && !idStr.trim().isEmpty()) {
            docId = Integer.parseInt(idStr);
            accion = "EDITAR_DOCUMENTO";

            StringBuilder sb = new StringBuilder(
                "UPDATE documento SET titulo=?, tipo=?, recibido_por=?, radicado_a=?"
            );
            if (filename != null) sb.append(", nombre_archivo=?");
            sb.append(" WHERE id=?");
            try (PreparedStatement ps = conn.prepareStatement(sb.toString())) {
                int idx = 1;
                ps.setString(idx++, titulo);
                ps.setString(idx++, tipo);
                if (recibidoPor != null) ps.setInt(idx++, recibidoPor);
                else ps.setNull(idx++, java.sql.Types.INTEGER);
                if (radicadoA != null) ps.setInt(idx++, radicadoA);
                else ps.setNull(idx++, java.sql.Types.INTEGER);
                if (filename != null) ps.setString(idx++, filename);
                ps.setInt(idx++, docId);
                ps.executeUpdate();
            }

            try (PreparedStatement pd = conn.prepareStatement(
                     "DELETE FROM docu_etiqueta WHERE doc_id=?")) {
                pd.setInt(1, docId);
                pd.executeUpdate();
            }


        } else {
            accion = "CREAR_DOCUMENTO";
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO documento "
                  + "(titulo,tipo,id_area,es_plantilla,recibido_por,radicado_a,requiere_respuesta,nombre_archivo) "
                  + "VALUES(?,?,?,?,?,?,?,?)", PreparedStatement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, titulo);
                ps.setString(2, tipo);
                ps.setNull(3, java.sql.Types.INTEGER);
                ps.setBoolean(4, false);
                if (recibidoPor != null) ps.setInt(5, recibidoPor);
                else ps.setNull(5, java.sql.Types.INTEGER);
                if (radicadoA != null) ps.setInt(6, radicadoA);
                else ps.setNull(6, java.sql.Types.INTEGER);
                ps.setBoolean(7, false);
                ps.setString(8, filename);
                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) docId = rs.getInt(1);
                    else throw new SQLException("No se obtuvo ID al crear documento.");
                }
            }

            if (!etiquetasCsv.isEmpty()) {
                try (PreparedStatement pe = conn.prepareStatement(
                         "INSERT INTO docu_etiqueta(doc_id,etq_id) VALUES(?,?)")) {
                    for (String s : etiquetasCsv.split(",")) {
                        int etqId = Integer.parseInt(s.trim());
                        pe.setInt(1, docId);
                        pe.setInt(2, etqId);
                        pe.addBatch();
                    }
                    pe.executeBatch();
                }
            }
        }

        try (PreparedStatement pa = conn.prepareStatement(
                 "INSERT INTO audit_log(usuario_id,documento_id,accion) VALUES(?,?,?)")) {
            pa.setInt(1, user.getId());
            pa.setInt(2, idStr != null && !idStr.trim().isEmpty() 
                         ? Integer.parseInt(idStr) 
                         : docId);
            pa.setString(3, accion);
            pa.executeUpdate();
        }

        conn.commit();

        out.println("<script>if(window.parent)window.parent.location.reload();</script>");
        return;

    } catch (SQLException sq) {
        out.println("<h3 style='color:red;'>Error en SQL</h3>");
        out.println("<pre>Mensaje: " + sq.getMessage()
                    + "\nSQLState: " + sq.getSQLState()
                    + "\nCódigo: " + sq.getErrorCode() + "</pre>");
    } catch (Exception ex) {
        StringWriter sw = new StringWriter();
        ex.printStackTrace(new PrintWriter(sw));
        out.println("<pre style='color:red;'>" + sw.toString() + "</pre>");
    }
%>
