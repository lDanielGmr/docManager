<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.io.File,
    java.io.FileInputStream,
    java.io.IOException,
    java.io.OutputStream,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException
" %>
<%@ page import="ConexionBD.conexionBD" %>
<%
    String idParam = request.getParameter("id");
    String type    = request.getParameter("type");
    if (type == null) type = "version";

    if (idParam == null || idParam.trim().isEmpty()) {
        out.println("<h3 style='color:red;'>Parámetro 'id' faltante.</h3>");
        return;
    }
    int id;
    try {
        id = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        out.println("<h3 style='color:red;'>ID inválido: " + idParam + "</h3>");
        return;
    }

    String rutaRelativa = null;
    Integer documentoId = null;
    try (Connection conn = conexionBD.conectar()) {
        String sql;
        if ("version".equalsIgnoreCase(type)) {
            sql = "SELECT ruta, doc_id FROM version WHERE id = ?";
        } else if ("respuesta".equalsIgnoreCase(type)) {
            sql = "SELECT archivo_path, documento_id FROM documento_respuesta WHERE id = ?";
        } else {  // documento
            sql = "SELECT nombre_archivo, id AS documento_id FROM documento WHERE id = ? AND IFNULL(eliminado,0)=0";
        }

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    rutaRelativa = rs.getString(1);
                    documentoId  = rs.getInt(2);
                }
            }
        }

        if (rutaRelativa == null || rutaRelativa.trim().isEmpty()) {
            if (documentoId == null) documentoId = id;
            try (PreparedStatement ps2 = conn.prepareStatement(
                     "SELECT nombre_archivo FROM documento WHERE id = ? AND IFNULL(eliminado,0)=0"
                 )) {
                ps2.setInt(1, documentoId);
                try (ResultSet rs2 = ps2.executeQuery()) {
                    if (rs2.next()) {
                        rutaRelativa = rs2.getString("nombre_archivo");
                    }
                }
            }
        }
    } catch (SQLException ex) {
        out.println("<h3 style='color:red;'>Error BD: " + ex.getMessage() + "</h3>");
        return;
    }

    if (rutaRelativa == null || rutaRelativa.trim().isEmpty()) {
        out.println("<h3 style='color:red;'>Archivo no encontrado o registro inválido.</h3>");
        return;
    }

    String uploadsDirPath = System.getenv("UPLOADS_DIR");
    if (uploadsDirPath == null || uploadsDirPath.trim().isEmpty()) {
        String userHome = System.getProperty("user.home");
        uploadsDirPath = userHome + File.separator + "uploads_app";
        File hd = new File(uploadsDirPath);
        if (!hd.exists() && !hd.mkdirs()) {
            uploadsDirPath = application.getRealPath("/") + File.separator + "uploads";
        }
    }
    File carpeta = new File(uploadsDirPath);

    File archivo = new File(carpeta, rutaRelativa);
    if (!archivo.exists() || !archivo.isFile()) {
        out.println("<h3 style='color:red;'>El archivo físico no existe en el servidor:<br/>"
                    + archivo.getAbsolutePath() + "</h3>");
        return;
    }

    String mimeType = application.getMimeType(archivo.getName());
    if (mimeType == null) mimeType = "application/octet-stream";

    response.reset();
    response.setContentType(mimeType);
    response.setContentLengthLong(archivo.length());
    response.setHeader("Content-Disposition",
        String.format("attachment; filename=\"%s\"", archivo.getName()));

    try (FileInputStream fis = new FileInputStream(archivo);
         OutputStream fileOut = response.getOutputStream()) {
        byte[] buf = new byte[4096];
        int n;
        while ((n = fis.read(buf)) > 0) {
            fileOut.write(buf, 0, n);
        }
        fileOut.flush();
    } catch (IOException ioe) {
        log("Error enviando archivo: " + ioe.getMessage(), ioe);
    }
%>
